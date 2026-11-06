@echo off
chcp 65001 > nul
title Antigravity Dotfiles - Auto Update ^& Push

echo ==========================================================
echo   Antigravity Dotfiles Auto Sync ^& Git Push
echo ==========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync.ps1"

echo.
echo ==========================================================
echo 작업을 완료했습니다. 창을 닫으려면 아무 키나 누르세요...
echo ==========================================================
pause > nul
