@echo off
title UzhavanAI Backend Server
cd /d "%~dp0\backend"

echo ===================================================
echo           UzhavanAI Backend Server
echo ===================================================
echo.

REM Configure Android USB port forwarding if ADB is found
set ADB_PATH=C:\Users\manis\AppData\Local\Android\Sdk\platform-tools\adb.exe
if exist "%ADB_PATH%" (
    echo Forwarding port 8000 to connected Android devices...
    "%ADB_PATH%" reverse tcp:8000 tcp:8000 >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] Port 8000 successfully reverse-forwarded to USB device.
    ) else (
        echo [INFO] No USB Android device connected or ADB server not running.
    )
)

echo Starting FastAPI backend on http://0.0.0.0:8000 ...
echo Press Ctrl+C to stop the server.
echo.

call .venv\Scripts\activate.bat
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

pause
