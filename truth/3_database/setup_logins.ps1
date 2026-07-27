<#
.SYNOPSIS
    Connects to SQL Server using sqlcmd and executes create_login.sql.
#>

# 1. Resolve SQL script path
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}

$sqlFile = Join-Path $scriptDir "create_login.sql"
if (-not (Test-Path $sqlFile)) {
    # Fallback search if create_login.sql is in truth\3_database
    $sqlFile = Join-Path $scriptDir "3_database\create_login.sql"
}

if (-not (Test-Path $sqlFile)) {
    Write-Error "SQL script not found: create_login.sql"
    exit 1
}

# 2. Locate sqlcmd utility
$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1

if (-not $sqlcmd) {
    $sqlcmd = Get-ChildItem -Path "C:\Program Files\Microsoft SQL Server" -Filter "sqlcmd.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
}

if (-not $sqlcmd -or -not (Test-Path $sqlcmd)) {
    Write-Error "sqlcmd.exe utility not found. Ensure SQL Server Command Line Utilities are installed."
    exit 1
}

Write-Host "Using sqlcmd: $sqlcmd" -ForegroundColor Green

# 3. Connect and execute SQL script
$server = "."
Write-Host "Executing create_login.sql on $server..." -ForegroundColor Cyan

# Try Windows Authentication first
& $sqlcmd -S $server -E -i $sqlFile -b
if ($LASTEXITCODE -ne 0) {
    Write-Host "Windows Authentication attempt returned exit code $LASTEXITCODE. Retrying with SA credentials..." -ForegroundColor Yellow
    & $sqlcmd -S $server -U sa -P "FuturePotato?" -i $sqlFile -b
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully executed create_login.sql!" -ForegroundColor Green
} else {
    Write-Error "Failed to execute create_login.sql. Exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}
