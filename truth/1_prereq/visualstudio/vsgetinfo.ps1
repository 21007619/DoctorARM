<#
.SYNOPSIS
    Lists all individual components and workloads installed for Visual Studio.

.DESCRIPTION
    Uses the Visual Studio Installer's vswhere.exe utility to locate installed
    Visual Studio instances and enumerate every individual component ID and
    workload ID installed for each instance. Defaults to Visual Studio
    Enterprise but can target any edition or all editions found on the
    machine. Requires vswhere.exe, which ships alongside the Visual Studio
    Installer at "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer".

.PARAMETER Edition
    The Visual Studio edition to filter for, e.g. "Enterprise", "Professional",
    "Community". Defaults to "Enterprise". Pass "All" to list components for
    every installed instance regardless of edition.

.PARAMETER OutputPath
    Optional path to a .csv file. When supplied, the results are also exported
    to this file in addition to being displayed on screen.

.EXAMPLE
    PS> .\Get-VSInstalledComponents.ps1

    Lists all individual components and workloads installed for Visual Studio
    Enterprise on this machine.

.EXAMPLE
    PS> .\Get-VSInstalledComponents.ps1 -Edition All -OutputPath "C:\Temp\VSComponents.csv"

    Lists components for every installed Visual Studio edition and also saves
    the results to a CSV file.

.NOTES
    Component and workload IDs match the identifiers used in a Visual Studio
    .vsconfig file, so this script is also useful for generating one.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Edition = "Enterprise",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# vswhere.exe is installed with the Visual Studio Installer itself, not with
# Visual Studio, so its path is fixed regardless of which VS edition is present.
$vswherePath = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"

if (-not (Test-Path -Path $vswherePath)) {
    Write-Error "vswhere.exe was not found at '$vswherePath'. Ensure the Visual Studio Installer is installed."
    return
}

# -include packages is the only valid switch that adds per-package detail
# (id, type, version) to each instance's "packages" array. Native exe output
# comes back as an array of lines, so it must be joined into one string
# before ConvertFrom-Json, otherwise PowerShell parses each line separately
# and fails on the first line that isn't valid JSON on its own.
try {
    $rawOutput = & $vswherePath -all -products * -include packages -utf8 -format json
    $instancesJson = ($rawOutput -join [Environment]::NewLine)
}
catch {
    Write-Error "Failed to run vswhere.exe: $_"
    return
}

if ([string]::IsNullOrWhiteSpace($instancesJson)) {
    Write-Warning "vswhere.exe returned no output. No Visual Studio instances may be installed."
    return
}

try {
    $instances = $instancesJson | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse vswhere.exe output as JSON: $_"
    Write-Host "Raw vswhere.exe output was:"
    Write-Host $instancesJson
    return
}

if (-not $instances -or $instances.Count -eq 0) {
    Write-Warning "No Visual Studio instances were found on this machine."
    return
}

if ($Edition -ne "All") {
    $instances = $instances | Where-Object { $_.displayName -like "*$Edition*" }
}

if (-not $instances -or $instances.Count -eq 0) {
    Write-Warning "No Visual Studio instances matching edition '$Edition' were found."
    return
}

$results = foreach ($instance in $instances) {
    # With "-include packages", each instance gets a "packages" array where
    # every entry has an "id" (the component/workload ID) and a "type"
    # ("Workload", "Component", or "Product").
    $packages = @($instance.packages) | Where-Object { $_ }

    foreach ($package in $packages) {
        [PSCustomObject]@{
            InstanceName        = $instance.displayName
            InstallationVersion = $instance.installationVersion
            Type                = $package.type
            ComponentId         = $package.id
        }
    }
}

$results = $results | Sort-Object InstanceName, Type, ComponentId

$results | Format-Table -AutoSize

if ($OutputPath) {
    try {
        $results | Export-Csv -Path $OutputPath -NoTypeInformation -Force
        Write-Host "Results exported to '$OutputPath'."
    }
    catch {
        Write-Error "Failed to export results to '$OutputPath': $_"
    }
}