## FILESPATHS AND PERMISSIONS

# Define required directories
$dirs = @(
    "C:\Program Files\Active Risk Manager\Server",
    "C:\Program Files\Active Risk Manager\Server\Logs",
    "C:\Program Files\Active Risk Manager\Server\Temp",
    "C:\Program Files\Active Risk Manager\Server\Web"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Ensure Web.config exists
$webConfig = "C:\Program Files\Active Risk Manager\Server\Web\Web.config"
if (-not (Test-Path $webConfig)) {
    $srcWebConfig = Join-Path $PSScriptRoot "Web.config"
    if (Test-Path $srcWebConfig) {
        Copy-Item -Path $srcWebConfig -Destination $webConfig -Force
    } else {
        New-Item -Path $webConfig -ItemType File -Force | Out-Null
    }
}

# Ensure instances.config exists in C:\Program Files\Active Risk Manager\Server\
$instancesConfig = "C:\Program Files\Active Risk Manager\Server\instances.config"
if (-not (Test-Path $instancesConfig)) {
    $srcInstancesConfig = Join-Path $PSScriptRoot "instances.config"
    if (Test-Path $srcInstancesConfig) {
        Copy-Item -Path $srcInstancesConfig -Destination $instancesConfig -Force
    } else {
        New-Item -Path $instancesConfig -ItemType File -Force | Out-Null
    }
}

# Ensure arm.config exists in C:\Projects\ARM
$armFolder = "C:\Projects\ARM"
if (-not (Test-Path $armFolder)) {
    New-Item -Path $armFolder -ItemType Directory -Force | Out-Null
}
$armConfig = Join-Path $armFolder "arm.config"
if (-not (Test-Path $armConfig)) {
    $srcArmConfig = Join-Path $PSScriptRoot "arm.config"
    if (Test-Path $srcArmConfig) {
        Copy-Item -Path $srcArmConfig -Destination $armConfig -Force
    } else {
        New-Item -Path $armConfig -ItemType File -Force | Out-Null
    }
}

# Apply permissions via batch script
$batPath = Join-Path $PSScriptRoot "set_permissions.bat"
& $batPath
