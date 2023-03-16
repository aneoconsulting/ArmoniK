# Infrastructure modules

The following directory tree represents the structure of the different modules of the ArmoniK infrastructure.

> ⚠ **WARNING**: This is non-final version of the ArmoniK infrastructure modules. Some updates could be performed as:
> add resources of other cloud providers, remove some resources which are only examples in the storage and monitoring
> modules, add other modules for utils (inputs, outputs, ...), and create meta-modules (for example ArmoniK's components
> to be deployed: control-plane, compute-plane and dataplane).

```bash
├── armonik
│├── admin-gui
│├── authentication
│├── compute-plane
│├── control-plane
│├── hpa
│└── ingress
├── container-registry
│├── aws
││└── ecr
│├── azure
││└── acr
│└── gcp
│    └── gcr
├── kubernetes
│├── aws
││├── addons
││├── eks
││└── node-group
│├── azure
││├── addons
││├── aks
││└── node-group
│├── gcp
││├── addons
││├── gke
││└── node-group
│└── onpremise
│    ├── addons
│    ├── k3s
│    └── kubeadm
├── monitoring
│├── aws
││├── cloudtrail
││├── cloudwatch
││├── datadog
││└── opensearch
│├── azure
││├── appinsight
││├── datadog
││├── log-analytics
││└── monitor
│├── gcp
││└── stackdriver
│└── onpremise
│    ├── grafana
│    ├── prometheus
│    └── seq
├── networking
│├── aws
││├── vpc
││└── vpce
│├── azure
││├── service-endpoint
││└── vnet
│└── gcp
│    ├── pga
│    └── vpc
├── persistent-volume
│├── aws
││├── ebs
││├── efs
││└── s3
│├── azure
││├── blob-storage
││├── disk
││└── file-storage
│├── gcp
││├── filestore
││├── gcs
││└── persistent-disk
│└── onpremise
│    └── nfs
├── storage
│├── aws
││├── amazon-mq
││├── aurora
││├── documentdb
││├── efs
││├── elasticache
││├── memorydb
││├── rds
││└── s3
│├── azure
││├── blob-storage
││├── cache-for-redis
││├── cosmosdb
││├── file-storage
││├── queue-storage
││├── service-bus
││├── sql-db
││├── storage-account
││└── table-storage
│├── gcp
││├── cloudsql
││├── filestore
││├── firestore
││├── gcs
││├── memorystore
││└── pub-sub
│└── onpremise
│    ├── activemq
│    ├── artemis
│    ├── minio
│    ├── mongodb
│    ├── rabbitmq
│    └── redis
└── utils
    └── default-images
```