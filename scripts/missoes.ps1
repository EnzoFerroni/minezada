# Gera o livro de missoes (FTB Quests) em server-config/config/ftbquests/quests a partir da tabela abaixo.
# O servidor manda o livro para cada jogador; o progresso fica no mundo, nao aqui.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/missoes.ps1 (Mac: pwsh scripts/missoes.ps1)
# Cada missao: t = titulo, d = texto (uma linha por item), e uma tarefa: item (id do item), dim (id da dimensao)
# mata (id do bicho), estrutura ou bioma (id do mundo) ou nada (o jogador marca como feito). q = quantidade da
# tarefa (itens ou abates). p = premio (id do item) e n = quantidade. Cada missao depende da anterior
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
    @{ t = 'Create 1: o basico'; icone = 'create:cogwheel'; m = @(
        @{ t = 'O que e o Create'; d = 'Create e um mod de maquinas que funcionam com rotacao, como um moinho de verdade: algo gira (agua, vento, vapor) e eixos levam o giro ate as maquinas.', 'Segure W com o mouse em cima de qualquer item do Create para ver uma animacao explicando ele (Ponder).' }
        @{ t = 'Liga de andesito'; d = 'O material de quase tudo no comeco: andesito com pepitas de ferro (ou zinco). Receita no JEI (tecla R).'; item = 'create:andesite_alloy'; q = 16; p = 'create:andesite_alloy'; n = 16 }
        @{ t = 'Revestimento de andesito'; d = 'Clique com a liga de andesito em um tronco descascado. O revestimento e a base de varias maquinas.'; item = 'create:andesite_casing' }
        @{ t = 'Eixos'; d = 'O eixo leva a rotacao em linha reta.'; item = 'create:shaft'; q = 8 }
        @{ t = 'Engrenagens'; d = 'Engrenagens passam o giro para os lados. Duas engrenagens encostadas giram em sentidos opostos.', 'Engrenagem grande ligada a pequena muda a velocidade: pequena para grande diminui, grande para pequena aumenta.'; item = 'create:cogwheel'; q = 4 }
        @{ t = 'Engrenagem grande'; d = 'Junto com a pequena, ela faz curvas e muda a velocidade (RPM).'; item = 'create:large_cogwheel' }
        @{ t = 'Caixa de engrenagens'; d = 'Faz curvas de 90 graus em pouco espaco.'; item = 'create:gearbox' }
        @{ t = 'Manivela'; d = 'Gira as maquinas com a mao, para testar. Cansa: gasta fome.'; item = 'create:hand_crank' }
        @{ t = 'Roda d''agua'; d = 'Coloque na beira de agua corrente: a agua empurra a roda e ela gira o eixo. Agua dos dois lados trava a roda.'; item = 'create:water_wheel'; p = 'create:shaft'; n = 8 }
        @{ t = 'Oculos de engenheiro'; d = 'Com os oculos voce olha uma maquina e ve a velocidade e o esforco (stress) dela.'; item = 'create:goggles' }
        @{ t = 'Stress'; d = 'Cada maquina gasta esforco (SU). Cada fonte de giro tem um limite de SU. Passou do limite, tudo para (overstressed): coloque mais fontes ou baixe a velocidade.', 'O medidor de stress mostra quanto da rede esta em uso.'; item = 'create:stressometer' }
    ) }
    @{ t = 'Create 2: primeiras maquinas'; icone = 'create:mechanical_press'; m = @(
        @{ t = 'Deposito'; d = 'O deposito segura itens embaixo das maquinas, como uma mesa.'; item = 'create:depot' }
        @{ t = 'Prensa'; d = 'A prensa em cima de um deposito amassa lingotes em chapas. Chapas de ferro aparecem em muitas receitas.'; item = 'create:mechanical_press' }
        @{ t = 'Chapa de ferro'; d = 'Faca suas primeiras chapas com a prensa.'; item = 'create:iron_sheet'; q = 16; p = 'minecraft:iron_ingot'; n = 16 }
        @{ t = 'Esteira'; d = 'Feita de alga seca. Clique em dois eixos para ligar: leva itens de uma maquina para outra e tambem passa o giro.'; item = 'create:belt_connector' }
        @{ t = 'Moedor'; d = 'O moedor transforma trigo em farinha e pedregulho em cascalho.'; item = 'create:millstone' }
        @{ t = 'Ventilador'; d = 'O ventilador sopra itens. Com fogo atras ele cozinha, com lava ele derrete, com agua ele lava os itens no caminho.'; item = 'create:encased_fan' }
        @{ t = 'Serra'; d = 'A serra corta madeira. Numa estrutura que anda, derruba arvores inteiras.'; item = 'create:mechanical_saw' }
        @{ t = 'Broca'; d = 'A broca quebra o bloco da frente. Com rolamentos e pistoes vira uma maquina de minerar.'; item = 'create:mechanical_drill' }
        @{ t = 'Moinho de vento'; d = 'O rolamento de moinho com velas em volta gira sem agua. Mais velas, mais forca. Clique no rolamento para comecar.'; item = 'create:windmill_bearing' }
        @{ t = 'Velas'; d = 'As velas do moinho. La tambem serve.'; item = 'create:white_sail'; q = 8 }
        @{ t = 'Cola'; d = 'A super cola junta blocos para que se movam juntos numa estrutura.'; item = 'create:super_glue' }
        @{ t = 'Pistao mecanico'; d = 'Empurra uma estrutura inteira para frente e para tras.'; item = 'create:mechanical_piston' }
        @{ t = 'Rolamento mecanico'; d = 'Gira uma estrutura inteira, como uma roda gigante ou uma porta.'; item = 'create:mechanical_bearing' }
    ) }
    @{ t = 'Create 3: era do latao'; icone = 'create:brass_ingot'; m = @(
        @{ t = 'Bacia'; d = 'A bacia guarda os ingredientes para o misturador e a prensa.'; item = 'create:basin' }
        @{ t = 'Misturador'; d = 'Em cima da bacia, com um bloco de espaco, ele mistura os ingredientes.'; item = 'create:mechanical_mixer' }
        @{ t = 'Queimador de blaze'; d = 'Faca o queimador vazio e clique com ele em um blaze. Embaixo da bacia ele aquece as receitas; alimente com carvao.'; item = 'create:blaze_burner' }
        @{ t = 'Latao'; d = 'Cobre e zinco na bacia aquecida viram latao.'; item = 'create:brass_ingot'; q = 16; p = 'create:brass_ingot'; n = 8 }
        @{ t = 'Revestimento de latao'; d = 'Latao em tronco descascado. Base das maquinas avancadas.'; item = 'create:brass_casing' }
        @{ t = 'Quartzo rosa'; d = 'Quartzo rosa polido vira tubo de eletrons, a peca eletronica do Create.'; item = 'create:electron_tube' }
        @{ t = 'Deployer'; d = 'O deployer usa o item da mao dele no bloco da frente, como um jogador. Base da montagem automatica.'; item = 'create:deployer' }
        @{ t = 'Mecanismo de precisao'; d = 'Feito em varias etapas numa esteira com deployers (montagem em sequencia). Veja o passo a passo no JEI.'; item = 'create:precision_mechanism'; p = 'create:precision_mechanism'; n = 2 }
        @{ t = 'Funil de latao'; d = 'Funis colocam e tiram itens das esteiras e baus. O de latao tem filtro.'; item = 'create:brass_funnel' }
        @{ t = 'Tunel de latao'; d = 'Divide os itens de uma esteira entre varias saidas.'; item = 'create:brass_tunnel' }
        @{ t = 'Crafter mecanico'; d = 'Varios crafters juntos fazem receitas grandes sozinhos.'; item = 'create:mechanical_crafter'; q = 9 }
        @{ t = 'Britadores'; d = 'Duas rodas trituradoras girando para dentro moem minerio e dao mais material.'; item = 'create:crushing_wheel'; q = 2 }
    ) }
    @{ t = 'Create 4: vapor, fluidos e trens'; icone = 'create:steam_engine'; m = @(
        @{ t = 'Tubos'; d = 'Tubos levam liquidos.'; item = 'create:fluid_pipe'; q = 8 }
        @{ t = 'Bomba'; d = 'A bomba gira e empurra o liquido pelos tubos. A chave inglesa inverte o sentido.'; item = 'create:mechanical_pump' }
        @{ t = 'Tanque'; d = 'Tanques guardam liquido. Varios juntos fazem um tanque grande.'; item = 'create:fluid_tank'; q = 4 }
        @{ t = 'Bico'; d = 'O bico (spout) enche itens com liquido, como garrafas e baldes.'; item = 'create:spout' }
        @{ t = 'Motor a vapor'; d = 'Tanque com agua em cima de queimadores de blaze vira caldeira; o motor a vapor no tanque da muita forca.'; item = 'create:steam_engine' }
        @{ t = 'Trilhos'; d = 'Os trilhos do Create fazem curvas grandes e subidas.'; item = 'create:track'; q = 32 }
        @{ t = 'Estacao'; d = 'A estacao e onde o trem para e e montado.'; item = 'create:track_station' }
        @{ t = 'Controles'; d = 'Os controles dirigem o trem. Com um horario, ele anda sozinho entre estacoes.'; item = 'create:controls' }
        @{ t = 'Construcoes prontas'; d = 'A mesa de esquemas e o canhao de esquemas montam uma construcao inteira a partir de um arquivo. Coloque arquivos .nbt na pasta schematics do jogo; ha muitos prontos no site createmod.com.'; item = 'create:schematicannon' }
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
        @{ t = 'Venus'; d = 'Venus e quente e acida: va com o traje certo.'; dim = 'ad_astra:venus'; solta = $true }
        @{ t = 'Mercurio'; d = 'O planeta mais perto do Sol.'; dim = 'ad_astra:mercury'; solta = $true }
        @{ t = 'Glacio'; d = 'O planeta gelado, o mais longe de todos.'; dim = 'ad_astra:glacio'; solta = $true }
        @{ t = 'Vila lunar'; d = 'Os lunarianos tem vilas na Lua e trocam itens como os aldeoes.'; estrutura = 'ad_astra:lunarian_village'; solta = $true }
    ) }
    @{ t = 'Utilidades'; icone = 'justhammers:iron_hammer'; m = @(
        @{ t = 'Minerar em bloco'; d = 'VeinMiner: segure a tecla ao lado do 1 e quebre um minerio para levar o veio inteiro.'; solta = $true }
        @{ t = 'Marcar no mapa'; d = 'Ping Wheel: o botao do meio do mouse marca um ponto para todo mundo ver.'; solta = $true }
        @{ t = 'Carregar bau'; d = 'Carry On: agache com a mao vazia e clique em um bau para levar ele inteiro, com tudo dentro.'; solta = $true }
        @{ t = 'Martelo'; d = 'Just Hammers: o martelo quebra uma area 3x3 de uma vez.'; item = 'justhammers:iron_hammer'; solta = $true }
        @{ t = 'Saco de dormir'; d = 'Comforts: o saco de dormir passa a noite sem mudar o seu ponto de nascer.'; item = 'comforts:sleeping_bag_white'; solta = $true }
        @{ t = 'Zoom'; d = 'Ok Zoomer: segure C para dar zoom; a roda do mouse ajusta.'; solta = $true }
        @{ t = 'Baus de saque'; d = 'Lootr: cada jogador abre o seu proprio saque nos baus das estruturas. Ninguem fica sem.'; solta = $true }
        @{ t = 'Terminal de armazenamento'; d = 'Tom''s Storage: liga varios baus em um terminal so, com busca.'; item = 'toms_storage:storage_terminal'; solta = $true }
        @{ t = 'Netherite melhor'; d = 'Advanced Netherite: ferramentas e armaduras alem da netherite, com ferro, ouro, esmeralda e diamante.'; item = 'advancednetherite:netherite_diamond_ingot'; solta = $true }
        @{ t = 'Fumar'; d = 'Smoking Pipe, CiggyCraft e Tobacconist: plante tabaco e fume. So por diversao.'; solta = $true }
    ) }
    @{ t = 'Create: addons'; icone = 'create_jetpack:jetpack'; m = @(
        @{ t = 'Jetpack'; d = 'Create Jetpack: voa com ar comprimido de um tanque.'; item = 'create_jetpack:jetpack'; solta = $true }
        @{ t = 'Escavadeira de minerio'; d = 'Create Ore Excavation: maquinas que extraem minerio de veios infinitos no subsolo.'; solta = $true }
        @{ t = 'Encantar com maquina'; d = 'Create Enchantment Industry: transforma experiencia em liquido e encanta itens com maquinas.'; solta = $true }
        @{ t = 'Energia'; d = 'Create Crafts & Additions: o alternador gera energia e o motor eletrico gira as maquinas.'; item = 'createaddition:electric_motor'; solta = $true }
        @{ t = 'Cozinha automatica'; d = 'Create Central Kitchen: as maquinas do Create fazem as comidas do Farmer''s Delight.'; solta = $true }
    ) }
    @{ t = 'Cacador de chefes'; icone = 'minecraft:wither_skeleton_skull'; m = @(
        @{ t = 'Wither'; d = 'Tres cranios de esqueleto wither em cima de areia das almas em T. Faca longe de casa.'; mata = 'minecraft:wither'; p = 'minecraft:diamond'; n = 8; solta = $true }
        @{ t = 'Dragao do Ender'; d = 'O chefe do End.'; mata = 'minecraft:ender_dragon'; p = 'minecraft:diamond'; n = 8; solta = $true }
        @{ t = 'Warden'; d = 'Mora nas cidades antigas do subsolo escuro. Sem barulho, ele nao aparece.'; mata = 'minecraft:warden'; p = 'minecraft:diamond'; n = 8; solta = $true }
        @{ t = 'Guardiao anciao'; d = 'Mora no monumento do oceano.'; mata = 'minecraft:elder_guardian'; p = 'minecraft:sponge'; n = 4; solta = $true }
        @{ t = 'Cavaleiro de ferro'; d = 'Mowzie''s Mobs: o Ferrous Wroughtnaut guarda uma camara no subsolo. Acerte as costas depois que ele erra o golpe.'; mata = 'mowziesmobs:ferrous_wroughtnaut'; solta = $true }
        @{ t = 'Frostmaw'; d = 'Mowzie''s Mobs: um gigante de gelo que dorme nos biomas de neve.'; mata = 'mowziesmobs:frostmaw'; solta = $true }
        @{ t = 'Umvuthi'; d = 'Mowzie''s Mobs: o passaro do sol que lidera o povo da savana.'; mata = 'mowziesmobs:umvuthi'; solta = $true }
        @{ t = 'Escultor'; d = 'Mowzie''s Mobs: Tongbi, o Escultor, no topo do monasterio nas montanhas.'; mata = 'mowziesmobs:sculptor'; solta = $true }
        @{ t = 'Capita Cornelia'; d = 'Aquamirae: o fantasma da capita nos navios piratas do oceano gelado.'; mata = 'aquamirae:captain_cornelia'; solta = $true }
        @{ t = 'Maw'; d = 'Aquamirae: monstro das aguas geladas.'; mata = 'aquamirae:maw'; solta = $true }
        @{ t = 'Guardiao esquecido'; d = 'Undergarden: o chefe das catacumbas.'; mata = 'undergarden:forgotten_guardian'; solta = $true }
        @{ t = 'Guardiao do portao'; d = 'Eternal Starlight: The Gatekeeper.'; mata = 'eternal_starlight:the_gatekeeper'; solta = $true }
        @{ t = 'Golem estelar'; d = 'Eternal Starlight: o golem da forja.'; mata = 'eternal_starlight:starlight_golem'; solta = $true }
        @{ t = 'Monstro lunar'; d = 'Eternal Starlight: a Lunar Monstrosity.'; mata = 'eternal_starlight:lunar_monstrosity'; solta = $true }
    ) }
    @{ t = 'Chefes da Twilight'; icone = 'twilightforest:naga_scale'; m = @(
        @{ t = 'Naga'; d = 'O primeiro chefe, no patio de pedra.'; mata = 'twilightforest:naga' }
        @{ t = 'Lich'; d = 'A torre do Lich. Quebre os escudos dele antes de atacar.'; mata = 'twilightforest:lich' }
        @{ t = 'Minoshroom'; d = 'No fundo do labirinto do pantano.'; mata = 'twilightforest:minoshroom' }
        @{ t = 'Hidra'; d = 'No covil de fogo. Leve resistencia ao fogo.'; mata = 'twilightforest:hydra' }
        @{ t = 'Cavaleiros fantasmas'; d = 'Na fortaleza dos cavaleiros, na floresta escura.'; mata = 'twilightforest:knight_phantom' }
        @{ t = 'Ur-Ghast'; d = 'No topo da torre escura.'; mata = 'twilightforest:ur_ghast' }
        @{ t = 'Yeti alfa'; d = 'Na caverna dos yetis, na floresta de neve.'; mata = 'twilightforest:alpha_yeti' }
        @{ t = 'Rainha da Neve'; d = 'No palacio da aurora, no glaciar.'; mata = 'twilightforest:snow_queen' }
    ) }
    @{ t = 'Explorador'; icone = 'explorerscompass:explorerscompass'; m = @(
        @{ t = 'Cidade antiga'; d = 'No subsolo escuro. Cuidado com o Warden.'; estrutura = 'minecraft:ancient_city'; solta = $true }
        @{ t = 'Camaras de desafio'; d = 'Salas com geradores de desafio e o cofre das chaves.'; estrutura = 'minecraft:trial_chambers'; solta = $true }
        @{ t = 'Mansao da floresta'; d = 'Na floresta escura, cheia de illagers.'; estrutura = 'minecraft:mansion'; solta = $true }
        @{ t = 'Fortaleza'; d = 'Onde fica o portal do End. Os olhos de ender apontam para ela.'; estrutura = 'betterstrongholds:stronghold'; solta = $true }
        @{ t = 'Fortaleza do Nether'; d = 'Onde nascem os blazes e os esqueletos wither.'; estrutura = 'betterfortresses:fortress'; solta = $true }
        @{ t = 'Monumento do oceano'; d = 'Debaixo do mar, com os guardioes.'; estrutura = 'betteroceanmonuments:ocean_monument'; solta = $true }
        @{ t = 'Coliseu'; d = 'When Dungeons Arise: uma arena enorme cheia de inimigos.'; estrutura = 'dungeons_arise:coliseum'; solta = $true }
        @{ t = 'Fortaleza illager'; d = 'When Dungeons Arise: um forte dos illagers.'; estrutura = 'dungeons_arise:illager_fort'; solta = $true }
        @{ t = 'Navio pirata morto-vivo'; d = 'When Dungeons Arise: um navio fantasma no mar.'; estrutura = 'dungeons_arise:undead_pirate_ship'; solta = $true }
        @{ t = 'Palacio Shiraz'; d = 'When Dungeons Arise: um palacio no deserto.'; estrutura = 'dungeons_arise:shiraz_palace'; solta = $true }
        @{ t = 'Asilo da praga'; d = 'When Dungeons Arise: o lugar mais assustador do pack.'; estrutura = 'dungeons_arise:plague_asylum'; solta = $true }
        @{ t = 'Dirigivel'; d = 'When Dungeons Arise: um dirigivel no ceu.'; estrutura = 'dungeons_arise:small_blimp'; solta = $true }
        @{ t = 'Navio pirata'; d = 'Aquamirae: navio pirata no oceano gelado, onde mora a Capita Cornelia.'; estrutura = 'aquamirae:pirate_ship'; solta = $true }
        @{ t = 'Camara de ferro'; d = 'Mowzie''s Mobs: a camara do Ferrous Wroughtnaut.'; estrutura = 'mowziesmobs:wrought_chamber'; solta = $true }
        @{ t = 'Vila dos sapos'; d = 'Ribbits: vila de sapos no pantano.'; estrutura = 'ribbits:ribbit_village'; solta = $true }
        @{ t = 'Castelo proibido'; d = 'Incendium: o castelo do Nether.'; estrutura = 'incendium:forbidden_castle'; solta = $true }
        @{ t = 'Vila piglin'; d = 'Incendium: uma vila de piglins no Nether.'; estrutura = 'incendium:piglin_village'; solta = $true }
        @{ t = 'Taverna'; d = 'Explorify: uma taverna na estrada.'; estrutura = 'explorify:tavern'; solta = $true }
        @{ t = 'Cidadela'; d = 'Friends&Foes: a cidadela dos illagers.'; estrutura = 'friendsandfoes:citadel'; solta = $true }
        @{ t = 'Ninho de dinossauro'; d = 'Archie''s Dinosaurs: uma cratera com fosseis.'; estrutura = 'ec_ad:big_crater'; solta = $true }
        @{ t = 'Esqueleto de dragao'; d = 'Nullscape: um esqueleto gigante no End.'; estrutura = 'nullscape:dragon_skeleton'; solta = $true }
    ) }
    @{ t = 'Volta ao mundo'; icone = 'naturescompass:naturescompass'; m = @(
        @{ t = 'Cerejeiras'; d = 'Um vale de cerejeiras rosa.'; bioma = 'terralith:sakura_valley'; solta = $true }
        @{ t = 'Canion vermelho'; d = 'O canion de pedra vermelha.'; bioma = 'terralith:bryce_canyon'; solta = $true }
        @{ t = 'Vulcao'; d = 'A cratera de um vulcao.'; bioma = 'terralith:volcanic_crater'; solta = $true }
        @{ t = 'Ilhas no ceu'; d = 'Ilhas que flutuam acima das nuvens.'; bioma = 'terralith:skylands_summer'; solta = $true }
        @{ t = 'Floresta de lavanda'; d = 'Tudo roxo de lavanda.'; bioma = 'terralith:lavender_forest'; solta = $true }
        @{ t = 'Penhascos brancos'; d = 'Penhascos de pedra branca no mar.'; bioma = 'terralith:white_cliffs'; solta = $true }
        @{ t = 'Oasis'; d = 'Um oasis no meio do deserto.'; bioma = 'terralith:desert_oasis'; solta = $true }
        @{ t = 'Selva subterranea'; d = 'Uma selva inteira dentro de uma caverna.'; bioma = 'terralith:cave/underground_jungle'; solta = $true }
        @{ t = 'Cavernas de cristal'; d = 'Um canion de ametista.'; bioma = 'terralith:amethyst_canyon'; solta = $true }
        @{ t = 'Floresta invertida'; d = 'Incendium: no Nether, uma floresta de cabeca para baixo.'; bioma = 'incendium:inverted_forest'; solta = $true }
        @{ t = 'Vale do choro'; d = 'Incendium: um vale do Nether.'; bioma = 'incendium:weeping_valley'; solta = $true }
    ) }
    @{ t = 'Colecionador'; icone = 'minecraft:diamond'; m = @(
        @{ t = 'Montinho de diamante'; d = 'Junte 64 diamantes. O VeinMiner ajuda.'; item = 'minecraft:diamond'; q = 64; p = 'minecraft:diamond_block'; n = 2 }
        @{ t = 'Netherite'; d = 'Restos antigos no fundo do Nether viram netherite.'; item = 'minecraft:netherite_ingot' }
        @{ t = 'Totem'; d = 'O totem da imortalidade vem dos evocadores das mansoes e cidadelas.'; item = 'minecraft:totem_of_undying'; solta = $true }
        @{ t = 'Tridente'; d = 'Os afogados as vezes deixam cair.'; item = 'minecraft:trident'; solta = $true }
        @{ t = 'Elytra'; d = 'Nos navios das cidades do End. Conserte com membrana de phantom na bigorna.'; item = 'minecraft:elytra'; solta = $true }
        @{ t = 'Cabeca de dragao'; d = 'Na proa dos navios do End.'; item = 'minecraft:dragon_head'; solta = $true }
        @{ t = 'Estrela do Nether'; d = 'O premio do Wither, para fazer um sinalizador.'; item = 'minecraft:nether_star'; solta = $true }
        @{ t = 'Sinalizador'; d = 'Um sinalizador em cima de uma piramide de blocos de ferro, ouro ou diamante da efeitos bons.'; item = 'minecraft:beacon'; solta = $true }
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
            elseif ($e.FullName -match '^data/([a-z0-9_.-]+)/(dimension|worldgen/structure|worldgen/biome)/([a-z0-9_/.-]+)\.json$') { [void]$existe.Add("$($matches[1]):$($matches[3])") }
            elseif ($e.FullName -match '^assets/[a-z0-9_.-]+/lang/en_us\.json$') {
                # Bichos: o id vem das chaves entity.<mod>.<nome> do arquivo de idioma.
                $r = New-Object IO.StreamReader $e.Open(); $txt = $r.ReadToEnd(); $r.Dispose()
                foreach ($k in [regex]::Matches($txt, '"entity\.([a-z0-9_]+)\.([a-z0-9_]+)"')) { [void]$existe.Add("$($k.Groups[1].Value):$($k.Groups[2].Value)") }
            }
        }
        $z.Dispose()
    }
    $faltam = @(foreach ($c in $capitulos) { foreach ($id in @($c.icone) + @($c.m | ForEach-Object { $_['item']; $_['dim']; $_['p']; $_['mata']; $_['estrutura']; $_['bioma'] })) {
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
        $q = if ($m['q']) { $m['q'] } else { 1 }
        $tarefa = if ($m['item']) { "{ id: `"$(Id "tarefa/$qid")`", item: { count: $q, id: `"$($m['item'])`" }, type: `"item`" }" }
            elseif ($m['mata']) { "{ entity: `"$($m['mata'])`", id: `"$(Id "tarefa/$qid")`", type: `"kill`", value: $($q)L }" }
            elseif ($m['estrutura']) { "{ id: `"$(Id "tarefa/$qid")`", structure: `"$($m['estrutura'])`", type: `"structure`" }" }
            elseif ($m['bioma']) { "{ biome: `"$($m['bioma'])`", id: `"$(Id "tarefa/$qid")`", type: `"biome`" }" }
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
