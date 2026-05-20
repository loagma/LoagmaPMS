@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  LoagmaPMS  —  Windows Release Build
::  Output: release_output\LoagmaPMS_vX.X.X_TIMESTAMP\
::          release_output\LoagmaPMS_vX.X.X_TIMESTAMP.zip
:: ============================================================

set "PROJECT_ROOT=%~dp0"
set "CLIENT_DIR=%PROJECT_ROOT%client"
set "OUTPUT_DIR=%PROJECT_ROOT%release_output"

:: ── Read version from pubspec.yaml ───────────────────────────
set "VERSION=unknown"
for /f "tokens=2 delims=: " %%V in ('findstr /b "version:" "%CLIENT_DIR%\pubspec.yaml"') do set "VERSION=%%V"
for /f "tokens=1 delims=+" %%V in ("!VERSION!") do set "VERSION=%%V"

:: ── Timestamp YYYYMMDD_HHMM ──────────────────────────────────
set "D=%date%"
set "T=%time%"
set "YY=!D:~-4!" & set "MM=!D:~3,2!" & set "DD=!D:~0,2!"
set "HH=!T:~0,2!" & set "MI=!T:~3,2!"
set "HH=!HH: =0!"
set "TIMESTAMP=!YY!!MM!!DD!_!HH!!MI!"
set "RELEASE_NAME=LoagmaPMS_v!VERSION!_!TIMESTAMP!"
set "RELEASE_FOLDER=!OUTPUT_DIR!\!RELEASE_NAME!"
set "WIN_BUILD=!CLIENT_DIR!\build\windows\x64\runner\Release"

echo.
echo ==========================================
echo   LoagmaPMS Windows Release Builder
echo   Version : !VERSION!
echo   Output  : !RELEASE_FOLDER!
echo ==========================================
echo.

:: ── 1. Check Flutter ────────────────────────────────────────
where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] flutter not found in PATH.
    echo         Open this bat from the Flutter-enabled terminal,
    echo         or add Flutter to your system PATH.
    pause & exit /b 1
)

cd /d "!CLIENT_DIR!"

:: ── 2. Enable Windows desktop support (one-time) ────────────
if not exist "windows\" (
    echo [SETUP] Enabling Windows desktop platform...
    flutter config --enable-windows-desktop
    if errorlevel 1 (
        echo [ERROR] Could not enable windows desktop config.
        pause & exit /b 1
    )
    flutter create --platforms=windows .
    if errorlevel 1 (
        echo [ERROR] flutter create --platforms=windows failed.
        pause & exit /b 1
    )
    echo [SETUP] Done. Windows platform added.
    echo.
)

:: ── 3. Fix CMakeLists project name if still "client" ─────────
::    Flutter generates CMakeLists.txt with project("client") but
::    our exe should be named LoagmaPMS. Patch it automatically.
set "CMAKE_FILE=!CLIENT_DIR!\windows\CMakeLists.txt"
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

:: ── 4. Clean build cache (important after CMake patch) ───────
echo [1/3] Cleaning previous build...
flutter clean
if errorlevel 1 (echo [ERROR] flutter clean failed. & pause & exit /b 1)

:: ── 5. Dependencies ──────────────────────────────────────────
echo.
echo [2/3] Getting dependencies...
flutter pub get
if errorlevel 1 (echo [ERROR] pub get failed. & pause & exit /b 1)

:: ── 6. Build Windows release ─────────────────────────────────
echo.
echo [3/3] Building Windows EXE...
flutter build windows --release
if errorlevel 1 (
    echo [ERROR] flutter build windows --release failed.
    pause & exit /b 1
)

:: ── 7. Verify EXE ────────────────────────────────────────────
if not exist "!WIN_BUILD!\LoagmaPMS.exe" (
    if not exist "!WIN_BUILD!\client.exe" (
        echo [ERROR] EXE not found in: !WIN_BUILD!
        pause & exit /b 1
    )
)

:: ── 8. Copy to output folder ──────────────────────────────────
if not exist "!OUTPUT_DIR!" mkdir "!OUTPUT_DIR!"
if exist "!RELEASE_FOLDER!" rmdir /s /q "!RELEASE_FOLDER!"
mkdir "!RELEASE_FOLDER!"

xcopy /e /i /q "!WIN_BUILD!\*" "!RELEASE_FOLDER!\" >nul
if errorlevel 1 (echo [ERROR] Copy failed. & pause & exit /b 1)

:: Rename client.exe -> LoagmaPMS.exe if needed
if exist "!RELEASE_FOLDER!\client.exe" (
    ren "!RELEASE_FOLDER!\client.exe" "LoagmaPMS.exe"
)

:: ── 9. ZIP the release folder ─────────────────────────────────
set "ZIP_PATH=!OUTPUT_DIR!\!RELEASE_NAME!.zip"
echo.
echo Zipping release folder...
powershell -NoProfile -Command ^
    "Compress-Archive -Path '!RELEASE_FOLDER!\*' -DestinationPath '!ZIP_PATH!' -Force"
if errorlevel 1 (
    echo [WARN] ZIP failed - folder is still usable without it.
) else (
    echo ZIP: !ZIP_PATH!
)

:: ── 10. Done ─────────────────────────────────────────────────
echo.
echo ==========================================
echo   BUILD SUCCESSFUL
echo ==========================================
echo   EXE : !RELEASE_FOLDER!\LoagmaPMS.exe
if exist "!ZIP_PATH!" echo   ZIP : !ZIP_PATH!
echo ==========================================
echo.
echo Press any key to open release folder...
pause >nul
explorer "!RELEASE_FOLDER!"

endlocal
