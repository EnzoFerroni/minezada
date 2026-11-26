# Gera o livro de missoes (FTB Quests) em server-config/config/ftbquests/quests a partir da tabela abaixo.
# O servidor manda o livro para cada jogador; o progresso fica no mundo, nao aqui.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/missoes.ps1 (Mac: pwsh scripts/missoes.ps1)
# Cada missao: t = titulo, d = texto (uma linha por item), e uma tarefa: item (id do item), dim (id da dimensao)
# mata (id do bicho), estrutura ou bioma (id do mundo) ou nada (o jogador marca como feito). q = quantidade da
# tarefa (itens ou abates). p = premio (id do item) e n = quantidade. Cada missao depende da anterior
# do mesmo capitulo, a menos que solta = $true. Ids conferidos nos jars do pack (26/11).
# Extras: capitulo g = grupo (da lista $grupos) e sub = subtitulo; missao sub = subtitulo, marco = $true
# (engrenagem maior, mais XP), opcional = $true (nao conta para completar o capitulo), xp = XP do premio
# (padrao 20, marco 100). Texto aceita cores do jogo (&e amarelo, &a verde, &b azul, &c vermelho, &l negrito,
# &r volta ao normal) e "{@pagebreak}" sozinho em uma linha para comecar outra pagina.
# Este arquivo tem BOM (UTF-8): os textos podem ter acento.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$destino = Join-Path $root 'server-config/config/ftbquests/quests'

# Grupos da lateral do livro, nesta ordem.
$grupos = @(
    @{ t = 'Começo'; icone = 'minecraft:oak_sapling' }
    @{ t = 'Tecnologia'; icone = 'create:cogwheel' }
    @{ t = 'Dimensões'; icone = 'minecraft:ender_eye' }
    @{ t = 'Aventura'; icone = 'minecraft:iron_sword' }
)

$capitulos = @(
    @{ t = 'Primeiros passos'; g = 'Começo'; icone = 'minecraft:crafting_table'; sub = 'O que muda neste Minecraft e as teclas que ajudam'; m = @(
        @{ t = 'Bem-vindo ao Minezada'; marco = $true; sub = 'Comece por aqui'; d = @(
            'Este é o &elivro de missões&r. Ele mostra o que fazer, explica cada mod e dá prêmios: toda missão dá &aXP&r e algumas dão itens.'
            ''
            'Abra quando quiser pelo &ebotão do livro&r no canto do inventário (tecla &eE&r).'
            ''
            'Cada bolinha é uma missão. Clique nela para ler. Quando você cumpre o pedido, ela fica verde e o prêmio aparece para pegar.'
            '{@pagebreak}'
            'Os capítulos ficam na &eesquerda&r, em grupos: &aComeço&r, &aTecnologia&r, &aDimensões&r e &aAventura&r.'
            ''
            'Não precisa seguir na ordem. Quer só construir e explorar? Tudo bem. As missões são um guia, não uma obrigação.'
            ''
            '&7Clique em &fConcluir&7 para marcar esta como lida.'
        ) }
        @{ t = 'Receitas: R e U'; sub = 'A tecla mais importante'; d = @(
            'O pack tem centenas de itens novos. Ninguém decora receita: use o &eJEI&r, a lista de itens na direita do inventário.'
            ''
            '&eR&r com o mouse em cima de um item: mostra &acomo fazer&r.'
            '&eU&r com o mouse em cima de um item: mostra &aonde ele é usado&r.'
            ''
            'A barra de busca embaixo da lista aceita nome em português ou inglês, e entende erro de digitação. Comece o texto com &e@&r para ver os itens de um mod (exemplo: &e@create&r).'
        ) }
        @{ t = 'O que é isso?'; sub = 'Jade'; d = @(
            'Mire em qualquer bloco ou bicho: o nome, o mod de onde ele vem e informações úteis aparecem no &etopo da tela&r.'
            ''
            'Serve para saber a vida de um bicho, quanto falta para uma planta crescer ou o que tem dentro de uma máquina.'
        ) }
        @{ t = 'Mesa de trabalho'; d = @(
            'O começo de sempre: junte madeira e faça uma &emesa de trabalho&r.'
            ''
            'Dica: segure a tecla &eao lado do 1&r (acento grave) enquanto quebra um tronco para derrubar a árvore inteira de uma vez. Funciona com minério também (&eVeinMiner&r).'
        ); item = 'minecraft:crafting_table'; p = 'minecraft:bread'; n = 4 }
        @{ t = 'Mapa'; sub = 'Nunca mais se perca'; d = @(
            'O &eminimapa&r fica no canto da tela. A tecla &eM&r abre o mapa do mundo, com tudo que você já explorou.'
            ''
            'A tecla &eN&r cria um ponto marcado (waypoint) onde você está. Marque a sua casa!'
            ''
            'Outros jogadores aparecem no minimapa como cabecinhas.'
        ) }
        @{ t = 'Mochila'; d = @(
            'Faça uma &emochila&r: ela guarda muito mais que o inventário. Clique com o botão direito segurando ela, ou coloque nas costas e abra pela tecla &eB&r.'
            ''
            'Ela ganha &aupgrades&r: coletar itens do chão, separar o que você pega, alimentar você sozinha e ficar maior (ferro, ouro, diamante). Veja no JEI com &eU&r em cima da mochila.'
        ); item = 'sophisticatedbackpacks:backpack'; p = 'minecraft:leather'; n = 4 }
        @{ t = 'Waystone'; sub = 'Teleporte'; d = @(
            'Waystones são &epedras de teleporte&r. Elas aparecem nas vilas e pelo mundo.'
            ''
            'Clique em uma para &aativar&r. Depois, de qualquer waystone, você viaja para as que já ativou.'
            ''
            'Faça a sua e coloque perto de casa: assim você sempre volta rápido.'
        ); item = 'waystones:waystone'; p = 'minecraft:ender_pearl'; n = 2 }
        @{ t = 'Se você morrer'; d = @(
            'Morreu? Seus itens &enão somem&r: ficam guardados em um &ecorpo&r no lugar da morte.'
            ''
            'Volte lá e clique no corpo para pegar tudo. O lugar aparece no mapa.'
            ''
            'Esqueceu onde foi? &eAlt + U&r mostra o histórico de mortes.'
        ) }
        @{ t = 'Cozinha'; d = @(
            '&eFarmer''s Delight&r traz panela, frigideira, tábua de corte e dezenas de comidas.'
            ''
            'Importante: cada comida &enova&r que você prova pela primeira vez dá &acorações extras de vida&r (Spice of Life). Variar a comida deixa você mais forte!'
            ''
            'O capítulo &eCozinha e fazenda&r explica tudo.'
        ); item = 'farmersdelight:cooking_pot'; p = 'minecraft:golden_carrot'; n = 4 }
        @{ t = 'Carregar baús e bichos'; sub = 'Carry On'; opcional = $true; d = @(
            'Com as &emãos vazias&r, segure &eShift&r e clique com o botão direito em um baú: você carrega ele inteiro, com os itens dentro.'
            ''
            'Funciona com bichos também. Ótimo para mudar de casa.'
        ) }
        @{ t = 'Avisar os amigos'; sub = 'Ping Wheel'; opcional = $true; d = @(
            'Clique com o &ebotão do meio do mouse&r para marcar um ponto que todos veem: "olha aqui", "perigo", "vem cá".'
        ) }
        @{ t = 'Jogo lento?'; sub = 'Perfis de gráfico'; opcional = $true; d = @(
            'Em &eOpções > Perfis&r tem 7 perfis prontos: do &e1 - Mínimo&r (computador fraco) ao &e7 - Ultra&r (com shader).'
            ''
            'Clique em um e ele muda tudo na hora. Não use &cSalvar&r nem &cCriar perfil&r: pode fechar o jogo.'
            ''
            'Tecla &eK&r liga e desliga o shader.'
        ) }
        @{ t = 'Achar uma tecla'; sub = 'Controles'; opcional = $true; d = @(
            'Em &eOpções > Controles > Teclas&r tem uma &abusca&r: digite o nome da ação (ou do mod) para ver e trocar a tecla.'
            ''
            'Tecla em vermelho está em conflito com outra.'
        ) }
    ) }
    @{ t = 'Create 1: o basico'; g = 'Tecnologia'; icone = 'create:cogwheel'; m = @(
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
    @{ t = 'Create 2: primeiras maquinas'; g = 'Tecnologia'; icone = 'create:mechanical_press'; m = @(
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
    @{ t = 'Create 3: era do latao'; g = 'Tecnologia'; icone = 'create:brass_ingot'; m = @(
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
    @{ t = 'Create 4: vapor, fluidos e trens'; g = 'Tecnologia'; icone = 'create:steam_engine'; m = @(
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
    @{ t = 'Mochila e baus'; g = 'Começo'; icone = 'sophisticatedbackpacks:backpack'; m = @(
        @{ t = 'Base de melhoria'; d = 'As melhorias da mochila partem desta base. Clique com o botao direito na mochila e coloque nas casas de melhoria.'; item = 'sophisticatedbackpacks:upgrade_base' }
        @{ t = 'Coletar sozinho'; d = 'A melhoria de coleta guarda direto na mochila o que voce pega do chao.'; item = 'sophisticatedbackpacks:pickup_upgrade' }
        @{ t = 'Ima'; d = 'A melhoria de ima puxa os itens de perto para a mochila.'; item = 'sophisticatedbackpacks:magnet_upgrade' }
        @{ t = 'Comer sozinho'; d = 'A melhoria de alimentacao come a comida da mochila quando voce fica com fome.'; item = 'sophisticatedbackpacks:feeding_upgrade' }
        @{ t = 'Mochila de ferro'; d = 'Mochila maior, com mais espaco e mais casas de melhoria. Depois vem ouro, diamante e netherite.'; item = 'sophisticatedbackpacks:iron_backpack' }
        @{ t = 'Bau de ferro'; d = 'Iron Chests: baus maiores que o normal. Ferro, ouro, diamante e outros.'; item = 'ironchest:iron_chest'; solta = $true }
        @{ t = 'Bau grande do Sophisticated'; d = 'Sophisticated Storage: baus e barris com melhorias, como a mochila.'; item = 'sophisticatedstorage:chest'; solta = $true }
    ) }
    @{ t = 'Cozinha e fazenda'; g = 'Começo'; icone = 'farmersdelight:cooking_pot'; m = @(
        @{ t = 'Faca'; d = 'A faca colhe palha e corta comida na tabua.'; item = 'farmersdelight:flint_knife' }
        @{ t = 'Tabua de corte'; d = 'Coloque um ingrediente na tabua e clique com a faca para cortar.'; item = 'farmersdelight:cutting_board' }
        @{ t = 'Fogao'; d = 'O fogao cozinha em cima e aquece a panela e a frigideira.'; item = 'farmersdelight:stove' }
        @{ t = 'Terra rica'; d = 'Composto organico vira terra rica, onde as plantas crescem mais rapido.'; item = 'farmersdelight:rich_soil' }
        @{ t = 'Cozinha montada'; d = 'Cooking for Blockheads: a mesa de cozinha mostra tudo que da para fazer com o que esta na geladeira e nos baus ao lado.'; item = 'cookingforblockheads:cooking_table'; solta = $true }
        @{ t = 'Vaso que planta sozinho'; d = 'Botany Pots: coloque terra e uma semente; com funil embaixo ele colhe sozinho.'; item = 'botanypots:terracotta_botany_pot'; solta = $true }
        @{ t = 'Plantacao de minerio'; d = 'Mystical Agriculture: essencia de inferium sai do minerio de inferium e vira sementes que dao materiais.'; item = 'mysticalagriculture:inferium_essence'; solta = $true }
        @{ t = 'Estacoes do ano'; d = 'Serene Seasons: o ano tem primavera, verao, outono e inverno. Cada planta cresce melhor em certas estacoes; o JEI mostra quais.'; solta = $true }
    ) }
    @{ t = 'Construir'; g = 'Começo'; icone = 'buildinggadgets2:gadget_building'; m = @(
        @{ t = 'Ferramenta de construir'; d = 'Building Gadgets: coloca varios blocos de uma vez. Precisa de energia (carregue em um carregador de energia).'; item = 'buildinggadgets2:gadget_building' }
        @{ t = 'Copiar e colar'; d = 'Copia uma area e cola em outro lugar, gastando os blocos do seu inventario.'; item = 'buildinggadgets2:gadget_copy_paste' }
        @{ t = 'Construir com espelho'; d = 'Effortless Building: segure Alt para escolher modos como parede, linha, espelho e repeticao.'; solta = $true }
        @{ t = 'Telhados de verdade'; d = 'Macaw''s Roofs, Windows, Doors, Fences e Furniture: blocos de telhado, janelas, portas, cercas e moveis. Procure por mcw no JEI.'; solta = $true }
        @{ t = 'Moveis'; d = 'Handcrafted, Beautify, Supplementaries e Bubblellaneous trazem moveis e decoracao. Procure pelo nome do mod no JEI com @.'; solta = $true }
    ) }
    @{ t = 'Animais'; g = 'Começo'; icone = 'alexsmobs:animal_dictionary'; m = @(
        @{ t = 'Dicionario animal'; d = 'Alex''s Mobs tem um livro que explica cada bicho, o que ele come e como domesticar.'; item = 'alexsmobs:animal_dictionary' }
        @{ t = 'Banana'; d = 'Bananas caem das folhas de selva. Varios bichos do Alex''s Mobs gostam delas, como os macacos.'; item = 'alexsmobs:banana' }
        @{ t = 'Hamster'; d = 'Adorable Hamster Pets: hamsters de estimacao que seguem voce e cabem no ombro.'; solta = $true }
        @{ t = 'Dragao'; d = 'Dragon Mounts: ovos de dragao chocam um dragao que voce cria e monta.'; solta = $true }
        @{ t = 'Mais bichos'; d = 'Naturalist, Critters and Companions, Friends&Foes, Wilder Nature e Archie''s Dinosaurs espalham bichos pelos biomas. O Jade mostra o nome de cada um.'; solta = $true }
    ) }
    @{ t = 'Explorar'; g = 'Aventura'; icone = 'naturescompass:naturescompass'; m = @(
        @{ t = 'Bussola de biomas'; d = 'Nature''s Compass aponta para o bioma que voce escolher.'; item = 'naturescompass:naturescompass' }
        @{ t = 'Bussola de estruturas'; d = 'Explorer''s Compass aponta para vilas, templos, masmorras e outras estruturas.'; item = 'explorerscompass:explorerscompass' }
        @{ t = 'Atlas'; d = 'Map Atlases junta mapas de papel em um livro. Na mao secundaria vira minimapa.'; item = 'map_atlases:atlas' }
        @{ t = 'Pergaminho de volta'; d = 'O pergaminho de retorno leva de volta para a ultima waystone ou cama.'; item = 'waystones:return_scroll' }
    ) }
    @{ t = 'Mekanism'; g = 'Tecnologia'; icone = 'mekanism:metallurgic_infuser'; m = @(
        @{ t = 'Infusor metalurgico'; d = 'A primeira maquina: mistura ferro com carvao para fazer aco e outras ligas. Precisa de energia.'; item = 'mekanism:metallurgic_infuser' }
        @{ t = 'Energia'; d = 'O Mekanism do pack nao tem geradores proprios: o alternador do Create Crafts & Additions transforma a rotacao do Create em energia para as maquinas.'; item = 'createaddition:alternator' }
        @{ t = 'Camara de enriquecimento'; d = 'Transforma um minerio em dois montes de po: o dobro de lingotes.'; item = 'mekanism:enrichment_chamber' }
        @{ t = 'Cabos'; d = 'Cabos universais levam energia do gerador para as maquinas.'; item = 'mekanism:basic_universal_cable' }
    ) }
    @{ t = 'Dimensoes'; g = 'Dimensões'; icone = 'minecraft:ender_eye'; m = @(
        @{ t = 'Nether'; d = 'Portal de obsidiana aceso com isqueiro.'; dim = 'minecraft:the_nether'; solta = $true }
        @{ t = 'Aether'; d = 'O ceu do Minecraft: moldura de pedra luminosa (glowstone) acesa com um balde de agua.'; dim = 'aether:the_aether'; solta = $true }
        @{ t = 'Twilight Forest'; d = 'Poca de agua 2x2 cercada de flores; jogue um diamante dentro.'; dim = 'twilightforest:twilight_forest'; solta = $true }
        @{ t = 'Undergarden'; d = 'Moldura de tijolos de pedra ativada com o catalisador do Undergarden (receita no JEI).'; dim = 'undergarden:undergarden'; solta = $true }
        @{ t = 'Eternal Starlight'; d = 'Dimensao das estrelas: procure as ruinas de portal pelo mundo e veja no JEI como ativar.'; dim = 'eternal_starlight:starlight'; solta = $true }
        @{ t = 'Masmorras infinitas'; d = 'Dimensional Dungeons: a chave de portal abre masmorras que se renovam (receita no JEI).'; dim = 'dimdungeons:dungeon_dimension'; solta = $true }
        @{ t = 'Lua'; d = 'Ad Astra: monte um foguete na bancada da NASA e voe para a Lua.'; dim = 'ad_astra:moon'; solta = $true }
        @{ t = 'End'; d = 'Olhos de ender levam ao portal do End e ao dragao.'; dim = 'minecraft:the_end'; solta = $true }
    ) }
    @{ t = 'Aether'; g = 'Dimensões'; icone = 'aether:ambrosium_shard'; m = @(
        @{ t = 'Chegar no Aether'; d = 'Moldura de glowstone acesa com um balde de agua. Leve o paraquedas dourado que o mod da na primeira visita.'; dim = 'aether:the_aether' }
        @{ t = 'Ambrosium'; d = 'Fragmentos de ambrosium curam e servem de combustivel no Aether.'; item = 'aether:ambrosium_shard' }
        @{ t = 'Zanite'; d = 'Gema azul para ferramentas e armadura do Aether.'; item = 'aether:zanite_gemstone' }
        @{ t = 'Primeira masmorra'; d = 'Venca o Slider na masmorra de bronze e pegue a chave de bronze.'; item = 'aether:bronze_dungeon_key' }
        @{ t = 'Rainha Valquiria'; d = 'A masmorra de prata guarda a Rainha Valquiria e a chave de prata.'; item = 'aether:silver_dungeon_key' }
        @{ t = 'Espirito do Sol'; d = 'A masmorra de ouro e o fim do Aether: venca o Espirito do Sol.'; item = 'aether:gold_dungeon_key' }
    ) }
    @{ t = 'Twilight Forest'; g = 'Dimensões'; icone = 'twilightforest:naga_scale'; m = @(
        @{ t = 'Entrar'; d = 'Poca de agua 2x2 cercada de flores; jogue um diamante dentro.'; dim = 'twilightforest:twilight_forest' }
        @{ t = 'Naga'; d = 'O primeiro chefe vive no patio de pedra. Ele deixa escamas para armadura.'; item = 'twilightforest:naga_scale' }
        @{ t = 'Mapa magico'; d = 'Com o foco de mapa magico voce faz um mapa que mostra os biomas e as estruturas dos chefes.'; item = 'twilightforest:magic_map_focus' }
        @{ t = 'Proximos chefes'; d = 'A progressao segue: Lich, Hidra, Ur-Ghast e outros. Cada chefe libera a regiao seguinte; tentar pular da efeitos ruins.'; }
    ) }
    @{ t = 'Undergarden'; g = 'Dimensões'; icone = 'undergarden:catalyst'; m = @(
        @{ t = 'Catalisador'; d = 'O catalisador ativa o portal de tijolos de pedra.'; item = 'undergarden:catalyst' }
        @{ t = 'Entrar'; d = 'Undergarden e um mundo escuro e perigoso embaixo da terra. Leve tochas.'; dim = 'undergarden:undergarden' }
        @{ t = 'Cloggrum'; d = 'O primeiro metal do Undergarden, para ferramentas.'; item = 'undergarden:cloggrum_ingot' }
        @{ t = 'Froststeel'; d = 'Metal gelado que deixa os inimigos mais lentos.'; item = 'undergarden:froststeel_ingot' }
        @{ t = 'Utherium'; d = 'Cristal forte contra as criaturas do Undergarden.'; item = 'undergarden:utherium_crystal' }
    ) }
    @{ t = 'Espaco'; g = 'Dimensões'; icone = 'ad_astra:tier_1_rocket'; m = @(
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
    @{ t = 'Utilidades'; g = 'Começo'; icone = 'justhammers:iron_hammer'; m = @(
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
    @{ t = 'Create: addons'; g = 'Tecnologia'; icone = 'create_jetpack:jetpack'; m = @(
        @{ t = 'Jetpack'; d = 'Create Jetpack: voa com ar comprimido de um tanque.'; item = 'create_jetpack:jetpack'; solta = $true }
        @{ t = 'Escavadeira de minerio'; d = 'Create Ore Excavation: maquinas que extraem minerio de veios infinitos no subsolo.'; solta = $true }
        @{ t = 'Encantar com maquina'; d = 'Create Enchantment Industry: transforma experiencia em liquido e encanta itens com maquinas.'; solta = $true }
        @{ t = 'Energia'; d = 'Create Crafts & Additions: o alternador gera energia e o motor eletrico gira as maquinas.'; item = 'createaddition:electric_motor'; solta = $true }
        @{ t = 'Cozinha automatica'; d = 'Create Central Kitchen: as maquinas do Create fazem as comidas do Farmer''s Delight.'; solta = $true }
    ) }
    @{ t = 'Cacador de chefes'; g = 'Aventura'; icone = 'minecraft:wither_skeleton_skull'; m = @(
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
    @{ t = 'Chefes da Twilight'; g = 'Aventura'; icone = 'twilightforest:naga_scale'; m = @(
        @{ t = 'Naga'; d = 'O primeiro chefe, no patio de pedra.'; mata = 'twilightforest:naga' }
        @{ t = 'Lich'; d = 'A torre do Lich. Quebre os escudos dele antes de atacar.'; mata = 'twilightforest:lich' }
        @{ t = 'Minoshroom'; d = 'No fundo do labirinto do pantano.'; mata = 'twilightforest:minoshroom' }
        @{ t = 'Hidra'; d = 'No covil de fogo. Leve resistencia ao fogo.'; mata = 'twilightforest:hydra' }
        @{ t = 'Cavaleiros fantasmas'; d = 'Na fortaleza dos cavaleiros, na floresta escura.'; mata = 'twilightforest:knight_phantom' }
        @{ t = 'Ur-Ghast'; d = 'No topo da torre escura.'; mata = 'twilightforest:ur_ghast' }
        @{ t = 'Yeti alfa'; d = 'Na caverna dos yetis, na floresta de neve.'; mata = 'twilightforest:alpha_yeti' }
        @{ t = 'Rainha da Neve'; d = 'No palacio da aurora, no glaciar.'; mata = 'twilightforest:snow_queen' }
    ) }
    @{ t = 'Explorador'; g = 'Aventura'; icone = 'explorerscompass:explorerscompass'; m = @(
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
    @{ t = 'Volta ao mundo'; g = 'Aventura'; icone = 'naturescompass:naturescompass'; m = @(
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
    @{ t = 'Colecionador'; g = 'Aventura'; icone = 'minecraft:diamond'; m = @(
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
# O nome entra sem acento: acentuar um titulo antigo nao muda o id.
$md5 = [Security.Cryptography.MD5]::Create()
function Sem($s) { -join ($s.Normalize([Text.NormalizationForm]::FormD).ToCharArray() | Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' }) }
function Id($s) { -join ($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes((Sem $s)))[0..7] | ForEach-Object { $_.ToString('X2') }) }
function Txt($s) { '"' + $s.Replace('\', '\\').Replace('"', '\"') + '"' }

$utf8 = New-Object Text.UTF8Encoding $false
if (Test-Path $destino) { Remove-Item -Recurse -Force $destino }
New-Item -ItemType Directory -Force (Join-Path $destino 'chapters'), (Join-Path $destino 'lang') | Out-Null
[IO.File]::WriteAllText((Join-Path $destino 'data.snbt'), "{`n`tdefault_quest_shape: `"circle`"`n`tdefault_reward_team: false`n`tdisable_gui: false`n`tgrid_scale: 0.5d`n`tpause_game: false`n`tprogression_mode: `"flexible`"`n`tversion: 13`n}`n", $utf8)
$lang = @()
# Grupos: titulos na lateral do livro que juntam os capitulos.
$gids = @{}
$gs = foreach ($g in $grupos) { $gids[$g.t] = Id "grupo/$($g.t)"; $lang += "`tchapter_group.$($gids[$g.t]).title: $(Txt $g.t)"; "`t`t{ icon: { id: `"$($g.icone)`" }, id: `"$($gids[$g.t])`" }" }
[IO.File]::WriteAllText((Join-Path $destino 'chapter_groups.snbt'), "{`n`tchapter_groups: [`n$($gs -join "`n")`n`t]`n}`n", $utf8)
$ordem = 0
foreach ($c in $capitulos) {
    $cid = Id "capitulo/$($c.t)"; $nome = ((Sem $c.t).ToLower() -replace '[^a-z0-9]+', '_').Trim('_')
    if ($c['g'] -and -not $gids[$c['g']]) { throw "Capitulo $($c.t): grupo '$($c['g'])' nao esta em `$grupos" }
    $grupo = if ($c['g']) { $gids[$c['g']] } else { '' }
    $lang += "`tchapter.$cid.title: $(Txt $c.t)"
    if ($c['sub']) { $lang += "`tchapter.$cid.chapter_subtitle: [$(Txt $c['sub'])]" }
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
        $xp = if ($m['xp']) { $m['xp'] } elseif ($m['marco']) { 100 } else { 20 }
        $premios = @("{ id: `"$(Id "xp/$qid")`", type: `"xp`", xp: $xp }")
        if ($m['p']) { $premios += "{ id: `"$(Id "premio/$qid")`", item: { count: $(if ($m['n']) { $m['n'] } else { 1 }), id: `"$($m['p'])`" }, type: `"item`" }" }
        $extra = "`n`t`t`trewards: [$($premios -join ', ')]"
        if ($m['marco']) { $extra += "`n`t`t`tshape: `"gear`"`n`t`t`tsize: 1.5d" }
        if ($m['opcional']) { $extra += "`n`t`t`toptional: true" }
        $dep = if ($ant -and -not $m['solta']) { "`n`t`t`tdependencies: [`"$ant`"]" } else { '' }
        $y = if ($m['solta']) { [math]::Floor($x / 4) * 1.5 } else { 0 }; $px = if ($m['solta']) { ($x % 4) * 1.5 } else { $x * 1.5 }
        $qs += "`t`t{$dep`n`t`t`tid: `"$qid`"$extra`n`t`t`ttasks: [$tarefa]`n`t`t`tx: $($px)d`n`t`t`ty: $($y)d`n`t`t}"
        $lang += "`tquest.$qid.title: $(Txt $m.t)"
        if ($m['sub']) { $lang += "`tquest.$qid.quest_subtitle: $(Txt $m['sub'])" }
        $lang += "`tquest.$qid.quest_desc: [$((@($m.d) | ForEach-Object { Txt $_ }) -join ', ')]"
        $ant = $qid; $x++
    }
    $cap = "{`n`tdefault_hide_dependency_lines: false`n`tdefault_quest_shape: `"`"`n`tfilename: `"$nome`"`n`tgroup: `"$grupo`"`n`ticon: { id: `"$($c.icone)`" }`n`tid: `"$cid`"`n`torder_index: $ordem`n`tquest_links: [ ]`n`tquests: [`n$($qs -join "`n")`n`t]`n}`n"
    [IO.File]::WriteAllText((Join-Path $destino "chapters/$nome.snbt"), $cap, $utf8)
    $ordem++
}
# pt_br para o jogo em portugues; en_us igual, para quem trocou o idioma nao ver chaves no lugar do texto.
foreach ($l in 'pt_br', 'en_us') { [IO.File]::WriteAllText((Join-Path $destino "lang/$l.snbt"), "{`n$($lang -join "`n")`n}`n", $utf8) }
Write-Host "$($capitulos.Count) capitulos, $(@($capitulos | ForEach-Object { $_.m }).Count) missoes -> $destino"
