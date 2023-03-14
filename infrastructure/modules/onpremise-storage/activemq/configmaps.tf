locals {
  jolokia_access_xml = <<EOF
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 -->
  <restrict>
    <!--  Enforce that an Origin/Referer header is present to prevent CSRF  -->
    <!--
    <cors>
      <strict-checking/>
    </cors>
    -->
    <!--  deny calling operations or getting attributes from these mbeans  -->
    <deny>
      <mbean>
        <name>com.sun.management:type=DiagnosticCommand</name>
        <attribute>*</attribute>
        <operation>*</operation>
      </mbean>
      <mbean>
        <name>com.sun.management:type=HotSpotDiagnostic</name>
        <attribute>*</attribute>
        <operation>*</operation>
      </mbean>
    </deny>
  </restrict>
EOF

  credentials_properties = <<EOF
# Defines credentials that will be used by components (like web console) to access the broker

activemq.username=${random_string.mq_admin_user.result}
activemq.password=${random_password.mq_admin_password.result}
guest.password=${random_password.mq_application_password.result}
EOF

  activemq_jetty_realm_properties = <<EOF
# username: password ,[role-name]
${random_string.mq_admin_user.result}:${random_password.mq_admin_password.result}, admin
${random_string.mq_application_user.result}:${random_password.mq_application_password.result}, guest
EOF

  activemq_jetty_xml = <<EOF

    <!--
        Licensed to the Apache Software Foundation (ASF) under one or more contributor
        license agreements. See the NOTICE file distributed with this work for additional
        information regarding copyright ownership. The ASF licenses this file to You under
        the Apache License, Version 2.0 (the "License"); you may not use this file except in
        compliance with the License. You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or
        agreed to in writing, software distributed under the License is distributed on an
        "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
        implied. See the License for the specific language governing permissions and
        limitations under the License.
    -->
    <!--
        An embedded servlet engine for serving up the Admin consoles, REST and Ajax APIs and
        some demos Include this file in your configuration to enable ActiveMQ web components
        e.g. <import resource="jetty.xml"/>
    -->
<beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="securityLoginService" class="org.eclipse.jetty.security.HashLoginService">
        <property name="name" value="ActiveMQRealm" />
        <property name="config" value="$${activemq.conf}/jetty-realm.properties" />
    </bean>

    <bean id="securityConstraint" class="org.eclipse.jetty.util.security.Constraint">
        <property name="name" value="BASIC" />
        <property name="roles" value="user,admin" />
        <!-- set authenticate=false to disable login -->
        <property name="authenticate" value="true" />
    </bean>
    <bean id="adminSecurityConstraint" class="org.eclipse.jetty.util.security.Constraint">
        <property name="name" value="BASIC" />
        <property name="roles" value="admin" />
         <!-- set authenticate=false to disable login -->
        <property name="authenticate" value="true" />
    </bean>
    <bean id="securityConstraintMapping" class="org.eclipse.jetty.security.ConstraintMapping">
        <property name="constraint" ref="securityConstraint" />
        <!--
        <property name="pathSpec" value="/,*.jsp,*.html,*.js,*.css,*.png,*.gif,*.ico" />
        -->
        <property name="pathSpec" value="/*,/api/*,/admin/*,*.jsp" />
    </bean>
    <bean id="adminSecurityConstraintMapping" class="org.eclipse.jetty.security.ConstraintMapping">
        <property name="constraint" ref="adminSecurityConstraint" />
        <property name="pathSpec" value="*.action" />
    </bean>

    <bean id="rewriteHandler" class="org.eclipse.jetty.rewrite.handler.RewriteHandler">
        <property name="rules">
            <list>
                <bean id="header" class="org.eclipse.jetty.rewrite.handler.HeaderPatternRule">
                  <property name="pattern" value="*"/>
                  <property name="name" value="X-FRAME-OPTIONS"/>
                  <property name="value" value="SAMEORIGIN"/>
                </bean>
                <bean id="header" class="org.eclipse.jetty.rewrite.handler.HeaderPatternRule">
                  <property name="pattern" value="*"/>
                  <property name="name" value="X-XSS-Protection"/>
                  <property name="value" value="1; mode=block"/>
                </bean>
                <bean id="header" class="org.eclipse.jetty.rewrite.handler.HeaderPatternRule">
                  <property name="pattern" value="*"/>
                  <property name="name" value="X-Content-Type-Options"/>
                  <property name="value" value="nosniff"/>
                </bean>
            </list>
        </property>
    </bean>

        <bean id="secHandlerCollection" class="org.eclipse.jetty.server.handler.HandlerCollection">
                <property name="handlers">
                        <list>
                    <ref bean="rewriteHandler"/>
                                <bean class="org.eclipse.jetty.webapp.WebAppContext">
                                        <property name="contextPath" value="/admin" />
                                        <property name="resourceBase" value="$${activemq.home}/webapps/admin" />
                                        <property name="logUrlOnStart" value="true" />
                                </bean>
                                <bean class="org.eclipse.jetty.webapp.WebAppContext">
                                        <property name="contextPath" value="/api" />
                                        <property name="resourceBase" value="$${activemq.home}/webapps/api" />
                                        <property name="logUrlOnStart" value="true" />
                                </bean>
                                <bean class="org.eclipse.jetty.server.handler.ResourceHandler">
                                        <property name="directoriesListed" value="false" />
                                        <property name="welcomeFiles">
                                                <list>
                                                        <value>index.html</value>
                                                </list>
                                        </property>
                                        <property name="resourceBase" value="$${activemq.home}/webapps/" />
                                </bean>
                                <bean id="defaultHandler" class="org.eclipse.jetty.server.handler.DefaultHandler">
                                        <property name="serveIcon" value="false" />
                                </bean>
                        </list>
                </property>
        </bean>
    <bean id="securityHandler" class="org.eclipse.jetty.security.ConstraintSecurityHandler">
        <property name="loginService" ref="securityLoginService" />
        <property name="authenticator">
            <bean class="org.eclipse.jetty.security.authentication.BasicAuthenticator" />
        </property>
        <property name="constraintMappings">
            <list>
                <ref bean="adminSecurityConstraintMapping" />
                <ref bean="securityConstraintMapping" />
            </list>
        </property>
        <property name="handler" ref="secHandlerCollection" />
    </bean>

    <bean id="contexts" class="org.eclipse.jetty.server.handler.ContextHandlerCollection">
    </bean>

    <bean id="jettyPort" class="org.apache.activemq.web.WebConsolePort" init-method="start">
             <!-- the default port number for the web console -->
        <property name="host" value="0.0.0.0"/>
        <property name="port" value="8161"/>
    </bean>

    <bean id="Server" depends-on="jettyPort" class="org.eclipse.jetty.server.Server"
        destroy-method="stop">

        <property name="handler">
            <bean id="handlers" class="org.eclipse.jetty.server.handler.HandlerCollection">
                <property name="handlers">
                    <list>
                        <ref bean="contexts" />
                        <ref bean="securityHandler" />
                    </list>
                </property>
            </bean>
        </property>

    </bean>

    <bean id="invokeConnectors" class="org.springframework.beans.factory.config.MethodInvokingFactoryBean">
        <property name="targetObject" ref="Server" />
        <property name="targetMethod" value="setConnectors" />
        <property name="arguments">
        <list>
                <bean id="Connector" class="org.eclipse.jetty.server.ServerConnector">
                        <constructor-arg ref="Server" />
                    <!-- see the jettyPort bean -->
                   <property name="host" value="#{systemProperties['jetty.host']}" />
                   <property name="port" value="#{systemProperties['jetty.port']}" />
               </bean>
                <!--
                    Enable this connector if you wish to use https with web console
                -->
                <!-- bean id="SecureConnector" class="org.eclipse.jetty.server.ServerConnector">
                                        <constructor-arg ref="Server" />
                                        <constructor-arg>
                                                <bean id="handlers" class="org.eclipse.jetty.util.ssl.SslContextFactory">

                                                        <property name="keyStorePath" value="$${activemq.conf}/broker.ks" />
                                                        <property name="keyStorePassword" value="password" />
                                                </bean>
                                        </constructor-arg>
                                        <property name="port" value="8162" />
                                </bean -->
            </list>
        </property>
    </bean>

        <bean id="configureJetty" class="org.springframework.beans.factory.config.MethodInvokingFactoryBean">
                <property name="staticMethod" value="org.apache.activemq.web.config.JspConfigurer.configureJetty" />
                <property name="arguments">
                        <list>
                                <ref bean="Server" />
                                <ref bean="secHandlerCollection" />
                        </list>
                </property>
        </bean>

    <bean id="invokeStart" class="org.springframework.beans.factory.config.MethodInvokingFactoryBean"
        depends-on="configureJetty, invokeConnectors">
        <property name="targetObject" ref="Server" />
        <property name="targetMethod" value="start" />
    </bean>


</beans>
EOF

  activemq_xml = <<EOF
<beans
  xmlns="http://www.springframework.org/schema/beans"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
  http://activemq.apache.org/schema/core http://activemq.apache.org/schema/core/activemq-core.xsd">

    <!-- Allows us to use system properties as variables in this configuration file -->
    <bean class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
        <property name="locations">
            <value>file:$${activemq.conf}/credentials.properties</value>
        </property>
    </bean>

    <!--
        The <broker> element is used to configure the ActiveMQ broker.
    -->
    <broker xmlns="http://activemq.apache.org/schema/core" brokerName="localhost" dataDirectory="$${activemq.data}">

        <destinationPolicy>
            <policyMap>
              <policyEntries>
                <policyEntry queue=">" prioritizedMessages="true" />
                <policyEntry topic=">" >
                    <!-- The constantPendingMessageLimitStrategy is used to prevent
                         slow topic consumers to block producers and affect other consumers
                         by limiting the number of messages that are retained
                         For more information, see:

                         http://activemq.apache.org/slow-consumer-handling.html

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
            the JVM. For more information, see:

            http://activemq.apache.org/jmx.html
        -->
        <managementContext>
            <managementContext createConnector="false"/>
        </managementContext>

        <!--
            Configure message persistence for the broker. The default persistence
            mechanism is the KahaDB store (identified by the kahaDB tag).
            For more information, see:

            http://activemq.apache.org/persistence.html
        -->
        <persistenceAdapter>
            <kahaDB directory="$${activemq.data}/kahadb"/>
        </persistenceAdapter>


          <!--
            The systemUsage controls the maximum amount of space the broker will
            use before disabling caching and/or slowing down producers. For more information, see:
            http://activemq.apache.org/producer-flow-control.html
          -->
          <systemUsage>
            <systemUsage sendFailIfNoSpaceAfterTimeout="60000">
                <memoryUsage>
                    <memoryUsage percentOfJvmHeap="90" />
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
            clients and other brokers. For more information, see:

            http://activemq.apache.org/configuring-transports.html
        -->
        <transportConnectors>
            <!-- DOS protection, limit concurrent connections to 1000 and frame size to 100MB -->
            <!--
            <transportConnector name="openwire" uri="tcp://0.0.0.0:61616?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
            <transportConnector name="amqp" uri="amqp://0.0.0.0:5672?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
            <transportConnector name="stomp" uri="stomp://0.0.0.0:61613?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
            <transportConnector name="mqtt" uri="mqtt://0.0.0.0:1883?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
            <transportConnector name="ws" uri="ws://0.0.0.0:61614?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
            -->
            <transportConnector name="amqp+ssl" uri="amqp+ssl://0.0.0.0:5672?maximumConnections=1000000&amp;wireFormat.maxFrameSize=1048576000"/>
        </transportConnectors>

        <!-- destroy the spring context on shutdown to stop jetty -->
        <shutdownHooks>
            <bean xmlns="http://www.springframework.org/schema/beans" class="org.apache.activemq.hooks.SpringContextHook" />
        </shutdownHooks>

        <sslContext>
            <sslContext keyStore="file:/credentials/certificate.pfx"
                        keyStorePassword="${random_password.mq_keystore_password.result}"/>
        </sslContext>
    </broker>

    <!--
        Enable web consoles, REST and Ajax APIs and demos
        The web consoles requires by default login, you can disable this in the jetty.xml file

        Take a look at $${ACTIVEMQ_HOME}/conf/jetty.xml for more details
    -->
    <import resource="jetty.xml"/>

</beans>
EOF

  log4j_properties = <<EOF
#
# This file controls most of the logging in ActiveMQ which is mainly based around
# the commons logging API.
#
log4j.rootLogger=INFO, console, logfile
log4j.logger.org.apache.activemq.spring=WARN
log4j.logger.org.apache.activemq.web.handler=WARN
log4j.logger.org.springframework=WARN
log4j.logger.org.apache.xbean=WARN
log4j.logger.org.apache.camel=INFO
log4j.logger.org.eclipse.jetty=WARN

# When debugging or reporting problems to the ActiveMQ team,
# comment out the above lines and uncomment the next.

#log4j.rootLogger=DEBUG, logfile, console

# Or for more fine grained debug logging uncomment one of these
#log4j.logger.org.apache.activemq=DEBUG
#log4j.logger.org.apache.camel=DEBUG

# Console appender
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%5p | %m%n
log4j.appender.console.threshold=INFO

# File appender
log4j.appender.logfile=org.apache.log4j.RollingFileAppender
log4j.appender.logfile.file=$${activemq.data}/activemq.log
log4j.appender.logfile.maxFileSize=1024KB
log4j.appender.logfile.maxBackupIndex=5
log4j.appender.logfile.append=true
log4j.appender.logfile.layout=org.apache.log4j.EnhancedPatternLayout
log4j.appender.logfile.layout.ConversionPattern=%d | %-5p | %m | %c | %t%n%throwable{full}

# you can control the rendering of exception in the ConversionPattern
# by default, we display the full stack trace
# if you want to display short form of the exception, you can use
#
# log4j.appender.logfile.layout.ConversionPattern=%d | %-5p | %m | %c | %t%n%throwable{short}
#
# a classic issue with filebeat/logstash is about multiline exception. The following pattern
# allows to work smoothly with filebeat/logstash
#
# log4j.appender.logfile.layour.ConversionPattern=%d | %-5p | %m | %c | %t%n%replace(%throwable){\n}{ }
#

# use some of the following patterns to see MDC logging data
#
# %X{activemq.broker}
# %X{activemq.connector}
# %X{activemq.destination}
#
# e.g.
#
# log4j.appender.logfile.layout.ConversionPattern=%d | %-20.20X{activemq.connector} | %-5p | %m | %c | %t%n

###########
# Audit log
###########

log4j.additivity.org.apache.activemq.audit=false
log4j.logger.org.apache.activemq.audit=INFO, audit

log4j.appender.audit=org.apache.log4j.RollingFileAppender
log4j.appender.audit.file=$${activemq.data}/audit.log
log4j.appender.audit.maxFileSize=1024KB
log4j.appender.audit.maxBackupIndex=5
log4j.appender.audit.append=true
log4j.appender.audit.layout=org.apache.log4j.PatternLayout
log4j.appender.audit.layout.ConversionPattern=%-5p | %m | %t%n
EOF
}

# configmap with all the variables
resource "kubernetes_config_map" "activemq_configs" {
  metadata {
    name      = "activemq-configs"
    namespace = var.namespace
  }
  data = {
    "jetty.xml"              = local.activemq_jetty_xml
    "activemq.xml"           = local.activemq_xml
    "log4j.properties"       = local.log4j_properties
    "credentials.properties" = local.credentials_properties
    "jetty-realm.properties" = local.activemq_jetty_realm_properties
  }
}

# configmap with all the variables
resource "kubernetes_config_map" "activemq_jolokia_configs" {
  metadata {
    name      = "activemq-jolokia-configs"
    namespace = var.namespace
  }
  data = {
    "jolokia-access.xml" = local.jolokia_access_xml
  }
}

resource "local_file" "activemq_jetty_xml_file" {
  content  = local.activemq_jetty_xml
  filename = "${path.root}/generated/configmaps/activemq/jetty.xml"
}

resource "local_file" "activemq_xml_file" {
  content  = local.activemq_xml
  filename = "${path.root}/generated/configmaps/activemq/activemq.xml"
}

resource "local_file" "activemq_jolokia_file" {
  content  = local.jolokia_access_xml
  filename = "${path.root}/generated/configmaps/activemq/jolokia-access.xml"
}
