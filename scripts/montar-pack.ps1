# Gera modpack/minezada.mrpack, modpack/pack (packwiz), o zip do Prism e a lista do README a partir de modpack/mods.txt, resolvendo versoes e
# dependencias obrigatorias no Modrinth para o loader e a versao do jogo abaixo.
# Uso: powershell -ExecutionPolicy Bypass -File scripts\montar-pack.ps1 [-Versao 1.0.0]
param([string]$Versao = (Get-Date -Format 'yyyy.MM.dd'))
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'

$mc = '1.21.1'
$loader = 'neoforge'
$root = Split-Path $PSScriptRoot -Parent
$api = 'https://api.modrinth.com/v2'
$packUrl = 'https://raw.githubusercontent.com/EnzoFerroni/minezada/main/modpack/pack/pack.toml'
$servidor = 'minezada-mc.duckdns.org'
$h = @{ 'User-Agent' = 'minezada-modpack-builder/1.0' }

# Le como UTF-8 (o PS 5.1 decodifica como Latin-1 e quebra emoji/acento) e achata arrays JSON.
function Get-Api($path) {
    $r = Invoke-WebRequest "$api/$path" -Headers $h -UseBasicParsing
    @([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ }
}

$filtro = 'loaders=' + [uri]::EscapeDataString("[`"$loader`"]") + '&game_versions=' + [uri]::EscapeDataString("[`"$mc`"]")
$linhas = Get-Content (Join-Path $root 'modpack\mods.txt') -Encoding UTF8
$pedidos = foreach ($l in $linhas) { if ($l -match '^\s*([a-z0-9_-]+)\s*\|') { $matches[1] } }

$vistos = @{}; $files = @(); $info = @{}; $pwMods = @()
$fila = New-Object System.Collections.Queue
$pedidos | ForEach-Object { $fila.Enqueue($_) }
while ($fila.Count) {
    $id = $fila.Dequeue()
    $p = Get-Api "project/$id"
    if ($vistos[$p.id]) { continue }
    $vistos[$p.id] = $true
    $vs = Get-Api "project/$($p.id)/version?$filtro"
    $v = ($vs | Where-Object version_type -eq 'release' | Select-Object -First 1)
    if (-not $v) { $v = $vs | Select-Object -First 1 }
    if (-not $v) { throw "$($p.slug): sem versao para $loader $mc" }
    $f = $v.files | Where-Object primary | Select-Object -First 1
    if (-not $f) { $f = $v.files[0] }
    $files += [ordered]@{
        path      = "mods/$($f.filename)"
        hashes    = [ordered]@{ sha1 = $f.hashes.sha1; sha512 = $f.hashes.sha512 }
        env       = [ordered]@{
            client = if ($p.client_side -eq 'unsupported') { 'unsupported' } else { 'required' }
            server = if ($p.server_side -eq 'unsupported') { 'unsupported' } else { 'required' }
        }
        downloads = @($f.url)
        fileSize  = $f.size
    }
    $foto = ($p.gallery | Sort-Object { -not $_.featured } | Select-Object -First 1).url  # imagem destacada da galeria do Modrinth
    $info[$p.slug] = [pscustomobject]@{ titulo = $p.title; versao = $v.version_number; servidor = $p.server_side -ne 'unsupported'; icone = $p.icon_url; foto = $foto }
    $lado = if ($p.server_side -eq 'unsupported') { 'client' } elseif ($p.client_side -eq 'unsupported') { 'server' } else { 'both' }
    $pwMods += [pscustomobject]@{ slug = $p.slug; titulo = $p.title; arquivo = $f.filename; url = $f.url; sha1 = $f.hashes.sha1; lado = $lado }
    foreach ($d in $v.dependencies | Where-Object { $_.dependency_type -eq 'required' -and $_.project_id }) { $fila.Enqueue($d.project_id) }
    Write-Host ('{0,-30} {1}' -f $p.slug, $v.version_number)
}

$neo = (Invoke-RestMethod "https://maven.neoforged.net/api/maven/latest/version/releases/net/neoforged/neoforge?filter=$($mc.Substring(2)).").version  # "21.1." (sem o ponto casa 21.11)
$index = [ordered]@{
    formatVersion = 1; game = 'minecraft'; versionId = $Versao; name = 'Minezada'
    summary = 'Vanilla melhorado: Create, baus, dragoes, Aether e guias'
    files = $files
    dependencies = [ordered]@{ minecraft = $mc; neoforge = $neo }
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) "minezada-pack-$PID"
New-Item -ItemType Directory -Force $tmp | Out-Null
[IO.File]::WriteAllText((Join-Path $tmp 'modrinth.index.json'), ($index | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding $false))
Get-ChildItem (Join-Path $root 'modpack') -Filter *.mrpack | Remove-Item
$saida = Join-Path $root 'modpack\minezada.mrpack'
Compress-Archive (Join-Path $tmp 'modrinth.index.json') "$tmp\pack.zip" -Force
Move-Item "$tmp\pack.zip" $saida

# Formato packwiz em modpack/pack: o Prism le pelo link raw do GitHub a cada abertura e sincroniza os mods.
$utf8 = New-Object Text.UTF8Encoding $false
function Escrever($caminho, $texto) { [IO.File]::WriteAllText($caminho, $texto.Replace("`r`n", "`n"), $utf8) }
function Sha256($caminho) { (Get-FileHash $caminho -Algorithm SHA256).Hash.ToLower() }
function Toml($s) { '"' + $s.Replace('\', '\\').Replace('"', '\"') + '"' }
$pw = Join-Path $root 'modpack\pack'
if (Test-Path $pw) { Remove-Item -Recurse -Force $pw }
New-Item -ItemType Directory -Force (Join-Path $pw 'mods') | Out-Null
$idx = "hash-format = `"sha256`"`n"
foreach ($m in $pwMods) {
    $rel = "mods/$($m.slug).pw.toml"
    Escrever (Join-Path $pw $rel) "name = $(Toml $m.titulo)`nfilename = $(Toml $m.arquivo)`nside = `"$($m.lado)`"`n`n[download]`nurl = $(Toml $m.url)`nhash-format = `"sha1`"`nhash = `"$($m.sha1)`"`n"
    $idx += "`n[[files]]`nfile = `"$rel`"`nhash = `"$(Sha256 (Join-Path $pw $rel))`"`nmetafile = true`n"
}
Escrever (Join-Path $pw 'index.toml') $idx
Escrever (Join-Path $pw 'pack.toml') "name = `"Minezada`"`nversion = `"$Versao`"`npack-format = `"packwiz:1.1.0`"`n`n[index]`nfile = `"index.toml`"`nhash-format = `"sha256`"`nhash = `"$(Sha256 (Join-Path $pw 'index.toml'))`"`n`n[versions]`nminecraft = `"$mc`"`nneoforge = `"$neo`"`n"

# Instancia do Prism: arrastar o zip no Prism e jogar. O pre-launch roda o packwiz, que baixa/atualiza os mods.
# shortcut: a versao do NeoForge fica fixa na instancia; se o pack trocar de NeoForge, os jogadores reimportam o zip.
$boot = Join-Path $root 'tools\packwiz-installer-bootstrap.jar'
if (-not (Test-Path $boot)) {
    New-Item -ItemType Directory -Force (Split-Path $boot) | Out-Null
    Invoke-WebRequest 'https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar' -OutFile $boot
}
$inst = Join-Path $tmp 'prism'
New-Item -ItemType Directory -Force (Join-Path $inst '.minecraft') | Out-Null
Copy-Item $boot (Join-Path $inst '.minecraft')
Escrever (Join-Path $inst 'instance.cfg') "[General]`nInstanceType=OneSix`nname=Minezada`nOverrideCommands=true`nPreLaunchCommand=`"`$INST_JAVA`" -jar packwiz-installer-bootstrap.jar $packUrl`nOverrideMemory=true`nMinMemAlloc=2048`nMaxMemAlloc=6144`nJoinServerOnLaunch=true`nJoinServerOnLaunchAddress=$servidor`n"
# servers.dat (NBT sem compressao) com o servidor ja na lista do Multiplayer.
function NbtStr($ms, $s) { $b = [Text.Encoding]::UTF8.GetBytes($s); $ms.WriteByte($b.Length -shr 8); $ms.WriteByte($b.Length -band 255); $ms.Write($b, 0, $b.Length) }
$ms = New-Object IO.MemoryStream
$ms.WriteByte(10); NbtStr $ms ''                                                                 # compound raiz
$ms.WriteByte(9); NbtStr $ms 'servers'; $ms.WriteByte(10); $ms.Write([byte[]](0, 0, 0, 1), 0, 4)  # lista com 1 compound
$ms.WriteByte(8); NbtStr $ms 'name'; NbtStr $ms 'Minezada'
$ms.WriteByte(8); NbtStr $ms 'ip'; NbtStr $ms $servidor
$ms.WriteByte(0); $ms.WriteByte(0)                                                               # fim do servidor e da raiz
[IO.File]::WriteAllBytes((Join-Path $inst '.minecraft\servers.dat'), $ms.ToArray())
Escrever (Join-Path $inst 'mmc-pack.json') "{`"formatVersion`":1,`"components`":[{`"uid`":`"net.minecraft`",`"version`":`"$mc`",`"important`":true},{`"uid`":`"net.neoforged`",`"version`":`"$neo`"}]}`n"
$zipPrism = Join-Path $root 'modpack\minezada-prism.zip'
if (Test-Path $zipPrism) { Remove-Item $zipPrism }
# Zip montado a mao: no PS 5.1 tanto Compress-Archive quanto ZipFile gravam "\" e o Prism no Mac nao entende.
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$za = [IO.Compression.ZipFile]::Open($zipPrism, 'Create')
foreach ($arq in Get-ChildItem $inst -Recurse -File -Force) {
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($za, $arq.FullName, $arq.FullName.Substring($inst.Length + 1).Replace('\', '/'))
}
$za.Dispose()
Remove-Item -Recurse -Force $tmp

# Vitrine de mods em docs/mods.md, entre os marcadores: icone, imagem, link e a descricao do mods.txt.
$md = @("<sub>Minecraft $mc · NeoForge $neo · pack ``$Versao`` · $($info.Count) mods. Gerado por ``scripts/montar-pack.ps1``.</sub>")
foreach ($l in $linhas) {
    if ($l -match '^## (.+)') { $md += '', "## $($matches[1])" }
    elseif ($l -match '^\s*([a-z0-9_-]+)\s*\|\s*(.+)$') {
        $i = $info[$matches[1]]
        $ico = if ($i.icone) { '<img src="' + $i.icone + '" width="28" align="center"> ' } else { '' }
        $md += '', "### $ico[$($i.titulo)](https://modrinth.com/mod/$($matches[1]))", '', $matches[2]
        if ($i.foto) { $md += '', "<img src=`"$($i.foto)`" width=`"480`">" }
        $md += '', "<sub>Versão ``$($i.versao)``$(if (-not $i.servidor) { ' · só no jogo de cada um, não no servidor' })</sub>"
    }
}
$extras = $info.Keys | Where-Object { $_ -notin $pedidos } | Sort-Object
if ($extras) { $md += '', '## Dependências (entram sozinhas)', '', (($extras | ForEach-Object { "[$($info[$_].titulo)](https://modrinth.com/mod/$_)" }) -join ' · ') }
$doc = Join-Path $root 'docs\mods.md'
$txt = [IO.File]::ReadAllText($doc)
if ($txt -notmatch '<!-- mods:inicio -->') { throw 'docs/mods.md sem os marcadores <!-- mods:inicio --> / <!-- mods:fim -->' }
$novo = [regex]::Replace($txt, '(?s)(<!-- mods:inicio -->).*?(<!-- mods:fim -->)', { param($m) "$($m.Groups[1].Value)`n$($md -join "`n")`n$($m.Groups[2].Value)" })
[IO.File]::WriteAllText($doc, $novo, (New-Object Text.UTF8Encoding $false))

Write-Host "`n$($files.Count) arquivos, NeoForge $neo -> $saida"
