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
$eu = $env:COMPUTERNAME
$envFile = Join-Path $root 'config.env'

function Atualizar-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

# Abre (ou fecha) a porta no roteador por UPnP falando SOAP direto com ele. Nao usa o HNetCfg.NATUPnP
# do Windows porque ele nao funciona com a rede em perfil "Publica". Falha: vale o redirecionamento manual.
function Porta-UPnP([bool]$abrir) {
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
        $campos = "<NewRemoteHost></NewRemoteHost><NewExternalPort>$porta</NewExternalPort><NewProtocol>TCP</NewProtocol>"
        if ($abrir) { $campos += "<NewInternalPort>$porta</NewInternalPort><NewInternalClient>$ip</NewInternalClient><NewEnabled>1</NewEnabled><NewPortMappingDescription>minezada</NewPortMappingDescription><NewLeaseDuration>0</NewLeaseDuration>" }
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

# 2. config.env na primeira vez, com o que der para detectar.
if (-not (Test-Path $envFile)) {
    Write-Host 'Primeira vez nesta maquina: criando config.env.'
    $gb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $ram = if ($gb -ge 24) { '8G' } else { '6G' }
    $sync = Get-PSDrive -PSProvider FileSystem |
        ForEach-Object { "$($_.Root)Meu Drive\minezada"; "$($_.Root)My Drive\minezada" } |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($sync) { Write-Host "Pasta do Google Drive encontrada: $sync" }
    else { Write-Host 'Pasta minezada do Google Drive nao encontrada: o mundo fica so nesta maquina (ver docs/requisitos.md).' }
    $token = Read-Host 'Token do DuckDNS (peca ao dono do repo; Enter para pular)'
    Set-Content $envFile -Encoding ascii @("RAM=$ram", "SYNC_DIR=`"$sync`"", 'JAVA=java', "DUCKDNS_TOKEN=$token")
}

$cfg = @{ RAM = '6G'; SYNC_DIR = ''; JAVA = 'java'; DUCKDNS_DOMAIN = 'minezada-mc'; DUCKDNS_TOKEN = '' }
foreach ($l in Get-Content $envFile) {
    if ($l -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') { $cfg[$matches[1]] = $matches[2].Trim('"') }
}

# 3. Java.
if (-not (Get-Command $cfg.JAVA -ErrorAction SilentlyContinue)) {
    Write-Host 'Instalando Java 25...'
    winget install --id EclipseAdoptium.Temurin.25.JDK -e --silent --accept-source-agreements --accept-package-agreements
    Atualizar-Path
    if (-not (Get-Command $cfg.JAVA -ErrorAction SilentlyContinue)) { throw 'Java nao instalado. Veja docs/requisitos.md' }
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
Copy-Item (Join-Path $root 'server-config\*') $server -Force

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
    # shortcut: a trava depende da nuvem ja ter sincronizado; dois hosts iniciando no mesmo minuto podem passar os dois.
    Set-Content $lock $eu
    # Trava ja era desta maquina = ultima sessao caiu sem enviar; o mundo local e o mais novo.
    if ($dono -ne $eu -and (Test-Path $estado)) {
        Write-Host 'Baixando mundo da pasta sincronizada...'
        $w = Join-Path $server 'world'
        if (Test-Path $w) {
            Remove-Item -Recurse -Force "$w.bak" -ErrorAction SilentlyContinue
            Rename-Item $w 'world.bak'
        }
        & $tar -xzf $estado -C $server
        if ($LASTEXITCODE) { throw 'Falha ao extrair o mundo.' }
    }
}

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
if (Porta-UPnP $true) { Write-Host "Porta $porta aberta via UPnP." }
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

# Impede o Windows de suspender enquanto o servidor roda (tela pode apagar).
Add-Type -Name Energia -Namespace Minezada -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);'
[void][Minezada.Energia]::SetThreadExecutionState(2147483649)  # 0x80000001 = ES_CONTINUOUS | ES_SYSTEM_REQUIRED (hex vira negativo no PS 5.1)

Push-Location $server
try {
    Write-Host "Iniciando servidor com $($cfg.RAM) de RAM. Digite 'stop' para desligar e salvar."
    & $cfg.JAVA "-Xms$($cfg.RAM)" "-Xmx$($cfg.RAM)" -jar server.jar nogui
}
finally {
    Pop-Location
    [void][Minezada.Energia]::SetThreadExecutionState(2147483648)  # 0x80000000 = volta ao normal
    if ($ddns) { Stop-Job $ddns; Remove-Job $ddns }
    [void](Porta-UPnP $false)
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
