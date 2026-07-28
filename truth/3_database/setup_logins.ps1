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

# 3. Determine target login name from the create script (simple regex for CREATE LOGIN)
$loginPattern = "CREATE\s+LOGIN\s+\[?(?<name>[^\]\s]+)\]?"
$loginMatch = Select-String -Path $sqlFile -Pattern $loginPattern -AllMatches | Select-Object -First 1
if (-not $loginMatch) {
    Write-Error "Could not determine login name from $sqlFile. Ensure it contains a CREATE LOGIN statement."
    exit 1
}
$loginName = $loginMatch.Matches[0].Groups["name"].Value
Write-Host "Target login: $loginName" -ForegroundColor Cyan

# 4. Connect to server and drop login if it exists, then create/re-create it
$server = "."
# Drop existing login (if any)
Write-Host "Attempting to drop existing login [$loginName]..." -ForegroundColor Yellow
$dropCmd = "IF EXISTS (SELECT name FROM sys.server_principals WHERE name = N'$loginName') BEGIN ALTER LOGIN [$loginName] DISABLE; DECLARE @kill nvarchar(max)=''; SELECT @kill = @kill + 'KILL ' + CAST(session_id AS varchar) + ';' FROM sys.dm_exec_sessions WHERE original_login_name = N'$loginName'; EXEC(@kill); DROP LOGIN [$loginName]; END"
& $sqlcmd -S $server -E -Q $dropCmd -b
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Drop login command returned exit code $LASTEXITCODE. Continuing..."
}

# Execute the create_login.sql script (attempt Windows Auth, fallback to SA)
Write-Host "Executing create_login.sql on $server..." -ForegroundColor Cyan
& $sqlcmd -S $server -E -i $sqlFile -b
if ($LASTEXITCODE -ne 0) {
    Write-Host "Windows Authentication attempt failed (exit $LASTEXITCODE). Retrying with SA credentials..." -ForegroundColor Yellow
    & $sqlcmd -S $server -U sa -P "FuturePotato?" -i $sqlFile -b
}
if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully executed create_login.sql!" -ForegroundColor Green
} else {
    Write-Error "Failed to execute create_login.sql. Exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}
