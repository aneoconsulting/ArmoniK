resource "aws_mq_broker" "mq" {
  broker_name             = var.name
  engine_type             = aws_mq_configuration.mq_configuration.engine_type
  engine_version          = aws_mq_configuration.mq_configuration.engine_version
  host_instance_type      = var.mq.host_instance_type
  apply_immediately       = var.mq.apply_immediately
  deployment_mode         = var.mq.deployment_mode
  storage_type            = var.mq.storage_type
  authentication_strategy = var.mq.authentication_strategy
  publicly_accessible     = var.mq.publicly_accessible
  security_groups         = [aws_security_group.mq.id]
  subnet_ids              = local.subnet_ids
  configuration {
    id       = aws_mq_configuration.mq_configuration.id
    revision = aws_mq_configuration.mq_configuration.latest_revision
  }
  encryption_options {
    kms_key_id        = var.mq.kms_key_id
    use_aws_owned_key = false
  }
  logs {
    audit   = true
    general = true
  }
  user {
    password       = local.password
    username       = local.username
    console_access = true
    groups         = []
  }
  tags                    = local.tags
}

/*# MQ configuration
resource "aws_mq_configuration" "mq_configuration" {
  description    = "ArmoniK ActiveMQ Configuration"
  name           = var.name
  engine_type    = var.mq.engine_type
  engine_version = var.mq.engine_version
  data           = <<DATA
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<broker xmlns="http://activemq.apache.org/schema/core">
  <plugins>
    <forcePersistencyModeBrokerPlugin persistenceFlag="true"/>
    <statisticsBrokerPlugin/>
    <timeStampingBrokerPlugin ttlCeiling="86400000" zeroExpirationOverride="86400000"/>
  </plugins>
</broker>
DATA
  tags           = local.tags
}*/

# MQ configuration
resource "aws_mq_configuration" "mq_configuration" {
  description    = "ArmoniK ActiveMQ Configuration"
  name           = var.name
  engine_type    = var.mq.engine_type
  engine_version = var.mq.engine_version
  data           = <<DATA
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<broker xmlns="http://activemq.apache.org/schema/core">
  <persistenceAdapter>
    <kahaDB preallocationStrategy="zeros" concurrentStoreAndDispatchQueues="false" journalDiskSyncInterval="10000" journalDiskSyncStrategy="periodic"/>
  </persistenceAdapter>
  <systemUsage>
    <systemUsage sendFailIfNoSpace="true" sendFailIfNoSpaceAfterTimeout="60000">
      <memoryUsage>
        <memoryUsage limit="100 gb" percentOfJvmHeap="70" />
      </memoryUsage>
      <storeUsage>
        <storeUsage limit="100 gb"/>
      </storeUsage>
      <tempUsage>
        <tempUsage limit="100 gb"/>
      </tempUsage>
    </systemUsage>
  </systemUsage>
</broker>
DATA
  tags           = local.tags
}

/*# MQ configuration
resource "aws_mq_configuration" "mq_configuration" {
  description    = "ArmoniK ActiveMQ Configuration"
  name           = var.name
  engine_type    = var.mq.engine_type
  engine_version = var.mq.engine_version
  data           = <<DATA
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<broker xmlns="http://activemq.apache.org/schema/core">
  <destinationPolicy>
    <policyMap>
      <policyEntries>
        <policyEntry topic=">" >
          <!-- The constantPendingMessageLimitStrategy is used to prevent
               slow topic consumers to block producers and affect other consumers
               by limiting the number of messages that are retained
               For more information, see: http://activemq.apache.org/slow-consumer-handling.html
          -->
          <pendingMessageLimitStrategy>
            <constantPendingMessageLimitStrategy limit="100000000"/>
          </pendingMessageLimitStrategy>
        </policyEntry>
      </policyEntries>
    </policyMap>
  </destinationPolicy>

  <!--
    The managementContext is used to configure how ActiveMQ is exposed in
    JMX. By default, ActiveMQ uses the MBean server that is started by
    the JVM. For more information, see: http://activemq.apache.org/jmx.html
  -->
  <managementContext>
    <managementContext createConnector="false"/>
  </managementContext>

  <!--
    Configure message persistence for the broker. The default persistence
    mechanism is the KahaDB store (identified by the kahaDB tag).
    For more information, see: http://activemq.apache.org/persistence.html
  -->
  <persistenceAdapter>
    <kahaDB directory="$${activemq.data}/kahadb"/>
  </persistenceAdapter>

  <!--
    The systemUsage controls the maximum amount of space the broker will
    use before disabling caching and/or slowing down producers. For more information, see: http://activemq.apache.org/producer-flow-control.html
  -->
  <systemUsage>
    <systemUsage sendFailIfNoSpaceAfterTimeout="60000">
      <memoryUsage>
        <memoryUsage percentOfJvmHeap="70" />
      </memoryUsage>
      <storeUsage>
        <storeUsage limit="100 gb"/>
      </storeUsage>
      <tempUsage>
        <tempUsage limit="50 gb"/>
      </tempUsage>
    </systemUsage>
  </systemUsage>

  <!--
    The transport connectors expose ActiveMQ over a given protocol to
    clients and other brokers. For more information, see: http://activemq.apache.org/configuring-transports.html
  -->
  <transportConnectors>
    <!-- DOS protection, limit concurrent connections to 1000 and frame size to 100MB -->
    <!--
    <transportConnector name="openwire" uri="tcp://0.0.0.0:61616?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
    <transportConnector name="stomp" uri="stomp://0.0.0.0:61613?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
    <transportConnector name="mqtt" uri="mqtt://0.0.0.0:1883?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
    <transportConnector name="ws" uri="ws://0.0.0.0:61614?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
    <transportConnector name="amqp+ssl" uri="amqp+ssl://0.0.0.0:5672?maximumConnections=1000000&amp;wireFormat.maxFrameSize=1048576000"/>
    -->
  </transportConnectors>

  <!-- destroy the spring context on shutdown to stop jetty -->
  <shutdownHooks>
    <bean xmlns="http://www.springframework.org/schema/beans" class="org.apache.activemq.hooks.SpringContextHook" />
  </shutdownHooks>
</broker>
DATA
  tags           = local.tags
}*/

# MQ security group
resource "aws_security_group" "mq" {
  name        = "${var.name}-sg"
  description = "Allow Amazon MQ inbound traffic on port 5672"
  vpc_id      = var.vpc.id
  ingress {
    description = "tcp from Amazon MQ"
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = var.vpc.cidr_blocks
  }
  ingress {
    description = "Web console for Amazon MQ"
    from_port   = 8162
    to_port     = 8162
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags        = local.tags
}

# IMA
data "aws_iam_policy_document" "mq_logs_policy" {
  statement {
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
      "logs:PutRetentionPolicy",
    ]
    resources = ["arn:aws:logs:*:*:*:/aws/amazonmq/*"]
    principals {
      identifiers = ["mq.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "mq_logs_publishing_policy" {
  policy_document = data.aws_iam_policy_document.mq_logs_policy.json
  policy_name     = "mq-logs-publishing-policy"
}