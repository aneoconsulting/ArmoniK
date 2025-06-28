# ArmoniK Windows Startup Script for GCP - Simplified Version
# Reduced to essential functionality for deploying ArmoniK containers

param (
    [Parameter(Mandatory = $false)]
    [string]$LogFile = "C:\ArmoniK\logs\startup.log"
)

Write-Output "=== ArmoniK Startup Script Started $(Get-Date) ==="

# Global variables
$FlagFeatures = "C:\flags\features.flag"
$FlagDocker = "C:\flags\docker.flag"
$Dirs = @("C:\flags", "C:\temp", "C:\ArmoniK\logs", "C:\ArmoniK\shared", "C:\ArmoniK\config", "C:\ArmoniK\scripts", "C:\ArmoniK\mount", "C:\ArmoniK\empty")
$SharedHostPath = "C:\ArmoniK\shared"
$AddRouteScript = "C:\ArmoniK\scripts\init.bat"
$script:ArmoniKConfig = $null
$script:DockerImages = @{}
$script:initBat = "C:\ArmoniK\scripts\init.bat"


function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logline = "$timestamp [$Level] $Message"
    Write-Output $logline
    
    $logDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $LogFile -Value $logline -ErrorAction SilentlyContinue
}

function Get-ArmoniKConfiguration {
    Write-Log "Retrieving ArmoniK configuration from GCP metadata"
    try {
        $headers = @{"Metadata-Flavor" = "Google"}
        $configUrl = "http://metadata.google.internal/computeMetadata/v1/instance/attributes/armonik-config-json"
        $response = Invoke-RestMethod -Uri $configUrl -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        $initBatUrl = "http://metadata.google.internal/computeMetadata/v1/instance/attributes/init-bat"
        $initBatResponse = Invoke-RestMethod -Uri $initBatUrl -Headers $headers -TimeoutSec 30 -ErrorAction Stop

        if ($initBatResponse) { 
            $initBatResponse | Set-Content -Path $script:initBat
            Write-Log "Using custom init script: $script:initBat"
        } else {
            Write-Log "No custom init script provided, using default" -Level "WARN"
        }

        if ($response) {
            $script:ArmoniKConfig = $response
            Write-Log "Configuration retrieved successfully"
            
            if ($script:ArmoniKConfig.armonik -and $script:ArmoniKConfig.armonik.images) {
                $script:DockerImages = $script:ArmoniKConfig.armonik.images
                Write-Log "Docker images: Polling Agent=$($script:DockerImages.polling_agent), Worker=$($script:DockerImages.worker)"
            }
            return $true
        }
        Write-Log "Empty response from metadata service" -Level "ERROR"
        return $false
    } catch {
        Write-Log "Failed to retrieve configuration: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Test-Flag {
    param([string]$FlagPath)
    return (Test-Path $FlagPath)
}

function Set-Flag {
    param([string]$FlagPath)
    try {
        $flagDir = Split-Path $FlagPath -Parent
        if (-not (Test-Path $flagDir)) {
            New-Item -ItemType Directory -Path $flagDir -Force | Out-Null
        }
        New-Item -ItemType File -Path $FlagPath -Force | Out-Null
        Write-Log "Flag set: $FlagPath"
    } catch {
        Write-Log "Failed to set flag $FlagPath : $($_.Exception.Message)" -Level "ERROR"
    }
}

function Enable-WindowsFeatures {
    Write-Log "Enabling Windows containers feature"
    try {
        # Check if feature is already enabled
        $featureState = Get-WindowsOptionalFeature -Online -FeatureName "Containers"
        if ($featureState.State -eq "Enabled") {
            Write-Log "Windows Containers feature is already enabled"
            Set-Flag $FlagFeatures
            return $true
        }
        
        # Enable the feature but suppress automatic restart
        $result = Enable-WindowsOptionalFeature -Online -FeatureName "Containers" -All -NoRestart -ErrorAction Stop
        
        # Set the flag first so we don't repeat this step after restart
        Set-Flag $FlagFeatures
        
        # Check if restart is needed
        if ($result.RestartNeeded) {
            Write-Log "Windows features enabled - restart required, initiating restart"
            Start-Sleep -Seconds 5  # Give a moment for logs to flush
            Restart-Computer -Force
        } else {
            Write-Log "Windows features enabled - no restart required"
        }
        return $true
    } catch {
        Write-Log "Failed to enable Windows features: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}


function Install-DockerEngine {
    Write-Log "Installing Docker Engine using Mirantis install.ps1"
    try {
        $dockerService = Get-Service -Name "docker" -ErrorAction SilentlyContinue
        if ($dockerService -and $dockerService.Status -eq "Running") {
            Write-Log "Docker service already exists and is running"
            # Test if Docker is actually working
            try {
                $dockerVersion = docker --version 2>&1
                if ($dockerVersion -match "Docker version") {
                    Write-Log "Docker is already installed and working: $dockerVersion"
                    return $true
                }
            } catch {
                Write-Log "Docker service exists but not responding properly" -Level "WARN"
            }
        }
        $installerPath = "C:\temp\install.ps1"
        Write-Log "Downloading Docker installer to $installerPath"
        Invoke-WebRequest -Uri https://get.mirantis.com/install.ps1 -OutFile $installerPath
        Write-Log "Running Docker installer"
        & $installerPath
        Write-Log "Docker Engine installation script completed"
        Write-Log "System will reboot to complete Docker installation"
        return $true
    } catch {
        Write-Log "Install-DockerEngine error: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Start-DockerDaemon {
    Write-Log "Starting Docker daemon"
    try {
        $dockerService = Get-Service -Name "docker" -ErrorAction SilentlyContinue
        if (-not $dockerService) {
            Write-Log "Docker service not found. Docker may not be installed properly." -Level "ERROR"
            return $false
        }
        if ($dockerService.Status -eq "Running") {
            Write-Log "Docker daemon is already running"
            return $true
        }
        Write-Log "Starting Docker service..."
        Start-Service -Name "docker" -ErrorAction Stop
        $timeout = 60
        $counter = 0
        while ($counter -lt $timeout) {
            $dockerService = Get-Service -Name "docker" -ErrorAction SilentlyContinue
            if ($dockerService.Status -eq "Running") {
                Write-Log "Docker daemon started successfully"
                return $true
            }
            Start-Sleep -Seconds 1
            $counter++
        }
        Write-Log "Docker service failed to start within timeout" -Level "ERROR"
        return $false
    } catch {
        Write-Log "Failed to start Docker daemon: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}


function Start-DockerService {
    Write-Log "Starting Docker service"
    try {
        Start-Service -Name "docker" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 30
        
        # Test Docker availability
        $dockerVersion = docker --version 2>&1
        if ($dockerVersion -match "Docker version") {
            Write-Log "Docker is running: $dockerVersion"
            return $true
        }
        
        Write-Log "Docker not responding" -Level "ERROR"
        return $false
    } catch {
        Write-Log "Failed to start Docker: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Create-Agent-Files {
    $mountPath = "C:\ArmoniK\mount"
    
    if (-not (Test-Path -Path $mountPath)) {
        New-Item -Path $mountPath -ItemType Directory -Force | Out-Null
    }

    $script:ArmoniKConfig.armonik.polling_agent_files.PSObject.Properties | ForEach-Object {
        $filePath = Join-Path $mountPath $_.Name
        if (-not (Test-Path -Path $filePath)) {
            New-Item -Path $filePath -ItemType File -Force | Out-Null
            Write-Log "Created file: $filePath"
        } else {
            Write-Log "File already exists: $filePath"
        }
    }
}

function Create-Container-Agent {
    
    $agentPort = $script:ArmoniKConfig.armonik.worker_environment.ComputePlane__AgentChannel__Port
    # Build environment arguments
    $envArgs = @()
    if ($script:ArmoniKConfig.armonik.polling_agent_environment) {
        $script:ArmoniKConfig.armonik.polling_agent_environment.PSObject.Properties | ForEach-Object {
            $envArgs += @("-e", "$($_.Name)=$($_.Value)")
        }
    }

    # docker run --network nat --rm -it --user ContainerAdministrator -v "C:\ArmoniK\:C:\mnt" -v "C:\Program Files\Google\:C:\Program Files\Google" -v "C:\Program Files (x86)\Google\:C:\Program Files (x86)\Google" mcr.microsoft.com/windows/nanoserver:ltsc2022
    # Run container with proper mounts
    $dockerArgs = @(
        "create","--name","armonik-polling-agent","--restart","unless-stopped",
        "-p","${agentPort}:${agentPort}",
        "--user", "ContainerAdministrator",
        "--network","nat",
        #"--add-host","metadata.google.internal:169.254.169.254",
        #"-v", "C:\Program Files\Google:C:\Program Files\Google",
        #"-v", "C:\Program Files (x86)\Google:C:\Program Files (x86)\Google",
        "-v","${SharedHostPath}:C:\shared",
        "-v", "C:\ArmoniK\scripts:C:\ArmoniK\scripts",
        "--entrypoint", "C:\ArmoniK\scripts\init.bat"
    ) + $envArgs + @($script:DockerImages.polling_agent, "--")
    
    Write-Log "Pulling polling agent image: $($script:DockerImages.polling_agent)"
    docker pull $script:DockerImages.polling_agent 2>$null
    Write-Log "Starting polling agent container with port $($script:ArmoniKConfig.armonik.polling_agent_environment.ComputePlane__AgentChannel__Port)"
    & docker $dockerArgs
}


function Copy-Container-Agent {
    Write-Log "Copying files to polling agent container"
    docker cp "C:\ArmoniK\scripts\init.bat" "armonik-polling-agent:C:\ArmoniK\scripts\init.bat"

    foreach ($file in $script:ArmoniKConfig.armonik.polling_agent_files.Keys) {
        # Normalize and convert Unix-style path to Windows-style
        $file = $file -replace '/', '\'
        $container = "armonik-polling-agent"

        # Split into parts
        $parts = $file.TrimStart('\').Split('\')

        # Construct and copy each folder level
        $containerPath = "C:\"
        for ($i = 0; $i -lt $parts.Length - 1; $i++) {
            $containerPath = Join-Path $containerPath $parts[$i]
            docker cp "C:\ArmoniK\empty\." "${container}:${containerPath}"
        }

        # Finally, copy the actual file
        $sourceFile = Join-Path "C:\ArmoniK\mount" ($file.TrimStart('\'))
        $destinationFile = "C:\$file"
        docker cp "$sourceFile" "${container}:${destinationFile}"
    }
}

function Start-Container-Agent {
    docker start armonik-polling-agent
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Polling agent started successfully"
        # Verify container is actually running
        Start-Sleep -Seconds 2
        $containerRunning = docker ps --filter "name=armonik-polling-agent" --format "{{.Names}}" | Where-Object { $_ -eq "armonik-polling-agent" }
        if ($containerRunning) {
            Write-Log "Polling agent container is running"
            return $true
        } else {
            Write-Log "Polling agent container failed to start properly" -Level "ERROR"
            docker logs armonik-polling-agent --tail 20 2>&1 | ForEach-Object { Write-Log "PA Log: $_" -Level "ERROR" }
            return $false
        }
    }
    
    Write-Log "Failed to start polling agent" -Level "ERROR"
    docker logs armonik-polling-agent --tail 20 2>&1 | ForEach-Object { Write-Log "PA Log: $_" -Level "ERROR" }
    return $false
}


function Deploy-Containers {
    Write-Log "Deploying ArmoniK containers"

    Create-Agent-Files
    Create-Container-Agent
    Copy-Container-Agent
    
    # Rest of your existing container deployment code
    if (-not (Start-Container-Agent)) {
        Write-Log "Failed to start polling agent" -Level "ERROR"
        return $false
    }
    
    if (-not (Start-Worker)) {
        Write-Log "Failed to start worker" -Level "ERROR"
        return $false
    }
    
    Write-Log "All containers deployed successfully"
    return $true
}
function Start-Worker {
    Write-Log "Starting worker container"
    
    # Remove existing container if it exists
    docker rm -f armonik-worker 2>$null
    
    # Define worker port explicitly and consistently
    $workerPort = $script:ArmoniKConfig.armonik.worker_environment.ComputePlane__WorkerChannel__Port
    Write-Log "Configuring worker with port: $workerPort"
    
    # Build environment arguments
    # Build environment arguments
    $envArgs = @()
    if ($script:ArmoniKConfig.armonik.worker_environment) {
        $script:ArmoniKConfig.armonik.worker_environment.PSObject.Properties | ForEach-Object {
            $envArgs += @("-e", "$($_.Name)=$($_.Value)")
        }
    }
    # Add proper port configuration - ensure we use a valid port
    $shared = "${SharedHostPath}:C:\shared"
    # Run container
    $dockerArgs = @(
        "run", "-d", "--name", "armonik-worker", "--restart", "unless-stopped",
        "-p", "${workerPort}:${workerPort}",
        "--network","nat",
        "-v",$shared
    ) + $envArgs + @($script:DockerImages.worker)
    # Pull and run container
    Write-Log "Pulling worker image: $($script:DockerImages.worker)"
    docker pull $script:DockerImages.worker 2>$null
    Write-Log "Starting worker container with port $workerPort"
    & docker $dockerArgs
    
    # Verify container started properly
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Worker container started, waiting for it to initialize..."
        Start-Sleep -Seconds 5
        
        # Verify container is actually running
        $containerRunning = docker ps --filter "name=armonik-worker" --format "{{.Names}}" | 
            Where-Object { $_ -eq "armonik-worker" }
        
        if ($containerRunning) {
            Write-Log "Worker container is running"
            return $true
        } else {
            Write-Log "Worker container failed to start properly" -Level "ERROR"
            docker logs armonik-worker --tail 20 2>&1 | ForEach-Object { 
                Write-Log "Worker Log: $_" -Level "ERROR" 
            }
            return $false
        }
    }
    
    Write-Log "Failed to start worker" -Level "ERROR"
    docker logs armonik-worker --tail 20 2>&1 | ForEach-Object { 
        Write-Log "Worker Log: $_" -Level "ERROR" 
    }
    return $false
}



function Test-ContainerHealth {
    $agentPort = $script:ArmoniKConfig.armonik.worker_environment.ComputePlane__AgentChannel__Port
    $workerPort = $script:ArmoniKConfig.armonik.worker_environment.ComputePlane__WorkerChannel__Port
    Write-Log "Checking container health"
    
    $pollingHealthy = $false
    $workerHealthy = $false
    
    # Check polling agent health
    for ($i = 1; $i -le 6; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:${agentPort}/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Log "Polling Agent is healthy"
                $pollingHealthy = $true
                break
            }
        } catch {
            Write-Log "Polling Agent health check attempt $i/6 failed" -Level "WARN"
            if ($i -lt 6) { Start-Sleep -Seconds 10 }
        }
    }
    
    # Check worker health
    for ($i = 1; $i -le 6; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:${workerPort}/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Log "Worker is healthy"
                $workerHealthy = $true
                break
            }
        } catch {
            Write-Log "Worker health check attempt $i/6 failed" -Level "WARN"
            if ($i -lt 6) { Start-Sleep -Seconds 10 }
        }
    }
    
    # If health checks fail, show container logs for debugging
    if (-not $pollingHealthy) {
        Write-Log "Polling agent health check failed, showing logs:" -Level "ERROR"
        docker logs armonik-polling-agent --tail 10 2>&1 | ForEach-Object { Write-Log "PA Log: $_" -Level "ERROR" }
    }
    
    if (-not $workerHealthy) {
        Write-Log "Worker health check failed, showing logs:" -Level "ERROR"
        docker logs armonik-worker --tail 10 2>&1 | ForEach-Object { Write-Log "Worker Log: $_" -Level "ERROR" }
    }
    
    return ($pollingHealthy -and $workerHealthy)
}

function Get-ServerMetadata {
    $metadataPath = "computeMetadata/v1/instance"
    $response = Invoke-RestMethod -Headers @{'Metadata-Flavor'='Google'} -Uri "http://metadata.google.internal/$metadataPath"
    Write-Output $response
}

# ===============================
# MAIN EXECUTION
# ===============================

Write-Log "=== ArmoniK Windows Startup Begin ==="

# Create required directories
foreach ($dir in $Dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Type Directory -Path $dir -Force | Out-Null
        Write-Log "Created directory: $dir"
    }
}

# Load configuration
Write-Log "Loading ArmoniK configuration"
if (-not (Get-ArmoniKConfiguration)) {
    Write-Log "Failed to load configuration" -Level "ERROR"
    exit 1
}

Write-Log "Checking server metadata"
if (-not (Get-ServerMetadata)) {
    Write-Log "Failed to retrieve server metadata" -Level "ERROR"
    exit 1
}


# Step 1: Enable Windows features (requires reboot)
if (-not (Test-Flag $FlagFeatures)) {
    Write-Log "Step 1: Enabling Windows features"
    Enable-WindowsFeatures
    exit 0
}

Get-ServerMetadata

# Step 2: Install Docker (requires reboot)
if (-not (Test-Flag $FlagDocker)) {
    Write-Log "Step 2: Installing Docker Engine"
    if (-not (Install-DockerEngine)) {
        Write-Log "Docker installation failed" -Level "ERROR"
        exit 1
    }
    Set-Flag $FlagDocker
    Write-Log "Docker installation completed, system will reboot"
    Restart-Computer -Force
    exit 0
}

Get-ServerMetadata

# Step 3: Start Docker and deploy containers
Write-Log "Step 3: Starting Docker and configuring authentication"
if (-not (Start-DockerService)) {
    Write-Log "Failed to start Docker" -Level "ERROR"
    exit 1
}

Get-ServerMetadata

Write-Log "Opening Windows firewall for port "
try {
    New-NetFirewallRule `
        -DisplayName "Allow ArmoniK PollingAgent" `
        -Direction Inbound `
        -LocalPort 8080 `
        -Protocol TCP `
        -Action Allow | Out-Null
    Write-Log "Firewall rule added for TCP/8080"
} catch {
    Write-Log "Failed to add firewall rule: $($_.Exception.Message)" -Level "WARN"
}

Write-Log "Opening Windows firewall for port 8090"
try {
  New-NetFirewallRule `
    -DisplayName "Allow ArmoniK Worker" `
    -Direction Inbound `
    -LocalPort 8090 `
    -Protocol TCP `
    -Action Allow | Out-Null
  Write-Log "Firewall rule added for TCP/8090"
} catch {
  Write-Log "Failed to add firewall rule for worker: $($_.Exception.Message)" -Level "WARN"
}

Write-Log "Step 4: Deploying ArmoniK containers"
if (-not (Deploy-Containers)) {
    Write-Log "Container deployment failed" -Level "ERROR"
    exit 1
}

if (-not (Get-ServerMetadata)) {
    Write-Log "Failed to retrieve server metadata after deployment" -Level "ERROR"
    Restart-Computer -Force
    exit 0
}

Write-Log "Step 5: Checking container health"
if (-not (Test-ContainerHealth)) {
    Write-Log "Container health checks failed" -Level "ERROR"
    exit 1
}

Write-Log "=== ArmoniK deployment completed successfully ==="
exit 0
