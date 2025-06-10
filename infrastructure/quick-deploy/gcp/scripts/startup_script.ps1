# ArmoniK Windows Startup Script - Clean Version
# This script downloads and executes the ArmoniK deployment

$ErrorActionPreference = "Continue"

# Configuration - These values are injected by Terraform
$HEALTH_PORT = ${health_port}
$PROJECT_ID = "${project_id}"
$REGION = "${region}"
$ENVIRONMENT = "${environment}"
$INSTANCE_NAME = "${instance_name}"
# GKE integration parameters
$CLUSTER_NAME = "${cluster_name}"
$CLUSTER_ENDPOINT = "${cluster_endpoint}"
$CLUSTER_REGION = "${cluster_region}"
$ARMONIK_NAMESPACE = "${armonik_namespace}"
# Database connection parameters
$MONGODB_HOST = "${mongodb_host}"
$REDIS_HOST = "${redis_host}"
$SERVICE_ACCOUNT = "${service_account}"

# Logging configuration
$LOG_FILE = "C:\armonik-startup.log"

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    try {
        $logDir = Split-Path $LOG_FILE -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $LOG_FILE -Value $logEntry -Force
    } catch {
        Write-Host "Failed to write to log file: $_"
    }
}

Write-Log "=== ArmoniK Windows Startup Script Started ==="
Write-Log "Health Port: $HEALTH_PORT"
Write-Log "Project ID: $PROJECT_ID"
Write-Log "Region: $REGION"
Write-Log "Environment: $ENVIRONMENT"
Write-Log "Instance Name: $INSTANCE_NAME"

# Get bucket name from instance metadata
try {
    Write-Log "Getting lifecycle bucket from metadata..."
    $bucketResponse = Invoke-WebRequest -Uri "http://metadata.google.internal/computeMetadata/v1/instance/attributes/lifecycle-bucket" -Headers @{"Metadata-Flavor"="Google"} -UseBasicParsing -TimeoutSec 10
    $bucketName = $bucketResponse.Content.Trim()
    Write-Log "Found lifecycle bucket: $bucketName"
}
catch {
    Write-Log "Failed to get bucket from metadata: $_" "ERROR"
    exit 1
}

# Install Google Cloud SDK if not present
$gcloudPath = "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
if (-not (Test-Path $gcloudPath)) {
    Write-Log "Installing Google Cloud SDK..."
    try {
        $gcloudInstallerUrl = "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe"
        $gcloudInstallerPath = "$env:TEMP\GoogleCloudSDKInstaller.exe"
        
        Invoke-WebRequest -Uri $gcloudInstallerUrl -OutFile $gcloudInstallerPath -UseBasicParsing
        Start-Process -FilePath $gcloudInstallerPath -ArgumentList "/S" -Wait
        
        # Add gcloud to PATH
        $env:PATH += ";C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin"
        Write-Log "Google Cloud SDK installed successfully"
    }
    catch {
        Write-Log "Failed to install Google Cloud SDK: $_" "ERROR"
        exit 1
    }
} else {
    Write-Log "Google Cloud SDK already installed"
}

# Download required files
$scriptDir = "C:\ArmoniK\scripts"
New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null

$files = @(
    "armonik_lifecycle_service.py",
    "armonik_windows_service.py",
    "armonik_config.json"
)

foreach ($file in $files) {
    Write-Log "Downloading $file from Cloud Storage..."
    try {
        & $gcloudPath storage cp "gs://$bucketName/$file" "$scriptDir\$file"
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Downloaded $file successfully"
        } else {
            Write-Log "Failed to download $file" "ERROR"
            exit 1
        }
    }
    catch {
        Write-Log "Error downloading $file : $_" "ERROR"
        exit 1
    }
}

# Rename files to their final names
Copy-Item "$scriptDir\armonik_lifecycle_service.py" "$scriptDir\armonik_lifecycle_service.py" -Force
Copy-Item "$scriptDir\armonik_windows_service.py" "$scriptDir\armonik_windows_service.py" -Force
Copy-Item "$scriptDir\armonik_config.json" "$scriptDir\armonik_config.json" -Force

# Install Python if needed
$pythonVersion = $null
try {
    $pythonVersion = python --version 2>$null
}
catch {
    # Python not found
}

if (-not $pythonVersion -or $pythonVersion -notmatch "Python 3\.([8-9]|1[0-9])\.") {
    Write-Log "Installing Python 3.11.8..."
    $pythonUrl = "https://www.python.org/ftp/python/3.11.8/python-3.11.8-amd64.exe"
    $pythonInstaller = "$env:TEMP\python-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -UseBasicParsing
        
        $installArgs = @(
            "/quiet",
            "InstallAllUsers=1",
            "PrependPath=1",
            "Include_test=0"
        )
        
        Start-Process -FilePath $pythonInstaller -ArgumentList $installArgs -Wait
        
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        Write-Log "Python installed successfully"
        Remove-Item $pythonInstaller -Force -ErrorAction SilentlyContinue
        
        # Install required packages
        $packages = @("pywin32")
        foreach ($package in $packages) {
            Write-Log "Installing Python package: $package"
            & python -m pip install $package
        }
        
    }
    catch {
        Write-Log "Failed to install Python: $_" "ERROR"
        exit 1
    }
} else {
    Write-Log "Python is already installed: $pythonVersion"
}

# Install and start the Windows service
Write-Log "Installing ArmoniK Windows Service..."
try {
    Set-Location $scriptDir
    & python armonik_windows_service.py install
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Service installed successfully"
        
        # Start the service
        & python armonik_windows_service.py start
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Service started successfully"
        } else {
            Write-Log "Failed to start service" "ERROR"
            exit 1
        }
    } else {
        Write-Log "Failed to install service" "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Error with service installation: $_" "ERROR"
    exit 1
}

# Wait a bit and test the health endpoint
Start-Sleep -Seconds 30
Write-Log "Testing health endpoint..."
try {
    $healthUrl = "http://localhost:8090/health"
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Log "✅ Health check passed - ArmoniK is running"
    } else {
        Write-Log "⚠️ Health check returned status code: $($response.StatusCode)" "WARNING"
    }
}
catch {
    Write-Log "⚠️ Health check failed: $_" "WARNING"
}

# Install kubectl for Windows node registration with GKE cluster
Write-Log "Installing kubectl..."
try {
    $kubectlUrl = "https://dl.k8s.io/release/stable.txt"
    $versionResponse = Invoke-WebRequest -Uri $kubectlUrl -UseBasicParsing
    $version = $versionResponse.Content.Trim()
    
    $kubectlDownloadUrl = "https://dl.k8s.io/release/$version/bin/windows/amd64/kubectl.exe"
    $kubectlPath = "C:\Windows\System32\kubectl.exe"
    
    Invoke-WebRequest -Uri $kubectlDownloadUrl -OutFile $kubectlPath -UseBasicParsing
    Write-Log "kubectl installed successfully"
}
catch {
    Write-Log "Failed to install kubectl: $_" "ERROR"
}

# Configure cluster access for Windows instances
Write-Log "Configuring GKE cluster access..."
try {
    # Get cluster credentials
    & $gcloudPath container clusters get-credentials $CLUSTER_NAME --region=$CLUSTER_REGION --project=$PROJECT_ID
    
    # Set up ArmoniK environment variables for Windows workers
    [Environment]::SetEnvironmentVariable("ARMONIK_CLUSTER_ENDPOINT", $CLUSTER_ENDPOINT, "Machine")
    [Environment]::SetEnvironmentVariable("ARMONIK_NAMESPACE", $ARMONIK_NAMESPACE, "Machine")
    [Environment]::SetEnvironmentVariable("MONGODB_HOST", $MONGODB_HOST, "Machine")
    [Environment]::SetEnvironmentVariable("REDIS_HOST", $REDIS_HOST, "Machine")
    
    Write-Log "GKE cluster access configured successfully"
}
catch {
    Write-Log "Failed to configure cluster access: $_" "ERROR"
}

Write-Log "=== ArmoniK Windows Startup Script Completed Successfully ==="
