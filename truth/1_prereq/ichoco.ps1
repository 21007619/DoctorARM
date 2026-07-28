if ((Get-Command choco -ErrorAction SilentlyContinue) -or (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe")) {
    Write-Host "Chocolatey is already installed." -ForegroundColor Green
} else {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));choco feature enable -n allowGlobalConfirmation
}

$packages = @(
    @{ Name = "git" },
    @{ Name = "nodejs"; Version = "26.5.0" },
    @{ Name = "sqlcmd" },
    @{ Name = "sqlserver-odbcdriver" },
    @{ Name = "googlechrome" },
    @{ Name = "notepadplusplus" },
    @{ Name = "7zip" },
    @{ Name = "everything" },
    @{ Name = "sql-server-management-studio"; Version = "19.3.4" }
)

foreach ($package in $packages) {
    $arguments = @(
        "install",
        $package.Name,
        "-y",
        "--ignore-checksums"
    )
    if ($package.Version) {
        $arguments += "--version=$($package.Version)"
    }
    choco @arguments
}
