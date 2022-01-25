resource "aws_mq_broker" "activemq" {
  broker_name = "activemq"

  configuration {
    id       = aws_mq_configuration.activemq.id
    revision = aws_mq_configuration.activemq.latest_revision
  }

  engine_type        = aws_mq_configuration.activemq.engine_type
  engine_version     = aws_mq_configuration.activemq.engine_version
  host_instance_type = "mq.m5.large"
  # security_groups    = [aws_security_group.test.id]
  apply_immediately = true

  user {
    username = "ExampleUser"
    password = "MindTheGap"
  }
}

resource "aws_mq_configuration" "activemq" {
  description    = "ArmoniK ActiveMQ Configuration"
  name           = "armonik-mq"
  engine_type    = "ActiveMQ"
  engine_version = "5.16.3"

  data = <<DATA
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<broker xmlns="http://activemq.apache.org/schema/core">
  <plugins>
    <forcePersistencyModeBrokerPlugin persistenceFlag="true"/>
    <statisticsBrokerPlugin/>
    <timeStampingBrokerPlugin ttlCeiling="86400000" zeroExpirationOverride="86400000"/>
  </plugins>
</broker>
DATA
}