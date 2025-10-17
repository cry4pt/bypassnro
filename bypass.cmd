@echo off
setlocal enabledelayedexpansion
title Windows OOBE Bypass Setup

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo ========================================
echo  Windows OOBE Bypass Configuration
echo ========================================
echo.

:: Get username with validation
:username_input
set "USERNAME="
set /p USERNAME="Enter your desired username: "
if "!USERNAME!"=="" (
    echo ERROR: Username cannot be empty.
    echo.
    goto username_input
)

:: Check for invalid characters
echo !USERNAME! | findstr /r "[^a-zA-Z0-9_-]" >nul
if !errorLevel! equ 0 (
    echo ERROR: Username can only contain letters, numbers, hyphens, and underscores.
    echo.
    goto username_input
)

:: Get and confirm password
:password_input
echo.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; try { $pass1 = Read-Host 'Enter password (min 8 chars)' -AsSecureString; $pass2 = Read-Host 'Confirm password' -AsSecureString; $p1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass1)); $p2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass2)); if ($p1.Length -lt 8) { Write-Host 'ERROR: Password must be at least 8 characters'; exit 2 } if ($p1 -eq $p2) { $p1 } else { exit 1 } } catch { exit 3 }" > "%temp%\pass.txt" 2>nul

if errorlevel 3 (
    echo ERROR: PowerShell execution failed.
    goto cleanup_error
)
if errorlevel 2 (
    echo ERROR: Password must be at least 8 characters.
    echo.
    goto password_input
)
if errorlevel 1 (
    echo ERROR: Passwords do not match. Please try again.
    echo.
    goto password_input
)

set /p PASSWORD=<"%temp%\pass.txt"
if "!PASSWORD!"=="" (
    echo ERROR: Password cannot be empty.
    echo.
    goto password_input
)

:: Download unattend.xml with error handling
echo.
echo Downloading unattend.xml...
curl -L --fail --silent --show-error -o "%TEMP%\unattend.xml" https://raw.githubusercontent.com/cry4pt/bypassnro/refs/heads/main/unattend.xml
if errorlevel 1 (
    echo ERROR: Failed to download unattend.xml
    echo Check your internet connection and try again.
    goto cleanup_error
)

:: Create backup directory if it doesn't exist
if not exist "C:\Windows\Panther" mkdir "C:\Windows\Panther"

:: Backup existing unattend.xml if present
if exist "C:\Windows\Panther\unattend.xml" (
    echo Backing up existing unattend.xml...
    copy /y "C:\Windows\Panther\unattend.xml" "C:\Windows\Panther\unattend.xml.backup" >nul
)

:: Move downloaded file
move /y "%TEMP%\unattend.xml" "C:\Windows\Panther\unattend.xml" >nul
if errorlevel 1 (
    echo ERROR: Failed to move unattend.xml to destination.
    goto cleanup_error
)

:: Modify XML with proper error handling
echo Configuring user account...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $xml = [xml](Get-Content 'C:\Windows\Panther\unattend.xml'); $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable); $ns.AddNamespace('u', 'urn:schemas-microsoft-com:unattend'); $ns.AddNamespace('wcm', 'http://schemas.microsoft.com/WMIConfig/2002/State'); $account = $xml.SelectSingleNode('//u:LocalAccount', $ns); if ($null -eq $account) { Write-Host 'ERROR: Could not find LocalAccount node in XML'; exit 1 }; $nameNode = $account.SelectSingleNode('u:Name', $ns); if ($null -eq $nameNode) { Write-Host 'ERROR: Could not find Name node'; exit 1 }; $nameNode.InnerText = $env:USERNAME; $passNode = $account.SelectSingleNode('u:Password/u:Value', $ns); if ($null -eq $passNode) { Write-Host 'ERROR: Could not find Password Value node'; exit 1 }; $passNode.InnerText = $env:PASSWORD; $xml.Save('C:\Windows\Panther\unattend.xml'); Write-Host 'Configuration successful!' } catch { Write-Host \"ERROR: $($_.Exception.Message)\"; exit 1 }"

if errorlevel 1 (
    echo ERROR: Failed to modify unattend.xml
    goto cleanup_error
)

:: Clean up password file
if exist "%temp%\pass.txt" del /f /q "%temp%\pass.txt"

:: Final confirmation
echo.
echo ========================================
echo Configuration complete!
echo ========================================
echo Username: !USERNAME!
echo.
echo WARNING: Your system will now reboot and reconfigure.
echo Press Ctrl+C to cancel, or
pause

:: Run Sysprep
echo.
echo Running Sysprep...
"%WINDIR%\System32\Sysprep\Sysprep.exe" /oobe /unattend:C:\Windows\Panther\unattend.xml /reboot

:: If we reach here, sysprep failed to start
echo.
echo ERROR: Failed to start Sysprep.
echo Please check that Sysprep is available on your system.
pause
exit /b 1

:cleanup_error
if exist "%temp%\pass.txt" del /f /q "%temp%\pass.txt"
if exist "%TEMP%\unattend.xml" del /f /q "%TEMP%\unattend.xml"
echo.
echo Script failed. Please try again or check the error messages above.
pause
exit /b 1
