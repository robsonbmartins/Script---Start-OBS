<#
.SYNOPSIS
    Script unificado para inicialização e encerramento do fluxo de gravação (Insta360 -> NVIDIA Broadcast -> OBS).
#>

# ==========================================
# IMPORTAÇÃO DE FUNÇÕES DO WINDOWS (API)
# ==========================================
# Isso permite enviar o comando "Minimizar" nativo do Windows para qualquer janela
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
}
"@

# ==========================================
# CONFIGURAÇÕES DE DIRETÓRIOS (Lidos via config.json)
# ==========================================
$configFile = Join-Path $PSScriptRoot "config.json"
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    $insta360Path = $config.Insta360
    $nvidiaBroadcastPath = $config.NvidiaBroadcast
    $obsPath = $config.OBS
    $obsWorkingDirectory = $config.OBSDir
} else {
    # Valores padrão de proteção
    $insta360Path = "C:\Program Files\Insta360 Link Controller\Insta360 Link Controller.exe"
    $nvidiaBroadcastPath = "C:\Program Files\NVIDIA Corporation\NVIDIA Broadcast\NVIDIA Broadcast.exe"
    $obsPath = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
    $obsWorkingDirectory = "C:\Program Files\obs-studio\bin\64bit"
}

# Nomes dos executáveis do gerenciador de tarefas para encerramento (sem terminar com .exe)
$processosParaEncerrar = @("Insta360 Link Controller", "NVIDIA Broadcast UI", "NVIDIA Broadcast")

# Função auxiliar para minimizar janelas teimosas diretamente via API do Windows
function Minimize-App {
    param ([string]$ProcessName)
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    foreach ($p in $processes) {
        if ($p.MainWindowHandle -ne 0) {
            # 6 refere-se a SW_MINIMIZE na API do Windows
            [Win32]::ShowWindow($p.MainWindowHandle, 6) | Out-Null
        }
    }
}

# ==========================================
# 1. INICIALIZAÇÃO DOS SOFTWARES (STARTUP)
# ==========================================
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Iniciando Fluxo de Captura de Vídeo  " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Função para iniciar processo com espera inteligente e timeout
function Start-App {
    param (
        [string]$Path,
        [int]$WaitSeconds
    )
    if (Test-Path $Path) {
        $AppName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        Write-Host "[$AppName] Iniciando aplicativo..." -ForegroundColor White
        
        # Inicia o processo minimizado (oculto na bandeja do sistema)
        Start-Process -FilePath $Path -WindowStyle Minimized
        
        Write-Host "[$AppName] Aguardando $WaitSeconds segundos para carregamento da camera virtual..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $WaitSeconds
        
        # Após a espera (e do aplicativo carregar totalmente sua tela), força a minimização!
        Minimize-App -ProcessName $AppName
        
        Write-Host "[$AppName] Carregamento concluído e forçado para bandeja." -ForegroundColor Green
    } else {
        Write-Host "AVISO: Executável não encontrado em $Path" -ForegroundColor Yellow
        Write-Host "Verifique os caminhos na seção de configuração." -ForegroundColor Yellow
    }
}

# Inicializa as aplicações
Start-App -Path $insta360Path -WaitSeconds 10
Start-App -Path $nvidiaBroadcastPath -WaitSeconds 15

# ==========================================
# 2. INICIAR OBS E MONITORAR (EXECUÇÃO)
# ==========================================
if (Test-Path $obsPath) {
    Write-Host "[OBS Studio] Iniciando OBS Studio e aguardando encerramento..." -ForegroundColor White
    
    # Inicia o OBS e guarda o objeto do processo para monitorá-lo.
    $obsProcess = Start-Process -FilePath $obsPath -WorkingDirectory $obsWorkingDirectory -PassThru
    
    Write-Host "`n>>> Fluxo em andamento. Feche o OBS Studio para encerrar todos os aplicativos automaticamente. <<<" -ForegroundColor Red
    Start-Sleep -Seconds 2
    
    # =========================================================================
    # Minimiza a PRÓPRIA janela do PowerShell (prompt) para não poluir a tela!
    # =========================================================================
    $consolePtr = [Win32]::GetConsoleWindow()
    [Win32]::ShowWindow($consolePtr, 6) | Out-Null
    
    # O script ficará em pausa aqui, consumindo 0% de CPU, até o OBS ser fechado.
    Wait-Process -InputObject $obsProcess
    
    # Restaura a janela do PowerShell para mostrar o log de encerramento
    [Win32]::ShowWindow($consolePtr, 9) | Out-Null
    
    Write-Host "`n[OBS Studio] Foi fechado. Iniciando rotina de encerramento." -ForegroundColor Yellow
} else {
    Write-Host "ERRO: O executável do OBS Studio não foi encontrado em $obsPath." -ForegroundColor Red
    Write-Host "Pressione qualquer tecla para sair..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    exit
}

# ==========================================
# 3. ENCERRAMENTO (TEARDOWN)
# ==========================================
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Encerrando Aplicativos de Segundo Plano" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

foreach ($processName in $processosParaEncerrar) {
    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "Encerrando $processName..." -ForegroundColor White
        
        # Tenta fechar graciosamente primeiro (enviando sinal para fechar a janela principal)
        foreach ($p in $processes) {
            $p.CloseMainWindow() | Out-Null
        }
        
        # Aguarda 3 segundos para que o aplicativo feche suavemente
        Start-Sleep -Seconds 3
        
        # Verifica se ainda está rodando, e força o encerramento se necessário (Kill)
        $processosFinais = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($processosFinais) {
            Write-Host "  -> Forçando encerramento de $processName..." -ForegroundColor DarkGray
            Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
        }
        Write-Host "[$processName] Encerrado com sucesso." -ForegroundColor Green
    }
}

Write-Host "`nFluxo totalmente encerrado. Esta janela será fechada em 3 segundos." -ForegroundColor Green
Start-Sleep -Seconds 3
