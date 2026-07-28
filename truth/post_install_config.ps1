<#
.SYNOPSIS
    Post-installation configuration script.
    Connects to SQL Server using sqlcmd and executes create_login.sql.
#>

$scriptDir = $PSScriptRoot
$setupLoginsScript = Join-Path $scriptDir "3_database\setup_logins.ps1"

if (Test-Path $setupLoginsScript) {
    & $setupLoginsScript
} else {
    Write-Error "Could not find setup_logins.ps1 at $setupLoginsScript"
}
