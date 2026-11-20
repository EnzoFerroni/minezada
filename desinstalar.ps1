# Remove o Minezada deste PC: instancia, atalho e launcher. Rode no PowerShell:
#   irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/desinstalar.ps1 | iex
# Sem pergunta: -Sim, ou $env:MINEZADA_SIM=1 antes (o iex nao passa parametro).
param([switch]$Sim)
$ErrorActionPreference = 'Stop'
$dados = "$env:APPDATA\PrismLauncher"
$prismDirs = "$env:LOCALAPPDATA\Programs\PrismLauncher", "$env:ProgramFiles\PrismLauncher"
$forkDir = "$env:LOCALAPPDATA\Programs\Minezada Launcher"
# MINEZADA_DESKTOP so existe para o teste nao tocar na Area de Trabalho real.
$desktop = if ($env:MINEZADA_DESKTOP) { $env:MINEZADA_DESKTOP } else { [Environment]::GetFolderPath('Desktop') }
$lnk = "$desktop\Minezada.lnk"

# Pasta das instancias, igual ao jogar.ps1.
$cfg = Join-Path $dados 'prismlauncher.cfg'
$instDir = if (Test-Path $cfg) { Select-String '^InstanceDir=(.+)$' $cfg | Select-Object -First 1 | ForEach-Object { $_.Matches[0].Groups[1].Value } }
if (-not $instDir) { $instDir = 'instances' }
if (-not [IO.Path]::IsPathRooted($instDir)) { $instDir = Join-Path $dados $instDir }
$inst = Join-Path $instDir 'Minezada'
if (-not (($inst, $lnk, $forkDir) | Where-Object { Test-Path $_ })) { Write-Host 'O Minezada nao esta instalado neste PC.'; return }
# Pastas com ponto sao do proprio Prism (ex: .LAUNCHER_TEMP).
$outras = @(Get-ChildItem $instDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'Minezada' -and $_.Name -notlike '.*' })
$prism = $prismDirs | Where-Object { Test-Path "$_\prismlauncher.exe" } | Select-Object -First 1

Write-Host 'Vai remover deste PC:'
Write-Host '- a instancia Minezada (mundos de um jogador, prints e opcoes) e o atalho Minezada'
if (Test-Path $forkDir) { Write-Host '- o Minezada Launcher' }
if ($outras) {
    Write-Host "O Prism Launcher e a pasta dele ficam: tem outras instancias ($(($outras | ForEach-Object Name) -join ', '))."
}
else {
    if ($prism) { Write-Host '- o Prism Launcher' }
    Write-Host "- a pasta $dados (contas e configuracoes do launcher)"
}
if (-not ($Sim -or $env:MINEZADA_SIM -eq '1')) {
    if ((Read-Host 'Continuar? [s/N]') -notmatch '^\s*s') { Write-Host 'Nada foi removido.'; return }
}

# Fecha so o jogo desta instancia e os launchers que este script remove.
$re = [regex]::Escape($inst) -replace '\\\\', '[\\/]'
Get-CimInstance Win32_Process -Filter "Name='javaw.exe' or Name='java.exe'" | Where-Object { $_.CommandLine -match $re } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
$exes = @("$forkDir\prismlauncher.exe") + ($prismDirs | ForEach-Object { "$_\prismlauncher.exe" })
Get-Process prismlauncher -ErrorAction SilentlyContinue | Where-Object { $_.Path -in $exes } | ForEach-Object { [void]$_.CloseMainWindow(); if (-not $_.WaitForExit(5000)) { $_ | Stop-Process -Force } }

foreach ($p in $inst, $lnk, $forkDir) { if (Test-Path $p) { Remove-Item $p -Recurse -Force } }
if (-not $outras) {
    if ($prism) {
        Write-Host 'Removendo o Prism Launcher...'
        # O winget usa este mesmo desinstalador com /S. Sem _?= ele se copia para o temp e o -Wait nao espera.
        # Em Arquivos de Programas o Windows pede permissao.
        if (Test-Path "$prism\uninstall.exe") { Start-Process "$prism\uninstall.exe" "/S _?=$prism" -Wait }
        Remove-Item $prism -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $dados) { Remove-Item $dados -Recurse -Force }
}

Write-Host "`nMinezada removido."
$srv = Join-Path $env:USERPROFILE 'Minezada-servidor'
if (Test-Path $srv) {
    Write-Host "A pasta do servidor ficou em $srv (e o atalho 'Hospedar Minezada')."
    Write-Host 'Para apagar, desligue o servidor e apague a pasta a mao. O mundo fica no Drive.'
}
