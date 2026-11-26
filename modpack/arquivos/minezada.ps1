# Roda antes de cada abertura do jogo (PreLaunchCommand da instancia, na pasta .minecraft).
# Vem pelo pack: uma mudanca aqui chega em todos sem rodar o comando de jogar de novo (vale a partir da
# abertura seguinte, porque o packwiz troca este arquivo enquanto ele roda).
# java.exe no lugar do javaw.exe: o PowerShell so espera programa de console terminar. (Start-Process -Wait
# da "Acesso negado" quando o Prism roda este script.)
# Perfis que sairam do pack (o packwiz nao apaga arquivo com preserve). Em 26/11 a escala virou 1 a 7 para PC e Mac.
$antigos = 'Shader - Sildurs Vibrant', 'Shader - Super Duper Vanilla', 'Shader - Miniature', 'PC - Solas', 'PC - Rethinking Voxels',
    '3 - Equilibrado', '5 - Bonito Shader', '6 - Muito Alto Shader', '7 - Ultra Shader', '8 - FPS Maximo', '9 - Bateria',
    'Mac 1 - Leve 8GB', 'Mac 2 - Equilibrado', 'Mac 3 - Alto Pro Max', 'Mac 4 - Shader Leve', 'Mac 5 - Shader Bonito',
    'Mac 6 - Shader Realista', 'Mac 7 - Bateria', 'Shader - BSL', 'PC - Photon', 'PC - Bliss'
foreach ($p in $antigos) {
    Remove-Item -LiteralPath "options-profiles/$p" -Recurse -Force -ErrorAction SilentlyContinue
}
# Teclas do pack, trocadas so em quem ainda esta sem a tecla salva ou no padrao do mod (tecla, padroes, nova):
# Ping Wheel no botao do meio (o padrao e o lateral, que o trackpad nao tem) e o pegar bloco no lateral;
# VeinMiner na tecla ao lado do 1 (o padrao Z bate com o Xaero).
# shortcut: quem escolher de volta um padrao do mod perde a escolha na abertura seguinte; marcar a troca se alguem reclamar.
$teclas = @(
    @('key_key.pingwheel.ping_location', 'key.mouse.5', 'key.mouse.middle'),
    @('key_key.pickItem', 'key.mouse.middle', 'key.mouse.5'),
    @('key_key.veinminer_client.hold', 'key.keyboard.z', 'key.keyboard.grave.accent'),
    # Teclas com varias acoes dos mods: a mais usada fica sozinha, as outras vao para Alt ou Shift
    # (Ctrl no Mac vira Cmd, e Cmd+H e Cmd+M escondem a janela).
    @('key_gui.xaero_new_waypoint', 'key.keyboard.b', 'key.keyboard.n'),
    @('key_key.toms_storage.open_terminal', 'key.keyboard.b', 'key.keyboard.b:ALT'),
    @('key_key.map_atlases.place_pin', 'key.keyboard.b', 'key.keyboard.b:SHIFT'),
    @('key_key.map_atlases.open_minimap', 'key.keyboard.m', 'key.keyboard.m:ALT'),
    @('key_key.jetpack.toggle_active.description', 'key.keyboard.g', 'key.keyboard.g:ALT'),
    @('key_key.jetpack.toggle_hover.description', 'key.keyboard.h', 'key.keyboard.h:ALT'),
    @('key_key.ad_astra.open_radio', 'key.keyboard.r', 'key.keyboard.r:ALT'),
    @('key_iris.keybind.reload', 'key.keyboard.r', 'key.keyboard.unknown'),
    @('key_supplementaries.keybind.quiver', 'key.keyboard.v', 'key.keyboard.v:ALT'),
    @('key_key.ad_astra.toggle_suit_flight', 'key.keyboard.v', 'key.keyboard.v:SHIFT'),
    @('key_key.aether.invisibility_toggle.desc', 'key.keyboard.v', 'key.keyboard.j'),
    @('key_key.deep_aether.toggle_skyjade_transparency', 'key.keyboard.v', 'key.keyboard.unknown'),
    @('key_key.corpse.death_history', 'key.keyboard.u', 'key.keyboard.u:ALT'),
    # Shader volta para o K (ficou em Alt+K enquanto um mod de teclado visual usou o K em 20/11).
    @('key_iris.keybind.toggleShaders', 'key.keyboard.k:ALT', 'key.keyboard.k'),
    # O escolhe o shader do Iris; a config do VeinMiner vai para Shift+O.
    @('key_key.veinminer_client.config', 'key.keyboard.o', 'key.keyboard.o:SHIFT')
)
if (Test-Path options.txt) {
    $o = [Collections.Generic.List[string]](Get-Content options.txt -Encoding UTF8)
    foreach ($t in $teclas) {
        $n = $o.FindIndex({ param($l) $l -like "$($t[0]):*" })
        if ($n -lt 0) { $o.Add("$($t[0]):$($t[2])") } elseif ($o[$n] -eq "$($t[0]):$($t[1])") { $o[$n] = "$($t[0]):$($t[2])" }
    }
    # Pacotes feitos para outra versao do Minecraft (3D Crops, pack_format 55; Deep Aether Tooltips): o jogo tira da
    # lista a cada abertura, a menos que o nome conste tambem em incompatibleResourcePacks. Garante nas duas listas.
    # Nome do zip do 3D Crops pelo packwiz.json, porque ele muda quando o mod atualiza.
    # shortcut: o packwiz.json e da abertura anterior; quando o nome muda, o pacote volta so na abertura seguinte.
    $crops = try { (Get-Content packwiz.json -Raw -ErrorAction Stop | ConvertFrom-Json).cachedFiles.'resourcepacks/3d-crops.pw.toml'.cachedLocation } catch { $null }
    $forcados = @(if ($crops) { 'file/' + ($crops -replace '^resourcepacks/', '') }) + 'builtin/client/deep_aether_tooltips'
    foreach ($k in 'resourcePacks', 'incompatibleResourcePacks') {
        $n = $o.FindIndex({ param($l) $l -like "${k}:*" })
        # @(if ...): sem o @() de fora, uma lista de um item so vira texto solto e o + junta as strings.
        $lista = @(if ($n -ge 0) { ($o[$n] -replace "^${k}:", '') | ConvertFrom-Json | ForEach-Object { $_ } })
        $falta = @($forcados | Where-Object { $lista -cnotcontains $_ })
        if ($falta.Count -eq 0) { continue }
        $linha = "${k}:" + (ConvertTo-Json -InputObject @($lista + $falta) -Compress)
        if ($n -ge 0) { $o[$n] = $linha } else { $o.Add($linha) }
    }
    [IO.File]::WriteAllLines("$PWD\options.txt", $o)
}
# Avisos dos mods que so atrapalham (arquivo, opcao, valor). O servidor tem os mesmos em server-config.
# Distant Horizons: avisos no chat de garbage collector (o ZGC que ele sugere gasta mais memoria nos PCs fracos),
# distancia de renderizacao alta e pouca memoria. Terralith: mensagem de boas-vindas.
# Hamster: sino de novidades e livro entregue na mao; o aviso de "sem livro" vem uma vez, no tempo maximo (5 min).
# Alex's Mobs: livro na mao ao entrar. Aether: Patreon. CodxLib, Xaero: versao nova. Supplementaries: avisos ao abrir.
# Vale para TOML (opcao = valor) e JSON ("opcao": valor).
$ajustes = @(
    @('config/DistantHorizons.toml', 'showGarbageCollectorWarning', 'false'),
    @('config/DistantHorizons.toml', 'showHighVanillaRenderDistanceWarning', 'false'),
    @('config/DistantHorizons.toml', 'showLowMemoryWarningOnStartup', 'false'),
    @('config/terralith.json', 'intro_message', 'false'),
    @('config/adorablehamsterpets/ui.toml', 'enableNotificationIcons', 'false'),
    @('config/adorablehamsterpets/ui.toml', 'serverDisableAnnouncements', 'true'),
    @('config/adorablehamsterpets/ui.toml', 'enableAutoGuidebookDelivery', 'false'),
    @('config/adorablehamsterpets/ui.toml', 'enableAutoGuidebookDeliveryFallback', 'false'),
    @('config/adorablehamsterpets/ui.toml', 'guidebookWarningTimer', '6000'),
    @('config/DistantHorizons.toml', 'showPoolInsufficientMemoryWarning', 'false'),
    @('config/amc.json', 'giveBookOnStartup', 'false'),
    @('config/aether-common.toml', 'Show Patreon message', 'false'),
    @('config/codxlib.json', 'updateNotifications', 'false'),
    @('config/supplementaries-common.toml', 'sanity_checks_messages', 'false'),
    @('config/xaero/minimap/client.cfg', 'update_notifications', 'false'),
    @('config/xaero/world-map/client.cfg', 'update_notifications', 'false')
)
foreach ($a in $ajustes) {
    if (-not (Test-Path $a[0])) { continue }
    $t = [IO.File]::ReadAllText("$PWD\$($a[0])")
    $n = $t -replace "(?m)^(\s*`"?$($a[1])`"?\s*[=:]\s*)[^\r\n,]*", "`${1}$($a[2])"
    if ($n -ne $t) { [IO.File]::WriteAllText("$PWD\$($a[0])", $n) }
}
# Na primeira abertura (instancia sem Java escolhido) o Prism passa a pasta de dados dele em INST_JAVA: usa o Java
# que ele baixou la dentro.
$java = $env:INST_JAVA
if (-not ($java -and (Test-Path -LiteralPath $java -PathType Leaf))) { $java = Get-ChildItem "$env:INST_JAVA\java\*\bin\javaw.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
$java = if ($java) { $java -replace 'javaw\.exe$', 'java.exe' } else { 'java' }
# Pack pelo link do commit mais novo: o link do main fica ate 5 min velho no cache do GitHub depois de um push.
$ref = try { "$(Invoke-RestMethod 'https://api.github.com/repos/EnzoFerroni/minezada/commits/main' -Headers @{ Accept = 'application/vnd.github.sha' } -TimeoutSec 10)".Trim() } catch { '' }
if ($ref -notmatch '^[0-9a-f]{40}$') { $ref = 'main' }
$pack = "https://raw.githubusercontent.com/EnzoFerroni/minezada/$ref/modpack/pack/pack.toml"
# -t 0: sem a espera de 10 s do "Reconfigure optional mods?". Opcional novo continua abrindo a lista.
# MINEZADA_SEM_PACKWIZ: so nos testes (scripts/testes/minezada.ps1), para conferir o resto sem rede.
if (-not $env:MINEZADA_SEM_PACKWIZ) {
    & $java -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -t 0 $pack
    # Sem internet ou GitHub fora: abre com os mods de antes (mundo sozinho funciona; servidor recusa se mudou).
    if ($LASTEXITCODE) { Write-Warning 'Pack nao atualizado (sem internet?): abrindo com os mods de antes.' }
}
# Mundo novo no servidor (scripts/resetar troca o mundo-id.txt): mapas e marcadores do Xaero e cache do DH do
# mundo velho saem, senao aparecem por cima do novo. Na primeira vez so grava o id.
# shortcut: apaga os mapas de todo servidor (Multiplayer_*), nao so o Minezada; serve enquanto o pack e so dele.
if (Test-Path mundo-id.txt) {
    $id = ([IO.File]::ReadAllText((Resolve-Path mundo-id.txt))).Trim()
    $idSalvo = if (Test-Path .minezada-mundo-id) { ([IO.File]::ReadAllText((Resolve-Path .minezada-mundo-id))).Trim() } else { '' }
    if ($idSalvo -and $id -ne $idSalvo) {
        Remove-Item -Recurse -Force xaero/world-map/Multiplayer_*, xaero/minimap/Multiplayer_*, Distant_Horizons_server_data -ErrorAction SilentlyContinue
    }
    [IO.File]::WriteAllText((Join-Path (Get-Location) '.minezada-mundo-id'), "$id`n")
}
# Shader atualizado muda o nome do zip: o iris.properties atual e o dos perfis (preserve) passam para o zip novo.
foreach ($f in @(Get-ChildItem config/iris.properties, options-profiles/*/iris.properties -ErrorAction SilentlyContinue)) {
    $t = [IO.File]::ReadAllText($f.FullName)
    if ($t -notmatch '(?m)^shaderPack=(.+?)\s*$') { continue }
    $velho = $matches[1]
    if (Test-Path -LiteralPath "shaderpacks/$velho") { continue }
    $novo = if ($velho -match '^(.+?)[_-][vr]?\d') { @(Get-ChildItem shaderpacks -Filter "$($matches[1])*" -ErrorAction SilentlyContinue) }
    # Shader que saiu do pack: vai para o Complementary Reimagined (o mais testado no Mac) em vez de ficar sem shader.
    if (@($novo).Count -ne 1) { $novo = @(Get-ChildItem shaderpacks -Filter 'ComplementaryReimagined*.zip' -ErrorAction SilentlyContinue) }
    if (@($novo).Count -eq 1) { [IO.File]::WriteAllText($f.FullName, $t.Replace("shaderPack=$velho", "shaderPack=$($novo[0].Name)")) }
}
exit 0
