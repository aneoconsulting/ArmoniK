# Hubble

```sh
kubectl port-forward -n kube-system svc/hubble-ui 12000:80
```

Open http://localhost:12000, namespace `armonik`. Paste one filter in "Filter by:", then Enter. Several filters
show anything matching any of them.

| To see | Filter |
|---|---|
| Control plane | `app.kubernetes.io/component=control-plane` |
| htcmock pods (during a run only) | `armonik.fr/partition=htcmock` |
| Envoy (client entry point) | `gateway.envoyproxy.io/owning-gateway-name=armonik` |
| Everything going to AWS (RDS, S3, SQS) | `identity=2` |
| RDS only | `ip=<RDS IP>` |
| KEDA reading the scaling metric | `app=keda-operator` |
| Logs going to Seq | `app=seq` |
| Everything but fluent-bit | `!app.kubernetes.io/name=fluent-bit` |

RDS IP: `getent hosts "$(terraform -chdir=terraform output -json postgresql | jq -r .host)"`

During an htcmock run: `armonik.fr/partition=htcmock`, then `identity=2`. With nothing running there are no
htcmock pods, and little traffic.
