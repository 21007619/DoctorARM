## CLONE ARM REPO
git config --global credential.credentialStore dpapi
git clone https://riskonnect@dev.azure.com/riskonnect/ARM/_git/ARM C:\project\arm\arm



## FILESPATHS AND PERMISSIONS
it must have:
C:\Program Files\Active Risk Manager\Server\
C:\Program Files\Active Risk Manager\Server\Logs
C:\Program Files\Active Risk Manager\Server\Temp
C:\Program Files\Active Risk Manager\Server\Web


icacls "C:\Program Files\Active Risk Manager\Server\" /grant Everyone:(OI)(CI)F /T
icacls "C:\project\arm\arm" /grant Everyone:(OI)(CI)F /T
icacls "C:\Windows\System32\inetsrv\config\administration.config" /grant Everyone:(OI)(CI)F /T

Web.config must be here
C:\Program Files\Active Risk Manager\Server\Web\Web.config

instances.config must be here
C:\Program Files\Active Risk Manager\Server\

arm.config must be here
C:\Projects\ARM


## BUILD ARM AND INSTALLER

arm.sln
C:\Projects\ARM\ARM\User Interface\arm.sln

ActiveRisk.Arm.sln
C:\Projects\ARM\ARM\User Interface\ActiveRisk.Arm.sln

Installer.sln
C:\Projects\ARM\ARM\Installer\Installer.sln

create symlink
mklink /d "C:\Projects\ARM\ARM\Installer\ActiveRisk.Arm.Installer\bin\Database" "C:\Projects\ARM\ARM\Database"

## INSTALL CERTIFICATE
