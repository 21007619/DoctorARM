## IIS SERVER INSTALL AND CONFIGURATION
yarp files must be executed
substitute that file with this one administration.config
iisadm.exe -config:C:\Windows\System32\inetsrv\config\administration.config   ???


## BUILD FRONTEND
cd "C:\projects\ARM\ARM\User Interface\App\src\ActiveRisk.Arm.App\ClientApp"
npm run reinstall
npm run dev-all
npm run build
