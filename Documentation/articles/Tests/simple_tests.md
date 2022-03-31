# Simple tests

After installing **Armonik**, it is time to execute some simple test to check that everything is working as expected. **ArmoniK** team is providing three simple tests to verify that the deployment wen well.

## Seq webserver

The first tests suggested is to validate that the log server ([Seq](https://datalust.co/)) did start correctly.

After the deployment, you can connect to the Seq webserver by using `seq.web_url` retrieved from the Terraform outputs `monitoring/generated/monitoring-output.json`, example:

```bash
http://192.168.1.13:8080
```

or:

```bash
http://localhost:8080
```

where `Username: admin` and `Password: admin`:

![Seq authentication](~/images/Tests/seq_auth.png)

## Tests

### Scripts of tests

You have three scripts for testing ArmoniK :

* [tools/tests/symphony_like.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/tests/symphony_like.sh)
* [tools/tests/datasynapse_like.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/tests/datasynapse_like.sh)
* [tools/tests/symphony_endToendTests.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/tests/symphony_endToendTests.sh).

The following commands in these scripts allow to retrieve the endpoint URL of ArmoniK control plane:

```bash
export CPIP=$(kubectl get svc control-plane -n armonik -o custom-columns="IP:.spec.clusterIP" --no-headers=true)
export CPPort=$(kubectl get svc control-plane -n armonik -o custom-columns="PORT:.spec.ports[*].port" --no-headers=true)
export Grpc__Endpoint=http://$CPIP:$CPPort
```

or You can replace them by the `armonik.control_plane_url` retrieved from Terraform
outputs `armonik/generated/armonik-output.json`, example:

```bash
export Grpc__Endpoint=http://192.168.1.13:5001
```

### Launch tests

Before executing the tests, You must download source codes of Samples from the **root** repository:

```bash
git submodule update --init --recursive
```

**and:**

```bash
git clone https://github.com/aneoconsulting/ArmoniK.Extensions.Csharp.git source/ArmoniK.Extensions.Csharp
```

**then:**

- Execute [tools/tests/symphony_like.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/tests/symphony_like.sh) from the **root** repository:
  ```bash
  tools/tests/symphony_like.sh
  ```

- Execute [tools/tests/datasynapse_like.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/tests/datasynapse_like.sh) from the **root** repository:
  ```bash
  tools/tests/datasynapse_like.sh
  ```

- Execute [tools/tests/symphony_endToendTests.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/tests/symphony_endToendTests.sh) from the **root**
  repository:
  ```bash
  tools/tests/symphony_endToendTests.sh
  ```

You can follow logs on Seq webserver:

![Seq Logs](~/images/Tests/seq.png)

## Clean-up

To delete all resources created in Kubernetes, You can execute the following all-in-one command:

```bash
make destroy-all
```

or execute the following commands in this order:

```bash
make destroy-armonik 
make destroy-monitoring 
make destroy-storage 
```

To clean-up and delete all generated files, You execute:

```bash
make clean-all
```

or:

```bash
make clean-armonik 
make clean-monitoring 
make clean-aws-storage 
``` 