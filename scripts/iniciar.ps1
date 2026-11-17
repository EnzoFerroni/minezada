# Faz tudo para hospedar: atualiza o repo, instala Java, cria config.env, instala/atualiza o pack,
# puxa o mundo da pasta sincronizada, abre a porta (UPnP), atualiza o DuckDNS, roda e devolve o mundo.
# Uso: iniciar.bat   (ou: powershell -ExecutionPolicy Bypass -File scripts\iniciar.ps1 [-Forcar])
param([switch]$Forcar)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'

$root = Split-Path $PSScriptRoot -Parent
$server = Join-Path $root 'server'
$tools = Join-Path $root 'tools'
$tar = "$env:SystemRoot\System32\tar.exe"  # bsdtar do Windows; o tar do Git Bash quebra com caminhos C:\
$mrpackVersion = '0.23.0'
$porta = 25565
$portaAlt = 443
$eu = $env:COMPUTERNAME
$envFile = Join-Path $root 'config.env'

# Abre (ou fecha) a porta no roteador por UPnP falando SOAP direto com ele. Nao usa o HNetCfg.NATUPnP
# do Windows porque ele nao funciona com a rede em perfil "Publica". Falha: vale o redirecionamento manual.
function Porta-UPnP([bool]$abrir, [int]$externa = $porta) {
    try {
        # IP da placa que vai pra internet; prender o socket nela evita a descoberta sair por VPN (Radmin etc).
        $ip = (Find-NetRoute -RemoteIPAddress 8.8.8.8 | Where-Object IPAddress | Select-Object -First 1).IPAddress
        $u = New-Object Net.Sockets.UdpClient (New-Object Net.IPEndPoint([Net.IPAddress]::Parse($ip), 0))
        $u.Client.ReceiveTimeout = 3000
        $q = [Text.Encoding]::ASCII.GetBytes("M-SEARCH * HTTP/1.1`r`nHOST: 239.255.255.250:1900`r`nMAN: `"ssdp:discover`"`r`nMX: 2`r`nST: urn:schemas-upnp-org:device:InternetGatewayDevice:1`r`n`r`n")
        [void]$u.Send($q, $q.Length, '239.255.255.250', 1900)
        $ep = New-Object Net.IPEndPoint([Net.IPAddress]::Any, 0)
        $resp = [Text.Encoding]::ASCII.GetString($u.Receive([ref]$ep))
        $u.Close()
        $loc = [regex]::Match($resp, '(?im)^location:\s*(\S+)').Groups[1].Value
        # Alguns roteadores respondem application/octet-stream: le os bytes crus.
        $xml = [Text.Encoding]::UTF8.GetString((Invoke-WebRequest $loc -UseBasicParsing).RawContentStream.ToArray())
        $acao = if ($abrir) { 'AddPortMapping' } else { 'DeletePortMapping' }
        $campos = "<NewRemoteHost></NewRemoteHost><NewExternalPort>$externa</NewExternalPort><NewProtocol>TCP</NewProtocol>"
        if ($abrir) { $campos += "<NewInternalPort>$porta</NewInternalPort><NewInternalClient>$ip</NewInternalClient><NewEnabled>1</NewEnabled><NewPortMappingDescription>minezada $externa</NewPortMappingDescription><NewLeaseDuration>0</NewLeaseDuration>" }
        $svcs = [regex]::Matches($xml, '<serviceType>(urn:schemas-upnp-org:service:WAN(?:IP|PPP)Connection:\d)</serviceType>.*?<controlURL>([^<]+)</controlURL>', 'Singleline')
        foreach ($s in $svcs) {
            $tipo = $s.Groups[1].Value
            $body = "<?xml version=`"1.0`"?><s:Envelope xmlns:s=`"http://schemas.xmlsoap.org/soap/envelope/`" s:encodingStyle=`"http://schemas.xmlsoap.org/soap/encoding/`"><s:Body><u:$acao xmlns:u=`"$tipo`">$campos</u:$acao></s:Body></s:Envelope>"
            try {
                Invoke-WebRequest ([Uri]::new([Uri]$loc, $s.Groups[2].Value)) -Method Post -Body $body -ContentType 'text/xml; charset="utf-8"' -Headers @{ SOAPAction = "`"$tipo#$acao`"" } -UseBasicParsing | Out-Null
                return $true
            }
            catch {}  # roteador pode anunciar WANIP e WANPPP; so um aceita
        }
        return $false
    }
    catch { return $false }
}

# 1. Repo atualizado: pack e scripts novos chegam sozinhos.
if ((Test-Path (Join-Path $root '.git')) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    git -C $root pull --ff-only
    if ($LASTEXITCODE) { Write-Warning 'git pull falhou; seguindo com a versao local.' }
}

# Link da pasta minezada no Drive: quem nao tem acesso ve o botao "Solicitar acesso".
$driveUrl = 'https://drive.google.com/drive/folders/1Kw45U0B-b906dnDsUH8bLy9nDg7HfWzh'

# Libera na whitelist os nicks de jogadores.txt (um por linha; "op" depois do nick tambem da admin).
# MixAuth: quem tem original entra com o UUID oficial e quem nao tem com o offline, entao libera os dois.
# Sem o arquivo, cria com o dono e quem ja esta liberado. So adiciona; tirar alguem e no console.
function Sincronizar-Whitelist($lista, $pasta) {
    # (o ForEach achata: no PS 5.1 o ConvertFrom-Json devolve a lista inteira como um item so)
    $ler = { param($n) $a = Join-Path $pasta $n; @(if (Test-Path $a) { Get-Content $a -Raw | ConvertFrom-Json | ForEach-Object { $_ } }) }
    $wl = @(& $ler 'whitelist.json'); $ops = @(& $ler 'ops.json')
    # Mesmo UUID que o servidor da ao nick sem conta Microsoft (maiusculas contam).
    $offline = { param($n)
        $b = [Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes("OfflinePlayer:$n"))
        $b[6] = ($b[6] -band 0x0f) -bor 0x30; $b[8] = ($b[8] -band 0x3f) -bor 0x80
        $x = -join ($b | ForEach-Object { $_.ToString('x2') })
        "$($x.Substring(0,8))-$($x.Substring(8,4))-$($x.Substring(12,4))-$($x.Substring(16,4))-$($x.Substring(20))"
    }
    # UUID oficial ja conhecido (whitelist/ops) evita consultar a Mojang a cada start.
    $oficiais = @{}
    foreach ($e in $wl + $ops) { if ($e.uuid -ne (& $offline $e.name)) { $oficiais[$e.name.ToLower()] = $e.uuid } }
    $oficial = { param($n)
        if ($oficiais.ContainsKey($n.ToLower())) { return $oficiais[$n.ToLower()] }
        # Dois enderecos da Mojang: rede compartilhada (faculdade) costuma levar 429 em um deles.
        foreach ($url in 'https://api.mojang.com/users/profiles/minecraft/', 'https://api.minecraftservices.com/minecraft/profile/lookup/name/') {
            try {
                $x = (Invoke-RestMethod "$url$n" -TimeoutSec 5).id
                if ($x) { return "$($x.Substring(0,8))-$($x.Substring(8,4))-$($x.Substring(12,4))-$($x.Substring(16,4))-$($x.Substring(20))" }
            }
            catch {
                if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 404) { return $null }  # nick sem conta original
            }
        }
        Write-Warning "A Mojang nao respondeu sobre $n. Se ele tem original, nao entra ate o proximo start (ou: whitelist add $n no console)."
        $null
    }
    if (-not (Test-Path $lista)) {
        $linhas = @("# Um nick por linha, igual ao do jogo (maiusculas contam); 'op' depois tambem da admin.",
            '# O servidor libera todos ao iniciar: depois de editar, reinicie. Nao use whitelist add no console.', 'Enzobullet op') + @($wl | Where-Object { $_.name -ne 'Enzobullet' } | ForEach-Object { $_.name })
        [IO.File]::WriteAllLines($lista, [string[]]$linhas)
    }
    $mundo = Join-Path $pasta 'world'
    foreach ($l in Get-Content $lista) {
        $partes = @(($l -split '#')[0].Trim() -split '\s+' | Where-Object { $_ })
        if (-not $partes) { continue }
        $nome = $partes[0]
        if ($nome -notmatch '^[A-Za-z0-9_]{1,16}$') { Write-Warning "Nick invalido em jogadores.txt: $nome"; continue }
        $op = @($partes | Select-Object -Skip 1) -contains 'op'
        $ids = @(& $offline $nome)
        $on = & $oficial $nome
        if ($on) {
            $ids += $on
            # Progresso de antes (UUID offline) copiado para o oficial, so se o oficial ainda nao tem nada.
            foreach ($a in 'playerdata\{0}.dat', 'advancements\{0}.json', 'stats\{0}.json') {
                $de = Join-Path $mundo ($a -f $ids[0]); $para = Join-Path $mundo ($a -f $on)
                if ((Test-Path $de) -and -not (Test-Path $para)) {
                    Copy-Item $de $para; Write-Host "Progresso de $nome copiado para o UUID oficial: $($a -f $on)"
                }
            }
        }
        foreach ($u in $ids) {
            if (-not ($wl | Where-Object { $_.uuid -eq $u })) { $wl += [pscustomobject]@{ uuid = $u; name = $nome }; Write-Host "Liberado na whitelist: $nome ($u)" }
            if ($op -and -not ($ops | Where-Object { $_.uuid -eq $u })) { $ops += [pscustomobject]@{ uuid = $u; name = $nome; level = 4; bypassesPlayerLimit = $false }; Write-Host "Admin (op): $nome ($u)" }
        }
    }
    [IO.File]::WriteAllText((Join-Path $pasta 'whitelist.json'), (ConvertTo-Json -InputObject @($wl) -Depth 3))
    [IO.File]::WriteAllText((Join-Path $pasta 'ops.json'), (ConvertTo-Json -InputObject @($ops) -Depth 3))
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
    }
    if (Test-Path $app) { Start-Process $app }
    Start-Process $driveUrl
    Write-Host ''
    Write-Host '1. Entre com a sua conta Google no Google Drive que abriu.'
    Write-Host "2. No navegador, abra a pasta 'minezada' e clique em 'Adicionar atalho ao Drive' > 'Meu Drive'."
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
    Set-Content $envFile -Encoding ascii @("RAM=$ram", 'SYNC_DIR=""', 'JAVA=java', 'DUCKDNS_TOKEN=')
}

$cfg = @{ RAM = '6G'; SYNC_DIR = ''; JAVA = 'java'; DUCKDNS_DOMAIN = 'minezada-mc'; DUCKDNS_TOKEN = ''; SEM_DRIVE = '' }
foreach ($l in Get-Content $envFile) {
    if ($l -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') { $cfg[$matches[1]] = $matches[2].Trim('"') }
}

# Pasta do Drive: acha sozinho; faltou, oferece instalar e configurar ("n" nao pergunta mais).
if (-not $cfg.SYNC_DIR) {
    $achado = Achar-Drive
    if (-not $achado -and $cfg.SEM_DRIVE -ne '1') { $achado = Configurar-Drive }
    if ($achado) {
        Write-Host "Pasta do Google Drive: $achado"
        $cfg.SYNC_DIR = $achado
        Set-Content $envFile -Encoding ascii (@(Get-Content $envFile | Where-Object { $_ -notmatch '^\s*SYNC_DIR\s*=' }) + "SYNC_DIR=`"$achado`"")
    }
}

# Token do DuckDNS mora na pasta do Drive (fora do git): quem tem o token no config.env grava la,
# e os outros hosts pegam de la sem precisar perguntar a ninguem.
if ($cfg.SYNC_DIR -and (Test-Path $cfg.SYNC_DIR)) {
    $tokenArq = Join-Path $cfg.SYNC_DIR 'duckdns.txt'
    if ($cfg.DUCKDNS_TOKEN) {
        if (-not (Test-Path $tokenArq)) { Set-Content $tokenArq -Encoding ascii $cfg.DUCKDNS_TOKEN }
    }
    elseif (Test-Path $tokenArq) { $cfg.DUCKDNS_TOKEN = (Get-Content $tokenArq -Raw).Trim() }
}

# 3. Java 21+ (NeoForge 1.21.1). Um Java 8/17 antigo no PATH tambem conta como faltando.
function Java-Ok($j) {
    $ErrorActionPreference = 'Continue'  # o java -version escreve no stderr; com 'Stop' o PS 5.1 aborta
    if (-not (Get-Command $j -ErrorAction SilentlyContinue)) { return $false }
    $v = (& $j -version 2>&1 | Out-String)
    return ([regex]::Match($v, 'version "(\d+)').Groups[1].Value -as [int]) -ge 21
}
if (-not (Java-Ok $cfg.JAVA)) {
    $temurin = { Get-ChildItem "$env:ProgramFiles\Eclipse Adoptium\jdk-25*\bin\java.exe" -ErrorAction SilentlyContinue | Select-Object -Last 1 }
    if (-not (& $temurin)) {
        Write-Host 'Instalando Java 25...'
        winget install --id EclipseAdoptium.Temurin.25.JDK -e --silent --accept-source-agreements --accept-package-agreements
    }
    $j = & $temurin
    if (-not ($j -and (Java-Ok $j.FullName))) { throw 'Java nao instalado. Veja docs/requisitos.md' }
    $cfg.JAVA = $j.FullName
}

# 4. Pack -> servidor.
$packs = @(Get-ChildItem (Join-Path $root 'modpack') -Filter *.mrpack -ErrorAction SilentlyContinue)
if ($packs.Count -ne 1) { throw "Precisa ter exatamente 1 arquivo .mrpack em modpack/ (achei $($packs.Count))." }

$exe = Join-Path $tools 'mrpack-install.exe'
if (-not (Test-Path $exe)) {
    Write-Host "Baixando mrpack-install $mrpackVersion..."
    New-Item -ItemType Directory -Force $tools | Out-Null
    $zip = Join-Path $tools 'mrpack-install.zip'
    Invoke-WebRequest "https://github.com/nothub/mrpack-install/releases/download/v$mrpackVersion/mrpack-install_${mrpackVersion}_windows_amd64.zip" -OutFile $zip
    # SHA-256 do checksums.txt oficial da release: so roda o binario se bater.
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne '91ceaf0843aa66dc2f001dc11d26d557871a507e67f4097306cad30da221e026') {
        Remove-Item $zip; throw 'Checksum do mrpack-install nao confere (download corrompido ou adulterado).'
    }
    Expand-Archive $zip $tools -Force
    Remove-Item $zip
}

# Idempotente: sem mudanca no pack, nao faz nada.
& $exe $packs[0].FullName --server-dir $server --server-file server.jar
if ($LASTEXITCODE) { throw 'mrpack-install falhou.' }

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
        # Extrai a parte e confere antes de mexer no mundo local ou pegar a trava: um arquivo corrompido
        # nao pode virar o mundo desta maquina (ele seria enviado por cima do bom no proximo stop).
        $novo = Join-Path $server '.mundo-novo'
        Remove-Item -Recurse -Force $novo -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force $novo | Out-Null
        & $tar -xzf $estado -C $novo
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
# Whitelist e admins: lista na pasta do Drive (vale para todos os hosts) ou, sem Drive, no servidor.
$lista = if ($sync) { Join-Path $sync 'jogadores.txt' } else { Join-Path $server 'jogadores.txt' }
try { Sincronizar-Whitelist $lista $server }
catch { Write-Warning "Falha ao atualizar a whitelist: $_" }

# 6. Rede: firewall, porta e endereco.
# Regra por porta (nao por programa): o aviso do Windows so libera o perfil de rede atual e nao repete.
if (-not (Get-NetFirewallRule -DisplayName 'minezin 25565' -ErrorAction SilentlyContinue)) {
    Write-Host "Liberando a porta $porta no firewall (o Windows vai pedir permissao de administrador)..."
    try {
        Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-Command',
            "New-NetFirewallRule -DisplayName 'minezin 25565' -Direction Inbound -Protocol TCP -LocalPort $porta -Action Allow -Profile Any"
    }
    catch { Write-Warning 'Firewall nao liberado: libere o Java quando o Windows perguntar.' }
}
# Roteador sem NAT loopback (ex.: Vivo) nao deixa quem esta na mesma casa entrar pelo endereco publico.
$ipLocal = try { (Find-NetRoute -RemoteIPAddress 8.8.8.8 | Where-Object IPAddress | Select-Object -First 1).IPAddress } catch { $null }
Write-Host "Na mesma casa: entre por localhost (nesta maquina) ou $ipLocal (outro computador)."
if (Porta-UPnP $true) {
    Write-Host "Porta $porta aberta via UPnP."
    # Redes de faculdade/empresa costumam liberar so 80/443 de saida: a 443 do roteador tambem leva ao servidor.
    if (Porta-UPnP $true $portaAlt) { Write-Host "Porta $portaAlt tambem aberta (para quem esta em rede que bloqueia a $porta)." }
}
else { Write-Host 'UPnP indisponivel: vale o redirecionamento manual do roteador (docs/requisitos.md).' }

$ddns = $null
if ($cfg.DUCKDNS_TOKEN) {
    $url = "https://www.duckdns.org/update?domains=$($cfg.DUCKDNS_DOMAIN)&token=$($cfg.DUCKDNS_TOKEN)"
    # Reaponta o nome para este host e repete a cada 5 min caso o IP mude durante a sessao.
    $ddns = Start-Job -ArgumentList $url {
        param($u)
        [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
        while ($true) { try { Invoke-RestMethod $u | Out-Null } catch {}; Start-Sleep 300 }
    }
    Write-Host "Endereco do servidor: $($cfg.DUCKDNS_DOMAIN).duckdns.org"
}

# Anuncia o servidor na rede local como o "Abrir para LAN" do jogo: quem esta na mesma rede ve
# "Minezada" sozinho em Multijogador, sem digitar IP.
$lan = Start-Job -ArgumentList $porta {
    param($p)
    $u = New-Object Net.Sockets.UdpClient
    $m = [Text.Encoding]::UTF8.GetBytes("[MOTD]Minezada[/MOTD][AD]$p[/AD]")
    while ($true) { try { [void]$u.Send($m, $m.Length, '224.0.2.60', 4445) } catch {}; Start-Sleep -Milliseconds 1500 }
}

# Impede o Windows de suspender enquanto o servidor roda (tela pode apagar).
Add-Type -Name Energia -Namespace Minezada -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);'
[void][Minezada.Energia]::SetThreadExecutionState(2147483649)  # 0x80000001 = ES_CONTINUOUS | ES_SYSTEM_REQUIRED (hex vira negativo no PS 5.1)

Push-Location $server
try {
    Write-Host "Iniciando servidor com $($cfg.RAM) de RAM. Digite 'stop' para desligar e salvar."
    # Flags do Aikar: coleta de lixo G1 ajustada para servidor de Minecraft (menos travadas).
    $flags = '-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1' -split ' '
    & $cfg.JAVA "-Xms$($cfg.RAM)" "-Xmx$($cfg.RAM)" @flags -jar server.jar nogui
}
finally {
    Pop-Location
    [void][Minezada.Energia]::SetThreadExecutionState(2147483648)  # 0x80000000 = volta ao normal
    if ($ddns) { Stop-Job $ddns; Remove-Job $ddns }
    Stop-Job $lan; Remove-Job $lan
    [void](Porta-UPnP $false)
    [void](Porta-UPnP $false $portaAlt)
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
        }
    }
}
