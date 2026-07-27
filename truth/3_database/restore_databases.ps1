<#
.SYNOPSIS
    Restores ARM database backups (22_05_2495.bak as ARMCurrent1 and AuthDB.bak as AuthDB)
    using sqlcmd with LukaszARM / FuturePotato? credentials.
#>

# 1. Setup backup directory (copies files out of C:\Users to avoid SQL Server Access Denied errors)
$workingBackupDir = "C:\sql_backups"
if (-not (Test-Path $workingBackupDir)) {
    New-Item -Path $workingBackupDir -ItemType Directory -Force | Out-Null
}

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent }

# Copy backup files to C:\sql_backups
Get-ChildItem -Path $scriptDir -Filter "*.bak" | ForEach-Object {
    $dest = Join-Path $workingBackupDir $_.Name
    Copy-Item -Path $_.FullName -Destination $dest -Force
}

# Grant permissions so SQL Server service account can read the backup files
icacls $workingBackupDir /grant "Everyone:(OI)(CI)F" /T | Out-Null

# 2. Locate sqlcmd.exe
$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if (-not $sqlcmd) {
    $sqlcmd = Get-ChildItem -Path "C:\Program Files\Microsoft SQL Server" -Filter "sqlcmd.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
}
if (-not $sqlcmd -or -not (Test-Path $sqlcmd)) {
    Write-Error "sqlcmd.exe utility not found."
    exit 1
}

Write-Host "Using sqlcmd: $sqlcmd" -ForegroundColor Green

# Helper function to run T-SQL queries
function Invoke-SqlCmdQuery {
    param (
        [string]$Query,
        [string]$Database = "master"
    )
    $server = "."
    # Try LukaszARM credentials first, fallback to sa / Windows Auth
    $result = & $sqlcmd -S $server -U "LukaszARM" -P "FuturePotato?" -d $Database -Q $Query -b 2>$null
    if ($LASTEXITCODE -ne 0) {
        $result = & $sqlcmd -S $server -U sa -P "FuturePotato?" -d $Database -Q $Query -b 2>$null
    }
    if ($LASTEXITCODE -ne 0) {
        $result = & $sqlcmd -S $server -E -d $Database -Q $Query -b
    }
    return $result
}

# 3. Detect SQL Server Data directory
Write-Host "Detecting SQL Server DATA directory..." -ForegroundColor Cyan
$sqlDataDirQuery = "SELECT TOP 1 SUBSTRING(physical_name, 1, CHARINDEX('master.mdf', LOWER(physical_name)) - 1) FROM master.sys.master_files WHERE name = 'master'"
$sqlDataDirRaw = & $sqlcmd -S . -E -Q $sqlDataDirQuery -h -1 -W
$sqlDataDir = ($sqlDataDirRaw | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -First 1).Trim()

if (-not $sqlDataDir -or -not (Test-Path $sqlDataDir)) {
    $sqlDataDir = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\"
}
Write-Host "SQL Data Directory: $sqlDataDir" -ForegroundColor Green

# 4. Restore Databases
$databases = @(
    @{
        BakFile     = Join-Path $workingBackupDir "22_05_2495.bak"
        TargetDb    = "ARMCurrent1"
        DataLogical = "22_05_2495"
        LogLogical  = "22_05_2495_log"
    },
    @{
        BakFile     = Join-Path $workingBackupDir "AuthDB.bak"
        TargetDb    = "AuthDB"
        DataLogical = "AuthDB"
        LogLogical  = "AuthDB_log"
    }
)

foreach ($db in $databases) {
    $bakFile  = $db.BakFile
    $targetDb = $db.TargetDb

    if (-not (Test-Path $bakFile)) {
        Write-Warning "Backup file not found: $bakFile"
        continue
    }

    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " Restoring Database: $targetDb from $bakFile" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    $mdfPath = Join-Path $sqlDataDir "$targetDb.mdf"
    $ldfPath = Join-Path $sqlDataDir "$targetDb.ldf"

    $dataLogical = $db.DataLogical
    $logLogical  = $db.LogLogical

    $restoreSql = @"
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = '$targetDb')
BEGIN
    ALTER DATABASE [$targetDb] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$targetDb];
END

RESTORE DATABASE [$targetDb]
FROM DISK = '$bakFile'
WITH MOVE '$dataLogical' TO '$mdfPath',
     MOVE '$logLogical' TO '$ldfPath',
     REPLACE;

ALTER DATABASE [$targetDb] SET MULTI_USER;
"@

    Write-Host "Executing restore query for $targetDb..." -ForegroundColor Yellow
    Invoke-SqlCmdQuery -Query $restoreSql

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Database $targetDb restored successfully!" -ForegroundColor Green
    } else {
        Write-Error "[FAIL] Failed to restore database $targetDb"
}
}

Write-Host "Database restore process finished!" -ForegroundColor Green
