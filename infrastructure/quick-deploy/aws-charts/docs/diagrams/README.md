# Chart diagrams

Two Mermaid diagrams of the AWS quick deploy charts, for a deployment done with the `helm` CLI from values built from
the Terraform outputs (see [../helm-cli.md](../helm-cli.md)). They render on GitHub and in any Markdown viewer with
Mermaid support.

| Diagram | Answers |
|---|---|
| [1. What gets deployed](01-deployment.md) | The `armonik` umbrella and what it installs: platform (Cilium, Karpenter, operators), storage (RDS, S3, SQS), ingress, monitoring. The choices, and what to validate |
| [2. From Terraform to the helm releases](02-pipeline.md) | Terraform outputs, the CI step that builds the values, and the install order |

Charts and values come from `ArmoniK.Infra/charts` and `docs/examples/values/`. The chart version of a deployment can
differ slightly from the local checkout: the diagrams show the structure, not a version. They are maintained by hand.
