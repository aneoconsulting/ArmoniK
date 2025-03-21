# Check the GUI and logs

After installing ArmoniK, it is time to execute some simple tests to check that everything is working as expected. In order to do that, the ArmoniK team is providing three simple tests to verify that the deployment went well.

## Seq

First of all, you can try to connect to the log server [Seq](https://datalust.co/) to check that it is working correctly.

You can find the Seq URL printed on your console after the deployment.



```{note}

You can also retrieve the `seq.web_url` from the Terraform outputs `monitoring/generated/monitoring-output.json`. The default port is `8080` but the ip address can be different depending on your machine.

```

Example:

```bash [shell]
http://<ip_address>:8080
```

<!-- TODO: Link 'enable it' with guide about https -->
No credentials are required to connect to Seq by default. Also, connexion is not encrypted by default (no HTTPS) but you can enable it.

## Admin GUI

You can also try to connect to the [ArmoniK Admin GUI](https://aneoconsulting.github.io/ArmoniK.Admin.GUI/) to check that it is working correctly.

You can find the Admin GUI URL printed on your console after the deployment.

<!-- TODO: need to be confirmed -->


```{note}

You can also retrieve the `armonik.admin_gui_url` from the Terraform outputs `armonik/generated/armonik-output.json`. The default port is `5000` but the ip address can be different depending on your machine.

```

Example:

```bash [shell]
http://<ip_address>:5000
```


