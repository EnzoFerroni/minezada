# Gera modpack/pack (packwiz, usado pelo jogo e pelo servidor), o zip do Prism e a lista de docs/mods.md a partir
# de modpack/mods.txt, resolvendo versoes e dependencias obrigatorias no Modrinth para o loader e a versao abaixo.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/montar-pack.ps1 (Mac: pwsh scripts/montar-pack.ps1) [-Versao 1.0.0] [-Atualizar]
# Versoes fixas: cada mod repete a versao do modpack/pack atual (o link de cada arquivo tem o id da versao); mod novo
# pega a mais nova. -Atualizar busca a versao mais nova de todos (revise a lista de mudancas antes do push).
param([string]$Versao = (Get-Date -Format 'yyyy.MM.dd'), [switch]$Atualizar)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'

$mc = '1.21.1'
$loader = 'neoforge'
$root = Split-Path $PSScriptRoot -Parent
$api = 'https://api.modrinth.com/v2'
$packUrl = 'https://raw.githubusercontent.com/EnzoFerroni/minezada/main/modpack/pack/pack.toml'
$servidor = 'minezada.dpdns.org'  # tunel da Cloudflare: o TXT do dominio manda o Modflared para mc.minezada.dpdns.org
$tunel = 'molecule-spindle.tun.ply.gg'  # playit: endereco fixo do tunel (playit-endereco.txt no Drive)
$h = @{ 'User-Agent' = 'minezada-modpack-builder/1.0' }

# Le como UTF-8 (o PS 5.1 decodifica como Latin-1 e quebra emoji/acento) e achata arrays JSON.
function Get-Api($path) {
    $r = Invoke-WebRequest "$api/$path" -Headers $h -UseBasicParsing
    @([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ }
}

$filtroMc = 'game_versions=' + [uri]::EscapeDataString("[`"$mc`"]")
$filtro = 'loaders=' + [uri]::EscapeDataString("[`"$loader`"]") + "&$filtroMc"
$pastas = @{ mod = 'mods'; resourcepack = 'resourcepacks'; shader = 'shaderpacks'; datapack = 'moonlight-global-datapacks' }
# Datapacks (loader "datapack" no Modrinth): o Moonlight carrega a pasta global em todo mundo do servidor. O pacote
# de recursos que vem junto (required-resource-pack) vai para o jogo como "<slug>-recursos", ja ligado.
$datapacks = @('bubblellaneous')
# So de servidor mesmo que o Modrinth aceite no cliente: o Chunky no jogo faz o Distant Horizons chamar a
# API dele sem servidor rodando (crash ao entrar no mundo).
$soServidor = @('chunky')
# Opcional no servidor pelo Modrinth, mas fica so no jogo: no servidor o Distant Horizons geraria terreno
# distante para todos (pesado com Terralith/Tectonic num PC de casa).
$soCliente = @('distanthorizons')
# Opcionais: o packwiz mostra uma janela na primeira abertura para cada um marcar (vem desmarcado). O Iris
# reserva as texturas do Distant Horizons so por ele estar instalado, e no Mac (16 texturas) o shader nao abre.
$opcionais = @{ 'distanthorizons' = 'Ver muito mais longe (montanhas no horizonte). Funciona junto com shader. No Mac ele fica desligado.' }
# Pacotes de recursos que ja vem ligados, nesta ordem (o ultimo tem prioridade:
# Fresh Animations em cima para os mobs). O jogar liga os desta lista ate em quem ja tinha options.txt.
$rpLigados = @('fast-better-grass', 'simple-grass-flowers', 'better-leaves',
    '3d-crops', 'better-lanterns', 'cubic-sun-moon', 'fresh-waystones-texture', 'low-shield-pack', 'low-on-fire',
    'fresh-animations', 'fresh-animations-extensions', 'bubblellaneous-recursos')
# Versao presa (id da versao no Modrinth), vale ate com -Atualizar.
# Accessories 1.1.0-beta.53: minimo que o Hamster aceita. O Aether embute a beta.48, que impede o
# servidor de abrir; a avulsa tem prioridade sobre a embutida.
# CustomSkinLoader 14.21.1-ForgeV3: testado no NeoForge 1.21.1; a Universal 15.x derruba o jogo (MCCustomSkinLoader#387).
$presas = @{ 'accessories' = 'Fb55Fgjz'; 'customskinloader' = '9B1Mb9IZ' }
# Dependencias que o jar exige mas a versao no Modrinth nao declara (ids de projeto do Modrinth).
# Hamster 3.7.0: architectury, geckolib, fzzy-config, patchouli e accessories (ver acima).
$depsExtras = @{ 'adorable-hamster-pets' = @('lhGA9TYQ', '8BmcQJ2H', 'hYykXjDp', 'nU0bVIaL', 'jtmvUHXj') }
$linhas = Get-Content (Join-Path $root 'modpack/mods.txt') -Encoding UTF8
$pedidos = foreach ($l in $linhas) { if ($l -match '^\s*((?:cf:)?[a-z0-9_-]+)\s*\|') { $matches[1] } }

# Mods do CurseForge ("cf:<id>" no mods.txt): so entram se o autor libera download por outros programas
# (allowModDistribution), para o packwiz baixar sozinho como os do Modrinth. Dependencias obrigatorias deles
# precisam estar no mods.txt (o script avisa). Chave da API: CURSEFORGE_KEY ou curseforge.txt na pasta do Drive.
$cfPedidos = @($pedidos | Where-Object { $_ -like 'cf:*' }); $pedidos = @($pedidos | Where-Object { $_ -notlike 'cf:*' })
function Get-Cf($path) {
    if (-not $script:cfKey) {
        $script:cfKey = $env:CURSEFORGE_KEY
        $sync = if (Test-Path (Join-Path $root 'config.env')) { (Select-String (Join-Path $root 'config.env') -Pattern '^SYNC_DIR="?(.*?)"?\s*$' | Select-Object -First 1).Matches.Groups[1].Value }
        if (-not $script:cfKey -and $sync -and (Test-Path (Join-Path $sync 'curseforge.txt'))) { $script:cfKey = (Get-Content (Join-Path $sync 'curseforge.txt') -Raw).Trim() }
        if (-not $script:cfKey) { throw 'Mod do CurseForge no mods.txt e sem chave da API (CURSEFORGE_KEY ou curseforge.txt no Drive)' }
    }
    $r = Invoke-WebRequest "https://api.curseforge.com/v1/$path" -Headers @{ 'x-api-key' = $script:cfKey; 'User-Agent' = $h['User-Agent'] } -UseBasicParsing
    ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json).data
}

# Pack anterior (modpack/pack): lista de arquivos (para mostrar o que mudou) e a versao de cada projeto (para
# repetir; o link de cada arquivo tem o id do projeto e da versao).
$antes = @(); $fixas = @{}
$neoAntes = if (Test-Path (Join-Path $root 'modpack/pack/pack.toml')) { [regex]::Match((Get-Content (Join-Path $root 'modpack/pack/pack.toml') -Raw), 'neoforge = "(.+?)"').Groups[1].Value }
foreach ($m in Get-ChildItem (Join-Path $root 'modpack/pack') -Filter *.pw.toml -Recurse -ErrorAction SilentlyContinue) {
    $c = Get-Content $m.FullName -Raw -Encoding UTF8
    if ($c -match '(?m)^filename = "(.+)"') { $antes += "$($m.Directory.Name)/$($matches[1])" }
    if ($c -match '/data/([^/]+)/versions/([^/]+)/') { $fixas[$matches[1]] = $matches[2] }
    if ($c -match '(?m)^project-id = (\d+)\s+file-id = (\d+)') { $fixas["cf:$($matches[1])"] = $matches[2] }
}
$vistos = @{}; $projs = [ordered]@{}; $info = @{}; $pwMods = @()
$fila = New-Object System.Collections.Queue
$pedidos | ForEach-Object { $fila.Enqueue($_) }
while ($fila.Count) {
    $id = $fila.Dequeue()
    $p = Get-Api "project/$id"
    if ($vistos[$p.id]) { continue }
    $vistos[$p.id] = $true
    $dp = $p.slug -in $datapacks
    $pasta = $pastas[$(if ($dp) { 'datapack' } else { $p.project_type })]
    if (-not $pasta) { throw "$($p.slug): tipo $($p.project_type) nao suportado" }
    if ($presas[$p.slug]) { $v = Get-Api "version/$($presas[$p.slug])" }
    elseif ($fixas[$p.id] -and -not $Atualizar) { $v = Get-Api "version/$($fixas[$p.id])" }
    else {
        # Pacotes de recursos e shaders nao tem loader NeoForge: filtra so pela versao do jogo.
        $vs = Get-Api "project/$($p.id)/version?$(if ($p.project_type -eq 'mod' -and -not $dp) { $filtro } else { $filtroMc })"
        $v = ($vs | Where-Object version_type -eq 'release' | Select-Object -First 1)
        if (-not $v) { $v = $vs | Select-Object -First 1 }
    }
    if (-not $v) { throw "$($p.slug): sem versao para $loader $mc" }
    $f = $v.files | Where-Object primary | Select-Object -First 1
    if (-not $f) { $f = $v.files[0] }
    $deps = @($v.dependencies | Where-Object { $_.dependency_type -eq 'required' -and $_.project_id } | ForEach-Object project_id) + @($depsExtras[$p.slug] | Where-Object { $_ })
    $deps | ForEach-Object { $fila.Enqueue($_) }
    $projs[$p.id] = [pscustomobject]@{ p = $p; v = $v; f = $f; pasta = $pasta; deps = $deps
        cliente = $p.client_side -ne 'unsupported' -and $p.slug -notin $soServidor -and -not $dp; servidor = $p.server_side -ne 'unsupported' -and $p.slug -notin $soCliente }
    $rf = if ($dp) { $v.files | Where-Object file_type -eq 'required-resource-pack' | Select-Object -First 1 }
    if ($rf) {
        $projs["$($p.id)-recursos"] = [pscustomobject]@{ p = [pscustomobject]@{ slug = "$($p.slug)-recursos"; title = "$($p.title) (recursos)"; icon_url = $p.icon_url }
            v = $v; f = $rf; pasta = 'resourcepacks'; deps = @(); cliente = $true; servidor = $false }
    }
    Write-Host ('{0,-30} {1}' -f $p.slug, $v.version_number)
}
# Dependencia do CurseForge que o pack ja traz pelo Modrinth (id do CurseForge = id do Modrinth).
$cfNoModrinth = @{ '419699' = 'lhGA9TYQ'; '531761' = 'MBAkmtvl' }  # Architectury API, Balm
$cfIds = @($cfPedidos | ForEach-Object { $_.Substring(3) }) + @($cfNoModrinth.Keys | Where-Object { $projs[$cfNoModrinth[$_]] })
foreach ($chave in $cfPedidos) {
    $cid = $chave.Substring(3)
    $m = Get-Cf "mods/$cid"
    if (-not $m.allowModDistribution) { throw "$($m.name) (cf:$cid): o autor nao libera download por outros programas; cada jogador teria que baixar na mao" }
    $cf = if ($fixas[$chave] -and -not $Atualizar) { Get-Cf "mods/$cid/files/$($fixas[$chave])" }
        else { Get-Cf "mods/$cid/files?gameVersion=$mc&modLoaderType=6&pageSize=50" | Where-Object releaseType -eq 1 | Select-Object -First 1 }
    if (-not $cf) { throw "$($m.name) (cf:$cid): sem arquivo release para $loader $mc" }
    $faltam = @($cf.dependencies | Where-Object { $_.relationType -eq 3 -and "$($_.modId)" -notin $cfIds } | ForEach-Object modId)
    if ($faltam) { throw "$($m.name) (cf:$cid) precisa de cf:$($faltam -join ', cf:') no mods.txt (ou do mesmo mod pelo Modrinth)" }
    $url = if ($cf.downloadUrl) { $cf.downloadUrl } else { "https://edge.forgecdn.net/files/$([math]::Floor($cf.id / 1000))/$($cf.id % 1000)/$([uri]::EscapeDataString($cf.fileName))" }
    $projs[$chave] = [pscustomobject]@{ p = [pscustomobject]@{ slug = $m.slug; title = $m.name; icon_url = $m.logo.thumbnailUrl; chave = $chave; link = $m.links.websiteUrl; cf = "$cid $($cf.id)" }
        v = [pscustomobject]@{ version_number = $cf.displayName }; f = [pscustomobject]@{ filename = $cf.fileName; url = $url; hashes = @{ sha1 = ($cf.hashes | Where-Object algo -eq 1).value } }
        pasta = 'mods'; deps = @(); cliente = $true; servidor = $true }
    Write-Host ('{0,-30} {1} (CurseForge)' -f $m.slug, $cf.displayName)
}

# Dependencia vai para todo lado onde algum mod que precisa dela esta: o Modrinth marca algumas como
# "so servidor" (ex: Lithostitched) mesmo quando o mod que depende delas tambem roda no cliente.
do {
    $mudou = $false
    foreach ($x in $projs.Values) {
        foreach ($d in $x.deps) {
            $y = $projs[$d]
            if ($x.cliente -and -not $y.cliente) { $y.cliente = $true; $mudou = $true }
            if ($x.servidor -and -not $y.servidor) { $y.servidor = $true; $mudou = $true }
        }
    }
} while ($mudou)

foreach ($x in $projs.Values) {
    $p = $x.p; $v = $x.v; $f = $x.f
    $info[$(if ($p.chave) { $p.chave } else { $p.slug })] = [pscustomobject]@{ titulo = $p.title; versao = $v.version_number; servidor = $x.servidor; icone = $p.icon_url
        link = $(if ($p.link) { $p.link } else { "https://modrinth.com/mod/$($p.slug)" }) }
    $lado = if (-not $x.servidor) { 'client' } elseif (-not $x.cliente) { 'server' } else { 'both' }
    $pwMods += [pscustomobject]@{ slug = $p.slug; titulo = $p.title; arquivo = $f.filename; url = $f.url; sha1 = $f.hashes.sha1; lado = $lado; pasta = $x.pasta; cf = $p.cf }
}

# NeoForge mais novo que o Prism ja conhece: o meta dele atrasa algumas horas em relacao ao maven,
# e uma versao que ainda nao esta la faz a instancia falhar ao abrir.
$metaNeo = [Text.Encoding]::UTF8.GetString((Invoke-WebRequest 'https://meta.prismlauncher.org/v1/net.neoforged/index.json' -UseBasicParsing).RawContentStream.ToArray()) | ConvertFrom-Json
$neo = ($metaNeo.versions | Where-Object { $_.version -like "$($mc.Substring(2)).*" } | Select-Object -First 1).version  # "21.1.*"
# Versao fixa como a dos mods (trocar o NeoForge faz o Prism de quem abre sem o atalho perguntar "Update"). -Atualizar busca a mais nova.
if ($neoAntes -and -not $Atualizar -and ($metaNeo.versions | Where-Object version -eq $neoAntes)) { $neo = $neoAntes }
if (-not $neo) { throw "Nenhum NeoForge para $mc no meta do Prism" }
$tmp = Join-Path ([IO.Path]::GetTempPath()) "minezada-pack-$PID"
New-Item -ItemType Directory -Force $tmp | Out-Null

# O que mudou desde o pack anterior: revisar antes do push (versao nova de mod = codigo novo no PC de todos).
$depois = @($pwMods | ForEach-Object { "$($_.pasta)/$($_.arquivo)" })
$saiu = @($antes | Where-Object { $_ -notin $depois }); $entrou = @($depois | Where-Object { $_ -notin $antes })
Write-Host "`nMudancas desde o pack anterior: $(if (-not ($saiu + $entrou)) { 'nenhuma' })"
$saiu | ForEach-Object { Write-Host "  - $_" }
$entrou | ForEach-Object { Write-Host "  + $_" }

# Formato packwiz em modpack/pack: o Prism le pelo link raw do GitHub a cada abertura e sincroniza os mods.
$utf8 = New-Object Text.UTF8Encoding $false
function Escrever($caminho, $texto) { [IO.File]::WriteAllText($caminho, $texto.Replace("`r`n", "`n"), $utf8) }
function Sha256($caminho) { (Get-FileHash $caminho -Algorithm SHA256).Hash.ToLower() }
function Toml($s) { '"' + $s.Replace('\', '\\').Replace('"', '\"') + '"' }
$pw = Join-Path $root 'modpack/pack'
if (Test-Path $pw) { Remove-Item -Recurse -Force $pw }
$pastas.Values | ForEach-Object { New-Item -ItemType Directory -Force (Join-Path $pw $_) | Out-Null }
$idx = "hash-format = `"sha256`"`n"
# Ordem fixa (ordinal, igual no Windows e no Mac): a ordem da fila do Modrinth muda e trocava o hash do pack sem mudar mod.
# (Array.Sort com chaves e itens nao move os itens no PS 5.1: por isso o dicionario ordenado.)
$ordenado = New-Object 'Collections.Generic.SortedDictionary[string,object]' ([StringComparer]::Ordinal)
foreach ($m in $pwMods) { $ordenado["$($m.pasta)/$($m.slug)"] = $m }
$pwMods = @($ordenado.Values)
foreach ($m in $pwMods) {
    $rel = "$($m.pasta)/$($m.slug).pw.toml"  # o packwiz instala o arquivo na pasta do metafile
    $opc = if ($opcionais[$m.slug]) { "`n[option]`noptional = true`ndefault = false`ndescription = $(Toml $opcionais[$m.slug])`n" } else { '' }
    Escrever (Join-Path $pw $rel) "name = $(Toml $m.titulo)`nfilename = $(Toml $m.arquivo)`nside = `"$($m.lado)`"`n`n[download]`nurl = $(Toml $m.url)`nhash-format = `"sha1`"`nhash = `"$($m.sha1)`"`n$opc$(if ($m.cf) { $c = $m.cf.Split(' '); "`n[update.curseforge]`nproject-id = $($c[0])`nfile-id = $($c[1])`n" })"
    $idx += "`n[[files]]`nfile = `"$rel`"`nhash = `"$(Sha256 (Join-Path $pw $rel))`"`nmetafile = true`n"
}
# Arquivos soltos (perfis de grafico etc) de modpack/arquivos vao para o jogo de cada um.
# preserve = so cria se nao existir: quem recalibrar um perfil nao perde o ajuste na proxima abertura.
$soltos = Join-Path $root 'modpack/arquivos'
if (Test-Path $soltos) {
    # Ordem ordinal: no Linux (CI) o Get-ChildItem lista em outra ordem e o hash do index mudaria.
    $rels = [string[]]@(Get-ChildItem $soltos -Recurse -File | ForEach-Object { $_.FullName.Substring($soltos.Length + 1).Replace('\', '/') })
    [Array]::Sort($rels, [StringComparer]::Ordinal)
    foreach ($rel in $rels) {
        $a = Get-Item -LiteralPath (Join-Path $soltos $rel)
        $dest = Join-Path $pw $rel
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Copy-Item $a.FullName $dest
        # minezada.ps1/.sh (rodam antes de abrir) e as regras do VeinMiner (mundo de um jogador so) sempre atualizam: sem preserve.
        $pres = if ($rel -like 'minezada.*' -or $rel -like 'config/Veinminer/*') { '' } else { "preserve = true`n" }
        $idx += "`n[[files]]`nfile = $(Toml $rel)`nhash = `"$(Sha256 $dest)`"`n$pres"
    }
}
# servers.dat (NBT sem compressao): os enderecos do servidor ja na lista do Multiplayer. Vai pelo packwiz
# sem preserve, entao todo mundo recebe a lista nova a cada abertura (servidor adicionado a mao some).
# Principal: Cloudflare (HTTPS na 443, passa em rede de faculdade). Reserva: playit (playit-endereco.txt no Drive).
function NbtStr($ms, $s) { $b = [Text.Encoding]::UTF8.GetBytes($s); $ms.WriteByte($b.Length -shr 8); $ms.WriteByte($b.Length -band 255); $ms.Write($b, 0, $b.Length) }
$entradas = @(@('Minezada', $servidor), @('Minezada (playit)', $tunel), @('Minezada (neste computador)', '127.0.0.1'))
$ms = New-Object IO.MemoryStream
$ms.WriteByte(10); NbtStr $ms ''                                                                 # compound raiz
$ms.WriteByte(9); NbtStr $ms 'servers'; $ms.WriteByte(10); $ms.Write([byte[]](0, 0, 0, $entradas.Count), 0, 4)  # lista de compounds
foreach ($e in $entradas) {
    $ms.WriteByte(8); NbtStr $ms 'name'; NbtStr $ms $e[0]
    $ms.WriteByte(8); NbtStr $ms 'ip'; NbtStr $ms $e[1]
    $ms.WriteByte(0)                                                                             # fim do servidor
}
$ms.WriteByte(0)                                                                                 # fim da raiz
$serversDat = $ms.ToArray()
[IO.File]::WriteAllBytes((Join-Path $pw 'servers.dat'), $serversDat)
$idx += "`n[[files]]`nfile = `"servers.dat`"`nhash = `"$(Sha256 (Join-Path $pw 'servers.dat'))`"`n"
Escrever (Join-Path $pw 'index.toml') $idx
Escrever (Join-Path $pw 'pack.toml') "name = `"Minezada`"`nversion = `"$Versao`"`npack-format = `"packwiz:1.1.0`"`n`n[index]`nfile = `"index.toml`"`nhash-format = `"sha256`"`nhash = `"$(Sha256 (Join-Path $pw 'index.toml'))`"`n`n[versions]`nminecraft = `"$mc`"`nneoforge = `"$neo`"`n"

# Instancia do Prism: arrastar o zip no Prism e jogar. O pre-launch roda o packwiz, que baixa/atualiza os mods.
# shortcut: a versao do NeoForge fica fixa na instancia; se o pack trocar de NeoForge, os jogadores reimportam o zip.
# packwiz-installer com versao fixa e SHA-256 no zip, sem se atualizar sozinho a cada abertura: um release
# adulterado no GitHub do packwiz nao chega nos jogadores. Atualizar: trocar url e hash.
$jars = @(@('packwiz-installer-bootstrap.jar', 'https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar', 'a8fbb24dc604278e97f4688e82d3d91a318b98efc08d5dbfcbcbcab6443d116c'),
    @('packwiz-installer.jar', 'https://github.com/packwiz/packwiz-installer/releases/download/v0.5.14/packwiz-installer.jar', 'c9f646908d340d84773948a9a7d98bc1dae250d35e1016dc6e2b8459760b5598'))
$inst = Join-Path $tmp 'prism'
New-Item -ItemType Directory -Force (Join-Path $inst '.minecraft') | Out-Null
foreach ($j in $jars) {
    $arq = Join-Path $root "tools/$($j[0])"
    if (-not (Test-Path $arq)) { New-Item -ItemType Directory -Force (Split-Path $arq) | Out-Null; Invoke-WebRequest $j[1] -OutFile $arq }
    if ((Sha256 $arq) -ne $j[2]) { Remove-Item $arq; throw "$($j[0]): checksum nao confere (download corrompido ou adulterado)." }
    Copy-Item $arq (Join-Path $inst '.minecraft')
}
# Scripts de antes de abrir: o jogar troca o PreLaunchCommand por eles (minezada.ps1 no Windows, .sh no Mac).
Copy-Item (Join-Path $soltos 'minezada.ps1'), (Join-Path $soltos 'minezada.sh') (Join-Path $inst '.minecraft')
# LowMemWarning=false: o aviso de pouca RAM livre do Prism cancela o jogo se a pessoa aperta Esc ou Nao.
# Sem JoinServerOnLaunch: o jogo abre no menu e a lista de servidores mostra quais estao no ar.
# PreLaunchCommand do zip serve para quem importa o zip no Prism a mao; o jogar troca pelo minezada.ps1/.sh.
Escrever (Join-Path $inst 'instance.cfg') "[General]`nInstanceType=OneSix`nname=Minezada`nOverrideCommands=true`nPreLaunchCommand=`"`$INST_JAVA`" -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -t 0 $packUrl`nOverrideMemory=true`nMinMemAlloc=1024`nMaxMemAlloc=4096`nLowMemWarning=false`n"
[IO.File]::WriteAllBytes((Join-Path $inst '.minecraft/servers.dat'), $serversDat)
# Opcoes iniciais (o jogo completa o resto); o jogar so copia se o jogador ainda nao tiver.
# Pacotes de $rpLigados ja vem ligados. As quatro ultimas opcoes pulam as telas de primeira abertura:
# acessibilidade, tutorial de movimento e avisos de multiplayer.
# Pacotes embutidos em mods (ids do jogo, conferidos no log do cliente): ficam por cima dos de arquivo. Id desconhecido o
# jogo tira da lista sem erro. Emissivity do Deep Aether so existe com o mod aether_emissivity, que o pack nao tem.
$rpMods = @('naturalist:custom_spawn_eggs', 'supplementaries:darker_ropes', 'builtin/overrides/deep_aether_additional_assets', 'builtin/client/deep_aether_tooltips')
# Feitos para um Minecraft mais novo: o jogo so os mantem se constarem em incompatibleResourcePacks.
$rpIncompativeis = @('3d-crops')
$rp = ($rpLigados | ForEach-Object { $s = $_; $m = $pwMods | Where-Object slug -eq $s; if (-not $m) { throw "Pacote ligado $s nao esta no pack" }; ",`"file/$($m.arquivo)`"" }) -join ''
$rp += ($rpMods | ForEach-Object { ",`"$_`"" }) -join ''
$rpInc = (@($rpIncompativeis | ForEach-Object { $s = $_; $m = $pwMods | Where-Object slug -eq $s; "`"file/$($m.arquivo)`"" }) + '"builtin/client/deep_aether_tooltips"') -join ','
Escrever (Join-Path $inst '.minecraft/options.txt') "lang:pt_br`nrenderDistance:10`nsimulationDistance:8`nresourcePacks:[`"vanilla`"$rp]`nincompatibleResourcePacks:[$rpInc]`nonboardAccessibility:false`ntutorialStep:none`njoinedFirstServer:true`nskipMultiplayerWarning:true`n"
Escrever (Join-Path $inst 'mmc-pack.json') "{`"formatVersion`":1,`"components`":[{`"uid`":`"net.minecraft`",`"version`":`"$mc`",`"important`":true},{`"uid`":`"net.neoforged`",`"version`":`"$neo`"}]}`n"
$zipPrism = Join-Path $root 'modpack/minezada-prism.zip'
if (Test-Path $zipPrism) { Remove-Item $zipPrism }
# Zip montado a mao: no PS 5.1 tanto Compress-Archive quanto ZipFile gravam "\" e o Prism no Mac nao entende.
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$za = [IO.Compression.ZipFile]::Open($zipPrism, 'Create')
foreach ($arq in Get-ChildItem $inst -Recurse -File -Force) {
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($za, $arq.FullName, $arq.FullName.Substring($inst.Length + 1).Replace('\', '/'))
}
$za.Dispose()
Remove-Item -Recurse -Force $tmp

# Vitrine de mods em docs/mods.md, entre os marcadores: indice das categorias e cada mod recolhido (icone,
# nome e a primeira frase da descricao do mods.txt; ao clicar, o resto, a imagem, o link e a versao).
$ancora = { param($t) ($t.ToLower() -replace '[^\p{L}\p{Nd} -]', '') -replace ' ', '-' }  # mesmo id que o GitHub da ao titulo
$cats = @($linhas | Where-Object { $_ -match '^## ' } | ForEach-Object { $_.Substring(3).Trim() })
$md = @("<sub>Minecraft $mc · NeoForge $neo · pack ``$Versao`` · $($info.Count) mods. Gerado por ``scripts/montar-pack.ps1``.</sub>",
    '', (($cats | ForEach-Object { $nome = ($_ -split ' [(]')[0]; $id = & $ancora $_; "[$nome](#$id)" }) -join ' · '))
# Fotos escolhidas por scripts/fotos.ps1 (modpack/fotos.txt; vazio = so o icone).
$fotos = @{}
$arqFotos = Join-Path $root 'modpack/fotos.txt'
if (Test-Path $arqFotos) { foreach ($l in Get-Content $arqFotos -Encoding UTF8) { if ($l -match '^\s*([a-z0-9_-]+)\s*\|\s*(.*?)\s*$') { $fotos[$matches[1]] = $matches[2] } } }
# Cada categoria e uma grade de cartoes (3 por linha): foto, icone com nome (link) e a primeira frase.
$cartoes = @()
$fechar = { if ($cartoes) { $script:md += '<table>'; for ($k = 0; $k -lt $cartoes.Count; $k += 3) { $script:md += '<tr>' + (($cartoes[$k..([Math]::Min($k + 2, $cartoes.Count - 1))]) -join '') + '</tr>' }; $script:md += '</table>' }; $script:cartoes = @() }
foreach ($l in $linhas) {
    if ($l -match '^## (.+)') { & $fechar; $md += '', "## $($matches[1])", '' }
    elseif ($l -match '^\s*((?:cf:)?[a-z0-9_-]+)\s*\|\s*(.+)$') {
        $slug = $matches[1]; $desc = $matches[2].Trim(); $i = $info[$slug]
        $p = $desc.IndexOf('. ')
        $resumo = if ($p -gt 0) { $desc.Substring(0, $p) } else { $desc.TrimEnd('.') }
        $link = $i.link
        $topo = if ($fotos[$slug]) { "<a href=`"$link`"><img src=`"$($fotos[$slug])`" width=`"100%`"></a>" } elseif ($i.icone) { "<a href=`"$link`"><img src=`"$($i.icone)`" width=`"64`"></a>" } else { '' }
        $ico = if ($i.icone) { "<img src=`"$($i.icone)`" width=`"16`"> " } else { '' }
        $cartoes += "<td width=`"33%`" valign=`"top`">$topo<br>$ico<a href=`"$link`"><b>$($i.titulo)</b></a><br><sub>$resumo</sub></td>"
    }
}
& $fechar
$extras = $info.Keys | Where-Object { $_ -notin $pedidos -and $_ -notin $cfPedidos } | Sort-Object
if ($extras) { $md += '', '## Dependências (entram sozinhas)', '', (($extras | ForEach-Object { "[$($info[$_].titulo)]($($info[$_].link))" }) -join ' · ') }
$doc = Join-Path $root 'docs/mods.md'
$txt = [IO.File]::ReadAllText($doc)
if ($txt -notmatch '<!-- mods:inicio -->') { throw 'docs/mods.md sem os marcadores <!-- mods:inicio --> / <!-- mods:fim -->' }
$novo = [regex]::Replace($txt, '(?s)(<!-- mods:inicio -->).*?(<!-- mods:fim -->)', { param($m) "$($m.Groups[1].Value)`n$($md -join "`n")`n$($m.Groups[2].Value)" })
[IO.File]::WriteAllText($doc, $novo, (New-Object Text.UTF8Encoding $false))

Write-Host "`n$($pwMods.Count) arquivos, NeoForge $neo -> modpack/pack"

# Confere as dependencias que cada jar declara (META-INF/neoforge.mods.toml, inclusive os jars embutidos em
# META-INF/jarjar), no jogo e no servidor: o Modrinth nem sempre lista o que o jar exige. Jars em tools/jars.
$cache = Join-Path $root 'tools/jars'
New-Item -ItemType Directory -Force $cache | Out-Null
function Ler-Toml($texto, $jarVer) {
    $mods = @(); $deps = @(); $atual = $null; $multi = $false
    foreach ($l in $texto -split "`r?`n") {
        # Pula strings de varias linhas (descricoes).
        if (([regex]::Matches($l, "'''|`"`"`"")).Count % 2) { $multi = -not $multi; continue }
        if ($multi) { continue }
        if ($l -match '^\s*\[\[mods\]\]') { $atual = @{}; $mods += $atual }
        elseif ($l -match '^\s*\[\[dependencies\.([^\]]+)\]\]') { $atual = @{ dono = $matches[1].Trim('"') }; $deps += $atual }
        elseif ($l -match '^\s*\[') { $atual = $null }
        elseif ($atual -and $l -match '^\s*([A-Za-z]+)\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s#]+))') {
            $atual[$matches[1]] = "$($matches[2])$($matches[3])$($matches[4])"
        }
    }
    foreach ($m in $mods) { if ($m.version -eq '${file.jarVersion}' -or -not $m.version) { $m.version = $jarVer } }
    , @($mods, $deps)
}
function Ler-Jar($zip, $saida, $embutido) {
    $man = $zip.GetEntry('META-INF/MANIFEST.MF'); $jarVer = '0'
    if ($man) { $r = New-Object IO.StreamReader($man.Open()); if ($r.ReadToEnd() -match 'Implementation-Version:\s*(\S+)') { $jarVer = $matches[1] }; $r.Dispose() }
    $e = $zip.GetEntry('META-INF/neoforge.mods.toml')
    if ($e) { $r = New-Object IO.StreamReader($e.Open()); $t = Ler-Toml $r.ReadToEnd() $jarVer; [void]$saida.Add(@($t[0], $t[1], $embutido)); $r.Dispose() }
    foreach ($j in @($zip.Entries | Where-Object { $_.FullName -like 'META-INF/jarjar/*.jar' })) {
        $ms = New-Object IO.MemoryStream; $s = $j.Open(); $s.CopyTo($ms); $s.Dispose()
        $z2 = New-Object IO.Compression.ZipArchive($ms); Ler-Jar $z2 $saida $true; $z2.Dispose()
    }
}
# Compara versoes como o Maven (o NeoForge usa as mesmas regras): numeros por valor, alpha < beta < rc < final.
# O que vem depois de "+" (ex: 1.0.82+mc1.21.1) e so informacao e nao conta.
function Comparar-Versao($a, $b) {
    # Como no Maven, o que vem antes do primeiro "-" decide primeiro: 1.21.1-3.8.5 > 1.21-2.29.17.
    $pa = (("$a" -split '\+')[0] -split '-', 2)[0]; $pb = (("$b" -split '\+')[0] -split '-', 2)[0]
    if ($pa -ne $pb -and $pa -match '^\d+(\.\d+)*$' -and $pb -match '^\d+(\.\d+)*$' -and ("$a$b" -match '-')) {
        $c = Comparar-Versao $pa $pb; if ($c) { return $c }
    }
    $ta = @([regex]::Matches(("$a" -split '\+')[0].ToLower(), '\d+|[a-z]+') | ForEach-Object Value)
    $tb = @([regex]::Matches(("$b" -split '\+')[0].ToLower(), '\d+|[a-z]+') | ForEach-Object Value)
    $ordem = @{ alpha = 1; a = 1; beta = 2; b = 2; milestone = 3; m = 3; rc = 4; cr = 4; pre = 4; snapshot = 5; final = 6; ga = 6; release = 6 }
    for ($i = 0; $i -lt [Math]::Max($ta.Count, $tb.Count); $i++) {
        $x = if ($i -lt $ta.Count) { $ta[$i] } else { '0' }
        $y = if ($i -lt $tb.Count) { $tb[$i] } else { '0' }
        $nx = $x -match '^\d+$'; $ny = $y -match '^\d+$'
        # Versao que acaba antes de um qualificador (1.0 contra 1.0-beta) e maior.
        if ($i -ge $ta.Count -and -not $ny) { return 1 }
        if ($i -ge $tb.Count -and -not $nx) { return -1 }
        if ($nx -and $ny) { $c = ([decimal]$x).CompareTo([decimal]$y) }
        elseif ($nx) { $c = 1 } elseif ($ny) { $c = -1 }
        else { $c = ([int]$ordem[$x]).CompareTo([int]$ordem[$y]); if (-not $c -and -not $ordem[$x]) { $c = [string]::CompareOrdinal($x, $y) } }
        if ($c) { return [Math]::Sign($c) }
    }
    0
}
# Faixa do Maven: "[1.0,2.0)", "[1.0,)", "[1.0]", varias separadas por virgula; vazia, "*" ou versao solta aceitam tudo.
function Na-Faixa($v, $faixa) {
    if (-not $faixa -or $faixa -eq '*' -or $faixa -notmatch '[\[\(]') { return $true }
    foreach ($f in [regex]::Matches($faixa, '([\[\(])([^,\]\)]*)(?:(,)([^\]\)]*))?([\]\)])')) {
        $ini = $f.Groups[2].Value.Trim(); $fim = if ($f.Groups[3].Success) { $f.Groups[4].Value.Trim() } else { $ini }
        $ok = $true
        if ($ini) { $c = Comparar-Versao $v $ini; if ($c -lt 0 -or ($c -eq 0 -and $f.Groups[1].Value -eq '(')) { $ok = $false } }
        if ($fim) { $c = Comparar-Versao $v $fim; if ($c -gt 0 -or ($c -eq 0 -and $f.Groups[5].Value -eq ')')) { $ok = $false } }
        if ($ok) { return $true }
    }
    $false
}
Write-Host "`nConferindo as dependencias dentro dos jars..."
$porJar = @{}
foreach ($m in $pwMods | Where-Object pasta -eq 'mods') {
    $arq = Join-Path $cache "$($m.sha1).jar"
    if (-not (Test-Path $arq)) {
        Invoke-WebRequest $m.url -OutFile "$arq.tmp" -Headers $h -UseBasicParsing
        if ((Get-FileHash "$arq.tmp" -Algorithm SHA1).Hash -ne $m.sha1) { Remove-Item "$arq.tmp"; throw "$($m.arquivo): checksum nao confere" }
        Move-Item "$arq.tmp" $arq
    }
    $lista = New-Object Collections.ArrayList
    $z = [IO.Compression.ZipFile]::OpenRead($arq); Ler-Jar $z $lista $false; $z.Dispose()
    $porJar[$m.arquivo] = @{ lado = $m.lado; tomls = $lista }
}
$problemas = 0
foreach ($lado in 'client', 'server') {
    $nome = @{ client = 'jogo'; server = 'servidor' }[$lado]
    # Mod avulso tem prioridade sobre o embutido; entre embutidos fica a versao mais nova (como o NeoForge faz).
    $tem = @{ minecraft = @{ version = $mc; arq = 'Minecraft' }; neoforge = @{ version = $neo; arq = 'NeoForge' } }
    $deps = @{}
    foreach ($embutido in $false, $true) {
        foreach ($k in $porJar.Keys) {
            $j = $porJar[$k]
            if ($j.lado -ne 'both' -and $j.lado -ne $lado) { continue }
            foreach ($t in @($j.tomls | Where-Object { $_[2] -eq $embutido })) {
                foreach ($mod in $t[0]) {
                    $id = $mod.modId; if (-not $id) { continue }
                    $antigo = $tem[$id]
                    if (-not $antigo -or ($embutido -and $antigo.embutido -and (Comparar-Versao $mod.version $antigo.version) -gt 0)) {
                        $tem[$id] = @{ version = $mod.version; arq = $k; embutido = $embutido }
                        $deps[$id] = @($t[1] | Where-Object { $_.dono -eq $id })
                    }
                }
            }
        }
    }
    foreach ($id in $deps.Keys) {
        foreach ($d in $deps[$id]) {
            if ($d.side -and $d.side -ne 'BOTH' -and $d.side.ToLower() -ne $lado) { continue }
            # Faixa do Minecraft fica de fora: o Modrinth ja filtra pela 1.21.1, e varios mods declaram [1.21,1.21.1) e rodam.
            if ($d.modId -eq 'minecraft') { continue }
            $tipo = if ($d.type) { $d.type.ToLower() } elseif ($d.mandatory -eq 'false') { 'optional' } else { 'required' }
            $alvo = $tem[$d.modId]; $faixa = $d.versionRange
            $msg = $null
            if ($tipo -eq 'required' -and -not $alvo) { $msg = "falta $($d.modId) $faixa" }
            elseif ($tipo -in 'required', 'optional' -and $alvo -and -not (Na-Faixa $alvo.version $faixa)) { $msg = "pede $($d.modId) $faixa, tem $($alvo.version) ($($alvo.arq))" }
            elseif ($tipo -in 'incompatible', 'discouraged' -and $alvo -and (Na-Faixa $alvo.version $faixa)) { $msg = "$tipo com $($d.modId) $($alvo.version) ($($alvo.arq))" }
            if ($msg) { Write-Host "  [$nome] $id ($($tem[$id].arq)): $msg" -ForegroundColor Red; $problemas++ }
        }
    }
}
if ($problemas) { Write-Host "$problemas problema(s) de dependencia: corrija antes do push." -ForegroundColor Red; exit 1 }
Write-Host 'Dependencias dos jars: ok'
