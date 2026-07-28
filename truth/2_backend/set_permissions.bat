@echo off
:: Apply permissions
icacls "C:\Program Files\Active Risk Manager\Server" /grant Everyone:(OI)(CI)F /T
icacls "C:\Projects\ARM\arm" /grant Everyone:(OI)(CI)F /T
icacls "C:\Windows\System32\inetsrv\config\administration.config" /grant Everyone:(OI)(CI)F /T
