# Chart diagrams

Mermaid diagrams of how the AWS quick deploy charts fit together, for a deployment done with the `helm` CLI from values
files built from the Terraform outputs (see [../helm-cli.md](../helm-cli.md)). They render on GitHub and in any
Markdown viewer with Mermaid support.

| Diagram | Answers |
|---|---|
| [1. Pipeline](01-pipeline.md) | What the CI job does, from the Terraform outputs to the six `helm upgrade --install`; which output feeds which key; the options for the awk step |
| [2. Umbrellas](02-umbrellas.md) | What `armonik` and `armonik-operators` install: subcharts, third-party charts, configuration fragments, and the toggle of each |
| [3. Values](03-values.md) | Which values file goes with which release, what is injected in it, the two local charts, and where each choice is set |
| [4. Runtime](04-runtime.md) | What talks to what once deployed: AWS services, pods, operators, credentials |

## How to read them

- Charts and values come from `ArmoniK.Infra/charts` and `docs/examples/values/`. The chart version pinned by your
  deployment (`ARMONIK_VERSION`) can differ slightly from the local checkout: the diagrams show the structure, not a
  version.
- The examples are the **customer scenario**: RDS PostgreSQL, Valkey, SQS, the operators' Prometheus, the customer's
  own Grafana. The levers of what is off there are written in the nodes.
- Colors: green = installed and active, grey dashed = available but off or optional, yellow = injected value or
  configuration fragment, blue = Terraform or AWS, purple = operators.
- The diagrams are hand-maintained: when a values file or an umbrella `Chart.yaml` changes, check the node that
  names it.
