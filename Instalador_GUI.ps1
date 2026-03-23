Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

function Show-Msg ($Text, $Title) {
    [System.Windows.Forms.MessageBox]::Show($Text, $Title, 0, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Get-FileName {
    param([string]$Title, [string]$InitialDir, [string]$Filter)
    
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $Title
    $openFileDialog.InitialDirectory = $InitialDir
    $openFileDialog.Filter = $Filter
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        return $openFileDialog.FileName
    }
    return ""
}

Show-Msg "Bem-vindo ao instalador! Vamos configurar os caminhos dos aplicativos do seu Fluxo de Gravação do OBS. Nas proximas janelas, selecione cada arquivo." "Instalador OBS Fluxo"

# 1. Insta360
$insta = Get-FileName -Title "Selecione o executável Insta360 Link Controller" -InitialDir "C:\Program Files" -Filter "Insta360 Link Controller.exe|*.exe"
if ([string]::IsNullOrWhiteSpace($insta)) { $insta = "C:\Program Files\Insta360 Link Controller\Insta360 Link Controller.exe" }

# 2. NVIDIA Broadcast
$nvidia = Get-FileName -Title "Selecione o executável do NVIDIA Broadcast" -InitialDir "C:\Program Files\NVIDIA Corporation" -Filter "NVIDIA Broadcast.exe|*.exe"
if ([string]::IsNullOrWhiteSpace($nvidia)) { $nvidia = "C:\Program Files\NVIDIA Corporation\NVIDIA Broadcast\NVIDIA Broadcast.exe" }

# 3. OBS Studio
$obs = Get-FileName -Title "Selecione o executável do OBS Studio (obs64.exe)" -InitialDir "C:\Program Files\obs-studio\bin" -Filter "obs64.exe|*.exe"
if ([string]::IsNullOrWhiteSpace($obs)) { 
    $obs = "C:\Program Files\obs-studio\bin\64bit\obs64.exe" 
    $obsDir = "C:\Program Files\obs-studio\bin\64bit"
} else {
    $obsDir = Split-Path $obs
}

# Salvar config
$config = @{
    Insta360 = $insta
    NvidiaBroadcast = $nvidia
    OBS = $obs
    OBSDir = $obsDir
}

$configPath = Join-Path $PSScriptRoot "config.json"
$config | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8

Show-Msg "Caminhos salvos no arquivo config.json no seu drive! O atalho será atualizado para refletir o seu OBS atual.`n`nClique em OK para iniciar o roteiro como teste!" "Configuração Concluída"

# Atualizar atalho com o novo diretorio do OBS (ajuda a fixar o icone perfeitamente)
$wshell = New-Object -ComObject WScript.Shell
$linkPath = Join-Path $PSScriptRoot "Iniciar Fluxo OBS.lnk"
$shortcut = $wshell.CreateShortcut($linkPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Minimized -File `"$PSScriptRoot\Iniciar_Fluxo_OBS.ps1`""
$shortcut.IconLocation = "$obs, 0"
$shortcut.WorkingDirectory = "$PSScriptRoot"
$shortcut.Save()

# Realizar Primeira Execução de Teste!
Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Minimized -File `"$PSScriptRoot\Iniciar_Fluxo_OBS.ps1`""

Show-Msg "O fluxo foi iniciado para teste nos painéis de fundo. Verifique a bandeja do sistema e aguarde o OBS abrir." "Teste Iniciado"
