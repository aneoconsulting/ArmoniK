import json
import argparse
import hcl2


def none_or_str(value):
    if value == 'None':
        return None
    return value


parser = argparse.ArgumentParser(description="Modify ArmoniK paramters.tfvars.json")
parser.add_argument("inputfile", help="Path to the input paramters.tfvars file", type=none_or_str)
parser.add_argument("outputfile", help="Path to the output paramters.tfvars.json file", type=none_or_str)
parser.add_argument("--namespace", dest="namespace", help="Change ArmoniK namespace", type=none_or_str, default=None)
parser.add_argument("--logging-level", dest="logginglevel", help="Change ArmoniK logging level", type=none_or_str, default=None, choices=["Information", "Debug", "Verbose"])
parser.add_argument("--storage-object", dest="storageobject", help="Change Object Storage type", type=none_or_str, default=None)
parser.add_argument("--storage-table", dest="storagetable", help="Change Table Storage type", type=none_or_str, default=None)
parser.add_argument("--storage-queue", dest="storagequeue", help="Change Queue Storage type", type=none_or_str, default=None)
parser.add_argument("--storage-lease-provider", dest="storageleaseprovider", help="Change Lease Provider Storage type", type=none_or_str, default=None)
parser.add_argument("--storage-shared-type", dest="storageshared", help="Change Shared Storage type", type=none_or_str, default=None)
parser.add_argument("--storage-external", dest="storageexternal", help="Change External Storage type", type=none_or_str, default=None)
parser.add_argument("--mongodb-host", dest="mongodbhost", help="Change MongoDB Host", type=none_or_str, default=None)
parser.add_argument("--mongodb-port", dest="mongodbport", help="Change MongoDB Port", type=none_or_str, default=None)
parser.add_argument("--mongodb-kube-secret", dest="mongodbkubesecret", help="Change MongoDB Kubernetes secret", type=none_or_str, default=None)
parser.add_argument("--redis-url", dest="redisurl", help="Change Redis Url", type=none_or_str, default=None)
parser.add_argument("--redis-kube-secret", dest="rediskubesecret", help="Change Redis Kubernetes secret", type=none_or_str, default=None)
parser.add_argument("--activemq-host", dest="activemqhost", help="Change ActiveMQ host", type=none_or_str, default=None)
parser.add_argument("--activemq-port", dest="activemqport", help="Change ActiveMQ port", type=none_or_str, default=None)
parser.add_argument("--activemq-kube-secret", dest="activemqkubesecret", help="Change ActiveMQ Kubernetes secret", type=none_or_str, default=None)
parser.add_argument("--shared-host", dest="sharedhost", help="Change Shared Storage host", type=none_or_str, default=None)
parser.add_argument("--shared-kube-secret", dest="sharedkubesecret", help="Change Shared Storage Kubernetes secret", type=none_or_str, default=None)
parser.add_argument("--shared-path", dest="sharedpath", help="Change Shared Storage path", type=none_or_str, default=None)
parser.add_argument("--external-url", dest="externalurl", help="Change External cache Url", type=none_or_str, default=None)
parser.add_argument("--external-kube-secret", dest="externalkubesecret", help="Change External cache Kubernetes secret", type=none_or_str, default=None)
parser.add_argument("--control-plane-replicas", dest="controlplanereplicas", help="Change number of replicas in Control Plane", type=none_or_str, default=None)
parser.add_argument("--control-plane-image", dest="controlplaneimage", help="Change docker image of Control Plane", type=none_or_str, default=None)
parser.add_argument("--control-plane-tag", dest="controlplanetag", help="Change docker image tag of Control Plane", type=none_or_str, default=None)
parser.add_argument("--control-plane-image-pull-policy", dest="controlplaneimagepullpolicy", help="Change docker image pull policy of Control Plane", type=none_or_str, default=None)
parser.add_argument("--control-plane-port", dest="controlplaneport", help="Change port of Control Plane", type=none_or_str, default=None)
parser.add_argument("--compute-plane-replicas", dest="computeplanereplicas", help="Change number of replicas in Compute Plane", type=none_or_str, default=None)
parser.add_argument("--compute-plane-max-priority", dest="computeplanemaxpriority", help="Change max priority in Compute Plane", type=none_or_str, default=None)
parser.add_argument("--polling-agent-image", dest="pollingagentimage", help="Change docker image of Polling Agent", type=none_or_str, default=None)
parser.add_argument("--polling-agent-tag", dest="pollingagenttag", help="Change docker image tag of Polling Agent", type=none_or_str, default=None)
parser.add_argument("--polling-agent-image-pull-policy", dest="pollingagentimagepullpolicy", help="Change docker image pull policy of Polling Agent", type=none_or_str, default=None)
parser.add_argument("--polling-agent-limits-cpu", dest="pollingagentlimitscpu", help="Change CPU limit of Polling Agent", type=none_or_str, default=None)
parser.add_argument("--polling-agent-limits-memory", dest="pollingagentlimitsmemory", help="Change Memory limit of Polling Agent", type=none_or_str, default=None)
parser.add_argument("--polling-agent-requests-cpu", dest="pollingagentrequestscpu", help="Change CPU requests of Polling Agent", type=none_or_str, default=None)
parser.add_argument("--polling-agent-requests-memory", dest="pollingagentrequestsmemory", help="Change Memory requests of Polling Agent", type=none_or_str, default=None)
parser.add_argument("--worker-port", dest="workerport", help="Change port of worker", type=none_or_str, default=None)
parser.add_argument("--worker-image", dest="workerimage", help="Change docker image of worker", type=none_or_str, default=None)
parser.add_argument("--worker-tag", dest="workertag", help="Change docker image tag of worker", type=none_or_str, default=None)
parser.add_argument("--worker-image-pull-policy", dest="workerimagepullpolicy", help="Change docker image pull policy of worker", type=none_or_str, default=None)
parser.add_argument("--worker-limits-cpu", dest="workerlimitscpu", help="Change CPU limit of worker", type=none_or_str, default=None)
parser.add_argument("--worker-limits-memory", dest="workerlimitsmemory", help="Change Memory limit of worker", type=none_or_str, default=None)
parser.add_argument("--worker-requests-cpu", dest="workerrequestscpu", help="Change CPU requests of worker", type=none_or_str, default=None)
parser.add_argument("--worker-requests-memory", dest="workerrequestsmemory", help="Change Memory requests of worker", type=none_or_str, default=None)
parser.add_argument("--monitoring-namespace", dest="monitoringnamespace", help="Change Monitoring namespace", type=none_or_str, default=None)
parser.add_argument("--use-seq", dest="useseq", help="Use Seq", type=none_or_str, default=None)
parser.add_argument("--use-grafana", dest="usegrafana", help="Use Grafana", type=none_or_str, default=None)
parser.add_argument("--use-prometheus", dest="useprometheus", help="Use Prometheus", type=none_or_str, default=None)
parser.add_argument("--use-kubernetes-dashboard", dest="usekubernetesdashboard", help="Use kubernetes dashboard", type=none_or_str, default=None)

args = parser.parse_args()

with open(args.inputfile, 'r') as fin:
    content = hcl2.load(fin)

if args.namespace is not None:
    content['namespace'] = args.namespace
if args.logginglevel is not None:
    content['logging_level'] = args.logginglevel
if args.monitoringnamespace is not None:
    content['monitoring']['namespace'] = args.monitoringnamespace
if args.useseq is not None:
    content['monitoring']['seq'] = args.useseq
if args.usegrafana is not None:
    content['monitoring']['grafana'] = args.usegrafana
if args.useprometheus is not None:
    content['monitoring']['prometheus'] = args.useprometheus
if args.usekubernetesdashboard is not None:
    content['monitoring']['dashboard'] = args.usekubernetesdashboard
if args.storageobject is not None:
    content['storage']['object'] = args.storageobject
if args.storagetable is not None:
    content['storage']['table'] = args.storagetable
if args.storagequeue is not None:
    content['storage']['queue'] = args.storagequeue
if args.storageleaseprovider is not None:
    content['storage']['lease_provider'] = args.storageleaseprovider
if args.storageshared is not None:
    content['storage']['shared'] = args.storageshared
if args.storageexternal is not None:
    content['storage']['external'] = args.storageexternal
if args.mongodbhost is not None:
    content['storage_endpoint_url']['mongodb']['host'] = args.mongodbhost
if args.mongodbport is not None:
    content['storage_endpoint_url']['mongodb']['port'] = args.mongodbport
if args.mongodbkubesecret is not None:
    content['storage_endpoint_url']['mongodb']['secret'] = args.mongodbkubesecret
if args.redisurl is not None:
    content['storage_endpoint_url']['redis']['url'] = args.redisurl
if args.rediskubesecret is not None:
    content['storage_endpoint_url']['redis']['secret'] = args.rediskubesecret
if args.activemqhost is not None:
    content['storage_endpoint_url']['activemq']['host'] = args.activemqhost
if args.activemqport is not None:
    content['storage_endpoint_url']['activemq']['port'] = args.activemqport
if args.activemqkubesecret is not None:
    content['storage_endpoint_url']['activemq']['secret'] = args.activemqkubesecret
if args.sharedhost is not None:
    content['storage_endpoint_url']['shared']['host'] = args.sharedhost
if args.sharedkubesecret is not None:
    content['storage_endpoint_url']['shared']['secret'] = args.sharedkubesecret
if args.sharedpath is not None:
    content['storage_endpoint_url']['shared']['path'] = args.sharedpath
if args.externalurl is not None:
    content['storage_endpoint_url']['external']['url'] = args.externalurl
if args.externalkubesecret is not None:
    content['storage_endpoint_url']['external']['secret'] = args.externalkubesecret
if args.controlplanereplicas is not None:
    content['control_plane']['replicas'] = args.controlplanereplicas
if args.controlplaneimage is not None:
    content['control_plane']['image'] = args.controlplaneimage
if args.controlplanetag is not None:
    content['control_plane']['tag'] = args.controlplanetag
if args.controlplaneimagepullpolicy is not None:
    content['control_plane']['image_pull_policy'] = args.controlplaneimagepullpolicy
if args.controlplaneport is not None:
    content['control_plane']['port'] = args.controlplaneport
if args.computeplanereplicas is not None:
    content['compute_plane']['replicas'] = args.computeplanereplicas
if args.pollingagentimage is not None:
    content['compute_plane']['polling_agent']['image'] = args.pollingagentimage
if args.pollingagenttag is not None:
    content['compute_plane']['polling_agent']['tag'] = args.pollingagenttag
if args.pollingagentimagepullpolicy is not None:
    content['compute_plane']['polling_agent']['image_pull_policy'] = args.pollingagentimagepullpolicy
if args.pollingagentlimitscpu is not None:
    content['compute_plane']['polling_agent']['limits']['cpu'] = args.pollingagentlimitscpu
if args.pollingagentlimitsmemory is not None:
    content['compute_plane']['polling_agent']['limits']['memory'] = args.pollingagentlimitsmemory
if args.pollingagentrequestscpu is not None:
    content['compute_plane']['polling_agent']['requests']['cpu'] = args.pollingagentrequestscpu
if args.pollingagentrequestsmemory is not None:
    content['compute_plane']['polling_agent']['requests']['memory'] = args.pollingagentrequestsmemory

if args.workerport is not None \
        or args.workerport is not None \
        or args.workerimage is not None \
        or args.workertag is not None \
        or args.workerimagepullpolicy is not None \
        or args.workerlimitscpu is not None \
        or args.workerlimitsmemory is not None \
        or args.workerrequestscpu is not None \
        or args.workerrequestsmemory is not None:
    workers = content['compute_plane']['worker']
    for w in workers:
        if args.workerport is not None:
            w['port'] = args.workerport
        if args.workerimage is not None:
            w['image'] = args.workerimage
        if args.workertag is not None:
            w['tag'] = args.workertag
        if args.workerimagepullpolicy is not None:
            w['image_pull_policy'] = args.workerimagepullpolicy
        if args.workerlimitscpu is not None:
            w['limits']['cpu'] = args.workerlimitscpu
        if args.workerlimitsmemory is not None:
            w['limits']['memory'] = args.workerlimitsmemory
        if args.workerrequestscpu is not None:
            w['requests']['cpu'] = args.workerrequestscpu
        if args.workerrequestsmemory is not None:
            w['requests']['memory'] = args.workerrequestsmemory
    content['compute_plane']['worker'] = workers


with open(args.outputfile, 'w') as fout:
    json.dump(content, fout, indent=2, sort_keys=True)
