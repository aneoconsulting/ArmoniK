# Configure Seq

If you want to access outside your kubernetes cluster, you have to configure seq to make it accessible from outside.
To do so, you have to set this service (`seq_web` in [infrastructure/localhost/deploy/modules/armonik/seq.tf](../infrastructure/localhost/deploy/modules/armonik/seq.tf#L92) ) as `LoadBalancer` instead of `ClusterIP`.

Then, redeploy.

# Connexion

When you perform the command:
```bash
kubectl get svc -n armonik
```
You should see a service called `seqweb`. You can connect to its external-ip:8080 in your browser to access seq.

Then the id and the password are `admin`.

# Useful requests

The application name for the control plane is `ArmoniK.Control`. (Application = 'ArmoniK.Control')
The application name for the polling agent is `ArmoniK.Compute.PollingAgent`. (Application = 'ArmoniK.Compute.PollingAgent')
The application name for the worker is `ArmoniK.Compute.Worker`. (Application = 'ArmoniK.Compute.Worker')
