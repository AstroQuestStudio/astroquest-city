@echo off
REM ============================================================
REM AstroQuest City - Lance le frontend Tauri en dev
REM Configure l'environnement VS Build Tools puis lance npm run tauri dev
REM ============================================================

setlocal

set ROOT=%~dp0
set CITY=%ROOT%apps\city
set VCVARS="C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

echo.
echo === AstroQuest City - Dev Mode ===
echo.

REM 1. Verifier que vcvars64 existe
if not exist %VCVARS% (
    echo [!] vcvars64.bat introuvable : %VCVARS%
    echo    VS Build Tools semble mal installee.
    pause
    exit /b 1
)

REM 2. Charger vcvars64 (configure PATH, INCLUDE, LIB)
echo [i] Chargement de vcvars64.bat...
call %VCVARS% >nul
if errorlevel 1 (
    echo [X] Echec vcvars64.bat
    pause
    exit /b 1
)
echo [OK] Environnement MSVC configure

REM 3. Verifier que link.exe est accessible
where link.exe >nul 2>&1
if errorlevel 1 (
    echo [X] link.exe toujours introuvable apres vcvars64
    pause
    exit /b 1
)
echo [OK] link.exe : link.exe

REM 4. Verifier les deps npm
if not exist "%CITY%\node_modules" (
    echo [!] Installation des dependances npm...
    cd /d "%CITY%"
    call npm install
    if errorlevel 1 (
        echo [X] Echec npm install
        pause
        exit /b 1
    )
)

REM 5. Verifier la connexion au backend LiteLLM
echo [i] Verification du backend LiteLLM...
curl -s --max-time 10 -k https://edge.astroquest.fr/litellm/health/readiness >nul
if errorlevel 1 (
    echo [!] Backend LiteLLM injoignable. Verifier que les containers tournent sur VPS3.
) else (
    echo [OK] Backend LiteLLM repond
)

REM 6. Lancer Tauri en dev
echo.
echo [i] Lancement de Tauri dev (la fenetre va s'ouvrir)...
echo    App URL : https://edge.astroquest.fr/litellm
echo.
cd /d "%CITY%"
call npm run tauri dev

endlocal