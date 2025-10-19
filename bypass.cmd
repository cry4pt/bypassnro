@echo off
setlocal EnableDelayedExpansion
title Windows OOBE Bypass Setup (Improved)

:: ---------------------------
:: Helper variables
:: ---------------------------
set "PASSFILE=%TEMP%\bypass_pass.txt"
set "UNATTEND_TEMP=%TEMP%\unattend.xml"
set "PANTHER_DIR=C:\Windows\Panther"
set "PANTHER_UNATTEND=%PANTHER_DIR%\unattend.xml"

:: ---------------------------
:: Check for admin privileges
:: ---------------------------
>nul 2>&1 net session
if %errorlevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    pause
    exit /b 1
)

echo ========================================
echo  Windows OOBE Bypass Configuration
echo ========================================
echo.

:: ---------------------------
:: Username input & validation
:: ---------------------------
:username_input
set "USERNAME="

rem Read raw input with delayed expansion disabled so '!' chars are preserved
setlocal DISABLEDELAYEDEXPANSION
set /p "TMPUSER=Enter your desired username: "
endlocal & set "USERNAME=%TMPUSER%"

if "%USERNAME%"=="" (
    echo ERROR: Username cannot be empty.
    echo.
    goto username_input
)

rem Validate allowed characters using PowerShell regex (letters, digits, hyphen, underscore)
powershell -NoProfile -Command ^
    "if ('%USERNAME%' -match '^[A-Za-z0-9_-]+$') { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Username can only contain letters, numbers, hyphens, and underscores.
    echo.
    goto username_input
)

:: ---------------------------
:: Password input & confirmation
:: ---------------------------
:password_input
if exist "%PASSFILE%" del /f /q "%PASSFILE%" >nul 2>&1

echo.
powershell -NoProfile -Command ^
  "$ErrorActionPreference='Stop'; try {
     $p1 = Read-Host 'Enter password (min 8 chars)' -AsSecureString;
     $p2 = Read-Host 'Confirm password' -AsSecureString;
     $plain1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p1));
     $plain2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p2));
     if ($plain1.Length -lt 8) { Write-Host 'ERRLEN'; exit 2 }
     if ($plain1 -ne $plain2) { Write-Host 'ERRMATCH'; exit 1 }
     Write-Output $plain1
   } catch {
     Write-Host 'ERRPS'
     exit 3
   }" > "%PASSFILE%" 2>nul

if errorlevel 3 (
    echo ERROR: PowerShell failed to read the password. Ensure PowerShell is available.
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

set /p PASSWORD=<"%PASSFILE"
if "%PASSWORD%"=="" (
    echo ERROR: Password cannot be empty.
    goto password_input
)

:: ---------------------------
:: Download unattend.xml
:: ---------------------------
echo.
echo Downloading unattend.xml...
set "UNATTEND_URL=https://raw.githubusercontent.com/cry4pt/bypassnro/refs/heads/main/unattend.xml"

:: Try curl first (preferred), otherwise fall back to PowerShell
where curl >nul 2>&1
if %errorlevel% equ 0 (
    curl -L --fail --silent --show-error -o "%UNATTEND_TEMP%" "%UNATTEND_URL%"
    if %errorlevel% neq 0 (
        echo ERROR: curl failed to download unattend.xml.
        goto cleanup_error
    )
) else (
    powershell -NoProfile -Command ^
      "try { (New-Object System.Net.WebClient).DownloadFile('%UNATTEND_URL%','%UNATTEND_TEMP%'); exit 0 } catch { exit 1 }"
    if %errorlevel% neq 0 (
        echo ERROR: Failed to download unattend.xml via PowerShell.
        goto cleanup_error
    )
)

:: ---------------------------
:: Prepare Panther dir and backup existing file
:: ---------------------------
if not exist "%PANTHER_DIR%" (
    mkdir "%PANTHER_DIR%" 2>nul
    if %errorlevel% neq 0 (
        echo ERROR: Failed to create %PANTHER_DIR%.
        goto cleanup_error
    )
)

if exist "%PANTHER_UNATTEND%" (
    echo Backing up existing unattend.xml...
    copy /y "%PANTHER_UNATTEND%" "%PANTHER_UNATTEND%.backup" >nul
    if %errorlevel% neq 0 (
        echo WARNING: Failed to back up existing unattend.xml. Continuing...
    )
)

:: Move downloaded file into place
move /y "%UNATTEND_TEMP%" "%PANTHER_UNATTEND%" >nul
if %errorlevel% neq 0 (
    echo ERROR: Failed to move unattend.xml to %PANTHER_UNATTEND%.
    goto cleanup_error
)

:: ---------------------------
:: Modify unattend.xml to set username and password
:: ---------------------------
echo Configuring user account in unattend.xml...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "param($u,$p,$path); try {
     [xml]$xml = Get-Content -Path $path -ErrorAction Stop;
     $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable);
     $ns.AddNamespace('u','urn:schemas-microsoft-com:unattend');
     $ns.AddNamespace('wcm','http://schemas.microsoft.com/WMIConfig/2002/State');

     $account = $xml.SelectSingleNode('//u:LocalAccount', $ns);
     if ($null -eq $account) { Write-Host 'ERR: LocalAccount node not found'; exit 1 }

     $nameNode = $account.SelectSingleNode('u:Name', $ns);
     if ($null -eq $nameNode) { Write-Host 'ERR: Name node not found'; exit 1 }
     $nameNode.InnerText = $u;

     $passNode = $account.SelectSingleNode('u:Password/u:Value', $ns);
     if ($null -eq $passNode) { Write-Host 'ERR: Password Value node not found'; exit 1 }
     $passNode.InnerText = $p;

     $xml.Save($path);
     Write-Host 'OK';
     exit 0
   } catch {
     Write-Host ('ERR: ' + $_.Exception.Message);
     exit 2
   }" -ArgumentList "%USERNAME%","%PASSWORD%","%PANTHER_UNATTEND%" > "%TEMP%\bypass_xml_out.txt" 2>&1

findstr /i "OK" "%TEMP%\bypass_xml_out.txt" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Failed to modify unattend.xml. See details below.
    type "%TEMP%\bypass_xml_out.txt"
    goto cleanup_error
)
del /f /q "%TEMP%\bypass_xml_out.txt" >nul 2>&1

:: ---------------------------
:: Cleanup sensitive temp file (password)
:: ---------------------------
if exist "%PASSFILE%" (
    del /f /q "%PASSFILE%" >nul 2>&1
)

:: ---------------------------
:: Final confirmation & run sysprep
:: ---------------------------
echo.
echo ========================================
echo Configuration complete!
echo ========================================
echo Username: %USERNAME%
echo.
echo WARNING: Your system will now reboot and reconfigure.
echo Press Ctrl+C to cancel, or press any key to continue...
pause >nul

echo.
echo Running Sysprep...
"%WINDIR%\System32\Sysprep\Sysprep.exe" /oobe /unattend:"%PANTHER_UNATTEND%" /reboot
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to start Sysprep. Please check that Sysprep is present and you have appropriate permissions.
    pause
    goto final_cleanup
)

exit /b 0

:: ---------------------------
:: Error cleanup label
:: ---------------------------
:cleanup_error
if exist "%PASSFILE%" del /f /q "%PASSFILE%" >nul 2>&1
if exist "%UNATTEND_TEMP%" del /f /q "%UNATTEND_TEMP%" >nul 2>&1
echo.
echo Script failed. Please review the messages above.
pause
exit /b 1

:final_cleanup
if exist "%PASSFILE%" del /f /q "%PASSFILE%" >nul 2>&1
pause
exit /b 1