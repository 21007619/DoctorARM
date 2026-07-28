$host.UI.RawUI.WindowTitle = "visualstudio"

# Find the VS installer executable in the current directory / script location
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$installer = Get-ChildItem -Path $scriptDir -Filter "*.exe" | Select-Object -First 1

if (-not $installer) {
    Write-Error "No executable found in $scriptDir"
    exit 1
}

Write-Host "Found installer: $($installer.FullName)"

$arguments = @(
    "--add", "Microsoft.VisualStudio.Workload.CoreEditor",
    "--add", "Microsoft.VisualStudio.Workload.NetWeb",
    "--add", "Microsoft.VisualStudio.Workload.ManagedDesktop",
    "--norestart",
    "--includeRecommended",
    "--quiet",
    "--wait"
)

# Start process and wait for completion
$process = Start-Process -FilePath $installer.FullName -ArgumentList $arguments -Wait -PassThru -NoNewWindow

# Open installation directory
if (Test-Path "C:\Program Files\Microsoft Visual Studio\") {
    Invoke-Item "C:\Program Files\Microsoft Visual Studio\"
}

Write-Host "Exit Code: $($process.ExitCode)"
