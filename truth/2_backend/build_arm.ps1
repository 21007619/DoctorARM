<#
.SYNOPSIS
    Builds ARM solutions using MSBuild and creates required symlink.
#>

# 1. Locate MSBuild
$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1

if (-not $msbuild) {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $msbuild = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | Select-Object -First 1
    }
}

if (-not $msbuild) {
    $vsPath = "C:\Program Files\Microsoft Visual Studio"
    if (Test-Path $vsPath) {
        $msbuild = Get-ChildItem -Path $vsPath -Filter "MSBuild.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
    }
}

if (-not $msbuild -or -not (Test-Path $msbuild)) {
    Write-Error "MSBuild.exe could not be found. Please ensure Visual Studio / MSBuild Tools are installed."
    exit 1
}

Write-Host "Using MSBuild: $msbuild" -ForegroundColor Green

# 2. Define Solutions to Build
$solutions = @(
    "C:\Projects\ARM\ARM\User Interface\arm.sln",
    "C:\Projects\ARM\ARM\User Interface\ActiveRisk.Arm.sln",
    "C:\Projects\ARM\ARM\Installer\Installer.sln"
)

# 3. Build each solution
foreach ($sln in $solutions) {
    if (Test-Path $sln) {
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host " Building: $sln" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        & $msbuild $sln /p:Configuration=Release /m /v:m
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed for solution: $sln"
            exit $LASTEXITCODE
        }
    } else {
        Write-Warning "Solution file not found at expected path: $sln"
    }
}

# 4. Create Symlink
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Creating Symlink" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$linkPath = "C:\Projects\ARM\ARM\Installer\ActiveRisk.Arm.Installer\bin\Database"
$targetPath = "C:\Projects\ARM\ARM\Database"

if (Test-Path $linkPath) {
    Write-Host "Symlink target path already exists at: $linkPath" -ForegroundColor Yellow
} else {
    # Ensure target folder exists
    if (-not (Test-Path $targetPath)) {
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    }
    # Ensure parent folder of link exists
    $linkParent = Split-Path -Path $linkPath -Parent
    if (-not (Test-Path $linkParent)) {
        New-Item -Path $linkParent -ItemType Directory -Force | Out-Null
    }

    cmd /c mklink /d "$linkPath" "$targetPath"
}

Write-Host "Build and Symlink process completed!" -ForegroundColor Green
