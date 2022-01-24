<?xml version="1.0" encoding="utf-8"?>

<configuration>
	<config>
	</config>
	<packageRestore>
		<!-- Allow NuGet to download missing packages -->
		<add key="enabled" value="True" />

		<!-- Automatically check for missing packages during build in Visual Studio -->
		<add key="automatic" value="True" />
	</packageRestore>
	<packageSources>
		{localPackage}
		<add key="NuGet official package source" value="https://api.nuget.org/v3/index.json" />
	</packageSources>
</configuration>