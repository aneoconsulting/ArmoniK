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

## Hello World


In this first example, we will use our Python SDK, [**PymoniK**](https://github.com/aneoconsulting/PymoniK), to write our first ArmoniK-flavored **Hello World** program.
We also provide SDKs in [**Java**](https://github.com/aneoconsulting/ArmoniK.Extensions.Java), [**C#**](https://github.com/aneoconsulting/ArmoniK.Extensions.CSharp.New),
and [**C++**](https://github.com/aneoconsulting/ArmoniK.Extensions.Cpp) for your convenience.

This guide will walk you through the steps to get your first distributed function up and running using PymoniK.

---

### Step 1: Install PymoniK

Ensure you have the PymoniK framework installed in your Python environment. You can usually install it via pip:

```bash
pip install pymonik
```

### Step 2: Import Necessary Modules

Start by importing the required modules to work with PymoniK. You'll need the `PymoniK` and `task` decorators.

```python
from pymonik import PymoniK, task
```


### Step 3: Define Your Distributed Function

Create your distributed function using the `@task` decorator. In this case, we will create a simple function that returns "hello world".

```python
@task
def hello_worlder():
    return "hello world"
```


### Step 4: Invoke Your Function

To run your `hello_worlder` function on the ArmoniK cluster, wrap your invocation in a `with PymoniK()` context. Call the `invoke()` method and wait for the result.

```python
with PymoniK():
    print(hello_worlder.invoke().wait().get())
```

### Step 5: Run the Complete Program

Combine all of the above steps into a complete script. Here’s how it looks:

```python
from pymonik import PymoniK, task

@task
def hello_worlder():
    return "hello world"

if __name__ == "__main__":
    with PymoniK():
        print(hello_worlder.invoke().wait().get())
```

### Step 6: Execute the Program

Run your script from the command line:

```bash
python your_script_name.py
```

You should see the output:

```
hello world
```

Congratulations! You have successfully set up your first distributed function using PymoniK.


## Check GUI and logs

## Troubleshooting quick tips

