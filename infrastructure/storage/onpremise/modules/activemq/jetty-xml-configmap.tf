# jetty.xml
locals {
  activemq_jetty_xml = <<EOF
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
}

# configmap with all the variables
resource "kubernetes_config_map" "activemq_jetty_xml" {
  metadata {
    name      = "activemq-jetty-xml"
    namespace = var.namespace
  }
  data = {
    "jetty.xml" = local.activemq_jetty_xml
  }
}

resource "local_file" "activemq_jetty_xml_file" {
  content  = local.activemq_jetty_xml
  filename = "./generated/configmaps/activemq_jetty.xml"
}