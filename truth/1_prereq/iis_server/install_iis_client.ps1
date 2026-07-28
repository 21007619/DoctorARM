<#
.SYNOPSIS
    Installs IIS and a curated set of sub-features on Windows 10/11 (client OS).

.DESCRIPTION
    The Install-WindowsFeature cmdlet and the Web-* feature names only exist on
    Windows Server (ServerManager module). Windows 10/11 clients expose IIS as
    Windows Optional Features instead, with different feature names (IIS-*) and
    a different cmdlet: Enable-WindowsOptionalFeature.

    This script mirrors the curated feature set from the Server install script,
    mapped onto the equivalent client-OS feature names. It must be run as
    Administrator.

.PARAMETER IncludeManagementTools
    Installs the IIS Manager console. Default: true.

.PARAMETER IncludeAspNet
    Installs ASP.NET 4.5 / .NET extensibility for IIS. Default: true.

.PARAMETER RestartIfNeeded
    Automatically restarts the machine if Windows reports a restart is needed.
    Default: true.

.PARAMETER InstallAll
    If set, installs every available IIS-* optional feature instead of the
    curated list. Default: false.

.EXAMPLE
    PS> .\install_iis_client.ps1

    Curated install: core web server, common HTTP features, health/diagnostics,
    performance, security, ASP.NET, and management tools.

.EXAMPLE
    PS> .\install_iis_client.ps1 -IncludeManagementTools:$false -RestartIfNeeded:$false

    Curated install without the IIS Manager console, and without auto-restart.

.EXAMPLE
    PS> .\install_iis_client.ps1 -InstallAll

    Installs every IIS-* optional feature available on this machine.

.NOTES
    Feature name mapping from the Server script (Web-*) to client OS (IIS-*):
        Web-Server          -> IIS-WebServerRole
        Web-WebServer        -> IIS-WebServer
        Web-Common-Http       -> IIS-CommonHttpFeatures
        Web-Default-Doc       -> IIS-DefaultDocument
        Web-Dir-Browsing      -> IIS-DirectoryBrowsing
        Web-Http-Errors       -> IIS-HttpErrors
        Web-Static-Content     -> IIS-StaticContent
        Web-Http-Redirect      -> IIS-HttpRedirect
        Web-Health           -> IIS-HealthAndDiagnostics
        Web-Http-Logging       -> IIS-HttpLogging
        Web-Log-Libraries      -> IIS-LoggingLibraries
        Web-Request-Monitor     -> IIS-RequestMonitor
        Web-Http-Tracing       -> IIS-HttpTracing
        Web-Performance       -> IIS-Performance
        Web-Stat-Compression    -> IIS-HttpCompressionStatic
        Web-Dyn-Compression     -> IIS-HttpCompressionDynamic
        Web-Security         -> IIS-Security
        Web-Filtering        -> IIS-RequestFiltering
        Web-Basic-Auth        -> IIS-BasicAuthentication
        Web-Windows-Auth       -> IIS-WindowsAuthentication
        Web-App-Dev          -> IIS-ApplicationDevelopment
        Web-AppInit          -> IIS-ApplicationInit
        Web-Asp-Net45         -> IIS-ASPNET45
        Web-Net-Ext45         -> IIS-NetFxExtensibility45
        Web-Mgmt-Tools        -> IIS-WebServerManagementTools
        Web-Mgmt-Console       -> IIS-ManagementConsole
        Web-Mgmt-Compat       -> IIS-IIS6ManagementCompatibility, IIS-Metabase

    Client OS IIS does not support some server-only pieces (for example FTP
    publishing, WebDAV, and some legacy compatibility shims may be named or
    packaged differently). If a feature name is not present on this build of
    Windows, Enable-WindowsOptionalFeature will report an error for that
    feature; the script continues with the rest and reports failures at the end.
#>
[CmdletBinding()]
param(
    [switch]$IncludeManagementTools = $true,
    [switch]$IncludeAspNet = $true,
    [switch]$RestartIfNeeded = $true,
    [switch]$InstallAll = $false
)

# Ensure script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as Administrator!"
    exit 1
}

Write-Host "Starting IIS installation (client OS)..." -ForegroundColor Green

if ($InstallAll) {
    Write-Host "InstallAll specified - every available IIS-* optional feature will be installed." -ForegroundColor Yellow
}

# Curated list of client-OS IIS optional feature names (used unless -InstallAll is specified)
$features = @(
    "IIS-WebServerRole",
    "IIS-WebServer",
    "IIS-CommonHttpFeatures",
    "IIS-DefaultDocument",
    "IIS-DirectoryBrowsing",
    "IIS-HttpErrors",
    "IIS-StaticContent",
    "IIS-HttpRedirect",

    "IIS-HealthAndDiagnostics",
    "IIS-HttpLogging",
    "IIS-LoggingLibraries",
    "IIS-RequestMonitor",
    "IIS-HttpTracing",

    "IIS-Performance",
    "IIS-HttpCompressionStatic",
    "IIS-HttpCompressionDynamic",

    "IIS-Security",
    "IIS-RequestFiltering",
    "IIS-BasicAuthentication",
    "IIS-WindowsAuthentication",

    "IIS-ApplicationDevelopment"
)

if ($IncludeAspNet -and -not $InstallAll) {
    $features += "IIS-ApplicationInit"
    $features += "IIS-ASPNET45"
    $features += "IIS-NetFxExtensibility45"
}

if ($IncludeManagementTools -and -not $InstallAll) {
    $features += "IIS-WebServerManagementTools"
    $features += "IIS-ManagementConsole"
    $features += "IIS-IIS6ManagementCompatibility"
    $features += "IIS-Metabase"
}

if ($InstallAll) {
    # Discover every IIS-* feature this build of Windows actually offers
    $features = (Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like "IIS-*" }).FeatureName
}

$succeeded = @()
$failed = @()
$restartNeeded = $false

Write-Host "Installing IIS features..." -ForegroundColor Cyan

foreach ($feature in $features) {
    try {
        $result = Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart -ErrorAction Stop

        if ($result.RestartNeeded) {
            $restartNeeded = $true
        }

        $succeeded += $feature
        Write-Host "   - $feature" -ForegroundColor Green
    }
    catch {
        $failed += $feature
        Write-Warning "Failed to enable $feature`: $($_.Exception.Message)"
    }
}

if ($succeeded.Count -gt 0) {
    Write-Host "`nIIS installed successfully for the following features:" -ForegroundColor Green
    $succeeded | ForEach-Object { Write-Host "   - $_" -ForegroundColor Green }
}

if ($failed.Count -gt 0) {
    Write-Warning "The following features could not be enabled (they may not exist on this Windows build):"
    $failed | ForEach-Object { Write-Warning "   - $_" }
}

if ($restartNeeded) {
    if ($RestartIfNeeded) {
        Write-Host "`nA restart is required. Restarting now..." -ForegroundColor Yellow
        Restart-Computer -Force
        # Script execution ends here on restart
    }
    else {
        Write-Warning "A restart is required to complete the installation, but -RestartIfNeeded was not set. Please restart manually."
    }
}

# Verify IIS is installed (only reached if no restart occurred)
if (Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue) {
    Write-Host "`nIIS Web Server service is ready!" -ForegroundColor Green
    Write-Host "Open IIS Manager with: inetmgr" -ForegroundColor Cyan
}
else {
    Write-Warning "IIS service not detected. A restart may be required."
}

Write-Host "`nScript completed." -ForegroundColor Green
