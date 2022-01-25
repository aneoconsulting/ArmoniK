# Table of contents

1. [Introduction](#introduction)
2. [ActiveMQ](#actvemq)
3. [MongoDB](#mongodb)
4. [Redis](#redis)

# Introduction

We present the different parameters for each storage resources.

# ActiveMQ

[Apache ActiveMQ](https://activemq.apache.org/) is the most popular open source, multi-protocol, Java-based message
broker.

### ***namespace***

```terraform
namespace = string
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `namespace` | Kubernetes namespace where ActiveMQ is created | string | `armonik-storage` |

### ***activemq***

```terraform
activemq = {
  replicas = number
  port     = {
    name        = string
    port        = number
    target_port = number
    protocol    = string
  }
}
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas of ActiveMQ | number | `1` |
| `port` | List of ports and their names | list(object({})) | `[{ name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },{ name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },{ name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },{ name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },{ name = "ws", port = 61614, target_port = 61614, protocol = "TCP" },{ name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }]` |

### ***kubernetes_secret***

```terraform
kubernetes_secret = string
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `kubernetes_secret` | Kubernetes secret for ActiveMQ, created during the [Create Kubernetes secrets](../README.md) | string | `"activemq-storage-secret"` |

# MongoDB

[MongoDB](https://www.mongodb.com/) is an open source NoSQL database management program.

### ***namespace***

```terraform
namespace = string
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `namespace` | Kubernetes namespace where MongoDB is created | string | `armonik-storage` |

### ***mongodb***

```terraform
mongodb = {
  replicas = number
  port     = string
}
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas of MongoDB | number | `1` |
| `port` | Port of MongoDB | number | `27017` |

### ***kubernetes_secret***

```terraform
kubernetes_secret = string
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `kubernetes_secret` | Kubernetes secret for MongoDB, created during the [Create Kubernetes secrets](../README.md) | string | `""` |

# Redis

[Redis](https://redis.io/) is an open source (BSD licensed), in-memory data structure store, used as a database, cache,
and message broker.

### ***namespace***

```terraform
namespace = string
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `namespace` | Kubernetes namespace where Redis is created | string | `armonik-storage` |

### ***redis***

```terraform
redis = {
  replicas = number
  port     = string
}
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `replicas` | Number of desired replicas of Redis | number | `1` |
| `port` | Port of Redis | number | `27017` |

### ***kubernetes_secret***

```terraform
kubernetes_secret = string
```

| Parameter | Description | Type | Default |
|:----------|:------------|:-----|:--------|
| `kubernetes_secret` | Kubernetes secret for Redis, created during the [Create Kubernetes secrets](../README.md) | string | `"redis-storage-secret"` |
