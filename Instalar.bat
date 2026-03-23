@echo off
TITLE Instalador Fluxo OBS
echo Iniciando assistente visual de instalacao...
REM Iniciar a interface grafica do Powershell escondendo esta janela CMD rapidamente
start /min "" PowerShell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0Instalador_GUI.ps1"
exit
