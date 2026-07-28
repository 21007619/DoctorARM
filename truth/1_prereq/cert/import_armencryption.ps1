function Get-PrivateKeyFilePath {
    param(
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    if (-not $Certificate.HasPrivateKey) {
        return $null
    }

    # Try legacy CSP key location first.
    try {
        $privateKey = $Certificate.PrivateKey
        if ($privateKey -and $privateKey.CspKeyContainerInfo) {
            $containerName = $privateKey.CspKeyContainerInfo.UniqueKeyContainerName
            if ($containerName) {
                $cspPath = Join-Path "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys" $containerName
                if (Test-Path $cspPath) {
                    return $cspPath
                }
            }
        }
    } catch {}

    # Then try CNG machine key location.
    try {
        $rsaCng = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
        if ($rsaCng -and $rsaCng.Key -and $rsaCng.Key.UniqueName) {
            $cngPath = Join-Path "$env:ProgramData\Microsoft\Crypto\Keys" $rsaCng.Key.UniqueName
            if (Test-Path $cngPath) {
                return $cngPath
            }
        }
    } catch {}

    return $null
}

function Grant-NetworkServiceFullControl {
    param(
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    $keyPath = Get-PrivateKeyFilePath -Certificate $Certificate
    if (-not $keyPath) {
        throw "Could not resolve private key file path for certificate thumbprint $($Certificate.Thumbprint)."
    }

    $acl = Get-Acl -Path $keyPath
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "NETWORK SERVICE",
        "FullControl",
        "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl -Path $keyPath -AclObject $acl

    Write-Host "Granted NETWORK SERVICE FullControl on private key: $keyPath"
}

try {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

    $pfxFile = Get-ChildItem -Path $scriptDir -Filter "*.pfx" -File | Select-Object -First 1
    if (-not $pfxFile) {
        Write-Error "No .pfx file found in script directory: $scriptDir"
        exit 1
    }

    $password = ConvertTo-SecureString "Supp0rt" -AsPlainText -Force

    $imported = Import-PfxCertificate `
        -FilePath $pfxFile.FullName `
        -Password $password `
        -CertStoreLocation "Cert:\LocalMachine\My" `
        -Exportable

    if (-not $imported) {
        Write-Error "Import-PfxCertificate did not return a certificate object."
        exit 1
    }

    foreach ($cert in $imported) {
        if ([string]::IsNullOrWhiteSpace($cert.FriendlyName)) {
            $cert.FriendlyName = "ARMEncryption"
        }

        Grant-NetworkServiceFullControl -Certificate $cert
    }

    Write-Host "PFX imported successfully from $($pfxFile.FullName) into Cert:\LocalMachine\My"
} catch {
    Write-Error "Failed to import ARMEncryption certificate: $($_.Exception.Message)"
    exit 1
}