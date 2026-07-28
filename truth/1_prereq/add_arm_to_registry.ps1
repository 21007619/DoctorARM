# add_arm_to_registry.ps1
# This script imports arm.reg into the Windows Registry.

# Resolve the path to the .reg file relative to this script
$regFile = Join-Path $PSScriptRoot "arm.reg"

if (Test-Path $regFile) {
    Write-Host "Importing registry file $regFile..."
    reg import $regFile
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Registry import succeeded."
    } else {
        Write-Error "Failed to import registry file. Exit code $LASTEXITCODE"
    }
} else {
    Write-Error "Registry file not found at $regFile"
}
