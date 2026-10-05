@echo off
rem Launch the MouseDistanceHUD.
rem Godot executable lookup order:
rem   1) GODOT_EXE environment variable
rem   2) godot_path.txt next to this script (optional, git-ignored)
rem   3) the default path below (edit or delete it as needed)
rem   4) godot found on PATH
setlocal
cd /d "%~dp0"

rem Kill a keyhook.exe left over from a previous run.
taskkill /F /IM keyhook.exe >nul 2>&1

set "GODOT="
if defined GODOT_EXE set "GODOT=%GODOT_EXE%"
if not defined GODOT if exist "godot_path.txt" set /p GODOT=<godot_path.txt
if not defined GODOT if exist "D:\Apps\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" set "GODOT=D:\Apps\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT for /f "delims=" %%i in ('where godot 2^>nul') do if not defined GODOT set "GODOT=%%i"

if not defined GODOT (
  echo [ERROR] Godot executable not found.
  echo Set the GODOT_EXE environment variable, for example:
  echo    setx GODOT_EXE "C:\path\to\Godot_v4.7-stable_win64.exe"
  echo or put godot on PATH, or write its path into godot_path.txt.
  exit /b 1
)

echo Launching: %GODOT%
start "" "%GODOT%" --path "%CD%"
endlocal