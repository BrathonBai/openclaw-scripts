@echo off
setlocal enabledelayedexpansion

REM OpenClaw Uninstaller for Windows (CMD/Batch)
REM Usage: uninstall.bat

echo.
echo   OpenClaw Uninstaller
echo.

REM Check for admin rights (optional, for system-wide removal)
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with administrator privileges
) else (
    echo [!] Running without administrator privileges
    echo     Some operations may require elevation
)

echo.
echo This will remove:
echo   - OpenClaw CLI and Gateway
echo   - Configuration files in %USERPROFILE%\.openclaw
echo   - Global npm packages
echo   - Shell integration and PATH entries
echo.

set /p CONFIRM="Continue with uninstallation? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Uninstallation cancelled
    exit /b 0
)

echo.
echo ========================================
echo Stopping OpenClaw Gateway
echo ========================================

where openclaw >nul 2>&1
if %errorLevel% == 0 (
    call openclaw gateway stop >nul 2>&1
    echo [OK] Gateway stopped
) else (
    echo [!] OpenClaw CLI not found, skipping gateway stop
)

echo.
echo ========================================
echo Removing npm packages
echo ========================================

where npm >nul 2>&1
if %errorLevel% == 0 (
    echo Checking for openclaw packages...
    
    call npm list -g openclaw >nul 2>&1
    if %errorLevel% == 0 (
        call npm uninstall -g openclaw >nul 2>&1
        echo [OK] Removed openclaw
    )
    
    call npm list -g @openclaw/gateway >nul 2>&1
    if %errorLevel% == 0 (
        call npm uninstall -g @openclaw/gateway >nul 2>&1
        echo [OK] Removed @openclaw/gateway
    )
    
    call npm list -g @openclaw/cli >nul 2>&1
    if %errorLevel% == 0 (
        call npm uninstall -g @openclaw/cli >nul 2>&1
        echo [OK] Removed @openclaw/cli
    )
) else (
    echo [!] npm not found, skipping npm package removal
)

echo.
echo ========================================
echo Checking for git-based installation
echo ========================================

set GIT_DIR=%USERPROFILE%\openclaw
if exist "%GIT_DIR%" (
    set /p REMOVE_GIT="Remove git repository at %GIT_DIR%? (y/N): "
    if /i "!REMOVE_GIT!"=="y" (
        rmdir /s /q "%GIT_DIR%"
        echo [OK] Removed git repository
    ) else (
        echo [!] Kept git repository
    )
) else (
    echo [!] No git installation found
)

REM Remove wrapper script
set WRAPPER_PATH=%USERPROFILE%\.local\bin\openclaw.cmd
if exist "%WRAPPER_PATH%" (
    del /f /q "%WRAPPER_PATH%"
    echo [OK] Removed wrapper script
)

echo.
echo ========================================
echo Removing configuration files
echo ========================================

set OPENCLAW_DIR=%USERPROFILE%\.openclaw
if exist "%OPENCLAW_DIR%" (
    set /p REMOVE_CONFIG="Remove %OPENCLAW_DIR% directory? This will delete all your data. (y/N): "
    if /i "!REMOVE_CONFIG!"=="y" (
        rmdir /s /q "%OPENCLAW_DIR%"
        echo [OK] Removed %OPENCLAW_DIR%
    ) else (
        echo [!] Kept configuration directory
    )
) else (
    echo [!] %OPENCLAW_DIR% not found
)

echo.
echo ========================================
echo Removing PATH entries
echo ========================================

REM Note: Batch script cannot easily modify system PATH
REM We'll provide instructions instead
echo.
echo [!] Manual PATH cleanup required:
echo     1. Press Win + X, select "System"
echo     2. Click "Advanced system settings"
echo     3. Click "Environment Variables"
echo     4. In "User variables", select "Path" and click "Edit"
echo     5. Remove entries containing:
echo        - %USERPROFILE%\.local\bin
echo        - %USERPROFILE%\openclaw\node_modules\.bin
echo     6. Click OK to save
echo.
pause

echo.
echo ========================================
echo Checking for scheduled tasks
echo ========================================

schtasks /query /fo LIST 2>nul | findstr /i "openclaw" >nul
if %errorLevel% == 0 (
    echo Found OpenClaw scheduled tasks
    for /f "tokens=*" %%a in ('schtasks /query /fo LIST ^| findstr /i "TaskName" ^| findstr /i "openclaw"') do (
        set TASK_LINE=%%a
        set TASK_NAME=!TASK_LINE:~10!
        schtasks /delete /tn "!TASK_NAME!" /f >nul 2>&1
        echo [OK] Removed scheduled task: !TASK_NAME!
    )
) else (
    echo [!] No scheduled tasks found
)

echo.
echo ========================================
echo Checking for startup entries
echo ========================================

set STARTUP_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
if exist "%STARTUP_PATH%\*openclaw*" (
    del /f /q "%STARTUP_PATH%\*openclaw*"
    echo [OK] Removed startup entries
) else (
    echo [!] No startup entries found
)

echo.
echo ========================================
echo Cleaning up cache
echo ========================================

set CACHE_DIR1=%LOCALAPPDATA%\openclaw
set CACHE_DIR2=%TEMP%\openclaw

if exist "%CACHE_DIR1%" (
    rmdir /s /q "%CACHE_DIR1%"
    echo [OK] Removed %CACHE_DIR1%
)

if exist "%CACHE_DIR2%" (
    rmdir /s /q "%CACHE_DIR2%"
    echo [OK] Removed %CACHE_DIR2%
)

echo.
echo ========================================
echo Uninstallation Complete
echo ========================================
echo.
echo [OK] OpenClaw has been uninstalled
echo.
echo Note: Node.js was not removed (it may be used by other applications)
echo If you want to remove Node.js, use: winget uninstall OpenJS.NodeJS.LTS
echo.
echo Please restart your command prompt for changes to take effect
echo.
pause
