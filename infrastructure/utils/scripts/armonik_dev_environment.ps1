<#
    .SYNOPSIS
    ArmoniK dev environment installation on Windows
    
    .DESCRIPTION
    This script will allow ArmoniK dev to create a fast development
    environment tailored for ArmoniK. 
    The script will, at least on a regular windows, open a new window
    with Ubuntu WSL. In this window you will create a user by giving a username and a password.
    This user will be `sudo` user. 
    In the original powershell window, you have to answer to three questions:
        * the username which should be the username defined above
        * the password which should be the username defined above
        * the name of the branch that will be deployed

    .EXAMPLE
    PS> Set-ExecutionPolicy Bypass -Scope Process -Force; .\armonik_dev_environnement.ps1
    PS> armonik_dev_environnement.ps1
    
    #>

# Use the version 1.23 for keda compatibility
$k3s_version = "v1.23.9+k3s1"

function Restart-Genie {

    # Stop wsl
    wsl --shutdown

    # Initialise genie (small workaround to avoid systemd unit not working)
    $job = Start-Job -ScriptBlock {
        wsl -d Ubuntu genie  -i
    }
    Write-Host "5 sec Pause "
    $job | Wait-Job -TimeoutSec 5

    # Start the Ubuntu image if systemd is running
    $genie_run = wsl -d Ubuntu genie  -r
    if ($genie_run -ne "running") {
        Write-Host "systemd not working on this Ubuntu installation. Please reinstall genie."
        Write-Host "This script should have done it but something didn'work."
        Write-Host "Try to rerun this script or install genie manually using the following link:"
        Write-Host "https://gist.github.com/djfdyuruiry/6720faa3f9fc59bfdf6284ee1f41f950\n"    
        Exit
    }
}

# Test if Powershell Core is installed
$Pwsh = Get-Command -Name pwsh.exe -ErrorAction SilentlyContinue
if (-Not $Pwsh) {
    Write-Host "Please install PowerShell Core https://github.com/PowerShell/PowerShell"
    Exit
}

# Test if Docker Desktop is running
try {
    $docker_desktop_inst = Get-Process com.docker.service -ea Stop
    Write-Host "WARNING: Please disable Docker Desktop service."
    Write-Host "WSL with systemd is needed to run kubernetes."
    Write-Host "There are an incompatibility if Docker Desktop is also running."
    Write-Host "Stopping the service need Administrative access." 
    Write-Host "In an elevated powershell you can run the following command:"
    Write-Host  "Stop-Service com.docker.service" -ForegroundColor Green
    Exit
}
catch {}

# Test if WSL with ubuntu image has been previously installed
$wsl_output = wsl --list | Out-String
$ubuntu_exist = "Ubuntu" -in $wsl_output.Split()
if ($ubuntu_exist) {
    Write-Host "WSL Ubuntu exist. This script will not touch this installation."
    Write-Host "You can save it and re-install it with the commande:"
    Write-Host "wsl --export Ubuntu <name of the saved wsl>.tar"
    Write-Host "After saving it. You can unregister this WSL and use this script."
    Write-Host "wsl --unregister Ubuntu" -ForegroundColor Green
    Exit
}

# Environments variables

$pathfile = Convert-Path $PWD
$pathfile = $pathfile.Replace(":","")
$pathlist = $pathfile.Split("\")
$pathlist[0] = $pathlist[0].Substring(0).ToLower()
$pathname = $pathlist[0..($pathlist.Count-1)] -join "/"
$pathname = -join("/mnt/", $pathname, "/shell")

# Note: to export a previous WSL based on Ubuntu
# wsl --export Ubuntu Ubuntu_with_armorik.tar

# installation Windows Subsystem Linux (WSL)
# Note: 
#   That will open a new powershell terminal.
#   This terminal will open the linux wsl and ask 
#   to give a user name and password.
#   This credentials will be the ones with the administrative
#   power.    
#   It is advised to use the same username on the linux and 
#   windows plateform or this script will have to be adapted.

Write-Host "The script will create a Windows Subsytem Linux using an Ubuntu image."
wsl --install -d Ubuntu 
Write-Host "Wait until the WSL is configured to answer the question." -ForegroundColor Yellow
$ubuntu_user = Read-Host -Prompt "Which username did you use for your wsl installation"
Write-Host "Username that will be use for the next steps: $ubuntu_user"

$ubuntu_password = Read-Host -Prompt "Which password did you use for your wsl installation" -AsSecureString
$ubuntu_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ubuntu_password))

Write-Host "Available branches:"
$available_branches=git branch -a
foreach ($branch_name in $available_branches) 
    {Write-Host $branch_name}
$armonik_branch = Read-Host -Prompt "Which branch do you want to use?"
Write-Host "ArmoniK branch that will be use for the next steps: $armonik_branch"
# TODO: parse the $available_branches, give a number using the actual one (with a * in front) as default


## Install requirements

## Note: the sed command is used to convert the end of line to unix ones
wsl -d Ubuntu cp $pathname/ubuntu_requirements.sh /tmp
wsl -d Ubuntu sed -i -e "'s/\r$//'" /tmp/ubuntu_requirements.sh 
wsl -d Ubuntu bash -c "echo $ubuntu_password | sudo -S bash /tmp/ubuntu_requirements.sh $ubuntu_user"
wsl -d Ubuntu rm /tmp/ubuntu_requirements.sh

# Genie installation to have a systemd on the Ubuntu wsl image
wsl -d Ubuntu cp $pathname/systemd_wsl.sh /tmp
wsl -d Ubuntu sed -i -e "'s/\r$//'" /tmp/systemd_wsl.sh
wsl -d Ubuntu bash -c "echo $ubuntu_password | sudo -S bash /tmp/systemd_wsl.sh"
wsl -d Ubuntu rm /tmp/systemd_wsl.sh

wsl --shutdown
Restart-Genie

# ArmoniK
Write-Host "ArmoniK requirements installation (docker, k3s, terraform)"
wsl -d Ubuntu genie  -c cp $pathname/armonik_requirements.sh /tmp
wsl -d Ubuntu genie  -c sed -i -e "'s/\r$//'" /tmp/armonik_requirements.sh
wsl -d Ubuntu genie  -c bash -c "echo $ubuntu_password | sudo -S bash /tmp/armonik_requirements.sh $ubuntu_user $k3s_version"
wsl -d Ubuntu genie  -c rm /tmp/armonik_requirements.sh

# wsl -d Ubuntu genie  -c cp -r $pathname/k3s_installation.sh /tmp
# wsl -d Ubuntu genie  -c sed -i -e "'s/\r$//'" /tmp/k3s_installation.sh
# wsl -d Ubuntu genie  -c bash -c "echo $ubuntu_password | sudo -S bash /tmp/k3s_installation.sh $ubuntu_user $k3s_version"
# wsl -d Ubuntu genie  -c rm /tmp/k3s_installation.sh

Write-Host "ArmoniK installation"
wsl -d Ubuntu genie  -c cp $pathname/armonik_installation.sh /tmp 
wsl -d Ubuntu genie  -c sed -i -e "'s/\r$//'" /tmp/armonik_installation.sh
wsl -d Ubuntu genie  -c bash /tmp/armonik_installation.sh $armonik_branch
wsl -d Ubuntu genie  -c rm /tmp/armonik_installation.sh

# Test installation
wsl -d Ubuntu genie  -c kubectl get po -n armonik
wsl -d Ubuntu genie  -c kubectl get svc -n armonik

# Get WSL host IP adress
$wsl_ip = (wsl -d Ubuntu genie  -c hostname -I).trim().split()[0]
Write-Host "WSL Machine IP: ""$wsl_ip"""

# Open seq webserver in default browser
$seq_url = -join("http://", $wsl_ip, ":5000/seq")
Start-Process $seq_url

# Launch integrations tests
Write-Host "Launch integration test"
wsl -d Ubuntu genie  -c cp $pathname/test_armonik.sh /tmp 
wsl -d Ubuntu genie  -c sed -i -e "'s/\r$//'" /tmp/test_armonik.sh
wsl -d Ubuntu genie  -c bash /tmp/test_armonik.sh $armonik_branch
wsl -d Ubuntu genie  -c rm /tmp/test_armonik.sh