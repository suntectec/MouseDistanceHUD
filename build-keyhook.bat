@echo off
rem Build keyhook.exe - the global keyboard hook helper used for punch counting.
rem Requires the csc.exe that ships with .NET Framework 4.x (present on Windows).
setlocal
cd /d "%~dp0"

rem A running keyhook.exe holds a lock on the output file, which makes csc fail
rem with "could not write to output file" (CS0016). Check for that first.
tasklist /FI "IMAGENAME eq keyhook.exe" /NH 2>nul | find /I "keyhook.exe" >nul
if not errorlevel 1 (
  set "ERR=keyhook.exe is currently running, so the output file is locked."
  set "HINT=Close the HUD and run this script again. If it was left behind by a crashed HUD, run: taskkill /F /IM keyhook.exe"
  goto :fail
)

set "CSC="
if exist "%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe" set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not defined CSC if exist "%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not defined CSC for /f "delims=" %%i in ('where csc 2^>nul') do if not defined CSC set "CSC=%%i"
if not defined CSC (
  set "ERR=csc.exe not found."
  set "HINT=Install .NET Framework 4.x, or run this from a Visual Studio Developer Command Prompt."
  goto :fail
)

echo Compiler: %CSC%
"%CSC%" /nologo /target:winexe /out:keyhook.exe keyhook.cs
if errorlevel 1 (
  set "ERR=Compilation failed - see the compiler output above."
  set "HINT=If the error mentions the output file, make sure keyhook.exe is not running."
  goto :fail
)

echo Done: keyhook.exe
exit /b 0

:fail
echo.
echo [ERROR] %ERR%
echo         %HINT%
echo.
if not defined BUILD_KEYHOOK_NOPAUSE pause
exit /b 1