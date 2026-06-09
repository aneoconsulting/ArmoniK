# Reference

## Configuration reference

Environment variables for each component are documented in the respective project's reference:

- [ArmoniK.Api — Environment Variables](https://armonikapi.readthedocs.io/en/latest/content/usage/envars/index.html)
- [ArmoniK.Core — Environment Variables](https://armonikcore.readthedocs.io/en/latest/content/envars/index.html)

---

## CLI reference

The ArmoniK CLI (`armonik`) is the primary tool for interacting with a running ArmoniK cluster from the terminal. Full documentation is available at [armonikadmincli.readthedocs.io](https://armonikadmincli.readthedocs.io/en/latest/).

### Installation

```bash
pipx install armonik-cli   # recommended
# or
pip install armonik-cli
```

### Global options

These options are accepted by every command and can also be set via environment variables or a config file pointed to by `AKCONFIG`.

| Option | Env var | Description |
|---|---|---|
| `-e`, `--endpoint` | `AK_ENDPOINT` | gRPC endpoint of the cluster |
| `--ca-cert` | | Path to the Certificate Authority file (TLS) |
| `--cert` | | Path to the client certificate file (mTLS) |
| `--key` | | Path to the client key file (mTLS) |
| `-o`, `--output` | `AK_OUTPUT` | Output format: `table` (default), `json`, `yaml` |
| `--debug` | `AK_DEBUG` | Print stack traces on internal errors |
| `--verbose` | `AK_VERBOSE` | Print info-level logs |

### Command groups

#### `armonik cluster`

| Command | Description |
|---|---|
| `armonik cluster info` | Show cluster endpoint and component versions |
| `armonik cluster health` | Show health status of cluster components |

```bash
armonik --endpoint http://localhost:5001 cluster info
```

#### `armonik session`

| Command | Description |
|---|---|
| `armonik session list` | List sessions, with optional filtering and sorting |
| `armonik session get <id>` | Get details of a specific session |
| `armonik session create` | Create a new session |
| `armonik session cancel <id>…` | Cancel one or more sessions |
| `armonik session pause <id>…` | Pause one or more sessions |
| `armonik session resume <id>…` | Resume paused sessions |
| `armonik session close <id>…` | Close sessions (no new tasks accepted) |
| `armonik session purge <id>…` | Delete all task data in sessions |
| `armonik session delete <id>…` | Delete sessions entirely |
| `armonik session stop-submission <id>…` | Stop task submission without closing the session |

```bash
# List all running sessions
armonik session list --filter "Status == Running"

# Cancel a session
armonik session cancel <session-id>
```

#### `armonik task`

| Command | Description |
|---|---|
| `armonik task list` | List tasks, with optional filtering and sorting |
| `armonik task get <id>…` | Get details of one or more tasks |
| `armonik task cancel <id>…` | Cancel one or more tasks |
| `armonik task create` | Create a task in an existing session |

```bash
# List failed tasks in a session
armonik task list --filter "SessionId == <session-id> and Status == Error"

# Get task details
armonik task get <task-id>
```

#### `armonik result`

| Command | Description |
|---|---|
| `armonik result list <session-id>` | List results in a session |
| `armonik result get <id>…` | Get metadata for one or more results |
| `armonik result create <session-id>` | Create result objects in a session |
| `armonik result download-data <id>…` | Download result data to files |
| `armonik result upload-data` | Upload data for a result |
| `armonik result delete-data <id>…` | Delete result data |

```bash
# Download all results from a session
armonik result list <session-id> -o json \
  | jq -r '.[].resultId' \
  | xargs armonik result download-data --output-dir ./results
```

#### `armonik partition`

| Command | Description |
|---|---|
| `armonik partition list` | List all partitions in the cluster |
| `armonik partition get <id>` | Get details of a specific partition |

#### `armonik config`

| Command | Description |
|---|---|
| `armonik config show` | Show the active configuration |
| `armonik config list` | List available config profiles |
| `armonik config get <field>` | Get the value of a specific config field |
| `armonik config set <field> <value>` | Set a config field value |
| `armonik config completions <shell>` | Output shell completion script |

```bash
# Set a default endpoint so you don't need --endpoint every time
armonik config set endpoint http://localhost:5001

# Enable bash completions
armonik config completions bash >> ~/.bashrc
```

#### `armonik extension`

| Command | Description |
|---|---|
| `armonik extension list` | List installed CLI extensions |

---

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
