@echo off

cd "C:\projects\ARM\ARM\User Interface\App\src\ActiveRisk.Arm.App\ClientApp"
call npm run reinstall
call npm run dev-all
call npm run build