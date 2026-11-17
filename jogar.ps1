# Instala/atualiza o Minezada e abre o jogo. Rode no PowerShell (serve para instalar, atualizar e reparar):
#   irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$zipUrl = 'https://github.com/EnzoFerroni/minezada/raw/main/modpack/minezada-prism.zip'
$dados = "$env:APPDATA\PrismLauncher"
$locais = "$env:LOCALAPPDATA\Programs\PrismLauncher\prismlauncher.exe", "$env:ProgramFiles\PrismLauncher\prismlauncher.exe"

# 1. Prism Launcher
$prism = $locais | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $prism) {
    Write-Host 'Instalando o Prism Launcher...'
    winget install -e --id PrismLauncher.PrismLauncher --accept-source-agreements --accept-package-agreements
    $prism = $locais | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $prism) { throw 'Prism nao encontrado. Instale em https://prismlauncher.org/download/ e rode de novo.' }
}

# 2. Primeira vez: idioma, tema e Java automatico, para o assistente do Prism so pedir o login.
$cfg = Join-Path $dados 'prismlauncher.cfg'
if (-not (Test-Path $cfg)) {
    New-Item -ItemType Directory -Force $dados | Out-Null
    Set-Content $cfg -Encoding ascii "[General]`nLanguage=pt_BR`nApplicationTheme=dark`nIconTheme=pe_colored`nAutomaticJavaDownload=true`nAutomaticJavaSwitch=true`nIgnoreJavaWizard=true"
}

# 3. Instancia: extrai direto na pasta do Prism (sem dialogo). Preserva mundo, opcoes e servidores do jogador.
$instDir = (Select-String '^InstanceDir=(.+)$' $cfg | Select-Object -First 1).Matches.Groups[1].Value
if (-not $instDir) { $instDir = 'instances' }
if (-not [IO.Path]::IsPathRooted($instDir)) { $instDir = Join-Path $dados $instDir }
$inst = Join-Path $instDir 'Minezada'
$tmp = Join-Path $env:TEMP "minezada-$PID"
New-Item -ItemType Directory -Force $tmp | Out-Null
Invoke-WebRequest $zipUrl -OutFile "$tmp\pack.zip"
Expand-Archive "$tmp\pack.zip" "$tmp\x" -Force
New-Item -ItemType Directory -Force "$inst\.minecraft" | Out-Null
# shortcut: instance.cfg e sobrescrito (zera tempo de jogo do Prism); trocar por merge se incomodar.
Copy-Item "$tmp\x\instance.cfg", "$tmp\x\mmc-pack.json" $inst -Force
Copy-Item "$tmp\x\.minecraft\packwiz-installer-bootstrap.jar" "$inst\.minecraft" -Force
foreach ($f in 'servers.dat', 'options.txt') { if (-not (Test-Path "$inst\.minecraft\$f")) { Copy-Item "$tmp\x\.minecraft\$f" "$inst\.minecraft" } }
# Liga os pacotes de recursos do pack em quem ja tinha options.txt, mantendo os que o jogador ligou.
$opt = "$inst\.minecraft\options.txt"
# (o ForEach achata: no PS 5.1 o ConvertFrom-Json devolve a lista inteira como um item so)
$doPack = @((Get-Content "$tmp\x\.minecraft\options.txt" | Where-Object { $_ -like 'resourcePacks:*' }) -replace '^resourcePacks:', '' | ConvertFrom-Json | ForEach-Object { $_ })
$linhas = @(Get-Content $opt)
$atual = $linhas | Where-Object { $_ -like 'resourcePacks:*' } | Select-Object -First 1
$lista = if ($atual) { @(($atual -replace '^resourcePacks:', '') | ConvertFrom-Json | ForEach-Object { $_ }) } else { @('vanilla') }
$lista += @($doPack | Where-Object { $_ -notin $lista })
$nova = 'resourcePacks:' + (ConvertTo-Json -InputObject @($lista) -Compress)
$linhas = if ($atual) { $linhas | ForEach-Object { if ($_ -like 'resourcePacks:*') { $nova } else { $_ } } } else { $linhas + $nova }
[IO.File]::WriteAllLines($opt, [string[]]$linhas, (New-Object Text.UTF8Encoding $false))
Remove-Item -Recurse -Force $tmp

# 4. Atalho na Area de Trabalho que abre direto o jogo.
$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("$([Environment]::GetFolderPath('Desktop'))\Minezada.lnk")
$lnk.TargetPath = $prism; $lnk.Arguments = '--launch Minezada'; $lnk.IconLocation = "$prism,0"; $lnk.Save()

Start-Process $prism -ArgumentList '--launch', 'Minezada'
Write-Host "`nPronto! Na primeira vez entre com a conta Microsoft. Depois e so clicar em 'Minezada' na Area de Trabalho."
