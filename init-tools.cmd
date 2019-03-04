@if not defined _echo @echo off
setlocal

set INIT_TOOLS_LOG=%~dp0init-tools.log
if [%PACKAGES_DIR%]==[] set PACKAGES_DIR=%~dp0packages/
if [%TOOLRUNTIME_DIR%]==[] set TOOLRUNTIME_DIR=%~dp0Tools
set DOTNET_PATH=%TOOLRUNTIME_DIR%\dotnetcli\
if [%DOTNET_CMD%]==[] set DOTNET_CMD=%DOTNET_PATH%dotnet.exe
set INIT_TOOLS_RESTORE_PROJECT=%~dp0init-tools.msbuild
set BUILD_TOOLS_ARCADE_SEMAPHORE=%TOOLRUNTIME_DIR%/%TOOLRUNTIME_DIR%\%BUILDTOOLS_VERSION%.init-tools.completed"

:: if force option is specified then clean the tool runtime and build tools package directory to force it to get recreated
if [%1]==[force] (
  if exist "%TOOLRUNTIME_DIR%" rmdir /S /Q "%TOOLRUNTIME_DIR%"
  if exist "%PACKAGES_DIR%Microsoft.DotNet.BuildTools" rmdir /S /Q "%PACKAGES_DIR%Microsoft.DotNet.BuildTools"
)

:: If semaphore exists do nothing
if exist "%BUILD_TOOLS_SEMAPHORE%" (
  echo Tools are already initialized.
  goto :EOF
)

if exist "%TOOLRUNTIME_DIR%" rmdir /S /Q "%TOOLRUNTIME_DIR%"

echo Running %0 > "%INIT_TOOLS_LOG%"

:afterdotnetrestore

:: Ask init-tools to also restore ILAsm
set /p ILASMCOMPILER_VERSION=< "%~dp0tools-local\ILAsmVersion.txt"

echo Initializing Arcade...
set DOTNET_INSTALL_DIR=%DOTNET_PATH%
set DotNetBuildFromSource=true
powershell -ExecutionPolicy ByPass -NoProfile %~dp0eng\tools.ps1

echo Done initializing Arcade.

echo Done initializing tools.

:error
echo Please check the detailed log that follows. 1>&2
type "%INIT_TOOLS_LOG%" 1>&2
exit /b 1
