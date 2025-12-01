Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Set TLS 1.2 for secure connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Print-Header {
    param([string]$Text)
    Write-Host "`n$Text`n" -ForegroundColor Cyan
}

# Authenticate with Azure using federated token (similar to Linux version)
if (Test-Path Env:AZURE_FEDERATED_TOKEN_FILE) {
    Print-Header "Authenticating with Azure using federated token..."
    $federatedToken = Get-Content $env:AZURE_FEDERATED_TOKEN_FILE
    az login --federated-token $federatedToken --service-principal -u $env:AZURE_CLIENT_ID -t $env:AZURE_TENANT_ID
    
    $token = az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv
    if (-not $token) {
        Write-Error "error: could not get access token from Azure"
        exit 1
    }
} else {
    Write-Error "error: missing AZURE_FEDERATED_TOKEN_FILE environment variable"
    exit 1
}

# Validate required environment variables
if (-not $env:AZP_URL) {
    Write-Error "error: missing AZP_URL environment variable"
    exit 1
}

# Save token to file
$AZP_TOKEN_FILE = "C:\azp\.token"
$token | Out-File -FilePath $AZP_TOKEN_FILE -Encoding ascii -NoNewline

# Create work directory if specified
if ($env:AZP_WORK) {
    if (-not (Test-Path $env:AZP_WORK)) {
        New-Item -Path $env:AZP_WORK -ItemType Directory | Out-Null
    }
}

# Cleanup function to remove agent on exit
$cleanup = {
    if (Test-Path ".\config.cmd") {
        Print-Header "Cleanup. Removing Azure Pipelines agent..."
        
        # If the agent has running jobs, configuration removal will fail
        # Give it time to finish
        while ($true) {
            $token = Get-Content $AZP_TOKEN_FILE
            & .\config.cmd remove --unattended --auth PAT --token $token
            if ($LASTEXITCODE -eq 0) {
                break
            }
            
            Write-Host "Retrying in 30 seconds..."
            Start-Sleep -Seconds 30
        }
    }
}

# Let the agent ignore the token env variables
$env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"
$env:AGENT_ALLOW_RUNASROOT = "1"

Print-Header "1. Determining matching Azure Pipelines agent..."

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-Content $AZP_TOKEN_FILE)"))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    Accept = "application/json"
}

try {
    $package = Invoke-RestMethod -Uri "$env:AZP_URL/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1" -Headers $headers
    $packageUrl = $package.value[0].downloadUrl
    
    if (-not $packageUrl) {
        Write-Error "error: could not determine a matching Azure Pipelines agent"
        Write-Error "check that account '$env:AZP_URL' is correct and the token is valid for that account"
        exit 1
    }
    
    Write-Host $packageUrl
} catch {
    Write-Error "error: could not connect to Azure DevOps: $_"
    exit 1
}

Print-Header "2. Downloading and extracting Azure Pipelines agent..."

$agentZip = "C:\azp\agent.zip"

Write-Host "Starting agent download at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Yellow
Write-Host "Download URL: $packageUrl"
$downloadStart = Get-Date

Invoke-WebRequest -Uri $packageUrl -OutFile $agentZip

$downloadEnd = Get-Date
$downloadDuration = ($downloadEnd - $downloadStart).TotalSeconds
Write-Host "Download completed in $([math]::Round($downloadDuration, 2)) seconds" -ForegroundColor Green

$zipSize = (Get-Item $agentZip).Length / 1MB
Write-Host "Downloaded agent package size: $([math]::Round($zipSize, 2)) MB"

Write-Host "Starting extraction at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Yellow
$extractStart = Get-Date

Expand-Archive -Path $agentZip -DestinationPath "C:\azp\agent" -Force

$extractEnd = Get-Date
$extractDuration = ($extractEnd - $extractStart).TotalSeconds
Write-Host "Extraction completed in $([math]::Round($extractDuration, 2)) seconds" -ForegroundColor Green

Remove-Item $agentZip

$totalDuration = ($extractEnd - $downloadStart).TotalSeconds
Write-Host "Total download and extraction time: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor Cyan

Set-Location "C:\azp\agent"

# Source environment script if it exists
if (Test-Path ".\env.ps1") {
    . .\env.ps1
}

# Register cleanup handlers
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $cleanup

try {
    Print-Header "3. Configuring Azure Pipelines agent..."
    
    $token = Get-Content $AZP_TOKEN_FILE
    
    & .\config.cmd --unattended `
        --agent "$(if (Test-Path Env:AZP_AGENT_NAME) { ${Env:AZP_AGENT_NAME} } else { hostname })" `
        --url $env:AZP_URL `
        --auth PAT `
        --token $token `
        --pool "$(if (Test-Path Env:AZP_POOL) { ${Env:AZP_POOL} } else { 'Default' })" `
        --work "$(if (Test-Path Env:AZP_WORK) { ${Env:AZP_WORK} } else { '_work' })" `
        --replace `
        --acceptTeeEula
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Agent configuration failed"
        exit $LASTEXITCODE
    }
    
    Print-Header "4. Running Azure Pipelines agent..."
    
    # Run the agent
    # Pass CMD_ARGS directly to run.cmd similar to how the Linux version does it
    if ($env:CMD_ARGS) {
        Write-Host "Executing: .\run.cmd $env:CMD_ARGS"
        $process = Start-Process -FilePath ".\run.cmd" -ArgumentList $env:CMD_ARGS -Wait -NoNewWindow -PassThru
        $exitCode = $process.ExitCode
    } else {
        Write-Host "Executing: .\run.cmd"
        $process = Start-Process -FilePath ".\run.cmd" -Wait -NoNewWindow -PassThru
        $exitCode = $process.ExitCode
    }
    
    if ($exitCode -ne 0) {
        Write-Error "Agent execution failed with exit code $exitCode"
        exit $exitCode
    }
    
} finally {
    & $cleanup
}
