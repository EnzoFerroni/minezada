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
)

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
