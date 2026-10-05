@echo off
rem Build keyhook.exe - the global keyboard hook helper used for punch counting.
rem Requires the csc.exe that ships with .NET Framework 4.x (present on Windows).
setlocal
cd /d "%~dp0"

set "CSC="
if exist "%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe" set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not defined CSC if exist "%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not defined CSC for /f "delims=" %%i in ('where csc 2^>nul') do if not defined CSC set "CSC=%%i"

if not defined CSC (
  echo [ERROR] csc.exe not found.
  echo Install .NET Framework 4.x, or run this from a Visual Studio Developer Command Prompt.
  exit /b 1
)

echo Compiler: %CSC%
"%CSC%" /nologo /target:winexe /out:keyhook.exe keyhook.cs
if errorlevel 1 (
  echo [ERROR] Build failed.
  exit /b 1
)
echo Done: keyhook.exe
endlocal