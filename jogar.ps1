# Instala/atualiza o Minezada e abre o jogo. Rode no PowerShell (serve para instalar, atualizar e reparar):
#   irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$zipUrl = 'https://github.com/EnzoFerroni/minezada/raw/main/modpack/minezada-prism.zip'
$dados = "$env:APPDATA\PrismLauncher"
$locais = "$env:LOCALAPPDATA\Programs\PrismLauncher\prismlauncher.exe", "$env:ProgramFiles\PrismLauncher\prismlauncher.exe"
# Fork do Prism que aceita conta offline sem conta Microsoft (o Prism oficial abre em modo Demo).
# Versao fixa com SHA-256: e mantido por uma pessoa so, entao so roda o binario conferido. Atualizar:
# trocar a versao e o sha256 (campo "digest" do arquivo na API de releases do GitHub).
$forkRepo = 'Diegiwg/PrismLauncher-Cracked'
$forkUrl = "https://github.com/$forkRepo/releases/download/11.1.1/PrismLauncher-Windows-MSVC-11.1.1.zip"
$forkSha = '38c00b10f62be0049e1715d25738003f92a33045707b4112296a844a210b7e3a'
$forkDir = "$env:LOCALAPPDATA\Programs\Minezada Launcher"

# 0. Conta. Launcher ja instalado responde sozinho (reparar nao pergunta de novo).
if (Test-Path "$forkDir\prismlauncher.exe") { $original = $false }
elseif ($locais | Where-Object { Test-Path $_ }) { $original = $true }
else { $original = (Read-Host 'Voce tem Minecraft original (conta Microsoft)? [s/n]') -notmatch '^\s*n' }

# 1. Launcher: Prism oficial com conta original; senao o fork, numa pasta separada para nao
# trocar o Prism de quem ja tem. Os dois usam a mesma pasta de dados.
if ($original) {
    $prism = $locais | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $prism) {
        Write-Host 'Instalando o Prism Launcher...'
        winget install -e --id PrismLauncher.PrismLauncher --accept-source-agreements --accept-package-agreements
        $prism = $locais | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $prism) { throw 'Prism nao encontrado. Instale em https://prismlauncher.org/download/ e rode de novo.' }
    }
}
else {
    # Baixado a cada vez (versao fixa): rodar o comando de novo repara o launcher. Zip MSVC sem
    # "Portable" guarda os dados em %APPDATA%\PrismLauncher, como o oficial.
    Write-Host 'Instalando o launcher para conta offline...'
    $forkZip = Join-Path $env:TEMP "minezada-launcher-$PID.zip"
    Invoke-WebRequest $forkUrl -OutFile $forkZip
    if ((Get-FileHash $forkZip -Algorithm SHA256).Hash -ne $forkSha) {
        Remove-Item $forkZip; throw 'O launcher baixado nao confere (checksum). Avise o Enzo.'
    }
    Expand-Archive $forkZip $forkDir -Force
    Remove-Item $forkZip
    $prism = "$forkDir\prismlauncher.exe"
}

# 2. Primeira vez: idioma, tema e Java automatico, para o assistente do Prism so pedir o login.
$cfg = Join-Path $dados 'prismlauncher.cfg'
if (-not (Test-Path $cfg)) {
    New-Item -ItemType Directory -Force $dados | Out-Null
    Set-Content $cfg -Encoding ascii "[General]`nLanguage=pt_BR`nApplicationTheme=dark`nIconTheme=pe_colored`nAutomaticJavaDownload=true`nAutomaticJavaSwitch=true`nIgnoreJavaWizard=true"
}

# 3. Instancia: extrai direto na pasta do Prism (sem dialogo). Preserva mundo, opcoes e servidores do jogador.
$instDir = Select-String '^InstanceDir=(.+)$' $cfg | Select-Object -First 1 | ForEach-Object { $_.Matches[0].Groups[1].Value }
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
# Memoria do jogo: 6 GB com 24 GB+ de RAM, 3 GB abaixo de 12 GB; senao fica a do zip (4 GB evita o
# aviso do Prism em 16 GB). Limites 23/11: o Windows reporta um pouco menos que o instalado.
$gb = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$mem = if ($gb -ge 23) { 6144 } elseif ($gb -lt 11) { 3072 } else { $null }
$cfgLinhas = Get-Content "$inst\instance.cfg"
if ($mem) { $cfgLinhas = $cfgLinhas -replace '^MaxMemAlloc=.*', "MaxMemAlloc=$mem" }
# Antes de abrir roda o minezada.ps1 (vem pelo pack): atualiza os mods e o que fica fora do pack.
$cfgLinhas = $cfgLinhas -replace '^PreLaunchCommand=.*', 'PreLaunchCommand=powershell -NoProfile -ExecutionPolicy Bypass -File minezada.ps1'
$cfgLinhas | Set-Content "$inst\instance.cfg" -Encoding ascii
Copy-Item "$tmp\x\.minecraft\packwiz-installer-bootstrap.jar", "$tmp\x\.minecraft\packwiz-installer.jar", "$tmp\x\.minecraft\minezada.ps1" "$inst\.minecraft" -Force
foreach ($f in 'servers.dat', 'options.txt') { if (-not (Test-Path "$inst\.minecraft\$f")) { Copy-Item "$tmp\x\.minecraft\$f" "$inst\.minecraft" } }
# Liga os pacotes de recursos do pack em quem ja tinha options.txt, mantendo os que o jogador ligou.
# -Encoding UTF8: o PS 5.1 le como ANSI e estragaria nomes com acento ou com o simbolo de secao (ex: Low On Fire).
$opt = "$inst\.minecraft\options.txt"
# (o ForEach achata: no PS 5.1 o ConvertFrom-Json devolve a lista inteira como um item so)
$doPack = @((Get-Content "$tmp\x\.minecraft\options.txt" -Encoding UTF8 | Where-Object { $_ -like 'resourcePacks:*' }) -replace '^resourcePacks:', '' | ConvertFrom-Json | ForEach-Object { $_ })
$linhas = @(Get-Content $opt -Encoding UTF8)
$atual = $linhas | Where-Object { $_ -like 'resourcePacks:*' } | Select-Object -First 1
$lista = if ($atual) { @(($atual -replace '^resourcePacks:', '') | ConvertFrom-Json | ForEach-Object { $_ }) } else { @('vanilla') }
# Pacotes do jogador na ordem dele e os do pack por cima, na ordem do pack; "vanilla" fica na base.
$lista = @($lista | Where-Object { $_ -eq 'vanilla' -or $_ -cnotin $doPack }) + @($doPack | Where-Object { $_ -ne 'vanilla' })
$nova = 'resourcePacks:' + (ConvertTo-Json -InputObject @($lista) -Compress)
$linhas = if ($atual) { $linhas | ForEach-Object { if ($_ -like 'resourcePacks:*') { $nova } else { $_ } } } else { $linhas + $nova }
[IO.File]::WriteAllLines($opt, [string[]]$linhas, (New-Object Text.UTF8Encoding $false))
Remove-Item -Recurse -Force $tmp

# 4. Atalho opcional na Area de Trabalho. Quem ja tem o atalho ganha a versao nova sem pergunta.
$abrir = 'abrir o Prism Launcher e jogar a instancia Minezada'
$lnkPath = "$([Environment]::GetFolderPath('Desktop'))\Minezada.lnk"
if ((Test-Path $lnkPath) -or (Read-Host 'Criar um atalho "Minezada" na Area de Trabalho para abrir o jogo? [S/n]') -notmatch '^\s*n') {
    $lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($lnkPath)
    $lnk.TargetPath = $prism; $lnk.Arguments = '--launch Minezada'; $lnk.IconLocation = "$prism,0"; $lnk.Save()
    $abrir = "clicar em 'Minezada' na Area de Trabalho"
}

Start-Process $prism -ArgumentList '--launch', 'Minezada'
if ($original) {
    Write-Host "`nPronto! Na primeira vez entre com a conta Microsoft. Depois e so $abrir."
}
else {
    Write-Host "`nPronto! Na primeira vez o launcher pede um nome: use seu nick exatamente como esta na"
    Write-Host "whitelist (maiusculas contam). Depois e so $abrir."
}
