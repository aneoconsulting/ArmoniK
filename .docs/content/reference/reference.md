# Reference

## Configuration reference

Environment variables for each component are documented in the respective project's reference:

- [ArmoniK.Api — Environment Variables](https://armonikapi.readthedocs.io/en/latest/content/usage/envars/index.html)
- [ArmoniK.Core — Environment Variables](https://armonikcore.readthedocs.io/en/latest/content/envars/index.html)

---

## CLI reference

The ArmoniK CLI (`armonik`) is the primary tool for interacting with a running ArmoniK cluster from the terminal. Source code is available on [ArmoniK.CLI](https://github.com/aneoconsulting/ArmoniK.CLI), and full documentation is available at [armonikadmincli.readthedocs.io](https://armonikadmincli.readthedocs.io/en/latest/).

## Image tags and compatibility matrix

The following table lists ArmoniK release versions and their tested Kubernetes compatibility. All component images for a given ArmoniK version are pinned in [`versions.tfvars.json`](https://github.com/aneoconsulting/ArmoniK/blob/main/versions.tfvars.json) in the main repository.

| ArmoniK version | Supported Kubernetes versions |
|---|---|
| 2.20.0 | 1.25, 1.29 |
| 2.20.1 | 1.25, 1.30 |
| 2.21.0 | 1.25, 1.31 |
| 2.22.0 | 1.32 |
| 2.22.1 | 1.32 |
| 2.22.2 | 1.32, 1.33 |
| 2.22.3 | 1.32, 1.33 |

---

## Error codes & messages

ArmoniK uses standard [gRPC status codes](https://grpc.github.io/grpc/core/md_doc_statuscodes.html). The table below lists the codes that appear most frequently in ArmoniK deployments and what they indicate.

| gRPC status | Typical cause in ArmoniK |
|---|---|
| `OK` | Request completed successfully |
| `CANCELLED` | The session or task was explicitly cancelled by a client |
| `INVALID_ARGUMENT` | Malformed request — missing required field, invalid partition ID, or null `PartitionId` in task options |
| `NOT_FOUND` | The referenced session, task, or result ID does not exist or has been deleted |
| `ALREADY_EXISTS` | Attempted to create a resource with an ID that already exists |
| `PERMISSION_DENIED` | Authentication succeeded but the identity lacks the required authorisation role |
| `UNAUTHENTICATED` | No valid client certificate or credentials were presented (mTLS is enabled) |
| `RESOURCE_EXHAUSTED` | Task queue is full or cluster resource limits have been reached |
| `FAILED_PRECONDITION` | Operation not allowed in the current state — e.g. submitting tasks to a closed or cancelled session |
| `UNAVAILABLE` | Control Plane is unreachable or not yet ready; also returned transiently during rolling restarts |
| `INTERNAL` | Unexpected server-side error — check Control Plane logs for the root cause |
| `DEADLINE_EXCEEDED` | Request timed out — usually indicates an overloaded cluster or a network issue |

### Common error scenarios

**`INVALID_ARGUMENT: PartitionId must not be null`**
Task options were submitted with `PartitionId = null`. Use an empty string `""` to request the default partition instead.

**`NOT_FOUND: session does not exist`**
The session ID is wrong, the session was deleted, or the client is pointing at a different cluster endpoint.

**`FAILED_PRECONDITION: session is not in a running state`**
Tasks cannot be submitted to a session that is closed, cancelled, or paused. Check the session status with `armonik session get <id>`.

**`UNAVAILABLE`**
The Control Plane pod is not ready. Check `kubectl get pods -n armonik` and the Control Plane logs. This is also returned transiently for a few seconds during a pod restart — retrying with backoff is safe.

**`PERMISSION_DENIED` or `UNAUTHENTICATED`**
Authentication is enabled on the cluster. Verify that the correct client certificate is configured and that the certificate's Common Name matches an entry in the authentication data file. See the [authentication guide](../user-guide/3.how-to-configure-authentication.md).
