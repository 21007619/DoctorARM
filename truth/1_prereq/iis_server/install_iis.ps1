# ================================================
# IIS Installation Script
# Runs on Windows Server 2016 / 2019 / 2022 / 2025
# Must be run with Administrator privileges
# ================================================
#
# Note: Before running this script, run the following command to repair the Windows Component Store:
# DISM /Online /Cleanup-Image /RestoreHealth
#
# USAGE:
#   Curated install (default - recommended for production):
#     .\install_iis.ps1
#
#   Curated install, skip management tools:
#     .\install_iis.ps1 -IncludeManagementTools:$false
#
#   Curated install, skip ASP.NET features:
#     .\install_iis.ps1 -IncludeAspNet:$false
#
#   Install every available IIS sub-feature (FTP, WebDAV, legacy compat, etc.):
#     .\install_iis.ps1 -InstallAll
#
#   Install but do not auto-restart even if Windows says one is required
#   (you restart manually later):
#     .\install_iis.ps1 -RestartIfNeeded:$false
#
#   Combine switches as needed, e.g. install everything and don't reboot:
#     .\install_iis.ps1 -InstallAll -RestartIfNeeded:$false
#
# PARAMETERS:
#   -IncludeManagementTools   Installs IIS Manager console + tools (default: $true)
#   -IncludeAspNet            Installs ASP.NET 4.5 / .NET extensibility (default: $true)
#   -RestartIfNeeded          Auto-restarts the server if install requires it (default: $true)
#   -InstallAll               Installs every Web-* sub-feature instead of the curated list (default: $false)
#
# ================================================
param(
    [switch]$IncludeManagementTools = $true,
    [switch]$IncludeAspNet = $true,
    [switch]$RestartIfNeeded = $true,
    [switch]$InstallAll = $false     # If set, installs every Web-* sub-feature instead of the curated list
)

# Ensure script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as Administrator!"
    exit 1
}

Write-Host "Starting IIS installation..." -ForegroundColor Green

if ($InstallAll) {
    Write-Host "InstallAll specified - every IIS sub-feature will be installed." -ForegroundColor Yellow
}

# Curated list of IIS features (used unless -InstallAll is specified)
$features = @(
    "Web-Server",                    # Core IIS Web Server
    "Web-WebServer",                 # Web Server role services
    "Web-Common-Http",               # Common HTTP features
    "Web-Default-Doc",
    "Web-Dir-Browsing",
    "Web-Http-Errors",
    "Web-Static-Content",
    "Web-Http-Redirect",

    "Web-Health",                    # Health and diagnostics
    "Web-Http-Logging",
    "Web-Log-Libraries",
    "Web-Request-Monitor",
    "Web-Http-Tracing",

    "Web-Performance",               # Performance features
    "Web-Stat-Compression",
    "Web-Dyn-Compression",

    "Web-Security",                  # Security
    "Web-Filtering",
    "Web-Basic-Auth",
    "Web-Windows-Auth",

    "Web-App-Dev"                    # Application Development
)

if ($IncludeAspNet -and -not $InstallAll) {
    $features += "Web-AppInit"
    $features += "Web-Asp-Net45"
    $features += "Web-Net-Ext45"
}

if ($IncludeManagementTools -and -not $InstallAll) {
    $features += "Web-Mgmt-Tools"    # IIS Management Console + tools
    $features += "Web-Mgmt-Console"
    $features += "Web-Mgmt-Compat"   # pulls in Web-Metabase for legacy compatibility
}

# Install the features (no auto-restart here - we decide what to do below)
try {
    Write-Host "Installing IIS features..." -ForegroundColor Cyan

    if ($InstallAll) {
        # Install the Web-Server role plus every available sub-feature under it
        $result = Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools:$IncludeManagementTools -ErrorAction Stop
    }
    else {
        $result = Install-WindowsFeature -Name $features -ErrorAction Stop
    }

    if ($result.Success) {
        Write-Host "IIS installed successfully!" -ForegroundColor Green

        Write-Host "`nInstalled features:" -ForegroundColor Cyan
        $result.FeatureResult | Where-Object { $_.Success } | ForEach-Object {
            Write-Host "   - $($_.Name)" -ForegroundColor Green
        }

        if ($result.RestartNeeded -eq 'Yes') {
            if ($RestartIfNeeded) {
                Write-Host "`nA restart is required. Restarting now..." -ForegroundColor Yellow
                Restart-Computer -Force
                # Script execution ends here on restart
            }
            else {
                Write-Warning "A restart is required to complete the installation, but -RestartIfNeeded was not set. Please restart manually."
            }
        }
    }
    else {
        Write-Warning "Installation completed with warnings."
    }
}
catch {
    Write-Error "Failed to install IIS: $($_.Exception.Message)"
    exit 1
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
