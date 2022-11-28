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
    You can specify the variable `diskpath` to change the location of the virtual disk

    .PARAMETER diskpath
    Folder in which to install the virtual disk. If not specified, the default path is used.

    .PARAMETER vmversion
    Version of Ubuntu to install. If unspecified, the version used is `Ubuntu`.

    .EXAMPLE
    PS> Set-ExecutionPolicy Bypass -Scope Process -Force; .\armonik_dev_environnement.ps1
    PS> armonik_dev_environnement.ps1

    .EXAMPLE
    PS> Set-ExecutionPolicy Bypass -Scope Process -Force; .\armonik_dev_environnement.ps1
    PS> armonik_dev_environnement.ps1 -diskpath D:\WSL

    .EXAMPLE
    PS> Set-ExecutionPolicy Bypass -Scope Process -Force; .\armonik_dev_environnement.ps1
    PS> armonik_dev_environnement.ps1 -diskpath D:\WSL -vmversion
    
    #>

param ($diskpath, $vmversion)

# Use the version 1.23 for keda compatibility
$k3s_version = "v1.23.9+k3s1"

function Restart-Genie {
    
    $max_retries = 4

    # Stop wsl
    wsl --shutdown

    # Initialise genie (small workaround to avoid systemd unit not working)
    $job = Start-Job -ScriptBlock {
        wsl -d Ubuntu genie  -i
    }
    Write-Host "Checking Genie installation, 5 sec Pause"
    $job | Wait-Job -TimeoutSec 5
    
    For ($i=0; $i -lt $max_retries;)
    {
        $genie_run = wsl -d Ubuntu genie  -r
        if ($genie_run -eq "running")
        {
            $i = $max_retries
        }
        else
        {
            $i++
            Write-Host "WSL is not up, 5 sec Pause, retry $i / $max_retries"
            Start-Sleep 5
        }
    }
    $genie_run = wsl -d Ubuntu genie  -r
    # Start the Ubuntu image if systemd is running
    if ($genie_run -like "running*") {
        Write-Host "systemd not working on this Ubuntu installation. Please reinstall genie."
        Write-Host "This script should have done it but something didn'work."
        Write-Host "Try to rerun this script or install genie manually using the following link:"
        Write-Host "https://gist.github.com/djfdyuruiry/6720faa3f9fc59bfdf6284ee1f41f950\n"    
        Exit
    }
}

function Move-Disk {
    # Stop wsl
    wsl --shutdown

    # Create directory, do nothing if it exists
    mkdir $diskpath -Force

    $tarpath = Join-Path -Path $diskpath -ChildPath tmp.tar

    # Export to tar
    Write-Host "Exporting to tar..."
    wsl --export $vmversion $tarpath

    # Unregister old
    wsl --unregister $vmversion 

    # Import in new path
    Write-Host "Importing to new location..."
    wsl --import $vmversion $diskpath $tarpath

    # Remove tar
    Remove-Item $tarpath

    $config_exe = $vmversion.Replace(".", "").Replace("-", "")

    # Change default user back to what it was
    Push-Location $env:LOCALAPPDATA\Microsoft\WindowsApps
    Invoke-expression "$config_exe config --default-user $ubuntu_user"
    Pop-Location
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

if (-Not $vmversion){
    $vmversion = 'Ubuntu-20.04'
}

$available_installs = wsl --list --online
$available_installs = $available_installs.split() -like "Ubuntu*" | Sort-Object | Get-Unique
if($vmversion -notin $available_installs){
    Write-Host "The demanded version $vmversion is not available"
    Write-Host "This deployment script only supports Ubuntu installations"
    Write-Host "Available installations are :" $available_installs -Separator "`n - "
    Exit
}

# Test if WSL with ubuntu image has been previously installed
$wsl_output = wsl --list --quiet | Out-String
$ubuntu_exist = $vmversion -in $wsl_output.Split()
if ($ubuntu_exist) {
    Write-Host "WSL $vmversion exist. This script will not touch this installation."
    Write-Host "You can save it and re-install it with the commande:"
    Write-Host "wsl --export $vmversion <name of the saved wsl>.tar"
    Write-Host "After saving it. You can unregister this WSL and use this script."
    Write-Host "wsl --unregister $vmversion" -ForegroundColor Green
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

Write-Host "The script will create a Windows Subsytem Linux using the $vmversion image."
wsl --install -d $vmversion 
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

## Move virtual disk if the option is specified
if($diskpath) {
    Write-Host "Moving installation to the specified disk path : $diskpath"
    Move-Disk
    Write-Host "WSL installation succesfully moved"
}

## Install requirements

## Note: the sed command is used to convert the end of line to unix ones
wsl -d $vmversion cp $pathname/ubuntu_requirements.sh /tmp
wsl -d $vmversion sed -i -e "'s/\r$//'" /tmp/ubuntu_requirements.sh 
wsl -d $vmversion bash -c "echo $ubuntu_password | sudo -S bash /tmp/ubuntu_requirements.sh $ubuntu_user"
wsl -d $vmversion rm /tmp/ubuntu_requirements.sh

# Genie installation to have a systemd on the Ubuntu wsl image
wsl -d $vmversion cp $pathname/systemd_wsl.sh /tmp
wsl -d $vmversion sed -i -e "'s/\r$//'" /tmp/systemd_wsl.sh
wsl -d $vmversion bash -c "echo $ubuntu_password | sudo -S bash /tmp/systemd_wsl.sh"
wsl -d $vmversion rm /tmp/systemd_wsl.sh
wsl -d $vmversion bash -c "echo $ubuntu_password | sudo -S systemctl disable getty@tty1.service multipathd.service multipathd.socket ssh.service"
wsl -d $vmversion bash -c "echo $ubuntu_password | sudo -S systemctl mask systemd-remount-fs.service"

Restart-Genie

# ArmoniK
Write-Host "ArmoniK requirements installation (docker, k3s, terraform)"
wsl -d $vmversion genie  -c cp $pathname/armonik_requirements.sh /tmp
wsl -d $vmversion genie  -c sed -i -e "'s/\r$//'" /tmp/armonik_requirements.sh
wsl -d $vmversion genie  -c bash -c "echo $ubuntu_password | sudo -S bash /tmp/armonik_requirements.sh $ubuntu_user $k3s_version"
wsl -d $vmversion genie  -c rm /tmp/armonik_requirements.sh

Write-Host "ArmoniK installation"
wsl -d $vmversion genie  -c cp $pathname/armonik_installation.sh /tmp 
wsl -d $vmversion genie  -c sed -i -e "'s/\r$//'" /tmp/armonik_installation.sh
wsl -d $vmversion genie  -c bash /tmp/armonik_installation.sh $armonik_branch
wsl -d $vmversion genie  -c rm /tmp/armonik_installation.sh

# Test installation
wsl -d $vmversion genie  -c kubectl get po -n armonik
wsl -d $vmversion genie  -c kubectl get svc -n armonik

# Get WSL host IP adress
$wsl_ip = (wsl -d $vmversion genie  -c hostname -I).trim().split()[0]
Write-Host "WSL Machine IP: ""$wsl_ip"""

# Open seq webserver in default browser
$seq_url = -join("http://", $wsl_ip, ":5000/seq")
Start-Process $seq_url

# Launch integrations tests
Write-Host "Launch integration test"
wsl -d $vmversion genie  -c cp $pathname/test_armonik.sh /tmp 
wsl -d $vmversion genie  -c sed -i -e "'s/\r$//'" /tmp/test_armonik.sh
wsl -d $vmversion genie  -c bash /tmp/test_armonik.sh $armonik_branch
wsl -d $vmversion genie  -c rm /tmp/test_armonik.sh