## Prerequisites

In this section, we'll guide you through a quick installation of ArmoniK on your machine. We assume you are either using a WSL virtual machine or an actual Linux machine running a Debian-based distribution, such as Ubuntu. The very first step is to clone ArmoniK's repository:

```bash [shell]
git clone https://github.com/aneoconsulting/ArmoniK.git
```

Then, you need to ensure ArmoniK's technical installation prerequisites are met. We have prepared an [prerequisites installer](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/installation/prerequisites-installer.sh) script to ease this task, you need to execute it on a terminal
on the target machine and from the root repository.

```bash [shell]
./tools/installation/prerequisites-installer.sh
```

## Local deployment

To launch the deployment, navigate to the [`infrastructure/quick-deploy/localhost`](https://github.com/aneoconsulting/ArmoniK/tree/main/infrastructure/quick-deploy/localhost) directory:

Execute the following command:

```bash
make
```

or

```bash
make deploy
```

After a few minutes you should get an ouput similar to this:

```bash

Apply complete! Resources: 125 added, 0 changed, 0 destroyed.
 Outputs:
 armonik = {
  "admin_app_url" = "http://10.100.1.166:5000/admin"
  "chaos_mesh_url" = null
  "control_plane_url" = "http://10.100.1.166:5001"
  "grafana_url" = "http://10.100.1.166:5000/grafana/"
  "seq_web_url" = "http://10.100.1.166:5000/seq/"
}

OUTPUT FILE: /home/ubuntu/ArmoniK/infrastructure/quick-deploy/localhost/generated/armonik-output.json
Run to point your ArmoniK CLI to this deployment:

------------------------------
export AKCONFIG=/home/ubuntu/ArmoniK/infrastructure/quick-deploy/localhost/generated/armonik-cli.yaml
```

The service endpoints correspond to:

- **admin_app_url**: ArmoniK's web interface.
- **control_plane_url**: Entry point for submitting tasks graphs.
- **grafana_url**: Dashboard for real-time metrics and observability.
- **seq_web_url**: Centralized log viewer for structured event traces.
- **chaos_mesh_url**: (Optional) Fault injection platform — used to simulate failures and validate resilience.

## Launch HelloWorld sample (step-by-step)

## Check GUI and logs

## Troubleshooting quick tips

