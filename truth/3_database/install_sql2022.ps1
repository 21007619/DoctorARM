<#
.SYNOPSIS
    Installs SQL Server 2022 from an ISO file found in the script directory.

.DESCRIPTION
    - Ensures the local Administrator account is active and configured.
    - Detects the first .iso file in the script directory (no hardcoded filename required).
    - Mounts the ISO and runs setup.exe using SQL_ConfigurationFile.ini.
    - Requires a single SQL Server 2022 ISO to be present in the same folder as this script.

.PARAMETER (none)
    No parameters. Edit SQL_ConfigurationFile.ini to customise the installation.

.EXAMPLE
    # Run from an elevated PowerShell prompt:
    .\install_sql2022.ps1

.NOTES
    Must be run as Administrator.
    ISO file must be in the same directory as this script.
#>

# for azure add admin if not exist
net user administrator /active:yes
$adminName = "Administrator"
$adminPW = "FuturePotato?"
$securePW = $adminPW | ConvertTo-SecureString -AsPlainText -Force
$adminExist = Get-LocalUser -Name $adminName -ErrorAction SilentlyContinue
if ($null -eq $adminExist.Name) {
    New-LocalUser -Name $adminName -AccountNeverExpires -PasswordNeverExpires -Password $securePW
    Add-LocalGroupMember -Group "Administrators" -Member $adminName
} else {
    Set-LocalUser -Name $adminName -AccountNeverExpires -PasswordNeverExpires $True -Password $securePW
}

# list users
net users

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$isoFile = Get-ChildItem -Path $scriptDir -Filter *.iso | Select-Object -First 1
if ($null -eq $isoFile) { throw "No ISO file found in $scriptDir" }
write-host $isoFile.FullName

# mount iso
$mountResult = Mount-DiskImage -ImagePath $isoFile.FullName -PassThru  # has to be fqn
$volumeInfo = $mountResult | Get-Volume
$driveLetter = Get-PSDrive -Name $volumeInfo.driveLetter
write-host $driveLetter

# install and configure - set password here
$configfile = Join-Path $PSScriptRoot "SQL_ConfigurationFile.ini"
write-host "config path --> " $configfile

$command = "${driveLetter}:\setup.exe /ConfigurationFile=$($configfile) /SAPWD=FuturePotato?"
Invoke-Expression -Command $command

get-service *sql*
write-host *DONE*
