@echo OFF
setlocal enabledelayedexpansion
set userNodeVersion=""
set latestNodeVersion=""
set downloadsFolder=%userprofile%\Downloads\
set npmCmd=npm
set powershellVersion=""
for /f "tokens=*" %%i in ('powershell -command "& { . .\nodeInstallerScript.ps1; FindPowershellVersion }"') do (
    set powershellVersion=%%i
)
if !powershellVersion! == False (
    set /p missingPrompt=This program requires powershell version 3.0 or higher.
    set /p missingPrompt=This can be downloaded at https://www.microsoft.com/en-us/download/details.aspx?id=34595
    exit /b 0
)
set /p missingPrompt=This program must be run with administrative privileges.
for /f "tokens=*" %%i in ('node -v 2^>nul') do (
    set userNodeVersion=%%i
)
for /f "tokens=*" %%i in ('powershell -command "& { . .\nodeInstallerScript.ps1; FindMostRecentVersion }"') do (
    set latestNodeVersion=%%i
)
if !userNodeVersion! == "" (
    call :InstallNode
    exit /b 0
)
call :ValidateNode
exit /b 0

:CheckNodeCompatibility
set notCompatible=""
set nodePath=""
for /f "tokens=*" %%i in ('node -e "console.log(require('semver').outside('!userNodeVersion:~1!', require('./package.json').globals.engines.node, '<'))"') do (
    set notCompatible=%%i
)
for /f "tokens=*" %%i in ('where node.exe') do (
    set nodePath=%%i
)
if !notCompatible! == true (
    echo local node version !userNodeVersion! is out of date, updating now
    powershell.exe -command "$client = New-Object System.Net.WebClient;$client.Headers['User-Agent'] = 'myUser';$client.DownloadFile('https://nodejs.org/download/release/latest/win-x64/node.exe', '!nodePath!')"
    set userNodeVersion=!latestNodeVersion!
)
if NOT !userNodeVersion! == !latestNodeVersion! (
    set /p optionalPrompt=a newer version of node is available. would you like to install this version now ^(yes/no^)^?
    if NOT !optionalPrompt! == no (
        powershell.exe -command "$client = New-Object System.Net.WebClient;$client.Headers['User-Agent'] = 'myUser';$client.DownloadFile('https://nodejs.org/download/release/latest/win-x64/node.exe', '!nodePath!')"
        set userNodeVersion=!latestNodeVersion!
    )
)
echo user node version !userNodeVersion! is up to date
call :StartNodeScript
exit /b 0

:InstallNode
set /p missingPrompt=node is missing, press any key to start installation
powershell.exe -command "$client = New-Object System.Net.WebClient;$client.Headers['User-Agent'] = 'myUser';$client.DownloadFile('https://nodejs.org/dist/latest/node-!latestNodeVersion!-x64.msi', '!downloadsFolder!node-!latestNodeVersion!-x64.msi')"
msiexec /qn /l* C:\node-log.txt /i !downloadsFolder!node-!latestNodeVersion!-x64.msi
set userNodeVersion=!latestNodeVersion!
echo node was installed with version !latestNodeVersion!
cd ../../../ && powershell.exe -command "$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine'); npm install --scripts-prepend-node-path=true;" && call :StartNodeScript
exit /b 0

:ValidateNode
cd ../../../ && npm install --scripts-prepend-node-path=true && call :CheckNodeCompatibility
exit /b 0

:StartNodeScript
powershell.exe -command "$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine'); node ./node_modules/webdev-setup-tools/setup-scripts/setup.js;"
exit /b 0
