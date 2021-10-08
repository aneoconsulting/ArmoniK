<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <config>
        <add key="http_proxy" value="{{endpoint_url}}" />
        <add key="http_proxy.user" value="{{user}}" />
        <add key="http_proxy.password" value="{{password}}" />
    </config>
    <packageSources>
        <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    </packageSources>
</configuration>