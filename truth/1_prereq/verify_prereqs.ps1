<#
.SYNOPSIS
    Prerequisite Verification Script for ARM Environment.
#>

$results = [Ordered]@{ }

function Test-Requirement {
    param (
        [string]$Name,
        [scriptblock]$TestBlock
    )
    try {
        $passed = & $TestBlock
        if ($passed) {
            Write-Host "[PASS] $Name" -ForegroundColor Green
            $results[$Name] = "PASS"
        } else {
            Write-Host "[FAIL] $Name" -ForegroundColor Red
            $results[$Name] = "FAIL"
        }
    } catch {
        Write-Host "[FAIL] $Name (Error: $_)" -ForegroundColor Red
        $results[$Name] = "FAIL"
    }
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Verifying ARM Environment Prerequisites" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Chocolatey
Test-Requirement "Chocolatey" {
    (Get-Command choco -ErrorAction SilentlyContinue) -or (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe")
}
# 2a. ARM Registry Check
Test-Requirement "ARM Registry Entries" {
    $regPath = "HKLM:\\SOFTWARE\\Strategic Thought Ltd\\Active Risk Manager Server"
    $prop = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
    $hasKey = $prop -and $prop.LicenceKey -ne $null
    if ($hasKey) {
        $domain = $prop.SetupDomainName
        $user = $prop.SetupUserName
        Write-Host "[INFO] SetupDomainName = $domain" -ForegroundColor Cyan
        Write-Host "[INFO] SetupUserName = $user" -ForegroundColor Cyan
    }
    $hasKey
}

# 2. Notepad++
Test-Requirement "Notepad++" {
    (Get-Command notepad++ -ErrorAction SilentlyContinue) -or 
    (Test-Path "C:\Program Files\Notepad++\notepad++.exe") -or 
    (Test-Path "C:\Program Files (x86)\Notepad++\notepad++.exe")
}

# 3. 7-Zip
Test-Requirement "7-Zip" {
    (Get-Command 7z -ErrorAction SilentlyContinue) -or 
    (Test-Path "C:\Program Files\7-Zip\7z.exe") -or 
    (Test-Path "C:\Program Files (x86)\7-Zip\7z.exe")
}

# 4. SqlCmd
Test-Requirement "SQLCmd Utility" {
    (Get-Command sqlcmd -ErrorAction SilentlyContinue) -or (Test-Path "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\*\Tools\Binn\sqlcmd.exe")
}

# 5. SQL Server ODBC Driver
Test-Requirement "SQL Server ODBC Driver" {
    $odbc = Get-ItemProperty "HKLM:\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers" -ErrorAction SilentlyContinue
    $hasDriver = $false
    if ($odbc) {
        $driverNames = $odbc.psobject.Properties.Name
        $hasDriver = ($driverNames -match "ODBC Driver .* for SQL Server").Count -gt 0 -or ($driverNames -contains "SQL Server")
    }
    $hasDriver
}

# 6. Everything (Voidtools)
Test-Requirement "Everything Search Tool" {
    (Get-Command Everything -ErrorAction SilentlyContinue) -or 
    (Test-Path "C:\Program Files\Everything\Everything.exe") -or 
    (Test-Path "C:\Program Files (x86)\Everything\Everything.exe")
}

# 7. Git
Test-Requirement "Git" {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    $null -ne $cmd
}

# 8. Node.js (Version 26.5.0)
Test-Requirement "Node.js (v26.5.0)" {
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    $nodeExe = if ($nodeCmd) { $nodeCmd.Source } else {
        @("C:\Program Files\nodejs\node.exe", 
          "$env:ProgramData\chocolatey\bin\node.exe",
          "$env:LOCALAPPDATA\Programs\node\node.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
    
    if ($nodeExe) {
        $nodeVer = & $nodeExe --version
        $nodeVer -like "v26.5.0*" -or $nodeVer -like "v26.*"
    } else {
        $false
    }
}

# 9. IIS Web Server
Test-Requirement "IIS Web Server (W3SVC)" {
    $service = Get-Service W3SVC -ErrorAction SilentlyContinue
    $null -ne $service
}

# 10. .NET Framework 4.8
Test-Requirement ".NET Framework 4.8" {
    $release = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release
    $release -ge 528040
}
# 11. .NET Framework 3.5
Test-Requirement ".NET Framework 3.5" {
    ((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue).State -eq "Enabled") -or
    ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" -ErrorAction SilentlyContinue).Install -eq 1)
}


# 13. WSE 3.0 (Web Services Enhancements 3.0)
Test-Requirement "WSE 3.0" {
    (Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\WSE\3.0") -or 
    (Test-Path "HKLM:\SOFTWARE\Microsoft\WSE\3.0") -or
    (Test-Path "C:\Program Files (x86)\Microsoft WSE\v3.0") -or
    (Test-Path "C:\Program Files\Microsoft WSE\v3.0")
}

# 14. .NET 10 SDK (major 10)
Test-Requirement ".NET 10 SDK (major 10)" {
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        $sdks = dotnet --list-sdks
        $matches = $sdks -split "`n" | ForEach-Object { $_.Trim() } |
            Where-Object { $_ -match '^10\.' }
        if ($matches) {
            Write-Host "[INFO] .NET SDK versions installed: $($matches -join ', ')" -ForegroundColor Cyan
            $true
        } else {
            $false
        }
    } else {
        $false
    }
}

# 15. ASP.NET Core Runtime 10 (10.0.10)
Test-Requirement "ASP.NET Core Runtime (10.0.10)" {
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        $runtimes = dotnet --list-runtimes
        ($runtimes -match "Microsoft\.AspNetCore\.App 10\.0\.10").Count -gt 0
    } else {
        $false
    }
}

# 16. Visual Studio
Test-Requirement "Visual Studio" {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vs = & $vswhere -latest -property installationPath
        [string]::IsNullOrWhiteSpace($vs) -eq $false
    } else {
        (Test-Path "C:\Program Files\Microsoft Visual Studio") -or (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio")
    }
}

# 17. MSBuild Tools
Test-Requirement "MSBuild Tools" {
    (Get-Command msbuild -ErrorAction SilentlyContinue) -or 
    (Get-ChildItem -Path "C:\Program Files\Microsoft Visual Studio" -Filter "MSBuild.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)
}

# 18. SQL Server 2022
Test-Requirement "SQL Server 2022" {
    $sqlServices = Get-Service -Name "MSSQL*" -ErrorAction SilentlyContinue
    if ($sqlServices) {
        $true
    } else {
        (Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server") -or (Test-Path "C:\Program Files\Microsoft SQL Server")
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
$failedCount = ($results.Values | Where-Object { $_ -eq "FAIL" }).Count
if ($failedCount -eq 0) {
    Write-Host "All prerequisites are installed and verified successfully!" -ForegroundColor Yellow
} else {
    Write-Host "$failedCount prerequisite(s) missing or failed verification." -ForegroundColor Yellow
}