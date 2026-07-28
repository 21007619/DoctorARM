@echo off

call %~dp0dotnetfx35.exe /passive /norestart
call %~dp0ndp48-x86-x64-allos-enu.exe /passive /norestart
start /wait msiexec /i "%~dp0Microsoft WSE 3.0.msi" /passive /norestart
call %~dp0dotnet-sdk-10.0.302-win-x64.exe /passive /norestart
