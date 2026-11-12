# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.8"]
# ///
"""Simulation of the autoscaling laws of rules.yaml, without a cluster: a queue, pods that take a while to start on
nodes that take longer, Prometheus scrapes and rule evaluations at their real periods, and the HPA with its
tolerance, policies and stabilization window.

    uv run simulate.py                      # every scenario under every configuration: a table per scenario
    uv run simulate.py burst-200ms waves    # some scenarios
    uv run simulate.py --warm               # the model remembers the task duration of an earlier run
    uv run simulate.py --plot out/          # also one PNG per scenario
    uv run simulate.py --startup 20 120     # other pod and node startup times (s)

A model of the rules, not the rules: the PromQL is rewritten here in Python (class Rules), and Core is reduced to a
FIFO queue and a fixed overhead per task. It ranks the laws and shows their failure modes; the numbers of a real run
come from bench/autoscaling.py. README.md, "Simulation".
"""

from __future__ import annotations

import argparse
import math
import pathlib
import random
from collections import deque
from dataclasses import dataclass, field

SCRAPE, EVAL, HPA_SYNC = 10, 5, 15  # seconds: Prometheus scrape, rule evaluation, HPA sync period


# ---- Load -------------------------------------------------------------------------------------------------------------


@dataclass
class Scenario:
    name: str
    description: str
    arrivals: list[tuple[int, int, float]]  # (second, tasks, duration of each in seconds)
    horizon: int  # simulated seconds


def steady(rate: float, duration: float, seconds: int, start: int = 0) -> list[tuple[int, int, float]]:
    out, acc = [], 0.0
    for t in range(start, start + seconds):
        acc += rate
        if acc >= 1:
            out.append((t, int(acc), duration))
            acc -= int(acc)
    return out


def mixed(n: int, at: int, short: float, long: float, share_long: float, seed: int = 1) -> list[tuple[int, int, float]]:
    rnd = random.Random(seed)
    return [(at, 1, long if rnd.random() < share_long else short) for _ in range(n)]


SCENARIOS = {
    s.name: s
    for s in [
        Scenario("burst-200ms", "6000 tasks of 200 ms at once, from 0 pod", [(0, 6000, 0.2)], 900),
        Scenario("burst-10s", "1000 tasks of 10 s at once, from 0 pod", [(0, 1000, 10)], 1200),
        Scenario("steady-200ms", "20 tasks/s of 200 ms for 5 min", steady(20, 0.2, 300), 900),
        Scenario("waves", "10 tasks/s of 200 ms for 8 min, bursts of 3000 at 2 and 5 min",
                 steady(10, 0.2, 480) + [(120, 3000, 0.2), (300, 3000, 0.2)], 1200),
        Scenario("long", "2 batches of 40 tasks of 5 min, 7 min apart", [(0, 40, 300), (420, 40, 300)], 1500),
        Scenario("mixed", "2000 tasks at once: 90 % of 5 s, 10 % of 10 min", mixed(2000, 0, 5, 600, 0.1), 2400),
        Scenario("ramp", "30 tasks/s for 100 s: 80 % of 4 s, 20 % of 5 min",
                 [(t, 1, d) for t in range(100) for _, _, d in mixed(30, 0, 4, 300, 0.2, seed=t)], 2400),
    ]
}


# ---- Configurations ---------------------------------------------------------------------------------------------------


@dataclass
class Config:
    name: str
    law: str  # queue, dual, model
    hpa: str = "fast"  # chart, fast, ramp
    catchup: float = 60  # T
    utilization: float = 0.9  # eta
    startup: float = 0  # dt of the prediction; 0 = off
    queue_target: float = 2


# name -> (scale-up policies [(type, value)] per 15 s, scale-down stabilization window, cooldown to 0)
HPA_PROFILES = {
    "chart": ([("Percent", 100), ("Pods", 4)], 300, 300),  # Kubernetes' default scale-up policies
    "fast": ([("Percent", 1000), ("Pods", 100)], 60, 60),
    "ramp": ([("Percent", 100), ("Pods", 4)], 60, 60),
}


def configs(dt: float) -> list[Config]:
    return [
        Config("queue / chart HPA", "queue", hpa="chart"),
        Config("queue", "queue"),
        Config("dual", "dual"),
        Config("model", "model"),
        Config(f"model, predicted ({dt:.0f} s)", "model", startup=dt),
        Config("model, ramp HPA", "model", hpa="ramp"),
    ]


# ---- Cluster ----------------------------------------------------------------------------------------------------------


@dataclass
class Pod:
    ready_at: float
    node: "Node"
    free_at: float = 0.0  # end of its current task
    task: float | None = None  # duration of the task it runs (overhead included)
    task_start: float = 0.0

    def busy(self, t: float) -> bool:
        return self.task is not None and self.free_at > t


@dataclass
class Node:
    ready_at: float
    created_at: float
    pods: int = 0
    empty_since: float | None = None


@dataclass
class Cluster:
    pod_startup: float
    node_startup: float
    pods_per_node: int = 7  # a 8 vCPU node of 1 CPU workers and their agents
    node_ttl: float = 60  # an empty node goes away a minute later (compute-classes.tf)
    overhead: float = 0.2  # Core's own time per task, on top of the task (pre and post processing)
    grace: float = 30  # terminationGracePeriodSeconds of the chart: a removed pod ends a task shorter than that
    pods: list[Pod] = field(default_factory=list)
    nodes: list[Node] = field(default_factory=list)
    queue: deque = field(default_factory=deque)
    done_count: int = 0  # the agents' counters, as Prometheus would sum them
    done_ms: float = 0.0
    completions: list[tuple[float, float, Pod]] = field(default_factory=list)  # scheduled (time, duration, pod)
    killed: int = 0
    node_seconds: float = 0.0

    def scale(self, replicas: int, t: float) -> None:
        while len(self.pods) < replicas:
            node = next((n for n in self.nodes if n.pods < self.pods_per_node), None)
            if node is None:
                node = Node(ready_at=t + self.node_startup, created_at=t)
                self.nodes.append(node)
            node.pods += 1
            node.empty_since = None
            self.pods.append(Pod(ready_at=max(t, node.ready_at) + self.pod_startup, node=node, free_at=t))
        if len(self.pods) > replicas:
            # The pod deletion cost controller: idle and starting pods go first, then the youngest tasks
            order = sorted(self.pods, key=lambda p: (p.busy(t), -p.task_start if p.busy(t) else 0))
            for pod in order[: len(self.pods) - replicas]:
                if pod.busy(t) and pod.free_at - t > self.grace:  # the task is retried, its work is lost
                    self.killed += 1
                    self.queue.appendleft(pod.task - self.overhead)
                    self.completions = [c for c in self.completions if c[2] is not pod]
                self.pods.remove(pod)
                pod.node.pods -= 1
                if pod.node.pods == 0:
                    pod.node.empty_since = t

    def step(self, t: int) -> None:
        """Runs [t, t + 1): the ready pods take tasks as they get free."""
        for pod in self.pods:
            if pod.ready_at >= t + 1:
                continue
            while self.queue and pod.free_at < t + 1:
                start = max(pod.free_at, pod.ready_at, t)
                pod.task = self.queue.popleft() + self.overhead
                pod.task_start, pod.free_at = start, start + pod.task
                self.completions.append((pod.free_at, pod.task, pod))
        still = []
        for when, duration, pod in self.completions:
            if when < t + 1:
                self.done_count += 1
                self.done_ms += duration * 1000
            else:
                still.append((when, duration, pod))
        self.completions = still
        for node in list(self.nodes):
            self.node_seconds += 1
            if node.pods == 0 and node.empty_since is not None and t - node.empty_since >= self.node_ttl:
                self.nodes.remove(node)

    def ready(self, t: float) -> int:
        return sum(1 for p in self.pods if p.ready_at <= t)

    def processing(self, t: float) -> int:
        return sum(1 for p in self.pods if p.busy(t))


# ---- The rules, in Python ---------------------------------------------------------------------------------------------


def window(series: list[tuple[float, float]], t: float, seconds: float) -> list[tuple[float, float]]:
    return [(ts, v) for ts, v in series if t - seconds <= ts <= t]


def rate(series: list[tuple[float, float]], t: float, seconds: float) -> float | None:
    w = window(series, t, seconds)
    if len(w) < 2:
        return None
    return (w[-1][1] - w[0][1]) / (w[-1][0] - w[0][0])


def deriv(series: list[tuple[float, float]], t: float, seconds: float) -> float:
    w = window(series, t, seconds)
    if len(w) < 2:
        return 0.0
    mx, my = sum(x for x, _ in w) / len(w), sum(y for _, y in w) / len(w)
    den = sum((x - mx) ** 2 for x, _ in w)
    return sum((x - mx) * (y - my) for x, y in w) / den if den else 0.0


class Rules:
    """rules.yaml on the scraped samples: one target per law."""

    def __init__(self, cfg: Config, memory: float | None = None):
        self.cfg = cfg
        self.memory = memory  # tau of an earlier run, less than an hour ago
        self.count, self.ms = [], []  # scraped counters
        self.in_system, self.f_raw, self.acquired = [], [], []  # recorded series
        self.scraped = {"waiting": 0, "processing": 0, "ages": [], "ready": 0, "created": 0}
        self.last = {}

    def scrape(self, t: float, c: Cluster) -> None:
        self.count.append((t, c.done_count))
        self.ms.append((t, c.done_ms))
        self.scraped = {
            "waiting": len(c.queue),
            "processing": c.processing(t),
            "ages": [t - p.task_start for p in c.pods if p.busy(t)],
            "ready": c.ready(t),
            "created": len(c.pods),
        }
        for s in (self.count, self.ms):
            del s[:-400]  # an hour of scrapes

    def evaluate(self, t: float) -> dict[str, float]:
        cfg, s = self.cfg, self.scraped
        waiting, processing = s["waiting"], s["processing"]
        self.in_system.append((t, waiting + processing))
        completions = rate(self.count, t, 30) or 0.0
        arrivals = max(completions + deriv(self.in_system, t, 30), 0.0)
        # tau: sliding mean of the last minute, else the larger of the mean of the hour (or 1 s) and the mean age
        n1, ms1 = rate(self.count, t, 60), rate(self.ms, t, 60)
        nh, msh = rate(self.count, t, 3600), rate(self.ms, t, 3600)
        if n1 and ms1:
            tau = ms1 / n1 / 1000
        else:
            memory = msh / nh / 1000 if nh and msh else self.memory or 1.0
            tau = max(memory, sum(s["ages"]) / len(s["ages"]) if s["ages"] else 0.0)
        self.acquired.append((t, processing))
        held = max(v for _, v in window(self.acquired, t, 30))
        self.f_raw.append((t, min(min(arrivals, completions) * tau, held) / cfg.utilization))
        w = window(self.f_raw, t, 30)
        flow = sum(v for _, v in w) / len(w)
        running = max(processing * min(tau / (2 * cfg.catchup), 1), sum(min(a / cfg.catchup, 1) for a in s["ages"]))
        busy = max(flow, running)
        per_task = min(tau / (cfg.catchup * cfg.utilization), 1)
        consumed = max(s["ready"] - busy, 0) * cfg.utilization * cfg.startup / tau
        now = busy + waiting * per_task
        predicted = busy + max(waiting - consumed, 0) * per_task
        model = min(max(s["created"], predicted), now)
        del self.in_system[:-20], self.f_raw[:-20], self.acquired[:-20]
        self.last = {"tau": tau, "flow": flow, "running": running, "waiting_workers": waiting * per_task}
        return {
            "model": max(math.ceil(model - 1e-9), 1 if processing > 0 else 0),
            "queue": math.ceil((waiting + processing) / 2),
            "dual": max(math.ceil(waiting / cfg.queue_target), math.ceil(processing / cfg.utilization - 1e-9)),
        }


# ---- KEDA and the HPA -------------------------------------------------------------------------------------------------


class Hpa:
    def __init__(self, cfg: Config, max_replicas: int):
        self.policies, self.down_window, self.cooldown = HPA_PROFILES[cfg.hpa]
        self.max = max_replicas
        self.replicas = 0
        self.history: list[tuple[float, int]] = []  # (t, replicas), for the scale-up policies
        self.recommendations: list[tuple[float, int]] = []  # for the scale-down stabilization
        self.last_active = -1e9

    def sync(self, t: float, target: float) -> int:
        if target > 0:
            self.last_active = t
        if self.replicas == 0:  # KEDA: 0 -> 1 on activation
            if target > 0:
                self.replicas = 1
            else:
                return 0
        elif target <= 0 and t - self.last_active >= self.cooldown:  # KEDA: back to 0 after the cooldown
            self.replicas = 0
            self.recommendations.clear()
            return 0
        desired = self.replicas if abs(target / self.replicas - 1) <= 0.1 else math.ceil(target)
        desired = min(max(desired, 1), self.max)
        self.recommendations.append((t, desired))
        self.recommendations = [(ts, d) for ts, d in self.recommendations if t - ts <= self.down_window]
        if desired > self.replicas:
            base = min([r for ts, r in self.history if t - ts <= HPA_SYNC] or [self.replicas])
            limit = max(base * (1 + v / 100) if kind == "Percent" else base + v for kind, v in self.policies)
            self.replicas = min(desired, math.ceil(limit), self.max)
        elif desired < self.replicas:
            self.replicas = min(self.replicas, max(d for _, d in self.recommendations))
        self.history.append((t, self.replicas))
        del self.history[:-10]
        return self.replicas


# ---- Run --------------------------------------------------------------------------------------------------------------


def simulate(sc: Scenario, cfg: Config, pod_startup: float, node_startup: float, warm: bool = False,
             max_replicas: int = 100) -> dict:
    c = Cluster(pod_startup, node_startup)
    total = sum(n for _, n, _ in sc.arrivals)
    work = sum(n * d for _, n, d in sc.arrivals)
    rules, hpa = Rules(cfg, work / total + c.overhead if warm else None), Hpa(cfg, max_replicas)
    arrivals: dict[int, list[tuple[int, float]]] = {}
    for at, n, d in sc.arrivals:
        arrivals.setdefault(at, []).append((n, d))
    targets = {"model": 0.0, "queue": 0.0, "dual": 0.0}
    trace = {k: [] for k in ("t", "waiting", "ready", "busy", "desired", "model", "queue", "dual", "nodes", "tau")}
    wait_integral = idle = ready_s = 0.0
    end = None
    for t in range(sc.horizon):
        for n, d in arrivals.get(t, []):
            c.queue.extend([d] * n)
        if t % SCRAPE == 0:
            rules.scrape(t, c)
        if t % EVAL == 0:
            targets = rules.evaluate(t)
        if t % HPA_SYNC == 0 or (hpa.replicas == 0 and t % EVAL == 0):
            c.scale(hpa.sync(t, targets[cfg.law]), t)
        c.step(t)
        ready, busy = c.ready(t + 1), c.processing(t + 1)
        wait_integral += len(c.queue)
        ready_s += ready
        idle += max(ready - busy, 0)
        if end is None and c.done_count >= total and t > max(arrivals):
            end = t + 1
        for k, v in (("t", t), ("waiting", len(c.queue)), ("ready", ready), ("busy", busy), ("desired", hpa.replicas),
                     ("nodes", len(c.nodes)), ("tau", rules.last.get("tau", 0)), *targets.items()):
            trace[k].append(v)
    return {
        "config": cfg.name,
        "makespan_s": end,
        "mean_wait_s": wait_integral / total,
        "peak_pods": max(trace["ready"]),
        "ready_pod_s": ready_s,
        "idle_pod_s": idle,
        "node_core_h": c.node_seconds * 8 / 3600,
        "efficiency": work / (c.node_seconds * c.pods_per_node) if c.node_seconds else 0,
        "killed_tasks": c.killed,
        "trace": trace,
    }


COLUMNS = [("makespan_s", "Makespan (s)", "{:.0f}"), ("mean_wait_s", "Mean wait (s)", "{:.0f}"),
           ("peak_pods", "Peak pods", "{:.0f}"), ("ready_pod_s", "Ready pod·s", "{:,.0f}"),
           ("idle_pod_s", "Idle pod·s", "{:,.0f}"), ("node_core_h", "Node core·h", "{:.1f}"),
           ("efficiency", "Work / paid", "{:.2f}"), ("killed_tasks", "Tasks killed", "{:.0f}")]


def table(sc: Scenario, results: list[dict]) -> str:
    lines = [f"### {sc.name}: {sc.description}", "",
             "| Configuration | " + " | ".join(label for _, label, _ in COLUMNS) + " |",
             "|---|" + "---:|" * len(COLUMNS)]
    for r in results:
        cells = ["not finished" if r[k] is None else f.format(r[k]) for k, _, f in COLUMNS]
        lines.append(f"| {r['config']} | " + " | ".join(cells) + " |")
    return "\n".join(lines) + "\n"


def plot(sc: Scenario, results: list[dict], out: pathlib.Path) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, axes = plt.subplots(len(results), 1, sharex=True, figsize=(12, 2.6 * len(results)), constrained_layout=True)
    for ax, r in zip(axes, results):
        tr = r["trace"]
        t = [x / 60 for x in tr["t"]]
        ax.plot(t, tr["desired"], color="#6b7280", linewidth=1, label="desired (HPA)")
        ax.plot(t, tr["ready"], color="#2563eb", linewidth=1.8, label="ready (paid)")
        ax.fill_between(t, tr["busy"], color="#2563eb", alpha=0.25, linewidth=0, label="busy (useful)")
        right = ax.twinx()
        right.plot(t, tr["waiting"], color="#eb6834", linewidth=1.2, label="waiting tasks")
        right.set_ylim(bottom=0)
        right.spines[["top"]].set_visible(False)
        ax.set_ylim(bottom=0)
        ax.spines[["top"]].set_visible(False)
        ax.grid(alpha=0.25)
        end = "not finished" if r["makespan_s"] is None else f"{r['makespan_s']} s"
        ax.set_title(f"{r['config']}: makespan {end}, idle {r['idle_pod_s']:,.0f} pod·s, {r['node_core_h']:.1f} core·h",
                     loc="left", fontsize=9)
        if ax is axes[0]:
            handles = ax.get_legend_handles_labels()[0] + right.get_legend_handles_labels()[0]
            ax.legend(handles=handles, loc="upper right", fontsize=8, frameon=False, ncols=4)
    axes[-1].set_xlabel("minutes (left axis: pods, right axis: tasks)")
    fig.suptitle(f"{sc.name}: {sc.description} (simulation)", fontsize=10)
    out.mkdir(parents=True, exist_ok=True)
    fig.savefig(out / f"{sc.name}.png", dpi=110)
    plt.close(fig)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("scenarios", nargs="*", help=f"default: all ({' '.join(SCENARIOS)})")
    ap.add_argument("--startup", nargs=2, type=float, default=[15, 75], metavar=("POD", "NODE"),
                    help="seconds for a pod to be ready on a node that is there, and for a new node (default: 15 75)")
    ap.add_argument("--warm", action="store_true",
                    help="the same workload ran less than an hour ago: the model starts with its mean task duration, "
                         "instead of 1 s")
    ap.add_argument("--plot", type=pathlib.Path, help="directory of the PNG files")
    a = ap.parse_args()
    pod, node = a.startup
    print(f"Pod startup {pod:.0f} s, node startup {node:.0f} s, 7 pods per node, 100 pods at most, "
          f"0.2 s of Core overhead per task, {'warm' if a.warm else 'cold'} start.\n")
    for name in a.scenarios or SCENARIOS:
        sc = SCENARIOS[name]
        results = [simulate(sc, cfg, pod, node, a.warm) for cfg in configs(pod + node)]
        print(table(sc, results))
        if a.plot:
            plot(sc, results, a.plot)


if __name__ == "__main__":
    main()
