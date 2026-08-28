@echo off
title Cordis-OxCaml Build & Test
cd /d "%~dp0"
echo ======================================================
echo  CORDIS-OXCAML: NATIVE BUILD & VERIFICATION
echo ======================================================
where dune >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [*] Running Dune Build...
    dune build @all
    echo [*] Running Dune Test Suite...
    dune runtest
) else (
    echo [*] Dune not found in PATH. Running JS-based structural audit...
    node verify_cordis.js
)
pause
