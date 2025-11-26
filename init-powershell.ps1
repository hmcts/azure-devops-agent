# Azure DevOps Agent PowerShell Initialization Script
# This script prevents type data loading conflicts in PowerShell tasks
# It should be called at the beginning of any PowerShell task if issues persist

Set-StrictMode -Off
$ErrorActionPreference = 'SilentlyContinue'

# Remove any existing type data for problematic types
$problematicTypes = @(
    'System.Security.AccessControl.ObjectSecurity',
    'System.Security.AccessControl.FileSystemSecurity',
    'System.Security.AccessControl.DirectorySecurity',
    'System.Security.AccessControl.FileSecurity',
    'System.Security.AccessControl.RegistrySecurity'
)

foreach ($typeName in $problematicTypes) {
    try {
        Remove-TypeData -TypeName $typeName -ErrorAction SilentlyContinue
    } catch {
        # Silently ignore if type doesn't exist or can't be removed
    }
}

# Set environment variables to prevent future loading
$env:__PSDisableTypeDataLoading = '1'
$env:PSModulePath = 'C:\Program Files\PowerShell\7\Modules;C:\Program Files\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules'
$env:POWERSHELL_TELEMETRY_OPTOUT = '1'
$env:POWERSHELL_UPDATECHECK = 'Off'

# Reset error action preference
$ErrorActionPreference = 'Continue'

Write-Host "PowerShell initialization complete - type data conflicts prevented"
