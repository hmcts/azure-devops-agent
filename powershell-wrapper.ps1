# PowerShell Wrapper Script for Azure DevOps Agent
# This script ensures proper PowerShell environment configuration for task execution

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Set strict module path to prevent module conflicts
$env:PSModulePath = 'C:\Program Files\PowerShell\7\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules'

# Disable telemetry and updates
$env:POWERSHELL_UPDATECHECK = 'Off'
$env:POWERSHELL_TELEMETRY_OPTOUT = '1'

# Remove problematic type data before executing the task
$ErrorActionPreference = 'SilentlyContinue'
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
        # Silently continue if type doesn't exist
    }
}
$ErrorActionPreference = 'Continue'

# Execute the provided command
if ($Arguments) {
    $scriptBlock = [ScriptBlock]::Create($Arguments -join ' ')
    & $scriptBlock
}
