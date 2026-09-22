@echo off
REM ============================================================
REM AstroQuest City - LANCE LE .EXE RELEASE (production)
REM Le dist est bundlé dans le .exe, pas besoin de dev server
REM ============================================================

setlocal

set ROOT=%~dp0
set EXE=%ROOT%apps\city\src-tauri\target\release\create-tauri-react.exe

echo.
echo === AstroQuest City - Production Mode ===
echo.

REM 1. Tuer toute instance précédente
echo [i] Nettoyage des instances precedentes...
taskkill /F /IM create-tauri-react.exe 2>nul
taskkill /F /IM opencode.exe 2>nul
timeout /t 2 /nobreak >nul

REM 2. Vérifier que le .exe release existe
if not exist "%EXE%" (
    echo [!] .exe release introuvable : %EXE%
    echo    Lance d'abord : cd apps\city\src-tauri ^&^& cargo tauri build --no-bundle
    pause
    exit /b 1
)
echo [OK] Release .exe : %EXE%

REM 3. Vérifier que opencode CLI est installé
where opencode >nul 2>&1
if errorlevel 1 (
    echo [!] opencode CLI non trouve dans PATH
    echo    Installe-le : irm https://opencode.ai/install.ps1 ^| iex
)

REM 4. Vérifier que Cortex est installé (optionnel)
if exist "%USERPROFILE%\Documents\Cortex\target\release\cortex.exe" (
    echo [OK] Cortex binary trouve
) else (
    echo [i] Cortex non trouve ^(optionnel - Knowledge Panel desactive^)
)

REM 5. Lancer le .exe
echo.
echo [i] Lancement de l'application...
echo.
start "" "%EXE%"

endlocal