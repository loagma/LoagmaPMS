@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  LoagmaPMS - Windows Release Build
::  Outputs:
::    release_output\LoagmaPMS_vX.X.X_TIMESTAMP\   (raw files)
::    release_output\LoagmaPMS_vX.X.X_TIMESTAMP.zip
::    installer\output\LoagmaPMS_Setup_vX.X.X.exe
:: ============================================================

set "PROJECT_ROOT=%~dp0"
set "CLIENT_DIR=%PROJECT_ROOT%client"
set "OUTPUT_DIR=%PROJECT_ROOT%release_output"
set "WIN_BUILD=%CLIENT_DIR%\build\windows\x64\runner\Release"
set "ISS_FILE=%PROJECT_ROOT%installer\loagmapms_setup.iss"

:: --- Read version from pubspec.yaml ---
set "VERSION=unknown"
for /f "usebackq tokens=2 delims=: " %%V in ("%CLIENT_DIR%\pubspec.yaml") do (
    echo %%V | findstr /b "[0-9]" >nul 2>&1
    if not errorlevel 1 (
        if "!VERSION!"=="unknown" set "VERSION=%%V"
    )
)
:: Strip build metadata (+N) from version
for /f "tokens=1 delims=+" %%V in ("!VERSION!") do set "VERSION=%%V"
:: Trim any trailing whitespace/CR
for /f "tokens=* delims= " %%V in ("!VERSION!") do set "VERSION=%%V"

:: --- Timestamp ---
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "DT=%%I"
set "TIMESTAMP=!DT:~0,4!!DT:~4,2!!DT:~6,2!_!DT:~8,2!!DT:~10,2!"

set "RELEASE_NAME=LoagmaPMS_v!VERSION!_!TIMESTAMP!"
set "RELEASE_FOLDER=!OUTPUT_DIR!\!RELEASE_NAME!"
set "ZIP_PATH=!OUTPUT_DIR!\!RELEASE_NAME!.zip"

echo.
echo ==========================================
echo   LoagmaPMS Windows Release Builder
echo   Version : !VERSION!
echo   Output  : !RELEASE_FOLDER!
echo ==========================================
echo.

:: --- Check Flutter ---
where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] flutter not found in PATH.
    echo         Add Flutter to your system PATH and retry.
    goto :fail
)

:: --- Go to client dir ---
cd /d "%CLIENT_DIR%"
if errorlevel 1 (
    echo [ERROR] Cannot cd to: %CLIENT_DIR%
    goto :fail
)

:: --- Enable Windows desktop (one-time) ---
if not exist "windows\" (
    echo [SETUP] Enabling Windows desktop platform...
    flutter config --enable-windows-desktop
    if errorlevel 1 ( echo [ERROR] flutter config failed. & goto :fail )
    flutter create --platforms=windows .
    if errorlevel 1 ( echo [ERROR] flutter create failed. & goto :fail )
    echo [SETUP] Done.
    echo.
)

:: --- Patch CMakeLists project name if still "client" ---
set "CMAKE_FILE=%CLIENT_DIR%\windows\CMakeLists.txt"
if exist "!CMAKE_FILE!" (
    findstr /c:"project(client" "!CMAKE_FILE!" >nul 2>&1
    if not errorlevel 1 (
        echo [SETUP] Patching CMakeLists.txt project name to LoagmaPMS...
        powershell -NoProfile -Command ^
            "(Get-Content '!CMAKE_FILE!') -replace 'project\(client', 'project(LoagmaPMS' | Set-Content '!CMAKE_FILE!'"
        echo [SETUP] Patched.
        echo.
    )
)

:: --- 1. Clean ---
echo [1/4] Cleaning previous build...
flutter clean
if errorlevel 1 ( echo [ERROR] flutter clean failed. & goto :fail )

:: --- 2. Get dependencies ---
echo.
echo [2/4] Getting dependencies...
flutter pub get
if errorlevel 1 ( echo [ERROR] flutter pub get failed. & goto :fail )

:: --- 3. Build ---
echo.
echo [3/4] Building Windows release (production API)...
flutter build windows --release --dart-define=USE_LOCAL=false
if errorlevel 1 (
    echo.
    echo [ERROR] flutter build windows --release failed.
    goto :fail
)

:: --- Verify EXE exists ---
if not exist "!WIN_BUILD!\LoagmaPMS.exe" (
    if not exist "!WIN_BUILD!\client.exe" (
        echo [ERROR] EXE not found in: !WIN_BUILD!
        goto :fail
    )
)

:: --- Rename client.exe if needed ---
if exist "!WIN_BUILD!\client.exe" (
    if not exist "!WIN_BUILD!\LoagmaPMS.exe" (
        ren "!WIN_BUILD!\client.exe" "LoagmaPMS.exe"
    )
)

:: --- 4. Package ---
echo.
echo [4/4] Packaging...
if not exist "!OUTPUT_DIR!" mkdir "!OUTPUT_DIR!"
if exist "!RELEASE_FOLDER!" rmdir /s /q "!RELEASE_FOLDER!"
mkdir "!RELEASE_FOLDER!"

xcopy /e /i /q "!WIN_BUILD!\*" "!RELEASE_FOLDER!\" >nul
if errorlevel 1 ( echo [ERROR] Copy failed. & goto :fail )

:: --- ZIP ---
powershell -NoProfile -Command ^
    "Compress-Archive -Path '!RELEASE_FOLDER!\*' -DestinationPath '!ZIP_PATH!' -Force"
if errorlevel 1 (
    echo [WARN] ZIP failed - folder is still usable without it.
) else (
    echo ZIP: !ZIP_PATH!
)

:: --- Installer (Inno Setup) ---
set "ISCC="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files\Inno Setup 6\ISCC.exe"       set "ISCC=C:\Program Files\Inno Setup 6\ISCC.exe"

if "!ISCC!"=="" (
    echo.
    echo [WARN] Inno Setup not found. Skipping installer.
    echo        Install from https://jrsoftware.org/isdl.php and re-run.
) else (
    echo.
    echo Building installer...
    "!ISCC!" /DAppVersion=!VERSION! "!ISS_FILE!"
    if errorlevel 1 (
        echo [WARN] Inno Setup compile failed.
    ) else (
        set "INSTALLER_OUT=%PROJECT_ROOT%installer\output\LoagmaPMS_Setup_v!VERSION!.exe"
        if exist "!INSTALLER_OUT!" (
            copy /y "!INSTALLER_OUT!" "!RELEASE_FOLDER!\" >nul
            echo Installer: !INSTALLER_OUT!
        )
    )
)

:: --- Done ---
echo.
echo ==========================================
echo   BUILD SUCCESSFUL
echo   Version : !VERSION!
echo   Folder  : !RELEASE_FOLDER!
if exist "!ZIP_PATH!"      echo   ZIP     : !ZIP_PATH!
if exist "!INSTALLER_OUT!" echo   Setup   : !INSTALLER_OUT!
echo ==========================================
echo.

explorer "!RELEASE_FOLDER!"
goto :eof

:fail
echo.
echo ==========================================
echo   BUILD FAILED - see errors above
echo ==========================================
echo.
exit /b 1
