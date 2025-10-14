@echo off
set /p USERNAME="Enter your desired username: "

:password_input
powershell -Command "$pass1 = Read-Host 'Enter password' -AsSecureString; $pass2 = Read-Host 'Confirm password' -AsSecureString; $p1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass1)); $p2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass2)); if ($p1 -eq $p2) { $p1 } else { exit 1 }" > %temp%\pass.txt
if errorlevel 1 (
    echo Passwords do not match. Please try again.
    goto password_input
)

set /p PASSWORD=<%temp%\pass.txt
del %temp%\pass.txt

curl -L -o C:\Windows\Panther\unattend.xml https://raw.githubusercontent.com/Felitendo/bypassnro/refs/heads/main/unattend.xml
powershell -Command "$xml = [xml](Get-Content C:\Windows\Panther\unattend.xml); $xml.unattend.settings.component.UserAccounts.LocalAccounts.LocalAccount.Name = '%USERNAME%'; $xml.unattend.settings.component.UserAccounts.LocalAccounts.LocalAccount.Password.Value = '%PASSWORD%'; $xml.Save('C:\Windows\Panther\unattend.xml')"
%WINDIR%\System32\Sysprep\Sysprep.exe /oobe /unattend:C:\Windows\Panther\unattend.xml /reboot
