@echo off
title Cordis-OxCaml Build & Test
cd /d "%~dp0"
echo ======================================================
echo  CORDIS-OXCAML: NATIVE OXCAML BUILD & VERIFICATION
echo ======================================================
where dune >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [*] Running Dune Build...
    dune build @all
    echo [*] Running Dune Test Suite...
    dune runtest
) else (
    echo [*] Native OxCaml Dune build toolchain required.
    echo [*] Install via: opam install dune ocaml
)
pause
