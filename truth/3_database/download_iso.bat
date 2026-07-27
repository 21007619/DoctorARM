@echo off


for %%a in (*.exe) do (
  set myexe=%%a
)

set media=%cd%
echo %myexe%
echo %media%



:: download

if not exist %~dp0SQLServer2022-x64-ENU-Dev.iso (
  %myexe% /ACTION=download /QUIET /MEDIAPATH=%media% /MEDIATYPE=ISO
  echo iso downloaded
) else (
  echo iso downloaded
)
