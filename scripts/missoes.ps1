# Gera o livro de missoes (FTB Quests) em server-config/config/ftbquests/quests a partir da tabela abaixo.
# O servidor manda o livro para cada jogador; o progresso fica no mundo, nao aqui.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/missoes.ps1 (Mac: pwsh scripts/missoes.ps1)
# Cada missao: t = titulo, d = texto (uma linha por item), e uma tarefa: item (id do item), dim (id da dimensao)
# ou nada (o jogador marca como feito). p = premio (id do item) e n = quantidade. Cada missao depende da anterior
# do mesmo capitulo, a menos que solta = $true. Ids conferidos nos jars do pack (26/11).
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$destino = Join-Path $root 'server-config/config/ftbquests/quests'

$capitulos = @(
    @{ t = 'Primeiros passos'; icone = 'minecraft:crafting_table'; m = @(
        @{ t = 'Bem-vindo ao Minezada'; d = 'Este livro guia o comeco. Abra quando quiser pelo botao do livro no inventario.', 'Tecla R em cima de um item mostra a receita; U mostra para que ele serve (JEI, na direita do inventario).', 'Mire em um bloco ou bicho para ver o nome e o mod no topo da tela (Jade).', 'Jogo lento? Opcoes > Perfis > 1 - Minimo. Os perfis vao de 1 - Minimo a 7 - Ultra.' }
        @{ t = 'Mesa de trabalho'; d = 'Junte madeira e faca uma mesa de trabalho.'; item = 'minecraft:crafting_table'; p = 'minecraft:bread'; n = 4 }
        @{ t = 'Mapa'; d = 'O minimapa fica no canto da tela. Tecla M abre o mapa do mundo que voce ja explorou.' }
        @{ t = 'Mochila'; d = 'Faca uma mochila: ela guarda muito mais que o inventario e pode ser melhorada.'; item = 'sophisticatedbackpacks:backpack'; p = 'minecraft:leather'; n = 4 }
        @{ t = 'Waystone'; d = 'Waystones sao pedras de teleporte. Ative uma clicando nela e depois viaje entre as que voce ativou.', 'Faca a sua para colocar perto de casa.'; item = 'waystones:waystone'; p = 'minecraft:ender_pearl'; n = 2 }
        @{ t = 'Se voce morrer'; d = 'Seus itens ficam guardados em um corpo no lugar da morte. Volte la e clique nele para pegar tudo.', 'O lugar da morte aparece no mapa.' }
        @{ t = 'Cozinha'; d = 'Farmer''s Delight traz panela, tabua de corte e dezenas de comidas.', 'Cada comida nova que voce prova pela primeira vez da coracoes extras de vida (Spice of Life).'; item = 'farmersdelight:cooking_pot'; p = 'minecraft:golden_carrot'; n = 4 }
    ) }
    @{ t = 'Create'; icone = 'create:cogwheel'; m = @(
        @{ t = 'Ponder'; d = 'O Create ensina cada bloco com animacoes: segure W com o mouse em cima de um item do Create.'; item = 'create:andesite_alloy'; p = 'create:andesite_alloy'; n = 8 }
        @{ t = 'Roda d''agua'; d = 'A roda d''agua gira com agua corrente e gera forca para as maquinas.'; item = 'create:water_wheel' }
        @{ t = 'Eixos e engrenagens'; d = 'Eixos e engrenagens levam a forca da roda ate as maquinas.'; item = 'create:cogwheel'; p = 'create:shaft'; n = 8 }
        @{ t = 'Prensa'; d = 'A prensa mecanica transforma lingotes em chapas, que muitas receitas pedem.'; item = 'create:mechanical_press'; p = 'minecraft:iron_ingot'; n = 8 }
    ) }
    @{ t = 'Create avancado'; icone = 'create:precision_mechanism'; m = @(
        @{ t = 'Moinho de vento'; d = 'Rolamento de moinho com velas em volta gira sem agua. Mais velas, mais forca.'; item = 'create:windmill_bearing' }
        @{ t = 'Misturador'; d = 'Misturador mecanico em cima de uma bacia mistura itens. Com aquecimento faz o latao.'; item = 'create:mechanical_mixer' }
        @{ t = 'Queimador de blaze'; d = 'Debaixo da bacia ele aquece as receitas. Alimente com combustivel comum.'; item = 'create:blaze_burner' }
        @{ t = 'Latao'; d = 'Cobre e zinco misturados com calor viram latao, o material das maquinas avancadas.'; item = 'create:brass_ingot'; p = 'create:brass_ingot'; n = 8 }
        @{ t = 'Mecanismo de precisao'; d = 'Peca das maquinas avancadas. Veja a receita em sequencia no JEI (tecla R).'; item = 'create:precision_mechanism' }
        @{ t = 'Construcoes prontas'; d = 'A mesa de esquemas e o canhao de esquemas (Schematicannon) montam uma construcao inteira a partir de um arquivo de esquema.', 'Coloque arquivos .nbt na pasta schematics do jogo; ha milhares prontos no site createmod.com.'; item = 'create:schematicannon' }
        @{ t = 'Trens'; d = 'Trilho, estacao e controles formam um trem. O Ponder (W) mostra a montagem passo a passo.'; item = 'create:controls' }
    ) }
    @{ t = 'Mochila e baus'; icone = 'sophisticatedbackpacks:backpack'; m = @(
        @{ t = 'Base de melhoria'; d = 'As melhorias da mochila partem desta base. Clique com o botao direito na mochila e coloque nas casas de melhoria.'; item = 'sophisticatedbackpacks:upgrade_base' }
        @{ t = 'Coletar sozinho'; d = 'A melhoria de coleta guarda direto na mochila o que voce pega do chao.'; item = 'sophisticatedbackpacks:pickup_upgrade' }
        @{ t = 'Ima'; d = 'A melhoria de ima puxa os itens de perto para a mochila.'; item = 'sophisticatedbackpacks:magnet_upgrade' }
        @{ t = 'Comer sozinho'; d = 'A melhoria de alimentacao come a comida da mochila quando voce fica com fome.'; item = 'sophisticatedbackpacks:feeding_upgrade' }
        @{ t = 'Mochila de ferro'; d = 'Mochila maior, com mais espaco e mais casas de melhoria. Depois vem ouro, diamante e netherite.'; item = 'sophisticatedbackpacks:iron_backpack' }
        @{ t = 'Bau de ferro'; d = 'Iron Chests: baus maiores que o normal. Ferro, ouro, diamante e outros.'; item = 'ironchest:iron_chest'; solta = $true }
        @{ t = 'Bau grande do Sophisticated'; d = 'Sophisticated Storage: baus e barris com melhorias, como a mochila.'; item = 'sophisticatedstorage:chest'; solta = $true }
    ) }
    @{ t = 'Cozinha e fazenda'; icone = 'farmersdelight:cooking_pot'; m = @(
        @{ t = 'Faca'; d = 'A faca colhe palha e corta comida na tabua.'; item = 'farmersdelight:flint_knife' }
        @{ t = 'Tabua de corte'; d = 'Coloque um ingrediente na tabua e clique com a faca para cortar.'; item = 'farmersdelight:cutting_board' }
        @{ t = 'Fogao'; d = 'O fogao cozinha em cima e aquece a panela e a frigideira.'; item = 'farmersdelight:stove' }
        @{ t = 'Terra rica'; d = 'Composto organico vira terra rica, onde as plantas crescem mais rapido.'; item = 'farmersdelight:rich_soil' }
        @{ t = 'Cozinha montada'; d = 'Cooking for Blockheads: a mesa de cozinha mostra tudo que da para fazer com o que esta na geladeira e nos baus ao lado.'; item = 'cookingforblockheads:cooking_table'; solta = $true }
        @{ t = 'Vaso que planta sozinho'; d = 'Botany Pots: coloque terra e uma semente; com funil embaixo ele colhe sozinho.'; item = 'botanypots:terracotta_botany_pot'; solta = $true }
        @{ t = 'Plantacao de minerio'; d = 'Mystical Agriculture: essencia de inferium sai do minerio de inferium e vira sementes que dao materiais.'; item = 'mysticalagriculture:inferium_essence'; solta = $true }
        @{ t = 'Estacoes do ano'; d = 'Serene Seasons: o ano tem primavera, verao, outono e inverno. Cada planta cresce melhor em certas estacoes; o JEI mostra quais.'; solta = $true }
    ) }
    @{ t = 'Construir'; icone = 'buildinggadgets2:gadget_building'; m = @(
        @{ t = 'Ferramenta de construir'; d = 'Building Gadgets: coloca varios blocos de uma vez. Precisa de energia (carregue em um carregador de energia).'; item = 'buildinggadgets2:gadget_building' }
        @{ t = 'Copiar e colar'; d = 'Copia uma area e cola em outro lugar, gastando os blocos do seu inventario.'; item = 'buildinggadgets2:gadget_copy_paste' }
        @{ t = 'Construir com espelho'; d = 'Effortless Building: segure Alt para escolher modos como parede, linha, espelho e repeticao.'; solta = $true }
        @{ t = 'Telhados de verdade'; d = 'Macaw''s Roofs, Windows, Doors, Fences e Furniture: blocos de telhado, janelas, portas, cercas e moveis. Procure por mcw no JEI.'; solta = $true }
        @{ t = 'Moveis'; d = 'Handcrafted, Beautify, Supplementaries e Bubblellaneous trazem moveis e decoracao. Procure pelo nome do mod no JEI com @.'; solta = $true }
    ) }
    @{ t = 'Animais'; icone = 'alexsmobs:animal_dictionary'; m = @(
        @{ t = 'Dicionario animal'; d = 'Alex''s Mobs tem um livro que explica cada bicho, o que ele come e como domesticar.'; item = 'alexsmobs:animal_dictionary' }
        @{ t = 'Banana'; d = 'Bananas caem das folhas de selva. Varios bichos do Alex''s Mobs gostam delas, como os macacos.'; item = 'alexsmobs:banana' }
        @{ t = 'Hamster'; d = 'Adorable Hamster Pets: hamsters de estimacao que seguem voce e cabem no ombro.'; solta = $true }
        @{ t = 'Dragao'; d = 'Dragon Mounts: ovos de dragao chocam um dragao que voce cria e monta.'; solta = $true }
        @{ t = 'Mais bichos'; d = 'Naturalist, Critters and Companions, Friends&Foes, Wilder Nature e Archie''s Dinosaurs espalham bichos pelos biomas. O Jade mostra o nome de cada um.'; solta = $true }
    ) }
    @{ t = 'Explorar'; icone = 'naturescompass:naturescompass'; m = @(
        @{ t = 'Bussola de biomas'; d = 'Nature''s Compass aponta para o bioma que voce escolher.'; item = 'naturescompass:naturescompass' }
        @{ t = 'Bussola de estruturas'; d = 'Explorer''s Compass aponta para vilas, templos, masmorras e outras estruturas.'; item = 'explorerscompass:explorerscompass' }
        @{ t = 'Atlas'; d = 'Map Atlases junta mapas de papel em um livro. Na mao secundaria vira minimapa.'; item = 'map_atlases:atlas' }
        @{ t = 'Pergaminho de volta'; d = 'O pergaminho de retorno leva de volta para a ultima waystone ou cama.'; item = 'waystones:return_scroll' }
    ) }
    @{ t = 'Mekanism'; icone = 'mekanism:metallurgic_infuser'; m = @(
        @{ t = 'Infusor metalurgico'; d = 'A primeira maquina: mistura ferro com carvao para fazer aco e outras ligas. Precisa de energia.'; item = 'mekanism:metallurgic_infuser' }
        @{ t = 'Energia'; d = 'O Mekanism do pack nao tem geradores proprios: o alternador do Create Crafts & Additions transforma a rotacao do Create em energia para as maquinas.'; item = 'createaddition:alternator' }
        @{ t = 'Camara de enriquecimento'; d = 'Transforma um minerio em dois montes de po: o dobro de lingotes.'; item = 'mekanism:enrichment_chamber' }
        @{ t = 'Cabos'; d = 'Cabos universais levam energia do gerador para as maquinas.'; item = 'mekanism:basic_universal_cable' }
    ) }
    @{ t = 'Dimensoes'; icone = 'minecraft:ender_eye'; m = @(
        @{ t = 'Nether'; d = 'Portal de obsidiana aceso com isqueiro.'; dim = 'minecraft:the_nether'; solta = $true }
        @{ t = 'Aether'; d = 'O ceu do Minecraft: moldura de pedra luminosa (glowstone) acesa com um balde de agua.'; dim = 'aether:the_aether'; solta = $true }
        @{ t = 'Twilight Forest'; d = 'Poca de agua 2x2 cercada de flores; jogue um diamante dentro.'; dim = 'twilightforest:twilight_forest'; solta = $true }
        @{ t = 'Undergarden'; d = 'Moldura de tijolos de pedra ativada com o catalisador do Undergarden (receita no JEI).'; dim = 'undergarden:undergarden'; solta = $true }
        @{ t = 'Eternal Starlight'; d = 'Dimensao das estrelas: procure as ruinas de portal pelo mundo e veja no JEI como ativar.'; dim = 'eternal_starlight:starlight'; solta = $true }
        @{ t = 'Masmorras infinitas'; d = 'Dimensional Dungeons: a chave de portal abre masmorras que se renovam (receita no JEI).'; dim = 'dimdungeons:dungeon_dimension'; solta = $true }
        @{ t = 'Lua'; d = 'Ad Astra: monte um foguete na bancada da NASA e voe para a Lua.'; dim = 'ad_astra:moon'; solta = $true }
        @{ t = 'End'; d = 'Olhos de ender levam ao portal do End e ao dragao.'; dim = 'minecraft:the_end'; solta = $true }
    ) }
    @{ t = 'Aether'; icone = 'aether:ambrosium_shard'; m = @(
        @{ t = 'Chegar no Aether'; d = 'Moldura de glowstone acesa com um balde de agua. Leve o paraquedas dourado que o mod da na primeira visita.'; dim = 'aether:the_aether' }
        @{ t = 'Ambrosium'; d = 'Fragmentos de ambrosium curam e servem de combustivel no Aether.'; item = 'aether:ambrosium_shard' }
        @{ t = 'Zanite'; d = 'Gema azul para ferramentas e armadura do Aether.'; item = 'aether:zanite_gemstone' }
        @{ t = 'Primeira masmorra'; d = 'Venca o Slider na masmorra de bronze e pegue a chave de bronze.'; item = 'aether:bronze_dungeon_key' }
        @{ t = 'Rainha Valquiria'; d = 'A masmorra de prata guarda a Rainha Valquiria e a chave de prata.'; item = 'aether:silver_dungeon_key' }
        @{ t = 'Espirito do Sol'; d = 'A masmorra de ouro e o fim do Aether: venca o Espirito do Sol.'; item = 'aether:gold_dungeon_key' }
    ) }
    @{ t = 'Twilight Forest'; icone = 'twilightforest:naga_scale'; m = @(
        @{ t = 'Entrar'; d = 'Poca de agua 2x2 cercada de flores; jogue um diamante dentro.'; dim = 'twilightforest:twilight_forest' }
        @{ t = 'Naga'; d = 'O primeiro chefe vive no patio de pedra. Ele deixa escamas para armadura.'; item = 'twilightforest:naga_scale' }
        @{ t = 'Mapa magico'; d = 'Com o foco de mapa magico voce faz um mapa que mostra os biomas e as estruturas dos chefes.'; item = 'twilightforest:magic_map_focus' }
        @{ t = 'Proximos chefes'; d = 'A progressao segue: Lich, Hidra, Ur-Ghast e outros. Cada chefe libera a regiao seguinte; tentar pular da efeitos ruins.'; }
    ) }
    @{ t = 'Undergarden'; icone = 'undergarden:catalyst'; m = @(
        @{ t = 'Catalisador'; d = 'O catalisador ativa o portal de tijolos de pedra.'; item = 'undergarden:catalyst' }
        @{ t = 'Entrar'; d = 'Undergarden e um mundo escuro e perigoso embaixo da terra. Leve tochas.'; dim = 'undergarden:undergarden' }
        @{ t = 'Cloggrum'; d = 'O primeiro metal do Undergarden, para ferramentas.'; item = 'undergarden:cloggrum_ingot' }
        @{ t = 'Froststeel'; d = 'Metal gelado que deixa os inimigos mais lentos.'; item = 'undergarden:froststeel_ingot' }
        @{ t = 'Utherium'; d = 'Cristal forte contra as criaturas do Undergarden.'; item = 'undergarden:utherium_crystal' }
    ) }
    @{ t = 'Espaco'; icone = 'ad_astra:tier_1_rocket'; m = @(
        @{ t = 'Aco'; d = 'Ad Astra comeca com aco.'; item = 'ad_astra:steel_ingot' }
        @{ t = 'Bancada da NASA'; d = 'A bancada da NASA monta as pecas do foguete.'; item = 'ad_astra:nasa_workbench' }
        @{ t = 'Traje espacial'; d = 'Capacete e traje espacial com oxigenio sao obrigatorios fora da Terra.'; item = 'ad_astra:space_suit' }
        @{ t = 'Foguete'; d = 'Foguete nivel 1: leva ate a Lua. Abasteca com combustivel e coloque na plataforma de lancamento.'; item = 'ad_astra:tier_1_rocket' }
        @{ t = 'Lua'; d = 'Na Lua tem desh, o metal do foguete seguinte.'; dim = 'ad_astra:moon' }
        @{ t = 'Desh'; d = 'Com desh voce faz o foguete nivel 2 e chega em Marte.'; item = 'ad_astra:desh_ingot' }
        @{ t = 'Marte'; d = 'Marte e o caminho para Venus, Mercurio e Glacio.'; dim = 'ad_astra:mars' }
    ) }
)

# Confere os ids nos jars do pack (tools/jars, baixados pelo montar-pack): item que nao existe deixaria a missao
# impossivel. Ids do Minecraft (minecraft:) ficam de fora. Sem tools/jars, avisa e segue.
$jarsDir = Join-Path $root 'tools/jars'
if (Test-Path $jarsDir) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $existe = New-Object 'Collections.Generic.HashSet[string]'
    foreach ($j in Get-ChildItem $jarsDir -Filter *.jar) {
        try { $z = [IO.Compression.ZipFile]::OpenRead($j.FullName) } catch { continue }
        foreach ($e in $z.Entries) {
            if ($e.FullName -match '^assets/([a-z0-9_.-]+)/models/item/([a-z0-9_/.-]+)\.json$') { [void]$existe.Add("$($matches[1]):$($matches[2])") }
            elseif ($e.FullName -match '^data/([a-z0-9_.-]+)/dimension/([a-z0-9_/.-]+)\.json$') { [void]$existe.Add("$($matches[1]):$($matches[2])") }
        }
        $z.Dispose()
    }
    $faltam = @(foreach ($c in $capitulos) { foreach ($id in @($c.icone) + @($c.m | ForEach-Object { $_['item']; $_['dim']; $_['p'] })) {
        if ($id -and $id -notlike 'minecraft:*' -and -not $existe.Contains($id)) { "$($c.t): $id" } } })
    if ($faltam) { throw "Ids que nao existem no pack:`n$($faltam -join "`n")" }
}
else { Write-Warning 'Sem tools/jars (rode o montar-pack): ids nao conferidos.' }

# Id fixo pelo nome (16 hex), para o progresso dos jogadores nao se perder quando o livro for gerado de novo.
$md5 = [Security.Cryptography.MD5]::Create()
function Id($s) { -join ($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))[0..7] | ForEach-Object { $_.ToString('X2') }) }
function Txt($s) { '"' + $s.Replace('\', '\\').Replace('"', '\"') + '"' }

$utf8 = New-Object Text.UTF8Encoding $false
if (Test-Path $destino) { Remove-Item -Recurse -Force $destino }
New-Item -ItemType Directory -Force (Join-Path $destino 'chapters'), (Join-Path $destino 'lang') | Out-Null
[IO.File]::WriteAllText((Join-Path $destino 'data.snbt'), "{`n`tdefault_quest_shape: `"circle`"`n`tdefault_reward_team: false`n`tdisable_gui: false`n`tgrid_scale: 0.5d`n`tpause_game: false`n`tprogression_mode: `"flexible`"`n`tversion: 13`n}`n", $utf8)
$lang = @()
$ordem = 0
foreach ($c in $capitulos) {
    $cid = Id "capitulo/$($c.t)"; $nome = ($c.t.ToLower() -replace '[^a-z0-9]+', '_').Trim('_')
    $lang += "`tchapter.$cid.title: $(Txt $c.t)"
    $qs = @(); $ant = $null; $x = 0
    foreach ($m in $c.m) {
        $qid = Id "missao/$($c.t)/$($m.t)"
        $tarefa = if ($m['item']) { "{ id: `"$(Id "tarefa/$qid")`", item: { count: 1, id: `"$($m['item'])`" }, type: `"item`" }" }
            elseif ($m['dim']) { "{ dimension: `"$($m['dim'])`", id: `"$(Id "tarefa/$qid")`", type: `"dimension`" }" }
            else { "{ id: `"$(Id "tarefa/$qid")`", type: `"checkmark`" }" }
        $premio = if ($m['p']) { "`n`t`t`trewards: [{ id: `"$(Id "premio/$qid")`", item: { count: $(if ($m['n']) { $m['n'] } else { 1 }), id: `"$($m['p'])`" }, type: `"item`" }]" } else { '' }
        $dep = if ($ant -and -not $m['solta']) { "`n`t`t`tdependencies: [`"$ant`"]" } else { '' }
        $y = if ($m['solta']) { [math]::Floor($x / 4) * 1.5 } else { 0 }; $px = if ($m['solta']) { ($x % 4) * 1.5 } else { $x * 1.5 }
        $qs += "`t`t{$dep`n`t`t`tid: `"$qid`"$premio`n`t`t`ttasks: [$tarefa]`n`t`t`tx: $($px)d`n`t`t`ty: $($y)d`n`t`t}"
        $lang += "`tquest.$qid.title: $(Txt $m.t)"
        $lang += "`tquest.$qid.quest_desc: [$((@($m.d) | ForEach-Object { Txt $_ }) -join ', ')]"
        $ant = $qid; $x++
    }
    $cap = "{`n`tdefault_hide_dependency_lines: false`n`tdefault_quest_shape: `"`"`n`tfilename: `"$nome`"`n`tgroup: `"`"`n`ticon: { id: `"$($c.icone)`" }`n`tid: `"$cid`"`n`torder_index: $ordem`n`tquest_links: [ ]`n`tquests: [`n$($qs -join "`n")`n`t]`n}`n"
    [IO.File]::WriteAllText((Join-Path $destino "chapters/$nome.snbt"), $cap, $utf8)
    $ordem++
}
# pt_br para o jogo em portugues; en_us igual, para quem trocou o idioma nao ver chaves no lugar do texto.
foreach ($l in 'pt_br', 'en_us') { [IO.File]::WriteAllText((Join-Path $destino "lang/$l.snbt"), "{`n$($lang -join "`n")`n}`n", $utf8) }
Write-Host "$($capitulos.Count) capitulos, $(@($capitulos | ForEach-Object { $_.m }).Count) missoes -> $destino"
