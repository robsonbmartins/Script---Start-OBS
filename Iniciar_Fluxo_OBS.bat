@echo off
REM Este arquivo batch facilita a inicializacao do script PowerShell principal
REM Isso previne qualquer problema de "ExecutionPolicy" no Windows e serve como um atalho facil.

TITLE Inicializador do Fluxo OBS
SET "ScriptPath=%~dp0Iniciar_Fluxo_OBS.ps1"

echo Iniciando automação pelo PowerShell...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%ScriptPath%"
