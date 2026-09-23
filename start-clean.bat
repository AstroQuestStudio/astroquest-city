@echo off
REM start-clean.bat — Purge WebView2 cache then launch AstroQuest City
setlocal
set "EXE=%USERPROFILE%\Documents\AstroQuest City\apps\city\src-tauri\target\release\create-tauri-react.exe"
set "CACHE=%LOCALAPPDATA%\com.tauri.app\EBWebView"

echo [AQ] Killing stale AstroQuest processes...
taskkill /F /IM create-tauri-react.exe /T 2>nul
timeout /t 2 /nobreak >nul

echo [AQ] Purging WebView2 cache...
if exist "%CACHE%" (
    "%USERPROFILE%\.minimax\bin\mavis-trash.cmd" "%CACHE%" >nul 2>&1
    echo [AQ] Cache cleared.
) else (
    echo [AQ] No stale cache.
)

echo [AQ] Launching AstroQuest City...
start "" "%EXE%"
endlocal