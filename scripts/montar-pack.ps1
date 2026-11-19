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
$pastas = @{ mod = 'mods'; resourcepack = 'resourcepacks'; shader = 'shaderpacks' }
# So de servidor mesmo que o Modrinth aceite no cliente: o Chunky no jogo faz o Distant Horizons chamar a
# API dele sem servidor rodando (crash ao entrar no mundo).
$soServidor = @('chunky')
# Opcional no servidor pelo Modrinth, mas fica so no jogo: no servidor o Distant Horizons geraria terreno
# distante para todos (pesado com Terralith/Tectonic num PC de casa).
$soCliente = @('distanthorizons')
# Opcionais: o packwiz mostra uma janela na primeira abertura para cada um marcar (vem desmarcado). O Iris
# reserva as texturas do Distant Horizons so por ele estar instalado, e no Mac (16 texturas) o shader nao abre.
$opcionais = @{ 'distanthorizons' = 'Ver muito mais longe (montanhas no horizonte). Funciona junto com shader. No Mac ele fica desligado.' }
# Pacotes de recursos que ja vem ligados, nesta ordem (o ultimo tem prioridade: Faithful embaixo como base,
# Fresh Animations em cima para os mobs). O jogar liga os desta lista ate em quem ja tinha options.txt.
$rpLigados = @('faithful-32x', 'default-dark-mode', 'fast-better-grass', 'simple-grass-flowers', 'better-leaves',
    '3d-crops', 'better-lanterns', 'cubic-sun-moon', 'fresh-waystones-texture', 'low-shield-pack', 'low-on-fire',
    'fresh-animations', 'fresh-animations-extensions')
# Versao presa (id da versao no Modrinth), vale ate com -Atualizar.
# Accessories 1.1.0-beta.53: minimo que o Hamster aceita. O Aether embute a beta.48, que impede o
# servidor de abrir; a avulsa tem prioridade sobre a embutida.
$presas = @{ 'accessories' = 'Fb55Fgjz' }
# Dependencias que o jar exige mas a versao no Modrinth nao declara (ids de projeto do Modrinth).
# Hamster 3.7.0: architectury, geckolib, fzzy-config, patchouli e accessories (ver acima).
$depsExtras = @{ 'adorable-hamster-pets' = @('lhGA9TYQ', '8BmcQJ2H', 'hYykXjDp', 'nU0bVIaL', 'jtmvUHXj') }
$linhas = Get-Content (Join-Path $root 'modpack/mods.txt') -Encoding UTF8
$pedidos = foreach ($l in $linhas) { if ($l -match '^\s*([a-z0-9_-]+)\s*\|') { $matches[1] } }

# Pack anterior (modpack/pack): lista de arquivos (para mostrar o que mudou) e a versao de cada projeto (para
# repetir; o link de cada arquivo tem o id do projeto e da versao).
$antes = @(); $fixas = @{}
foreach ($m in Get-ChildItem (Join-Path $root 'modpack/pack') -Filter *.pw.toml -Recurse -ErrorAction SilentlyContinue) {
    $c = Get-Content $m.FullName -Raw -Encoding UTF8
    if ($c -match '(?m)^filename = "(.+)"') { $antes += "$($m.Directory.Name)/$($matches[1])" }
    if ($c -match '/data/([^/]+)/versions/([^/]+)/') { $fixas[$matches[1]] = $matches[2] }
}
$vistos = @{}; $projs = [ordered]@{}; $info = @{}; $pwMods = @()
$fila = New-Object System.Collections.Queue
$pedidos | ForEach-Object { $fila.Enqueue($_) }
while ($fila.Count) {
    $id = $fila.Dequeue()
    $p = Get-Api "project/$id"
    if ($vistos[$p.id]) { continue }
    $vistos[$p.id] = $true
    $pasta = $pastas[$p.project_type]
    if (-not $pasta) { throw "$($p.slug): tipo $($p.project_type) nao suportado" }
    if ($presas[$p.slug]) { $v = Get-Api "version/$($presas[$p.slug])" }
    elseif ($fixas[$p.id] -and -not $Atualizar) { $v = Get-Api "version/$($fixas[$p.id])" }
    else {
        # Pacotes de recursos e shaders nao tem loader NeoForge: filtra so pela versao do jogo.
        $vs = Get-Api "project/$($p.id)/version?$(if ($p.project_type -eq 'mod') { $filtro } else { $filtroMc })"
        $v = ($vs | Where-Object version_type -eq 'release' | Select-Object -First 1)
        if (-not $v) { $v = $vs | Select-Object -First 1 }
    }
    if (-not $v) { throw "$($p.slug): sem versao para $loader $mc" }
    $f = $v.files | Where-Object primary | Select-Object -First 1
    if (-not $f) { $f = $v.files[0] }
    $deps = @($v.dependencies | Where-Object { $_.dependency_type -eq 'required' -and $_.project_id } | ForEach-Object project_id) + @($depsExtras[$p.slug] | Where-Object { $_ })
    $deps | ForEach-Object { $fila.Enqueue($_) }
    $projs[$p.id] = [pscustomobject]@{ p = $p; v = $v; f = $f; pasta = $pasta; deps = $deps
        cliente = $p.client_side -ne 'unsupported' -and $p.slug -notin $soServidor; servidor = $p.server_side -ne 'unsupported' -and $p.slug -notin $soCliente }
    Write-Host ('{0,-30} {1}' -f $p.slug, $v.version_number)
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
    $info[$p.slug] = [pscustomobject]@{ titulo = $p.title; versao = $v.version_number; servidor = $x.servidor; icone = $p.icon_url }
    $lado = if (-not $x.servidor) { 'client' } elseif (-not $x.cliente) { 'server' } else { 'both' }
    $pwMods += [pscustomobject]@{ slug = $p.slug; titulo = $p.title; arquivo = $f.filename; url = $f.url; sha1 = $f.hashes.sha1; lado = $lado; pasta = $x.pasta }
}

# NeoForge mais novo que o Prism ja conhece: o meta dele atrasa algumas horas em relacao ao maven,
# e uma versao que ainda nao esta la faz a instancia falhar ao abrir.
$metaNeo = [Text.Encoding]::UTF8.GetString((Invoke-WebRequest 'https://meta.prismlauncher.org/v1/net.neoforged/index.json' -UseBasicParsing).RawContentStream.ToArray()) | ConvertFrom-Json
$neo = ($metaNeo.versions | Where-Object { $_.version -like "$($mc.Substring(2)).*" } | Select-Object -First 1).version  # "21.1.*"
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
foreach ($m in $pwMods) {
    $rel = "$($m.pasta)/$($m.slug).pw.toml"  # o packwiz instala o arquivo na pasta do metafile
    $opc = if ($opcionais[$m.slug]) { "`n[option]`noptional = true`ndefault = false`ndescription = $(Toml $opcionais[$m.slug])`n" } else { '' }
    Escrever (Join-Path $pw $rel) "name = $(Toml $m.titulo)`nfilename = $(Toml $m.arquivo)`nside = `"$($m.lado)`"`n`n[download]`nurl = $(Toml $m.url)`nhash-format = `"sha1`"`nhash = `"$($m.sha1)`"`n$opc"
    $idx += "`n[[files]]`nfile = `"$rel`"`nhash = `"$(Sha256 (Join-Path $pw $rel))`"`nmetafile = true`n"
}
# Arquivos soltos (perfis de grafico etc) de modpack/arquivos vao para o jogo de cada um.
# preserve = so cria se nao existir: quem recalibrar um perfil nao perde o ajuste na proxima abertura.
$soltos = Join-Path $root 'modpack/arquivos'
if (Test-Path $soltos) {
    foreach ($a in Get-ChildItem $soltos -Recurse -File) {
        $rel = $a.FullName.Substring($soltos.Length + 1).Replace('\', '/')
        $dest = Join-Path $pw $rel
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Copy-Item $a.FullName $dest
        # minezada.ps1/.sh (rodam antes de abrir) sempre atualizam: sem preserve.
        $pres = if ($rel -like 'minezada.*') { '' } else { "preserve = true`n" }
        $idx += "`n[[files]]`nfile = $(Toml $rel)`nhash = `"$(Sha256 $dest)`"`n$pres"
    }
}
# servers.dat (NBT sem compressao): os enderecos do servidor ja na lista do Multiplayer. Vai pelo packwiz
# sem preserve, entao todo mundo recebe a lista nova a cada abertura (servidor adicionado a mao some).
# Principal: Cloudflare (HTTPS na 443, passa em rede de faculdade). Reserva: playit (playit-endereco.txt no Drive).
function NbtStr($ms, $s) { $b = [Text.Encoding]::UTF8.GetBytes($s); $ms.WriteByte($b.Length -shr 8); $ms.WriteByte($b.Length -band 255); $ms.Write($b, 0, $b.Length) }
$entradas = @(@('Minezada', $servidor), @('Minezada (playit)', $tunel), @('Minezada (neste computador)', 'localhost'))
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
# Sem JoinServerOnLaunch: o jogo abre no menu e a lista de servidores mostra quais estao no ar.
# PreLaunchCommand do zip serve para quem importa o zip no Prism a mao; o jogar troca pelo minezada.ps1/.sh.
Escrever (Join-Path $inst 'instance.cfg') "[General]`nInstanceType=OneSix`nname=Minezada`nOverrideCommands=true`nPreLaunchCommand=`"`$INST_JAVA`" -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -t 0 $packUrl`nOverrideMemory=true`nMinMemAlloc=1024`nMaxMemAlloc=4096`n"
[IO.File]::WriteAllBytes((Join-Path $inst '.minecraft/servers.dat'), $serversDat)
# Opcoes iniciais (o jogo completa o resto); o jogar so copia se o jogador ainda nao tiver.
# Pacotes de $rpLigados ja vem ligados. As quatro ultimas opcoes pulam as telas de primeira abertura:
# acessibilidade, tutorial de movimento e avisos de multiplayer.
$rp = ($rpLigados | ForEach-Object { $s = $_; $m = $pwMods | Where-Object slug -eq $s; if (-not $m) { throw "Pacote ligado $s nao esta no pack" }; ",`"file/$($m.arquivo)`"" }) -join ''
Escrever (Join-Path $inst '.minecraft/options.txt') "lang:pt_br`nrenderDistance:10`nsimulationDistance:8`nresourcePacks:[`"vanilla`"$rp]`nonboardAccessibility:false`ntutorialStep:none`njoinedFirstServer:true`nskipMultiplayerWarning:true`n"
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
    elseif ($l -match '^\s*([a-z0-9_-]+)\s*\|\s*(.+)$') {
        $slug = $matches[1]; $desc = $matches[2].Trim(); $i = $info[$slug]
        $p = $desc.IndexOf('. ')
        $resumo = if ($p -gt 0) { $desc.Substring(0, $p) } else { $desc.TrimEnd('.') }
        $link = "https://modrinth.com/mod/$slug"
        $topo = if ($fotos[$slug]) { "<a href=`"$link`"><img src=`"$($fotos[$slug])`" width=`"100%`"></a>" } elseif ($i.icone) { "<a href=`"$link`"><img src=`"$($i.icone)`" width=`"64`"></a>" } else { '' }
        $ico = if ($i.icone) { "<img src=`"$($i.icone)`" width=`"16`"> " } else { '' }
        $cartoes += "<td width=`"33%`" valign=`"top`">$topo<br>$ico<a href=`"$link`"><b>$($i.titulo)</b></a><br><sub>$resumo</sub></td>"
    }
}
& $fechar
$extras = $info.Keys | Where-Object { $_ -notin $pedidos } | Sort-Object
if ($extras) { $md += '', '## Dependências (entram sozinhas)', '', (($extras | ForEach-Object { "[$($info[$_].titulo)](https://modrinth.com/mod/$_)" }) -join ' · ') }
$doc = Join-Path $root 'docs/mods.md'
$txt = [IO.File]::ReadAllText($doc)
if ($txt -notmatch '<!-- mods:inicio -->') { throw 'docs/mods.md sem os marcadores <!-- mods:inicio --> / <!-- mods:fim -->' }
$novo = [regex]::Replace($txt, '(?s)(<!-- mods:inicio -->).*?(<!-- mods:fim -->)', { param($m) "$($m.Groups[1].Value)`n$($md -join "`n")`n$($m.Groups[2].Value)" })
[IO.File]::WriteAllText($doc, $novo, (New-Object Text.UTF8Encoding $false))

Write-Host "`n$($pwMods.Count) arquivos, NeoForge $neo -> modpack/pack"
