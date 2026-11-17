# Instala o Prism Launcher (se faltar) e importa o modpack da Minezada. Rode no PowerShell:
#   irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
$ErrorActionPreference = 'Stop'
$zip = 'https://github.com/EnzoFerroni/minezada/raw/main/modpack/minezada-prism.zip'
$locais = "$env:LOCALAPPDATA\Programs\PrismLauncher\prismlauncher.exe", "$env:ProgramFiles\PrismLauncher\prismlauncher.exe"

$prism = $locais | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $prism) {
    Write-Host 'Instalando o Prism Launcher...'
    winget install -e --id PrismLauncher.PrismLauncher --accept-source-agreements --accept-package-agreements
    $prism = $locais | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $prism) { throw 'Prism nao encontrado. Instale em https://prismlauncher.org/download/ e rode de novo.' }
}

Start-Process $prism -ArgumentList '--import', $zip
Write-Host @'

No Prism:
  1. Confirme a importacao do "Minezada" (OK).
  2. Entre com a conta Microsoft (icone de conta, canto superior direito).
  3. Clique duas vezes em "Minezada". Na primeira vez aceite baixar o Java.
O jogo ja entra direto no servidor. Atualizacoes do pack sao automaticas.
'@
