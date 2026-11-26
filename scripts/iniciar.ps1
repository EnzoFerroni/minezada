# Faz tudo para hospedar: atualiza o repo, instala Java, cria config.env, instala/atualiza o pack,
# puxa o mundo da pasta sincronizada, liga os tuneis (Cloudflare e playit), roda e devolve o mundo.
# Uso: iniciar.bat   (ou: powershell -ExecutionPolicy Bypass -File scripts\iniciar.ps1 [-Forcar])
param([switch]$Forcar, [switch]$Rodar)  # -Rodar: etapa do servidor, chamada pelo proprio script
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'

$root = Split-Path $PSScriptRoot -Parent
$server = Join-Path $root 'server'
$tools = Join-Path $root 'tools'
$tar = "$env:SystemRoot\System32\tar.exe"  # bsdtar do Windows; o tar do Git Bash quebra com caminhos C:\
$porta = 25565
$eu = $env:COMPUTERNAME
$envFile = Join-Path $root 'config.env'

# 1. Repo atualizado: pack e scripts novos chegam sozinhos.
if (-not $Rodar -and (Test-Path (Join-Path $root '.git')) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    git -C $root pull --ff-only
    if ($LASTEXITCODE) { Write-Warning 'git pull falhou; seguindo com a versao local.' }
}

# Link da pasta minezada no Drive: quem nao tem acesso ve o botao "Solicitar acesso".
$driveUrl = 'https://drive.google.com/drive/folders/1Kw45U0B-b906dnDsUH8bLy9nDg7HfWzh'

# Tunel playit.gg: segunda entrada (o jogador entra por ele se a Cloudflare falhar). Sem porta aberta no
# roteador e sem expor o IP do host. O segredo do agente fica em playit.txt na pasta do Drive: todo host usa
# o mesmo tunel e endereco (anotado em playit-endereco.txt). Devolve o processo do agente ja conectado, ou $null.
function Iniciar-Tunel($pasta) {
    $seg = if ($pasta) { Join-Path $pasta 'playit.txt' }
    if (-not ($seg -and (Test-Path $seg))) {
        Write-Host 'Sem tunel playit.gg (precisa da pasta do Drive): so quem esta nesta rede consegue entrar.'
        return $null
    }
    $dir = Join-Path $tools 'playit'
    $exe = Join-Path $dir 'playitd.exe'
    if (-not (Test-Path $exe)) {
        Write-Host 'Baixando o playit.gg...'
        New-Item -ItemType Directory -Force $dir | Out-Null
        Invoke-WebRequest 'https://github.com/playit-cloud/playit-agent/releases/download/v2.0.2/playitd-windows-x86_64-signed.exe' -OutFile "$exe.tmp"
        # SHA-256 publicado na release: so roda o binario se bater.
        if ((Get-FileHash "$exe.tmp" -Algorithm SHA256).Hash -ne '6e62da9f56a3bcf72e0c62c29e94609c847cc9b110c460f68b20035525985238') {
            Remove-Item "$exe.tmp"; Write-Warning 'Checksum do playit.gg nao confere; tunel nao ligado.'; return $null
        }
        Move-Item "$exe.tmp" $exe
    }
    # Agente que sobrou de uma sessao fechada sem stop (janela fechada no X).
    Get-Process playitd -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe } | Stop-Process -Force
    New-Item -ItemType Directory -Force (Join-Path $server 'logs') | Out-Null
    $log = Join-Path $server 'logs\playit.log'
    Remove-Item $log -ErrorAction SilentlyContinue
    # Certificados e pipe proprios: nada vai para a pasta do Drive nem briga com um playit instalado.
    $p = Start-Process $exe -WindowStyle Hidden -PassThru -ArgumentList '--secret-path', "`"$seg`"",
        '--socket-path', '\\.\pipe\minezada-playit', '--cert-dir', "`"$(Join-Path $dir 'certs')`"", '-l', "`"$log`""
    Write-Host 'Ligando o tunel playit.gg...'
    for ($i = 0; $i -lt 40 -and -not ((Test-Path $log) -and (Select-String -Quiet 'playit connected' $log)); $i++) { Start-Sleep -Milliseconds 500 }
    if (-not (Select-String -Quiet 'playit connected' $log -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        Write-Warning "O tunel playit.gg nao conectou (detalhes em $log)."
        return $null
    }
    $end = Join-Path $pasta 'playit-endereco.txt'
    Write-Host "Endereco do servidor (tunel): $(if (Test-Path $end) { (Get-Content $end -Raw).Trim() } else { 'veja no painel do playit.gg' })"
    $p
}

# Tunel da Cloudflare: endereco principal (minezada.dpdns.org). O jogador conecta como HTTPS na 443 (o mod
# Modflared liga o cloudflared nele), entao passa em rede de faculdade e Wi-Fi publico. O host so faz conexao
# de saida (porta 7844). O token fica em cloudflare.txt na pasta do Drive. Devolve o processo conectado, ou $null.
function Iniciar-Cloudflare($pasta) {
    $tok = if ($pasta) { Join-Path $pasta 'cloudflare.txt' }
    if (-not ($tok -and (Test-Path $tok))) { Write-Host 'Sem tunel da Cloudflare (precisa de cloudflare.txt na pasta do Drive).'; return $null }
    $dir = Join-Path $tools 'cloudflared'
    $exe = Join-Path $dir 'cloudflared.exe'
    # Versao fixa com o SHA-256 do release oficial. Atualizar: trocar a versao e o hash (campo digest da API).
    if (-not ((Test-Path $exe) -and (Get-FileHash $exe -Algorithm SHA256).Hash -eq '2493dbc168923bb3e59e5e7716f71deced92992eea9acd6e9d74f84ac7751343')) {
        Write-Host 'Baixando o cloudflared...'
        New-Item -ItemType Directory -Force $dir | Out-Null
        Invoke-WebRequest 'https://github.com/cloudflare/cloudflared/releases/download/2026.10.7/cloudflared-windows-amd64.exe' -OutFile "$exe.tmp"
        if ((Get-FileHash "$exe.tmp" -Algorithm SHA256).Hash -ne '2493dbc168923bb3e59e5e7716f71deced92992eea9acd6e9d74f84ac7751343') {
            Remove-Item "$exe.tmp"; Write-Warning 'Checksum do cloudflared nao confere; tunel nao ligado.'; return $null
        }
        Move-Item -Force "$exe.tmp" $exe
    }
    Get-Process cloudflared -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe } | Stop-Process -Force
    New-Item -ItemType Directory -Force (Join-Path $server 'logs') | Out-Null
    $log = Join-Path $server 'logs\cloudflared.log'
    Remove-Item $log -ErrorAction SilentlyContinue
    # --token-file: o token nao aparece na lista de processos. Opcoes globais antes do "run".
    $p = Start-Process $exe -WindowStyle Hidden -PassThru -ArgumentList 'tunnel', '--no-autoupdate', '--logfile', "`"$log`"", 'run', '--token-file', "`"$tok`""
    Write-Host 'Ligando o tunel da Cloudflare...'
    for ($i = 0; $i -lt 40 -and -not ((Test-Path $log) -and (Select-String -Quiet 'Registered tunnel connection' $log)); $i++) { Start-Sleep -Milliseconds 500 }
    if (-not (Select-String -Quiet 'Registered tunnel connection' $log -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        Write-Warning "O tunel da Cloudflare nao conectou (detalhes em $log)."
        return $null
    }
    Write-Host 'Endereco do servidor: minezada.dpdns.org (tunel da Cloudflare)'
    $p
}

function Achar-Drive {
    Get-PSDrive -PSProvider FileSystem |
        ForEach-Object { "$($_.Root)Meu Drive\minezada"; "$($_.Root)My Drive\minezada" } |
        Where-Object { Test-Path $_ } | Select-Object -First 1
}

# Instala o Google Drive, abre o login e a pasta, e espera ela aparecer. Devolve o caminho ou $null.
function Configurar-Drive {
    Write-Host ''
    Write-Host "Recomendado: Google Drive com a pasta 'minezada'. Ele guarda o mundo compartilhado, entao"
    Write-Host 'qualquer pessoa pode hospedar e continuar de onde a outra parou. Sem ele o mundo fica so aqui.'
    $r = Read-Host 'Configurar o Google Drive agora? [S/n]'
    if ($r -match '^[nN]') { Add-Content $envFile 'SEM_DRIVE=1'; return $null }
    $app = "$env:ProgramFiles\Google\Drive File Stream\launch.bat"
    if (-not (Test-Path $app)) {
        Write-Host 'Instalando o Google Drive...'
        winget install -e --id Google.GoogleDrive --silent --accept-source-agreements --accept-package-agreements
        # 1610/3010: o Windows espera um reinicio (ex: Drive desinstalado ha pouco) e o instalador recusa rodar.
        if (-not (Test-Path $app)) {
            Write-Host ''
            Write-Host 'O Google Drive nao instalou. Reinicie o PC e rode o iniciar de novo, ou baixe em'
            Write-Host 'https://www.google.com/drive/download/ e instale; depois continue aqui.'
        }
    }
    if (Test-Path $app) { Start-Process $app }
    Start-Process $driveUrl
    Write-Host ''
    Write-Host '1. Entre com a sua conta Google no Google Drive que abriu.'
    Write-Host "2. No navegador: clique com o botao direito na pasta 'minezada' > Organizar > Adicionar atalho > Meu Drive. Se a pasta e sua, pule este passo."
    Write-Host "   Sem acesso? Clique em 'Solicitar acesso' e avise o Enzo."
    Write-Host 'Esperando a pasta aparecer neste PC (Enter para pular e jogar com o mundo so aqui)...'
    while ($true) {
        $d = Achar-Drive
        if ($d) { return $d }
        for ($i = 0; $i -lt 10; $i++) {
            if ([Console]::KeyAvailable -and [Console]::ReadKey($true).Key -eq 'Enter') {
                Write-Host 'Pulado: na proxima vez o script pergunta de novo.'
                return $null
            }
            Start-Sleep -Milliseconds 500
        }
    }
}

# 2. config.env na primeira vez, com o que der para detectar.
if (-not (Test-Path $envFile)) {
    Write-Host 'Primeira vez nesta maquina: criando config.env.'
    $gb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $ram = if ($gb -ge 24) { '8G' } elseif ($gb -ge 12) { '6G' } else { '4G' }
    Set-Content $envFile -Encoding ascii @("RAM=$ram", 'SYNC_DIR=""', 'JAVA=java')
}

$cfg = @{ RAM = '6G'; SYNC_DIR = ''; JAVA = 'java'; SEM_DRIVE = '' }
foreach ($l in Get-Content $envFile) {
    if ($l -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') { $cfg[$matches[1]] = $matches[2].Trim('"') }
}

# Pasta do Drive: acha sozinho; faltou, oferece instalar e configurar ("n" nao pergunta mais).
if (-not $Rodar -and -not $cfg.SYNC_DIR) {
    $achado = Achar-Drive
    if (-not $achado -and $cfg.SEM_DRIVE -ne '1') { $achado = Configurar-Drive }
    if ($achado) {
        Write-Host "Pasta do Google Drive: $achado"
        $cfg.SYNC_DIR = $achado
        Set-Content $envFile -Encoding ascii (@(Get-Content $envFile | Where-Object { $_ -notmatch '^\s*SYNC_DIR\s*=' }) + "SYNC_DIR=`"$achado`"")
    }
}

# 3. JDK 21+ (NeoForge 1.21.1; o JDK roda o scripts/Whitelist.java direto). Java 8/17 antigo ou so JRE contam
# como faltando: baixa o Temurin 25 para tools/, sem winget nem administrador (igual ao iniciar.sh).
function Java-Ok($j) {
    $ErrorActionPreference = 'Continue'  # o java -version escreve no stderr; com 'Stop' o PS 5.1 aborta
    if (-not (Get-Command $j -ErrorAction SilentlyContinue)) { return $false }
    $v = (& $j -version 2>&1 | Out-String)
    return ([regex]::Match($v, 'version "(\d+)').Groups[1].Value -as [int]) -ge 21 -and ((& $j --list-modules 2>$null) -match '^jdk\.compiler')
}
if (-not (Java-Ok $cfg.JAVA)) {
    $jdk = Join-Path $tools 'jdk\bin\java.exe'
    if (-not (Java-Ok $jdk)) {
        Write-Host 'Instalando Java 25...'
        New-Item -ItemType Directory -Force $tools | Out-Null
        $zip = Join-Path $tools 'jdk.zip'; $tmp = Join-Path $tools 'jdk-tmp'
        Remove-Item -Recurse -Force $tmp, (Join-Path $tools 'jdk') -ErrorAction SilentlyContinue
        Invoke-WebRequest 'https://api.adoptium.net/v3/binary/latest/25/ga/windows/x64/jdk/hotspot/normal/eclipse' -OutFile $zip
        New-Item -ItemType Directory $tmp | Out-Null
        & $tar -xf $zip -C $tmp
        Move-Item (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName (Join-Path $tools 'jdk')
        Remove-Item -Recurse -Force $zip, $tmp
    }
    if (-not (Java-Ok $jdk)) { throw 'Java nao instalado. Veja docs/hospedar.md' }
    $cfg.JAVA = $jdk
}
# 4. Pack -> servidor.
$sync = $cfg.SYNC_DIR
$lock = if ($sync) { Join-Path $sync 'host.lock' }
$estado = if ($sync) { Join-Path $sync 'mundo.tar.gz' }
# Whitelist e admins: lista na pasta do Drive (vale para todos os hosts) ou, sem Drive, no servidor.
$lista = if ($sync) { Join-Path $sync 'jogadores.txt' } else { Join-Path $server 'jogadores.txt' }
$neo = [regex]::Match((Get-Content (Join-Path $root 'modpack/pack/pack.toml') -Raw), 'neoforge = "(.+?)"').Groups[1].Value
if (-not $neo) { throw 'Versao do NeoForge nao encontrada em modpack/pack/pack.toml.' }
if (-not $Rodar) {
    # Servidor ja rodando nesta maquina (atalho clicado duas vezes): nao mexe no mundo dele.
    if (Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue) { throw "Ja tem um servidor rodando nesta maquina (porta $porta em uso)." }
    # Instalador oficial do NeoForge e packwiz, igual ao iniciar.sh (e ao jogo de cada jogador).
    New-Item -ItemType Directory -Force $server | Out-Null
    if (-not (Test-Path (Join-Path $server "libraries/net/neoforged/neoforge/$neo/win_args.txt"))) {
        Write-Host "Instalando NeoForge $neo..."
        $inst = Join-Path $server 'neoforge-installer.jar'
        Invoke-WebRequest "https://maven.neoforged.net/releases/net/neoforged/neoforge/$neo/neoforge-$neo-installer.jar" -OutFile $inst
        Push-Location $server
        & $cfg.JAVA -jar $inst --installServer . | Out-Null
        $ok = -not $LASTEXITCODE
        Pop-Location
        Remove-Item $inst, "$inst.log" -ErrorAction SilentlyContinue
        if (-not $ok) { throw 'Instalacao do NeoForge falhou.' }
    }
    # Servidor montado pelo mrpack-install antigo: limpa os mods para o packwiz assumir sem duplicar.
    if (-not (Test-Path (Join-Path $server 'packwiz.json'))) { Remove-Item -Recurse -Force (Join-Path $server 'mods') -ErrorAction SilentlyContinue }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $z = [IO.Compression.ZipFile]::OpenRead((Join-Path $root 'modpack/minezada-prism.zip'))
    foreach ($e in $z.Entries | Where-Object { $_.FullName -in '.minecraft/packwiz-installer-bootstrap.jar', '.minecraft/packwiz-installer.jar' }) {
        [IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $server $e.Name), $true)
    }
    $z.Dispose()
    # Idempotente: sem mudanca no pack, nao baixa nada. "-s server" pula os mods so de cliente.
    $packToml = 'file:///' + ((Join-Path $root 'modpack/pack/pack.toml') -replace '\\', '/' -replace ' ', '%20')
    Push-Location $server
    & $cfg.JAVA -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -g -s server $packToml
    $ok = -not $LASTEXITCODE
    Pop-Location
    if (-not $ok) { throw 'Instalacao dos mods falhou.' }
    $eula = Join-Path $server 'eula.txt'
    if (-not ((Test-Path $eula) -and (Select-String -Quiet 'eula=true' $eula))) {
        $r = Read-Host 'Voce aceita o EULA do Minecraft (https://aka.ms/MinecraftEULA)? [s/N]'
        if ($r -ne 's') { throw 'EULA nao aceito.' }
        Set-Content $eula 'eula=true'
    }
    Copy-Item (Join-Path $root 'server-config\*') $server -Recurse -Force

    # 5. Mundo da pasta sincronizada, com trava para so um host por vez.
    $sync = $cfg.SYNC_DIR
    if ($sync) {
        # Drive fechado: a pasta some ou fica com a copia velha, e o servidor abriria o mundo antigo e depois
        # o enviaria por cima do bom. Igual ao iniciar.sh: abre o Drive e espera o Enter.
        $app = "$env:ProgramFiles\Google\Drive File Stream\launch.bat"
        if ($sync -match '\\(Meu|My) Drive\\' -and (Test-Path $app) -and -not (Get-Process GoogleDriveFS -ErrorAction SilentlyContinue)) {
            Write-Host 'O Google Drive estava fechado. Abrindo agora...'
            Start-Process $app
            for ($i = 0; $i -lt 120 -and -not (Test-Path $sync); $i++) { Start-Sleep 1 }
            Read-Host 'Espere o icone do Drive na bandeja parar de sincronizar e aperte Enter' | Out-Null
        }
        if (-not (Test-Path $sync)) { throw "SYNC_DIR nao existe: $sync" }
        $lock = Join-Path $sync 'host.lock'
        $estado = Join-Path $sync 'mundo.tar.gz'
        $dono = if (Test-Path $lock) { (Get-Content $lock -Raw).Trim() } else { '' }
        if ($dono -and $dono -ne $eu -and -not $Forcar) {
            throw "Servidor ja esta ativo em '$dono'. Se tiver certeza que nao esta, rode com -Forcar."
        }
        # Trava ja era desta maquina = ultima sessao caiu sem enviar; o mundo local e o mais novo.
        if ($dono -ne $eu -and (Test-Path $estado)) {
            Write-Host 'Baixando mundo da pasta sincronizada...'
            # Copia da sessao (a cada 30 min) mais nova que o mundo.tar.gz = o ultimo host caiu antes do stop.
            $origem = $estado
            $sessao = Join-Path $sync 'backups\sessao-atual.tar.gz'
            if ((Test-Path $sessao) -and (Get-Item $sessao).LastWriteTimeUtc -gt (Get-Item $estado).LastWriteTimeUtc) {
                Write-Host "O ultimo host caiu sem salvar: usando a copia da sessao de $((Get-Item $sessao).LastWriteTime)."
                $origem = $sessao
            }
            # Extrai a parte e confere antes de mexer no mundo local ou pegar a trava: um arquivo corrompido
            # nao pode virar o mundo desta maquina (ele seria enviado por cima do bom no proximo stop).
            $novo = Join-Path $server '.mundo-novo'
            Remove-Item -Recurse -Force $novo -ErrorAction SilentlyContinue
            New-Item -ItemType Directory -Force $novo | Out-Null
            & $tar -xzf $origem -C $novo
            if ($LASTEXITCODE -or -not (Test-Path (Join-Path $novo 'world'))) {
                Remove-Item -Recurse -Force $novo
                throw "mundo.tar.gz corrompido. Copie o mais novo de $sync\backups por cima dele e rode de novo."
            }
            $w = Join-Path $server 'world'
            if (Test-Path $w) {
                Remove-Item -Recurse -Force "$w.bak" -ErrorAction SilentlyContinue
                Rename-Item $w 'world.bak'
            }
            Get-ChildItem -Force $novo | ForEach-Object {
                Remove-Item -Recurse -Force (Join-Path $server $_.Name) -ErrorAction SilentlyContinue
                Move-Item $_.FullName $server
            }
            Remove-Item -Recurse -Force $novo
        }
        # shortcut: a trava depende da nuvem ja ter sincronizado; dois hosts iniciando no mesmo minuto podem passar os dois.
        Set-Content $lock $eu
    }
    # Mesma logica no Windows e no Mac: scripts/Whitelist.java, rodado com o Java do servidor.
    & $cfg.JAVA (Join-Path $PSScriptRoot 'Whitelist.java') $lista $server
    if ($LASTEXITCODE) { Write-Warning 'Falha ao atualizar a whitelist.' }

    # Etapa do servidor num PowerShell escondido, fora desta janela: fechar esta janela nao derruba nada. O servidor
    # abre na janela propria do Minecraft; fechar ela no X salva e para como o stop, e ai o mundo vai para o Drive.
    $log = Join-Path $server 'logs\iniciar.log'
    New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
    Start-Process powershell -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError "$log.erros" -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Rodar'
    Write-Host ''
    Write-Host 'Servidor abrindo na janela "Minecraft server" (leva uns 30 segundos). Endereco: minezada.dpdns.org'
    Write-Host 'Para desligar: feche a janela do servidor ou digite stop nela. O mundo vai sozinho para o Drive.'
    Write-Host "Esta janela pode ser fechada. Registro da rede e do envio do mundo: $log"
    exit
}

# 6. Rede: tuneis da Cloudflare e do playit. Quem esta nesta maquina entra por localhost; o resto, pelo tunel.
$cf = Iniciar-Cloudflare $cfg.SYNC_DIR
$tunel = Iniciar-Tunel $cfg.SYNC_DIR
if (-not ($cf -or $tunel)) { Write-Warning 'Nenhum tunel conectou: so esta maquina consegue entrar (localhost).' }

# Impede o Windows de suspender enquanto o servidor roda (tela pode apagar).
Add-Type -Name Energia -Namespace Minezada -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);'
[void][Minezada.Energia]::SetThreadExecutionState(2147483649)  # 0x80000001 = ES_CONTINUOUS | ES_SYSTEM_REQUIRED (hex vira negativo no PS 5.1)

# Pede a consulta do selo agora (scripts/Selo.java), sem esperar o horario do GitHub. Sem dispatch.txt no Drive, nada.
function Avisar-Selo($motivo) {
    if (-not $sync -or -not (Test-Path (Join-Path $sync 'dispatch.txt'))) { return }
    Start-Process -WindowStyle Hidden -FilePath $cfg.JAVA -ArgumentList @("`"$(Join-Path $PSScriptRoot 'Selo.java')`"", "`"$sync`"", $motivo)
}

# Copia do mundo com o servidor ligado, para a pagina (o do Drive so muda no stop). save-off para o jogo nao gravar
# no meio da copia, save-all flush para o que esta na memoria ir para o disco; sem "Saved the game" em um minuto,
# desiste. Anda um passo a cada volta do laco (30 s) e o tar roda escondido: o laco nao para. Sem github.txt, nada.
$foto = @{ Fase = ''; Antes = 0; Volta = 0; Tar = $null }
function Foto-Passo([switch]$Comecar) {
    $wlog = Join-Path $server 'logs\latest.log'
    $arq = Join-Path $server 'logs\mundo-agora.tar.gz'
    $salvos = @(Select-String -SimpleMatch 'Saved the game' $wlog -ErrorAction SilentlyContinue).Count
    if ($Comecar) {
        if ($foto.Fase -or -not $sync -or -not (Test-Path (Join-Path $sync 'github.txt'))) { return }
        try { $proc.StandardInput.WriteLine('save-off'); $proc.StandardInput.WriteLine('save-all flush') } catch { return }
        $foto.Fase = 'salvando'; $foto.Antes = $salvos; $foto.Volta = $voltas
        return
    }
    if ($foto.Fase -eq 'salvando') {
        if ($salvos -gt $foto.Antes) {
            $itens = @('world', 'ops.json', 'whitelist.json', 'banned-players.json', 'banned-ips.json') |
                Where-Object { Test-Path (Join-Path $server $_) }
            # session.lock fica travado pelo servidor ligado no Windows e o tar falha com "(null)" sem este exclude.
            try {
                $foto.Tar = Start-Process -PassThru -WindowStyle Hidden -FilePath $tar -ErrorAction Stop -ArgumentList (@('-czf', "`"$arq.tmp`"", '--exclude', 'session.lock', '-C', "`"$server`"") + $itens)
                $null = $foto.Tar.Handle  # sem pegar o Handle antes de sair, o ExitCode do Start-Process vem vazio
                $foto.Fase = 'tar'
                return
            }
            catch { Write-Warning "Foto do mundo sem tar: $($_.Exception.Message)" }
        }
        # Sem tar ou sem "Saved the game" em um minuto: volta a salvar e desiste desta foto.
        if ($salvos -gt $foto.Antes -or $voltas - $foto.Volta -ge 2) {
            try { $proc.StandardInput.WriteLine('save-on') } catch { }
            $foto.Fase = ''
        }
        return
    }
    if ($foto.Fase -ne 'tar' -or -not $foto.Tar.HasExited) { return }
    try { $proc.StandardInput.WriteLine('save-on') } catch { }
    $foto.Fase = ''
    if ($foto.Tar.ExitCode) { Remove-Item -Force "$arq.tmp" -ErrorAction SilentlyContinue; return }
    Move-Item -Force "$arq.tmp" $arq
    # Copia de seguranca no Drive (backups\sessao-atual.tar.gz): se o PC cair, outro host ainda tem a sessao. O
    # mundo.tar.gz e a trava continuam so do stop.
    try {
        $bk = Join-Path $sync 'backups'
        New-Item -ItemType Directory -Force $bk | Out-Null
        Copy-Item -Force $arq (Join-Path $bk 'sessao-atual.tar.gz')
    } catch { Write-Warning "Nao copiei a sessao para o Drive: $($_.Exception.Message)" }
    Start-Process -WindowStyle Hidden -FilePath $cfg.JAVA -ArgumentList @("`"$(Join-Path $PSScriptRoot 'MundoGithub.java')`"", "`"$arq`"", "`"$sync`"")
}

Push-Location $server
try {
    Write-Host "Iniciando servidor com $($cfg.RAM) de RAM, na janela propria (fechar ela ou digitar stop salva e desliga)."
    # Flags do Aikar: coleta de lixo G1 ajustada para servidor de Minecraft (menos travadas).
    $flags = '-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1' -split ' '
    # Sem "nogui": a janela do Minecraft server tem campo de comando, e fechar ela no X salva e para.
    # A entrada do java fica com este script: se o jogadores.txt mudar, libera os novos e manda whitelist reload
    # (issue #16). Se o whitelist.json ou o ops.json mudar (/whitelist add ou /op no jogo), copia o nick para a
    # lista antes. Confere a cada 30 s.
    $psi = New-Object Diagnostics.ProcessStartInfo $cfg.JAVA
    $psi.Arguments = (@("-Xms$($cfg.RAM)", "-Xmx$($cfg.RAM)") + $flags + "@libraries/net/neoforged/neoforge/$neo/win_args.txt") -join ' '
    $psi.WorkingDirectory = $server
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $proc = [Diagnostics.Process]::Start($psi)
    $wl = Join-Path $PSScriptRoot 'Whitelist.java'
    $datas = { param($arqs) ($arqs | ForEach-Object { if (Test-Path $_) { (Get-Item $_).LastWriteTimeUtc.Ticks } }) -join ',' }
    $jsons = (Join-Path $server 'whitelist.json'), (Join-Path $server 'ops.json')
    $visto = & $datas $lista; $vistoJogo = & $datas $jsons
    # Selo avisado quando o servidor termina de abrir e a cada 10 minutos; foto do mundo a cada 30. O latest.log da
    # sessao anterior ainda tem o "Done": so conta o log escrito depois do start.
    $inicio = Get-Date; $pronto = 0; $voltas = 0
    $wlog = Join-Path $server 'logs\latest.log'
    while (-not $proc.WaitForExit(30000)) {
        $voltas++
        if (-not $pronto) {
            if ((Test-Path $wlog) -and (Get-Item $wlog).LastWriteTime -ge $inicio -and (Select-String -Quiet -SimpleMatch 'Done (' $wlog)) {
                $pronto = $voltas
                Avisar-Selo 'ligou'
                # Explosao dropa tudo que quebra (creeper, TNT, cama no Nether). Vale no mundo; reaplicado a cada partida.
                try { foreach ($r in 'mobExplosionDropDecay', 'tntExplosionDropDecay', 'blockExplosionDropDecay') { $proc.StandardInput.WriteLine("gamerule $r false") } }
                catch { Write-Warning "Nao apliquei as regras de explosao: $($_.Exception.Message)" }
            }
        }
        else {
            $t = $voltas - $pronto
            if ($t % 20 -eq 0) { Avisar-Selo 'ligado' }
            if ($t % 60 -eq 0) { Foto-Passo -Comecar } else { Foto-Passo }
        }
        $jogo = & $datas $jsons
        if ($jogo -ne $vistoJogo) {
            $vistoJogo = $jogo
            & $cfg.JAVA $wl --do-jogo $lista $server | ForEach-Object { Write-Host $_ }
        }
        $agora = & $datas $lista
        if ($agora -eq $visto) { continue }
        $visto = $agora
        Write-Host 'jogadores.txt mudou: atualizando a whitelist.'
        $saida = @(& $cfg.JAVA $wl $lista $server)
        $saida | ForEach-Object { Write-Host $_ }
        $vistoJogo = & $datas $jsons
        # Sem "op Nick" aqui: o servidor resolve nick offline em minusculas e daria admin a outro UUID.
        if ($saida -like 'Admin (op): *') { Write-Host 'Admin novo vale no proximo start (ou /op Nick no jogo com a pessoa online).' }
        try { $proc.StandardInput.WriteLine('whitelist reload') } catch { Write-Warning "Nao consegui avisar o servidor: $($_.Exception.Message)" }
    }
}
finally {
    Pop-Location
    [void][Minezada.Energia]::SetThreadExecutionState(2147483648)  # 0x80000000 = volta ao normal
    foreach ($t in $cf, $tunel) { if ($t) { Stop-Process -Id $t.Id -Force -ErrorAction SilentlyContinue } }
    if ($sync -and (Test-Path (Join-Path $sync 'dispatch.txt'))) {
        & $cfg.JAVA (Join-Path $PSScriptRoot 'Selo.java') $sync 'desligou' | ForEach-Object { Write-Host $_ }
    }
    if ($sync) {
        Write-Host 'Enviando mundo para a pasta sincronizada...'
        $itens = @('world', 'ops.json', 'whitelist.json', 'banned-players.json', 'banned-ips.json') |
            Where-Object { Test-Path (Join-Path $server $_) }
        & $tar -czf "$estado.tmp" -C $server @itens
        if ($LASTEXITCODE) {
            Write-Warning "Falha ao enviar o mundo. Trava mantida em $eu; rode de novo nesta maquina."
        }
        else {
            Move-Item -Force "$estado.tmp" $estado
            # Guarda os 5 ultimos mundos com data, caso um envio saia corrompido.
            $bk = Join-Path $sync 'backups'
            New-Item -ItemType Directory -Force $bk | Out-Null
            Copy-Item $estado (Join-Path $bk "mundo-$(Get-Date -Format yyyyMMdd-HHmm).tar.gz")
            Get-ChildItem $bk -Filter 'mundo-*.tar.gz' | Sort-Object Name -Descending | Select-Object -Skip 5 | Remove-Item
            Remove-Item $lock
            Write-Host 'Pronto. Outro host ja pode iniciar.'
            # Depois da trava: um envio lento ao GitHub nao segura o proximo host. Sem github.txt, nao faz nada.
            & $cfg.JAVA (Join-Path $PSScriptRoot 'MundoGithub.java') $estado $sync | ForEach-Object { Write-Host $_ }
        }
    }
}
