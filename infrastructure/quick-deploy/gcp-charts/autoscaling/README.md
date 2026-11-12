# Autoscaling of the compute plane

How many pods a partition needs, computed in PromQL and applied by KEDA and the HPA. This document states the
problem, the three laws that are computed, the mathematics behind the model, the metrics it reads, what was taken
from [llm-d](https://llm-d.ai/docs/architecture/autoscaling/keda-epp), and a review of the 2024 control study
("Asservissement d'ArmoniK", A. Lelièvre) the model descends from.

Status: the rules are unit-tested with promtool and compared in simulation. **Nothing here has run on a cluster
yet**: the numbers of "Simulation" come from a model, and `bench/autoscaling.py` is there to replace them with
measurements.

| File | Content |
|---|---|
| `rules.yaml` | The recording rules: inputs, task duration, the three laws |
| `rules.test.yaml` | Their unit tests, on synthetic series |
| `../autoscaling.tf` | The PrometheusRule, the parameters and the KEDA trigger and HPA of each partition |
| `simulate.py` | The laws on a simulated cluster |
| `../bench/autoscaling.py` | The laws on the real cluster, on twin partitions |
| `../monitoring/gen-dashboards.py` | Dashboard "Bench - autoscaling" |

## Use

A partition of `terraform.tfvars` selects its law and its HPA; without the block it keeps the chart's behaviour.

```hcl
partitions = {
  myapp = {
    image = "..."
    tag   = "1.0.0"
    autoscaling = {
      law             = "model" # queue (default), dual or model
      hpa             = "fast"  # chart (default), fast or ramp
      catchup_seconds = 120     # T, default 60
      startup_seconds = 90      # dt, default 0: no prediction
    }
  }
}
```

The three laws are computed for every partition, whatever it selects: the dashboard shows the two others next to
the one that drives the pods. They are computed on the load as the selected law shaped it, so they tell what the
others would have asked for, not what would have happened; a real comparison takes one partition per law
(`bench/autoscaling.py suite`).

```sh
promtool test rules rules.test.yaml           # the rules (Prometheus 2.45 and 3.x)
uv run simulate.py --warm                      # the laws on simulated loads
python3 ../monitoring/gen-dashboards.py ../monitoring/dashboards   # after a change of the dashboard
uv run ../bench/autoscaling.py suite           # on the cluster: every scenario under every law
```

## The problem

Notation, per partition:

| Symbol | Meaning | Where it comes from |
|---|---|---|
| `Q` | tasks waiting for a pod (submitted + dispatched) | metrics exporter |
| `B` | tasks being processed, i.e. busy pods | metrics exporter |
| `lambda` | tasks per second: arrivals `lambda_a`, completions `lambda_c` | polling agents, conservation |
| `tau` | time a task holds its pod (download, execution, upload) | polling agents |
| `n` | pods: ready `n_r`, created `n_c`, asked for `n*` | kube-state-metrics, the law |
| `eta` | share of its time a pod spends on tasks | parameter `utilization`, 0.9 |
| `T` | time given to absorb the queue | parameter `catchup_seconds`, 60 s |
| `dt` | time from a scale-up decision to a ready pod | parameter `startup_seconds`, measured |
| `Te` | period of the control loop | 15 s (HPA sync period) |

The plant is an integrator with a delay. Pods drain the queue at `n * eta / tau` tasks per second, tasks arrive at
`lambda_a`, and a pod asked for at `t` works from `t + dt`:

```
dQ/dt = lambda_a(t) - eta * n(t - dt) / tau
```

The arrivals are a disturbance, the pod count is the command, and the objective is double: finish early (keep `Q`
near 0) and pay for few idle pods. The two pull apart, and `T` is the knob between them.

Two facts shape everything that follows:

- **The delay is one-sided.** Starting a pod takes `dt` (15 s on a node that is there, 60 to 120 s when GKE creates
  the node); removing a pod is immediate for the queue. Too few pods are corrected at the next evaluation, too many
  are paid for at least `dt` plus the scale-down window, and the node for a minute more. Every estimate below is
  biased towards too few on purpose.
- **A pod is not the unit of cost, a node is.** An empty workers node goes away a minute later
  (`compute-classes.tf`), so a pod that was useful for 10 s costs a share of a node for minutes. This is what makes
  the first point matter.

## The three laws

`armonik:scaler_target{partition, law}`, a number of pods.

**queue**: `ceil((Q + B) / 2)`. The chart's default, read by KEDA straight from the metrics exporter, with no
Prometheus in the path. It knows nothing about the tasks: 2 tasks per pod whatever they last. Two defects follow.
With short tasks it asks for far too many pods (6000 tasks of 0.2 s are 20 pod·minutes of work, it asks for 3000
pods). With long tasks it asks for too few at the worst moment: once the queue is empty, `B` running tasks ask for
`B / 2` pods, and the HPA removes half of the pods that are running a task.

**dual**: `max(ceil(Q / q), ceil(B / eta))`. The shape llm-d recommends: one signal for the unmet demand (their
flow-control queue size), one for the active concurrency (their running requests), each with a per-pod target, the
larger wins. A pod runs one task at a time, so the concurrency target is `eta`: the law never asks for fewer pods
than there are running tasks, which fixes the second defect of `queue` with no rule on the task duration. The
first defect stays: `q` is a constant.

**model**: `ceil(max(F, R) + W)`, at least 1 while a task is processing. The rest of this document.

## The model

### F, the flow

By Little's law, a system served at rate `lambda` by tasks lasting `tau` holds `lambda * tau` tasks in service on
average. One task per pod, and a pod is busy `eta` of its time:

```
F = min(lambda_a, lambda_c) * tau / eta        bounded by max over 30 s of the tasks held by pods, / eta
```

In control terms `F` is the feedforward of the 2024 study (its section 3.3, `C'(p) = tau`): it cancels the
disturbance instead of waiting for the queue to show it. Without it a proportional law on `Q` alone leaves a
permanent queue under a steady flow: at equilibrium `n = lambda * tau / eta` must come from `W`, which takes
`Q = lambda * T`, i.e. every task waits `T`.

Three precautions:

- `min(lambda_a, lambda_c)`: Core exports no counter of submitted tasks, so the arrivals are
  `lambda_c + d(Q + B)/dt`, and a burst is a huge slope for 30 s. A burst is a stock, which `W` counts; the
  completions cannot follow a slope, so the minimum keeps the flow.
- The bound by the tasks held by pods: Little's law is about averages over windows longer than `tau`. 40 tasks of
  5 min that end within 30 s read as 1.3 tasks/s of 300 s, 440 pods, at the moment the next batch arrives. A flow
  cannot ask for more pods than were seen busy.
- A 30 s average: the counts move by steps, and the HPA holds every upward jitter for its whole scale-down window.
  The two bounds apply before the average, so a spike never enters it whole (llm-d's "clamp, then smooth").

### R, the running tasks

The tasks being processed keep their pod. For short tasks `F` covers them; for long ones there are few completions
per second, `F` is near 0, and at the end of a batch `W` is 0 too.

```
R = max( B * min(tau / 2, T) / T ,  sum over the busy pods of min(age / T, 1) )
```

The first term is an expectation: a running task has `tau / 2` left on average, and needs its pod for that share
of the next `T` seconds. The second is evidence: a task running for `T` or more is long, whatever `tau` says. It
exists for mixed workloads: with short and long tasks together `tau` is the duration of the short ones, the only
ones that complete, and the first term alone lets the HPA scale below the pods of the long tasks. This is the
"workers occupied for long" of the study (its equation 22), with a ramp instead of an exponential.

`max(F, R)` and not `F + R`: in a steady flow the running tasks are the flow.

### W, the queue

`Q` tasks are `Q * tau` pod·seconds of work. To absorb them in `T` with pods busy `eta` of their time:

```
W = Q * min(tau / (T * eta), 1)
```

This is the proportional corrector of the study, `K = tau / T`: a pod started for the queue has `T` seconds of
work ahead, which bounds the waste of starting it. The cap at one pod per task is its `K <= 1`: 50 tasks of 10 min
are 50 pods, not 555.

### tau, the task duration

`tau` is pre-processing + execution + post-processing, from the histograms of the polling agents: execution alone
misses the download of the inputs and the upload of the results, half of the time on 200 ms tasks.

It is a **sliding mean over the tasks**, never a median:

```
tau = (time spent by the tasks completed in the window) / (tasks completed in the window)
```

- over the last minute while tasks complete: reactive;
- else the larger of the same mean over the last hour (the memory; 1 s without any) and the mean age of the
  running tasks.

Why the mean. Capacity is about work, and work is `tasks * mean duration`: Little's law is a statement about
means. With 90 % of tasks of 5 s and 10 % of 10 min, the median is 5 s and the mean 64.5 s; a law fed with the
median plans for 8 % of the work. The earlier version used the median of the past measures as its memory, to
ignore the few tasks that end alone after a run and measure a duration of their own. A mean weighted by task does
that better: one straggler among 6000 tasks weighs 1/6001, where a mean (or a median) of per-minute measures gives
its minute the same weight as a busy one.

Why the mean age. Before the first completion of a new workload there is no measure, but each running task lasts
at least its age, so the mean duration of the running tasks is at least their mean age: a lower bound, which is
the side to err on. The median age is a bound of nothing.

Known bias, kept. A mean over completed tasks is biased low while long tasks are running, because they have not
completed yet. `armonik:task_duration_seconds:little` (busy pods / completions, Little's law read backwards)
counts their time and is unbiased in steady state, but it over-reacts in the case that costs: long tasks holding
pods when a burst of short ones arrives. The study reached the same conclusion (its sections 7 and 8) and chose to
underestimate. The series is on the dashboard: far above the measure, it says long tasks are holding pods.

Known limit. When nothing completes and the only running tasks are old (one straggler), a burst is sized with
their age until the first completion, a few seconds after a free pod takes a task. With no free pod that lasts a
pod startup. The `ramp` HPA bounds the damage.

### The startup delay: prediction

With `startup_seconds` set, `W` is computed on the queue as it will be when a pod started now is ready. The pods
there are, beyond those `max(F, R)` needs, will have consumed in the meantime:

```
consumed = max(n_r - max(F, R), 0) * eta * dt / tau
W'       = max(Q - consumed, 0) * min(tau / (T * eta), 1)
```

and the prediction only counts to scale up, since only starting a pod takes `dt`:

```
n* = min( max(n_c, max(F, R) + W'), max(F, R) + W )
```

that is: `max(F,R) + W'` when even the predicted queue needs more pods than were created; `max(F,R) + W` when even
the queue as it is needs fewer; the pods already created in between.

This is a Smith predictor: the model of the plant is run forward over the delay, and the corrector acts on the
predicted output, which takes the delay out of the loop. It is the "future consumption" of the study (its
equations 19 to 27), and llm-d's credit for replicas "provisioned but not yet serving" (their `ready / replicas`
factor), in an additive form. Its meaning for the cost: a pod is started only for work that will still be there
when it is ready.

## Stability, and the choice of T

Take `W` alone, in discrete time. Every `Te` the law asks `n = Q * tau / (T * eta)` pods, which drain
`n * eta * Te / tau = Q * Te / T` tasks per period once started, `d = ceil(dt / Te)` periods later:

```
Q[k+1] = Q[k] - (Te / T) * Q[k - d]
```

The characteristic equation is `z^(d+1) - z^d + Te/T = 0`, and its roots stay in the unit circle if and only if

```
Te / T  <  2 * sin( pi / (2 * (2d + 1)) )        for large d:   T  >  (2 * dt + Te) / pi
```

(checked numerically for d = 0 to 10). With `Te` = 15 s:

| Startup `dt` | `d` | Smallest stable `T` | `T` for a 60° phase margin, `6 (dt + Te/2) / pi` |
|---|---|---|---|
| 15 s (node there) | 1 | 15 s | 43 s |
| 45 s | 3 | 34 s | 100 s |
| 90 s (new node) | 6 | 62 s | 186 s |
| 120 s | 8 | 82 s | 244 s |

The last column is three times the limit: the usual margin for a response without oscillation (the open loop is
`e^(-(dt + Te/2) p) / (T p)`, whose phase margin is `90° - (dt + Te/2) / T` in radians). So the default `T` = 60 s
is comfortable when the nodes are there and at the limit when GKE has to create them.
Unstable does not mean divergent here, since pods and queues are bounded: it means pods asked for after the queue
they were meant for is gone, i.e. idle pods and nodes. Three things move the limit:

- the prediction removes the delay from the loop: with `startup_seconds` set, the bound is that of `d = 0`,
  `T > Te / 2`, and `T` is then a choice of cost against time only;
- the HPA scale-down window hides oscillations (it holds the maximum), at the price of idle pods;
- `F` and `R` do not depend on `Q`: they are outside the loop.

The study found the same thing from the other side (its section 4): with `C = -1` (one pod per task) the loop is
unstable as soon as the delay exceeds the task duration, and lowering the gain restores it; its rule of thumb
"stable when `dt < tau`" is this bound with `T = tau`.

In practice: read the pod startup on the dashboard (row "Startup time"), set `startup_seconds` to its median, and
choose `T` as the time a pod must work to be worth starting, a few times the startup. The simulated sweep below
(scenario `waves`, startup 90 s) shows the trade: the wait grows with `T`, the idle pods fall, and the prediction
helps where the bound says it should, when `T` is below the startup.

| `T` | Prediction | Mean wait (s) | Peak pods | Idle pod·s | Node core·h |
|---:|---|---:|---:|---:|---:|
| 15 | off | 28 | 100 | 10,432 | 12.4 |
| 15 | 90 s | 29 | 91 | 7,894 | 10.0 |
| 30 | off | 38 | 59 | 6,162 | 8.1 |
| 30 | 90 s | 43 | 59 | 4,031 | 6.8 |
| 60 | off | 47 | 31 | 2,876 | 4.6 |
| 60 | 90 s | 50 | 33 | 2,676 | 5.0 |
| 120 | off | 63 | 24 | 1,238 | 3.8 |
| 120 | 90 s | 66 | 21 | 1,145 | 3.8 |
| 240 | off | 108 | 20 | 388 | 3.1 |

## KEDA and the HPA

The law gives a number of pods; the trigger reads it with a threshold of 1, so the HPA's `ceil(value / 1)` is the
law. What the HPA adds is part of the control loop:

| Mechanism | Value | Role in the loop |
|---|---|---|
| HPA sync period | 15 s, fixed by GKE | the sampling period `Te` between 1 and N pods; KEDA's `pollingInterval` only drives 0 to 1 |
| Tolerance | 10 % | a dead band: no change while the target is within 10 % of the pods. The hysteresis llm-d writes in its formula comes for free |
| Scale-up policy | `fast`: none. `ramp`: x2 or +4 per 15 s | `ramp` is the progressive take-in of a burst of the study (its equation 21, growth by a factor per period): the first pods measure `tau` before the bulk of the pods, and of the nodes, is asked for |
| Scale-down window | `chart` 300 s, `fast` and `ramp` 60 s | holds the maximum of the window: hides jitter, keeps the pods that are starting, and pays idle pods for that long |
| `cooldownPeriod` | 300 s or 60 s | only the last step, 1 to 0 |
| Fallback | 3 failures, keep the pods | Prometheus is in the path of `dual` and `model`: an empty answer is an error, not 0 (`ignoreNullValues: "false"`), and KEDA keeps the pods there are |
| `terminationGracePeriodSeconds` | 30 s (chart) | a pod removed while it runs a longer task loses it; Core retries it. `R` is what avoids it; the pod-deletion-cost controller picks idle pods first |

llm-d sets 300 s windows both ways, sized on a model load of 4 minutes; their scale-up window is their answer to
the overshoot while pods start. Here the target is absolute (a pod count, not a ratio to the current pods), so
asking again does not add pods, and the startup is handled by the prediction instead of by delaying every
scale-up.

## What comes from llm-d

Their autoscaling is KEDA alone since 1.0 (the custom controller, WVA, is deprecated); the relevant pages are
"KEDA with EPP Metrics" and "SLO-Aware Autoscaling".

| llm-d | Here |
|---|---|
| Demand signals instead of utilization (queue, running requests) | `Q` and `B`, never CPU |
| Dual-metric strategy: unmet demand and active concurrency, the larger wins | the `dual` law; `max(F, R) + W` in the model |
| One formula whose output is the replica count, target 1 (SLO-aware path) | `armonik:scaler_target`, threshold 1 |
| Signal chain raw -> clamp -> smooth, as recording rules | `scaler_flow_workers:raw` (two bounds), then a 30 s average |
| Credit for replicas provisioned but not serving (`ready / replicas`) | the prediction, from `n_r` and `n_c` |
| Hysteresis band | the HPA tolerance |
| Fast up, slow down, windows sized on the startup time | HPA profiles; `T` and `dt` sized on the measured startup |
| A failing trigger must be visible, absence is not zero | `ignoreNullValues: "false"`, fallback, "KEDA scaler errors" on the dashboard |
| Latency against an SLO as the signal | not done: Core exports no queue wait. `T` plays that role (a task waits about `T` at most once pods are there) |

Not taken: their thresholds (tuned for model servers), the 300 s scale-up window (a batch queue is not hurt by an
early pod the way a model load is), Kueue (one budget per partition is `maxReplicaCount`).

## Metrics

| Series | Source | Used for |
|---|---|---|
| `armonik_<partition>_tasks_{submitted,dispatched,processing}` | Core metrics exporter, 10 s | `Q`, `B`, arrivals |
| `TaskHandler_{PreProcessing,ExecuteTask,PostProcessing}_milliseconds_{sum,count}` | polling agents, per pod | `tau`, completions |
| `TaskRunningTime_Milliseconds` | polling agents, per pod | ages: `R`, `tau` before the first completion |
| `kube_deployment_status_replicas{,_available}` | kube-state-metrics | `n_c`, `n_r`: prediction, idle pods |
| `kube_pod_created`, `kube_pod_status_{scheduled,ready}_time` | kube-state-metrics | startup time (dashboard) |
| `kube_horizontalpodautoscaler_*`, `keda_scaler_*` | kube-state-metrics, KEDA | what the HPA did (dashboard) |

Workarounds in place, and what a change in Core would replace them with:

| Missing | Workaround | Proposal for Core |
|---|---|---|
| Counter of submitted tasks per partition | arrivals = completions + slope of the unfinished tasks, noisy, bounded by the completions | `tasks_submitted_total{partition}` in the submitter |
| Counter of completed tasks per partition and status | the `_count` of a histogram, per pod, summed; series vanish with their pod | `tasks_completed_total{partition, status}` |
| Partition as a label | the partition is in the metric name; `label_replace` on `__name__` | `armonik_tasks{partition, status}` |
| Queue wait | Little's law on the dashboard (integral of `Q` over completions); no SLO-based law | histogram of acquisition date - submission date in the agent |
| Busy pods | `processing` from the database, sampled; `dispatched` mixes prefetch and download | gauge `busy` (0/1) per agent |
| Age of the running task | biased by the prefetch, frozen on a terminating pod (filtered with `changes()`) | start of execution rather than of acquisition, 0 when terminating |

None of them blocks the model; the first two would remove most of the noise `F` has to be protected from.

## Simulation

`simulate.py` runs the laws on a queue, pods and nodes with startup times, at the real periods (scrape 10 s, rules
5 s, HPA 15 s) and with the HPA's tolerance, policies and window. It is a model of the rules, rewritten in Python,
with Core reduced to a FIFO queue and 0.2 s of overhead per task: it ranks the laws and shows how they fail, it
does not predict a bill. Pod startup 15 s, node startup 75 s, 7 pods per node, 100 pods at most, the task duration
known from an earlier run (`--warm`). "queue / chart HPA" is today's default; the other rows use the `fast` HPA.

Steady flow, 20 tasks/s of 200 ms for 5 min (8 busy pods at equilibrium):

| Configuration | Mean wait (s) | Peak pods | Idle pod·s | Node core·h | Tasks killed |
|---|---:|---:|---:|---:|---:|
| queue / chart HPA | 27 | 100 | 30,928 | 16.3 | 0 |
| queue | 19 | 100 | 8,043 | 9.2 | 0 |
| dual | 19 | 100 | 7,323 | 8.8 | 0 |
| model | 50 | 21 | 1,588 | 2.4 | 0 |

10 tasks/s of 200 ms for 8 min, with bursts of 3000 at 2 and 5 min:

| Configuration | Mean wait (s) | Peak pods | Idle pod·s | Node core·h | Tasks killed |
|---|---:|---:|---:|---:|---:|
| queue / chart HPA | 15 | 100 | 46,047 | 22.0 | 0 |
| queue | 20 | 100 | 14,909 | 16.2 | 0 |
| dual | 25 | 100 | 15,447 | 16.3 | 0 |
| model | 47 | 31 | 2,876 | 4.6 | 0 |
| model, predicted (90 s) | 50 | 33 | 2,676 | 5.0 | 0 |

2 batches of 40 tasks of 5 min, 7 min apart:

| Configuration | Makespan (s) | Mean wait (s) | Peak pods | Node core·h | Tasks killed |
|---|---:|---:|---:|---:|---:|
| queue / chart HPA | 1111 | 245 | 33 | 12.5 | 0 |
| queue | not finished | 309 | 30 | 11.9 | 26 |
| dual | 931 | 134 | 55 | 12.8 | 0 |
| model | 721 | 45 | 42 | 12.9 | 0 |

2000 tasks at once, 90 % of 5 s and 10 % of 10 min:

| Configuration | Makespan (s) | Mean wait (s) | Node core·h | Tasks killed |
|---|---:|---:|---:|---:|
| queue / chart HPA | not finished | 501 | 71.5 | 75 |
| queue | not finished | 461 | 65.5 | 55 |
| dual | 1619 | 445 | 53.2 | 0 |
| model | 1619 | 445 | 53.3 | 0 |

What it says:

- On short tasks the model pays 3 to 4 times fewer node core·hours than the queue depth with the same HPA (5 to 7
  times fewer than today's default), for 20 to 30 s more wait,
  most of it during the cold start, where it asks for the pods the work needs (20) instead of all of them (100).
  That wait is `T`: lower it to buy time with pods.
- On long tasks the queue depth removes pods that are running tasks (26 and 55 to 75 tasks killed and retried, runs
  that do not finish in the simulated time). The chart's 300 s window hides it for tasks shorter than the window.
  `dual` and the model never do.
- `dual` is the cheap fix for long tasks and changes nothing for short ones.
- The prediction and the `ramp` HPA are second-order on these loads; the prediction matters when `T` is below the
  startup (previous table).
- Cold (no memory of `tau`, `uv run simulate.py`): the model starts from 1 s per task, so a first burst of 200 ms
  tasks is sized 2.5 times too large and a first burst of 10 s tasks 10 times too small for a few seconds. After
  one run the memory holds for an hour.

## Review of the 2024 study

The study models ArmoniK as the integrator with delay above, tunes a PID on it, finds that only the proportional
action helps, then builds by simulation (SimGrid) a series of correctors (TA, TX, TBL) around one idea: a pod
started must work at least `T`. Its conclusions hold and the model implements them. Corrections:

| Where | Issue |
|---|---|
| Eq. 9 | `Td * p^2` should read `Td * p` (eq. 10 is consistent with the corrected form) |
| Eq. 12 | `K' = G * wc / (1 + wc^2 T^2)` should read `(1/G) * ...`: the corrector's gain is the inverse of the plant's, as section 4.4.2 uses it (`K = 1/33` for `G = 33`) |
| Eq. 18 | `K = max(tau/T, 1)` should read `min`: the text states a maximal gain of 1 (one pod per task) |
| Eq. 21 | `max(n_tasks, (1 + x Te/T) n_pc)` should read `min`: it is a limit on the growth |
| Section 4.3 | "stable when `dt < tau`" (with `C = -1`) is approximate: the exact condition is `Te/tau < 2 sin(pi / (2(2d+1)))`, about `tau > (2 dt + Te) / pi` |
| Section 8.2 | `x = 5` is said to give a factor `e^5` over `T`; `e^5` is 148, the 57 quoted further is `1.5^10`: with 10 periods the limit `(1 + x/n)^n -> e^x` is far |
| Section 11.2 | "20 % of short tasks and 80 % of long ones": the reverse of the profile of section 5.5 |
| Section 6.1 | "removing workers is immediate": true for the queue, not for the bill. On Kubernetes a pod is removed after the HPA window, and its node a minute later |

Complements:

- Why the integral and derivative actions failed (sections 4.5 and 4.6). The plant already integrates, so an
  integral action makes the open loop start at -180° (figures 16 and 25) and the loop only conditionally stable;
  the unfiltered derivative raises the gain again near the Nyquist frequency (the upturn at the right of the same
  figures), a second crossover with no phase margin. With a type 1 plant, a proportional corrector already has no
  static error on a step; the error it leaves on a ramp (a steady flow) is what the feedforward `F` removes.
- The equivalence between "initial queue `Q0`, zero setpoint" and a step of setpoint (section 3.2, "to be
  demonstrated") follows from linearity: an initial condition on the integrator is a step at its output.
- The estimate of `tau` is the central difficulty of sections 5 to 9 because the simulated controller only saw the
  queue. The polling agents export the duration of each completed task, which removes most of it; what remains is
  the bias of completed-only measures, discussed above.
- Its feedforward `C'(p) = tau * e^((dt + dt')p)` is not causal; without the prediction term it is Little's law.
- Its "future consumption" is a Smith predictor; its "progressive take-in" is an HPA scale-up policy; its
  "do not remove busy workers" is `R`, plus the pod-deletion-cost controller.

Where each idea went:

| Study | Implementation |
|---|---|
| Proportional corrector `K = tau / T`, `K <= 1` (sections 4.7, 6.4) | `W` |
| Count the busy workers with the queue (5.6.2) | `max(F, R)` added to `W` |
| Do not remove busy workers (5.3, 6.3) | `R`, floor of 1 while a task runs |
| Workers "occupied for long" and "apt" (9.2) | `R` from the ages |
| Future consumption, for scale-up only (6.5, 9.4.2, 9.8) | the prediction |
| Do not remove workers being created (9.4.1) | `n_c` in the prediction; the HPA window |
| Progressive take-in (8.2, 9.1) | HPA `ramp` |
| Moving average of `tau`, minimal `tau` (7.2, 9.11) | sliding means of 1 min and 1 h; 1 s default |
| Feedforward of the arrivals (3.3) | `F` |
| Nodes rather than workers (9.7.6) | not done: see below |

## Limits and next steps

- **Measure.** Run `bench/autoscaling.py suite` on the cluster and replace the simulated tables.
- **Nodes.** The law counts pods; the bill counts nodes of 7 pods. Rounding the target up to full nodes, or
  holding the last pods of a node, is the next lever on cost.
- **Cold start of `tau`.** 1 s when a partition has no history; a per-partition default would be one more
  parameter.
- **Arrivals.** Derived, not measured: a counter in Core would let `F` react to a flow before the completions do.
- **SLO.** With a queue-wait histogram in Core, `T` could be replaced by a target on the wait, as llm-d does with
  latency.
- **Several partitions on the same nodes** compete for them; nothing arbitrates beyond `maxReplicaCount`.
