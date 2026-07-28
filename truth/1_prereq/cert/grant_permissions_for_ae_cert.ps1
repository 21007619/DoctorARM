<#
.SYNOPSIS
    Grants FullControl permissions to Everyone on the private key file of the ARMEncryption certificate.
#>

# 1. Locate the ARMEncryption certificate
$cert = Get-ChildItem "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*ARMEncryption*" } | Select-Object -First 1

if (-not $cert) {
    Write-Error "ARMEncryption certificate not found in Cert:\LocalMachine\My"
    exit 1
}

Write-Host "Found Certificate: $($cert.Subject) [Thumbprint: $($cert.Thumbprint)]" -ForegroundColor Green

# 2. Extract RSA Private Key Unique Name
$rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
if (-not $rsa -or -not $rsa.Key.UniqueName) {
    Write-Error "Could not retrieve private key UniqueName for the certificate."
    exit 1
}

$uniqueName = $rsa.Key.UniqueName
Write-Host "Private Key UniqueName: $uniqueName" -ForegroundColor Cyan

# 3. Locate Private Key file path and store in $keyPath
$keyFile = Get-ChildItem -Path "C:\ProgramData\Microsoft\Crypto" -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -like "*$uniqueName*" } | 
    Select-Object -First 1

if (-not $keyFile) {
    Write-Error "Private key file not found under C:\ProgramData\Microsoft\Crypto"
    exit 1
}

$keyPath = $keyFile.FullName
Write-Host "Stored Key Path in `$keyPath: $keyPath" -ForegroundColor Yellow

# 4. Grant FullControl permissions to Everyone on the private key
$acl = Get-Acl -Path $keyPath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Allow")
$acl.AddAccessRule($rule)
Set-Acl -Path $keyPath -AclObject $acl

Write-Host "Done - Permissions successfully granted on ARMEncryption private key." -ForegroundColor Green