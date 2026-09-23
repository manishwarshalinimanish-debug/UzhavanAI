@echo off
title UzhavanAI Public Cloud Server
cd /d "%~dp0"

echo ===================================================
echo     Starting UzhavanAI Public Server & Tunnel
echo ===================================================
echo.

backend\.venv\Scripts\python.exe -u run_public_server.py

pause
