@echo off

for /f "tokens=3 delims= " %%G in ('route print -4 ^| findstr "0.0.0.0 0.0.0.0"') do (
    set GW=%%G
    goto :gotGW
)

echo Error: Default gateway not found
exit /b 1

:gotGW


for /f "tokens=1,2,* delims= " %%A in ('netsh interface ipv4 show interfaces ^| findstr /R "vEthernet"') do (
    set IFACE=%%A
    goto :gotIF
)

echo Error: Hyper-V interface not found
exit /b 1

:gotIF

netsh interface ipv4 add route 169.254.169.254/32 interface=%IFACE% nexthop=%GW% store=persistent

if errorlevel 1 (
    echo Error: Failed to add route
    exit /b 1
)

echo 10.43.0.26 mongodb-armonik-headless.armonik.svc.cluster.local >> "C:\Windows\System32\drivers\etc\hosts"

"C:\Program Files\dotnet\dotnet.exe" ArmoniK.Core.Compute.PollingAgent.dll 

endlocal
