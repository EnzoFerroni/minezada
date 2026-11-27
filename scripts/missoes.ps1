# Gera o livro de missoes (FTB Quests) em server-config/config/ftbquests/quests a partir da tabela abaixo.
# O servidor manda o livro para cada jogador; o progresso fica no mundo, nao aqui.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/missoes.ps1 (Mac: pwsh scripts/missoes.ps1)
# Cada missao: t = titulo, d = texto (uma linha por item), e uma tarefa: item (id do item), dim (id da dimensao)
# mata (id do bicho), estrutura ou bioma (id do mundo), conquista (id da conquista, ex.: domar um bicho) ou nada (o jogador marca como feito). q = quantidade da
# tarefa (itens ou abates). p = premio (id do item) e n = quantidade. Cada missao depende da anterior
# do mesmo capitulo, a menos que solta = $true. Ids conferidos nos jars do pack (26/11).
# Extras: capitulo g = grupo (da lista $grupos) e sub = subtitulo; missao sub = subtitulo, marco = $true
# (engrenagem maior, mais XP), opcional = $true (nao conta para completar o capitulo), xp = XP do premio
# (padrao 20, marco 100). depois = titulo (ou lista de titulos) de que a missao depende; sem depois, ela depende
# da anterior. O livro e desenhado em arvore a partir disso. Texto aceita cores do jogo (&e amarelo, &a verde, &b azul, &c vermelho, &l negrito,
# &r volta ao normal) e "{@pagebreak}" sozinho em uma linha para comecar outra pagina. mod = slug (ou lista) do mods.txt que a missao
# ensina, para missao sem id do mod (teclas, mecanicas); conta na cobertura em docs/missoes.md.
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
        @{ t = 'Receitas: R e U'; mod = @('jei'); depois = 'Bem-vindo ao Minezada'; sub = 'A tecla mais importante'; d = @(
            'O pack tem centenas de itens novos. Ninguém decora receita: use o &eJEI&r, a lista de itens na direita do inventário.'
            ''
            '&eR&r com o mouse em cima de um item: mostra &acomo fazer&r.'
            '&eU&r com o mouse em cima de um item: mostra &aonde ele é usado&r.'
            ''
            'A barra de busca embaixo da lista aceita nome em português ou inglês, e entende erro de digitação. Comece o texto com &e@&r para ver os itens de um mod (exemplo: &e@create&r).'
        ) }
        @{ t = 'O que é isso?'; mod = @('jade', 'jade-addons-forge'); depois = 'Bem-vindo ao Minezada'; sub = 'Jade'; d = @(
            'Mire em qualquer bloco ou bicho: o nome, o mod de onde ele vem e informações úteis aparecem no &etopo da tela&r.'
            ''
            'Serve para saber a vida de um bicho, quanto falta para uma planta crescer ou o que tem dentro de uma máquina.'
        ) }
        @{ t = 'Mesa de trabalho'; depois = 'Bem-vindo ao Minezada'; d = @(
            'O começo de sempre: junte madeira e faça uma &emesa de trabalho&r.'
            ''
            'Dica: segure a tecla &eao lado do 1&r (acento grave) enquanto quebra um tronco para derrubar a árvore inteira de uma vez. Funciona com minério também (&eFTB Ultimine&r).'
        ); item = 'minecraft:crafting_table'; p = 'minecraft:bread'; n = 4 }
        @{ t = 'Mapa'; mod = @('xaeros-minimap', 'xaeros-world-map'); depois = 'Bem-vindo ao Minezada'; sub = 'Nunca mais se perca'; d = @(
            'O &eminimapa&r fica no canto da tela. A tecla &eM&r abre o mapa do mundo, com tudo que você já explorou.'
            ''
            'A tecla &eN&r cria um ponto marcado (waypoint) onde você está. Marque a sua casa!'
            ''
            'Outros jogadores aparecem no minimapa como cabecinhas.'
        ) }
        @{ t = 'Mochila'; depois = 'Mesa de trabalho'; d = @(
            'Faça uma &emochila&r: ela guarda muito mais que o inventário. Clique com o botão direito segurando ela, ou coloque nas costas e abra pela tecla &eB&r.'
            ''
            'Ela ganha &aupgrades&r: coletar itens do chão, separar o que você pega, alimentar você sozinha e ficar maior (ferro, ouro, diamante). Veja no JEI com &eU&r em cima da mochila.'
        ); item = 'sophisticatedbackpacks:backpack'; p = 'minecraft:leather'; n = 4 }
        @{ t = 'Waystone'; depois = 'Mesa de trabalho'; sub = 'Teleporte'; d = @(
            'Waystones são &epedras de teleporte&r. Elas aparecem nas vilas e pelo mundo.'
            ''
            'Clique em uma para &aativar&r. Depois, de qualquer waystone, você viaja para as que já ativou.'
            ''
            'Faça a sua e coloque perto de casa: assim você sempre volta rápido.'
        ); item = 'waystones:waystone'; p = 'minecraft:ender_pearl'; n = 2 }
        @{ t = 'Se você morrer'; mod = @('corpse'); depois = 'Bem-vindo ao Minezada'; d = @(
            'Morreu? Seus itens &enão somem&r: ficam guardados em um &ecorpo&r no lugar da morte.'
            ''
            'Volte lá e clique no corpo para pegar tudo. O lugar aparece no mapa.'
            ''
            'Esqueceu onde foi? &eAlt + U&r mostra o histórico de mortes.'
        ) }
        @{ t = 'Cozinha'; depois = 'Mesa de trabalho'; d = @(
            '&eFarmer''s Delight&r traz panela, frigideira, tábua de corte e dezenas de comidas.'
            ''
            'Importante: cada comida &enova&r que você prova pela primeira vez dá &acorações extras de vida&r (Spice of Life). Variar a comida deixa você mais forte!'
            ''
            'O capítulo &eCozinha e fazenda&r explica tudo.'
        ); item = 'farmersdelight:cooking_pot'; p = 'minecraft:golden_carrot'; n = 4 }
        @{ t = 'Carregar baús e bichos'; mod = @('carry-on'); depois = 'Bem-vindo ao Minezada'; sub = 'Carry On'; opcional = $true; d = @(
            'Com as &emãos vazias&r, segure &eShift&r e clique com o botão direito em um baú: você carrega ele inteiro, com os itens dentro.'
            ''
            'Funciona com bichos também. Ótimo para mudar de casa.'
        ) }
        @{ t = 'Avisar os amigos'; mod = @('ping-wheel'); depois = 'Mapa'; sub = 'Ping Wheel'; opcional = $true; d = @(
            'Clique com o &ebotão do meio do mouse&r para marcar um ponto que todos veem: "olha aqui", "perigo", "vem cá".'
        ) }
        @{ t = 'Jogo lento?'; depois = 'Bem-vindo ao Minezada'; sub = 'Perfis de gráfico'; opcional = $true; d = @(
            'Em &eOpções > Perfis&r tem 7 perfis prontos: do &e1 - Mínimo&r (computador fraco) ao &e7 - Ultra&r (com shader).'
            ''
            'Clique em um e ele muda tudo na hora. Não use &cSalvar&r nem &cCriar perfil&r: pode fechar o jogo.'
            ''
            'Tecla &eK&r liga e desliga o shader.'
        ) }
        @{ t = 'Achar uma tecla'; mod = @('controlling'); depois = 'Bem-vindo ao Minezada'; sub = 'Controles'; opcional = $true; d = @(
            'Em &eOpções > Controles > Teclas&r tem uma &abusca&r: digite o nome da ação (ou do mod) para ver e trocar a tecla.'
            ''
            'Tecla em vermelho está em conflito com outra.'
        ) }
    ) }
    @{ t = 'Create 1: o básico'; g = 'Tecnologia'; icone = 'create:cogwheel'; sub = 'Máquinas que funcionam com rotação'; m = @(
        @{ t = 'O que é o Create'; marco = $true; sub = 'Comece por aqui'; d = @(
            'O &eCreate&r é um mod de máquinas que funcionam com &erotação&r, como um moinho de verdade.'
            'Algo gira (água, vento, vapor), &eeixos&r e &eengrenagens&r levam o giro e as máquinas trabalham sozinhas.'
            ''
            'Dica de ouro: segure &eW&r com o mouse em cima de qualquer item do Create. Abre o &aPonder&r, uma animação que mostra como ele funciona.'
            ''
            '&7Clique em Concluir quando tiver aberto um Ponder.'
        ) }
        @{ t = 'Zinco'; depois = 'O que é o Create'; d = @(
            'O &ezinco&r é o minério novo do Create. Aparece em cavernas, mais fundo, como blocos verde-claros.'
            'Derreta o minério bruto na fornalha para ter lingotes.'
        ); item = 'create:zinc_ingot'; q = 4 }
        @{ t = 'Liga de andesito'; depois = 'O que é o Create'; marco = $true; d = @(
            'A &eliga de andesito&r é o material de quase tudo no começo.'
            'Feita com &eandesito&r e &epepitas de ferro&r (ou de zinco). Veja a receita no JEI com &eR&r.'
        ); item = 'create:andesite_alloy'; q = 16; p = 'create:andesite_alloy'; n = 16 }
        @{ t = 'Chave inglesa'; depois = 'Liga de andesito'; d = @(
            'A &echave inglesa&r é a ferramenta do Create.'
            '&eBotão direito&r: gira o bloco. &eShift + botão direito&r: pega a máquina de volta na hora, sem quebrar.'
        ); item = 'create:wrench' }
        @{ t = 'Revestimento de andesito'; depois = 'Liga de andesito'; d = @(
            'Clique com a liga de andesito em um &etronco descascado&r. Ele vira &erevestimento&r, a base de várias máquinas.'
        ); item = 'create:andesite_casing'; q = 4 }
        @{ t = 'Eixos'; depois = 'Liga de andesito'; d = @(
            'O &eeixo&r leva a rotação em linha reta. Encaixe um atrás do outro.'
        ); item = 'create:shaft'; q = 8 }
        @{ t = 'Engrenagens'; depois = 'Eixos'; d = @(
            '&eEngrenagens&r passam o giro para os lados. Duas encostadas giram em sentidos opostos.'
            ''
            'Engrenagem &egrande&r com a &epequena&r muda a velocidade: da pequena para a grande &adiminui&r, da grande para a pequena &aaumenta&r.'
        ); item = 'create:cogwheel'; q = 4 }
        @{ t = 'Engrenagem grande'; depois = 'Engrenagens'; d = @(
            'Faz curvas e muda a velocidade junto com a pequena.'
        ); item = 'create:large_cogwheel'; q = 2 }
        @{ t = 'Caixa de engrenagens'; depois = 'Engrenagens'; d = @(
            'A &ecaixa de engrenagens&r faz curvas de 90 graus em pouco espaço.'
        ); item = 'create:gearbox' }
        @{ t = 'Manivela'; depois = 'Eixos'; d = @(
            'A &emanivela&r gira as máquinas com a mão. Boa para testar. Cansa: gasta fome.'
        ); item = 'create:hand_crank' }
        @{ t = 'Roda d''água'; depois = 'Eixos'; marco = $true; sub = 'Primeira fonte de força'; d = @(
            'Coloque a &eroda d''água&r encostada em &eágua corrente&r: a água empurra a roda e ela gira o eixo.'
            'Mais rodas no mesmo eixo, mais força. A &eroda d''água grande&r dá ainda mais.'
        ); item = 'create:water_wheel'; p = 'create:shaft'; n = 8 }
        @{ t = 'Óculos de engenheiro'; depois = 'Roda d''água'; d = @(
            'Com os &eóculos&r na cabeça você olha uma máquina e vê a &evelocidade&r e o &eesforço&r dela.'
        ); item = 'create:goggles' }
        @{ t = 'Stress'; depois = 'Óculos de engenheiro'; marco = $true; sub = 'Por que a máquina parou?'; d = @(
            'Cada máquina gasta &eesforço&r (SU). Cada fonte de giro aguenta um tanto de SU.'
            'Passou do limite, &ctudo para&r. Coloque mais fontes ou baixe a velocidade.'
            ''
            'O &emedidor de stress&r mostra quanto da rede está em uso; o &evelocímetro&r mostra a velocidade.'
        ); item = 'create:stressometer' }
        @{ t = 'Embreagem e câmbio'; depois = 'Stress'; opcional = $true; d = @(
            '&eEmbreagem&r: com sinal de redstone, corta o giro.'
            '&eCâmbio&r: com sinal de redstone, inverte o sentido.'
        ); item = 'create:clutch' }
        @{ t = 'Correia'; depois = 'Stress'; opcional = $true; d = @(
            'A &ecaixa de correia&r leva o giro para os lados sem engrenagem. A versão ajustável muda a velocidade com redstone.'
        ); item = 'create:encased_chain_drive'; q = 2 }
    ) }
    @{ t = 'Create 2: primeiras máquinas'; g = 'Tecnologia'; icone = 'create:mechanical_press'; sub = 'Esteiras, prensa, moedor e ventilador'; m = @(
        @{ t = 'Depósito'; d = @(
            'O &edepósito&r segura itens embaixo das máquinas, como uma mesa. Clique para pôr e tirar.'
        ); item = 'create:depot' }
        @{ t = 'Prensa'; depois = 'Depósito'; marco = $true; d = @(
            'A &eprensa&r em cima de um depósito (ou esteira) amassa &elingotes em chapas&r.'
            'Precisa de giro. Chapas aparecem em muitas receitas.'
        ); item = 'create:mechanical_press' }
        @{ t = 'Chapa de ferro'; depois = 'Prensa'; d = @(
            'Faça suas primeiras &echapas de ferro&r com a prensa.'
        ); item = 'create:iron_sheet'; q = 16; p = 'minecraft:iron_ingot'; n = 16 }
        @{ t = 'Chapa de ouro'; depois = 'Chapa de ferro'; opcional = $true; d = @(
            'A chapa de ouro serve no &emecanismo de precisão&r, lá na era do latão.'
        ); item = 'create:golden_sheet'; q = 4 }
        @{ t = 'Esteira'; depois = 'Depósito'; marco = $true; d = @(
            'A &eesteira&r é feita de &ealga seca&r. Clique em um eixo e depois em outro, na mesma linha: a esteira liga os dois.'
            'Ela leva itens de uma máquina para outra e também passa o giro.'
        ); item = 'create:belt_connector'; q = 4 }
        @{ t = 'Funil e calha'; depois = 'Esteira'; d = @(
            'O &efunil&r põe e tira itens de esteiras e baús.'
            'A &ecalha&r é um cano de itens para cima e para baixo.'
        ); item = 'create:andesite_funnel'; q = 2 }
        @{ t = 'Moedor'; depois = 'Prensa'; d = @(
            'O &emoedor&r faz farinha de trigo, cascalho de pedregulho, corante de flores.'
            'Ponha itens por cima, pegue o resultado com a mão ou com um funil.'
        ); item = 'create:millstone' }
        @{ t = 'Ventilador'; depois = 'Moedor'; marco = $true; sub = 'Cozinhar, assar e lavar em massa'; d = @(
            'O &eventilador&r sopra itens. O que estiver no vento passa por um processo:'
            '&eágua&r na frente: lava (cascalho dá pepitas, minério moído dá extra).'
            '&efogo&r ou fogueira: cozinha comida.'
            '&elava&r: derrete, como uma fornalha.'
            '&efogo de alma&r: assombra (itens novos, veja no JEI).'
        ); item = 'create:encased_fan' }
        @{ t = 'Massa e pão'; depois = 'Ventilador'; opcional = $true; d = @(
            'Farinha do moedor com água dá &emassa&r. O ventilador com fogo vira pão. Uma fazenda de pão sem tocar em nada.'
        ); item = 'create:dough'; q = 8 }
        @{ t = 'Serra'; depois = 'Esteira'; d = @(
            'A &eserra&r corta tronco em tábuas no caminho da esteira. Em uma estrutura que anda, derruba árvores.'
        ); item = 'create:mechanical_saw' }
        @{ t = 'Broca'; depois = 'Prensa'; d = @(
            'A &ebroca&r quebra o bloco da frente. Junto de rolamentos e pistões vira uma máquina de minerar.'
        ); item = 'create:mechanical_drill' }
        @{ t = 'Moinho de vento'; depois = 'Prensa'; marco = $true; sub = 'Força sem água'; d = @(
            'O &erolamento de moinho&r com &evelas&r (ou lã) colados nele gira sem água.'
            'Mais velas, mais força. Clique no rolamento com a mão vazia para montar.'
        ); item = 'create:windmill_bearing'; p = 'create:white_sail'; n = 16 }
        @{ t = 'Cola'; depois = 'Moinho de vento'; d = @(
            'A &esuper cola&r junta blocos para eles se moverem juntos. Clique em dois cantos para colar a área.'
        ); item = 'create:super_glue' }
        @{ t = 'Pistão mecânico'; depois = 'Cola'; d = @(
            'Empurra uma estrutura inteira para a frente e para trás. Use &eextensões de pistão&r para ir mais longe.'
        ); item = 'create:mechanical_piston' }
        @{ t = 'Rolamento mecânico'; depois = 'Cola'; d = @(
            'Gira uma estrutura inteira: roda-gigante, porta, ponte levadiça.'
        ); item = 'create:mechanical_bearing' }
        @{ t = 'Colheitadeira'; depois = 'Rolamento mecânico'; d = @(
            'A &ecolheitadeira&r em uma estrutura que anda colhe plantações e replanta.'
            'Faça uma fazenda que se colhe sozinha com um pistão ou rolamento.'
        ); item = 'create:mechanical_harvester' }
        @{ t = 'Arado'; depois = 'Colheitadeira'; opcional = $true; d = @(
            'O &earado&r ara a terra e quebra grama e plantas na frente da estrutura.'
        ); item = 'create:mechanical_plough' }
        @{ t = 'Polia de corda'; depois = 'Cola'; opcional = $true; d = @(
            'Desce e sobe uma estrutura pela corda. Boa para elevador e para minerar para baixo.'
        ); item = 'create:rope_pulley' }
    ) }
    @{ t = 'Create 3: era do latão'; g = 'Tecnologia'; icone = 'create:brass_ingot'; sub = 'Misturar, aquecer e montar peças'; m = @(
        @{ t = 'Bacia'; marco = $true; d = @(
            'A &ebacia&r guarda ingredientes para o misturador e a prensa trabalharem.'
        ); item = 'create:basin' }
        @{ t = 'Misturador'; depois = 'Bacia'; d = @(
            'O &emisturador&r fica &edois blocos acima da bacia&r (um de espaço). Ele mistura o que está na bacia.'
        ); item = 'create:mechanical_mixer' }
        @{ t = 'Compactar'; depois = 'Bacia'; opcional = $true; d = @(
            'A &eprensa em cima da bacia&r compacta: 9 itens viram um bloco, e algumas receitas novas (veja no JEI).'
        ) }
        @{ t = 'Queimador de blaze'; depois = 'Misturador'; marco = $true; d = @(
            'Faça o &equeimador vazio&r e clique com ele em um &eblaze&r (no Nether).'
            'Embaixo da bacia ele &aaquece&r as receitas. Alimente com carvão ou madeira.'
            'Com &ebolo de blaze&r ele fica &esuperaquecido&r, para receitas difíceis.'
        ); item = 'create:blaze_burner' }
        @{ t = 'Latão'; depois = 'Queimador de blaze'; marco = $true; d = @(
            '&eCobre&r e &ezinco&r na bacia aquecida, com o misturador: viram &elatão&r.'
        ); item = 'create:brass_ingot'; q = 16; p = 'create:brass_ingot'; n = 8 }
        @{ t = 'Revestimento de latão'; depois = 'Latão'; d = @(
            'Latão em tronco descascado. Base das máquinas avançadas.'
        ); item = 'create:brass_casing'; q = 4 }
        @{ t = 'Quartzo rosa'; depois = 'Bacia'; d = @(
            'O &equartzo rosa&r é quartzo com redstone. Lixe com a &elixa&r para ficar polido.'
        ); item = 'create:polished_rose_quartz'; q = 4 }
        @{ t = 'Tubo de elétrons'; depois = 'Quartzo rosa'; d = @(
            'O &etubo de elétrons&r é a peça eletrônica do Create: quartzo rosa polido com chapa de ferro.'
        ); item = 'create:electron_tube'; q = 4 }
        @{ t = 'Deployer'; depois = 'Tubo de elétrons'; marco = $true; d = @(
            'O &edeployer&r usa o item da mão dele no bloco da frente, como um jogador.'
            'Põe blocos, usa ferramentas, até ataca. É a base da montagem automática.'
        ); item = 'create:deployer' }
        @{ t = 'Mecanismo de precisão'; depois = @('Deployer', 'Latão'); marco = $true; sub = 'Montagem em sequência'; d = @(
            'Feito em várias etapas em uma esteira com deployers e prensa: a &emontagem em sequência&r.'
            'Veja o passo a passo no JEI. Algumas peças saem quebradas: é normal, recicle.'
        ); item = 'create:precision_mechanism'; p = 'create:precision_mechanism'; n = 2 }
        @{ t = 'Funil de latão'; depois = 'Revestimento de latão'; d = @(
            'O &efunil de latão&r tem &efiltro&r: escolha qual item passa. Também tira a quantidade exata.'
        ); item = 'create:brass_funnel'; q = 2 }
        @{ t = 'Túnel de latão'; depois = 'Funil de latão'; d = @(
            'O &etúnel de latão&r em cima da esteira divide os itens entre várias saídas, com filtro.'
        ); item = 'create:brass_tunnel'; q = 2 }
        @{ t = 'Braço mecânico'; depois = @('Mecanismo de precisão', 'Funil de latão'); marco = $true; d = @(
            'O &ebraço mecânico&r pega de um lugar e põe em outro.'
            'Segure o braço e clique nos lugares de entrada (azul) e saída (laranja) antes de colocar.'
        ); item = 'create:mechanical_arm' }
        @{ t = 'Crafter mecânico'; depois = 'Latão'; d = @(
            'Vários &ecrafters&r juntos fazem receitas grandes sozinhos. Use a chave inglesa para virar as setas.'
        ); item = 'create:mechanical_crafter'; q = 9 }
        @{ t = 'Britadores'; depois = 'Latão'; marco = $true; sub = 'Mais minério por minério'; d = @(
            'Duas &erodas trituradoras&r girando para dentro moem minério e dão &aminério moído&r e extras.'
            'Lave o minério moído com o ventilador e água para ganhar pepitas a mais.'
        ); item = 'create:crushing_wheel'; q = 2 }
        @{ t = 'Cofre'; depois = 'Revestimento de latão'; d = @(
            'O &ecofre&r guarda muito item. Vários juntos viram um cofre grande.'
        ); item = 'create:item_vault'; q = 4 }
        @{ t = 'Calha inteligente'; depois = 'Funil de latão'; opcional = $true; d = @(
            'Uma calha com filtro, que também controla quantos itens descem por vez.'
        ); item = 'create:smart_chute' }
        @{ t = 'Lançador'; depois = 'Funil de latão'; opcional = $true; d = @(
            'O &elançador&r joga itens (ou você) até um alvo. Segure e clique no destino antes de colocar.'
        ); item = 'create:weighted_ejector' }
    ) }
    @{ t = 'Create 4: fluidos e vapor'; g = 'Tecnologia'; icone = 'create:steam_engine'; sub = 'Canos, tanques e muita força'; m = @(
        @{ t = 'Canos'; d = @(
            'Os &ecanos&r levam líquidos. Sozinhos não empurram nada: precisam de bomba.'
        ); item = 'create:fluid_pipe'; q = 8 }
        @{ t = 'Bomba'; depois = 'Canos'; marco = $true; d = @(
            'A &ebomba&r gira e empurra o líquido. Gire a bomba com a chave para inverter o sentido.'
        ); item = 'create:mechanical_pump' }
        @{ t = 'Tanque'; depois = 'Canos'; d = @(
            'O &etanque&r guarda líquido. Vários juntos viram um tanque grande.'
        ); item = 'create:fluid_tank'; q = 4 }
        @{ t = 'Bico'; depois = 'Bomba'; d = @(
            'O &ebico&r enche itens com líquido: garrafas, baldes, e receitas especiais no depósito.'
        ); item = 'create:spout' }
        @{ t = 'Ralo'; depois = 'Bomba'; d = @(
            'O &eralo&r esvazia itens com líquido (baldes, poções) jogados nele.'
        ); item = 'create:item_drain' }
        @{ t = 'Mangueira'; depois = 'Bomba'; d = @(
            'A &epolia de mangueira&r tira ou põe líquido em uma área. Em um lago bem grande, a água &anunca acaba&r.'
        ); item = 'create:hose_pulley' }
        @{ t = 'Válvula'; depois = 'Canos'; opcional = $true; d = @(
            'A &eválvula&r abre e fecha o cano com giro. O &ecano inteligente&r tem filtro de líquido.'
        ); item = 'create:fluid_valve' }
        @{ t = 'Motor a vapor'; depois = @('Tanque', 'Bomba'); marco = $true; sub = 'A fonte de força mais forte'; d = @(
            'Um &etanque&r com &equeimadores de blaze&r embaixo vira caldeira. Bombeie &eágua&r para dentro.'
            'Coloque o &emotor a vapor&r na lateral do tanque e um eixo nele.'
            ''
            'Mais queimadores e mais tanque, mais motores. Olhe a caldeira com os óculos: ela diz o que falta.'
        ); item = 'create:steam_engine'; p = 'minecraft:coal_block'; n = 8 }
        @{ t = 'Apito'; depois = 'Motor a vapor'; opcional = $true; d = @(
            'O &eapito&r na caldeira toca com redstone. Empilhe para mudar a nota.'
        ); item = 'create:steam_whistle' }
        @{ t = 'Chocolate e mel'; depois = 'Bico'; opcional = $true; d = @(
            'O Create tem &echocolate&r e &emel&r líquidos. O bico cobre doces com eles: veja no JEI.'
        ); item = 'create:bar_of_chocolate'; q = 4 }
    ) }
    @{ t = 'Create 5: trens'; g = 'Tecnologia'; icone = 'create:track_station'; sub = 'Linhas de trem entre as bases'; m = @(
        @{ t = 'Trilhos'; marco = $true; d = @(
            'Os &etrilhos do Create&r fazem curvas grandes e subidas. Clique em um ponto e depois no outro para fazer a curva.'
        ); item = 'create:track'; q = 32; p = 'create:track'; n = 32 }
        @{ t = 'Revestimento de trem'; depois = 'Trilhos'; d = @(
            'O &erevestimento de trem&r vem da chapa reforçada (feita com o ventilador e lava, veja no JEI).'
        ); item = 'create:railway_casing'; q = 4 }
        @{ t = 'Estação'; depois = 'Revestimento de trem'; marco = $true; d = @(
            'A &eestação&r fica ao lado do trilho. É onde o trem para e onde ele é montado.'
            'Clique nela para dar nome e entrar no modo de montar.'
        ); item = 'create:track_station' }
        @{ t = 'Controles'; depois = 'Estação'; d = @(
            'Os &econtroles&r são o volante do trem. Sem eles, o trem não anda.'
        ); item = 'create:controls' }
        @{ t = 'Montar um trem'; depois = 'Controles'; marco = $true; sub = 'Seu primeiro trem'; d = @(
            'No modo de montar da estação, ponha &etruques&r (clique com revestimento de trem no trilho) e blocos em cima.'
            'Cole tudo com &esuper cola&r, ponha os controles e clique em &eMontar&r.'
            ''
            '&7Clique em Concluir quando o trem andar.'
        ) }
        @{ t = 'Horário'; depois = 'Montar um trem'; d = @(
            'Com um &ehorário&r na mão, clique em quem está nos controles (pode ser um bicho sentado). O trem anda sozinho entre estações.'
        ); item = 'create:schedule' }
        @{ t = 'Sinais'; depois = 'Montar um trem'; d = @(
            'Os &esinais&r dividem a linha em partes. Dois trens nunca ficam na mesma parte: &asem batida&r.'
        ); item = 'create:track_signal'; q = 2 }
        @{ t = 'Observador de trilho'; depois = 'Sinais'; opcional = $true; d = @(
            'Dá sinal de redstone quando um trem passa. Bom para cancelas e luzes.'
        ); item = 'create:track_observer' }
        @{ t = 'Porta de trem'; depois = 'Montar um trem'; opcional = $true; d = @(
            'A &eporta de trem&r abre sozinha quando o trem para na estação.'
        ); item = 'create:train_door' }
    ) }
    @{ t = 'Create 6: logística'; g = 'Tecnologia'; icone = 'create:packager'; sub = 'Pacotes, estoque e entregas'; m = @(
        @{ t = 'Ligação de redstone'; d = @(
            'A &eligação de redstone&r manda sinal sem fio. Ponha dois itens nas casas dela: só ligações com os mesmos itens conversam.'
        ); item = 'create:redstone_link'; q = 2 }
        @{ t = 'Painel e link'; depois = 'Ligação de redstone'; d = @(
            'O &elink de display&r lê uma máquina, baú ou trem e escreve no &epainel&r, em placas ou em tubos nixie.'
            'Mostre o estoque do armazém ou o horário do trem.'
        ); item = 'create:display_link'; p = 'create:display_board'; n = 6 }
        @{ t = 'Prancheta'; depois = 'Ligação de redstone'; opcional = $true; d = @(
            'Anote listas na &eprancheta&r. Clique em uma máquina para copiar a configuração dela e em outra para colar.'
        ); item = 'create:clipboard' }
        @{ t = 'Empacotador'; depois = 'Ligação de redstone'; marco = $true; sub = 'Itens em caixas'; d = @(
            'O &eempacotador&r encostado em um baú põe os itens em &epacotes de papelão&r.'
            'Pacote com &eendereço&r vai sozinho pelas esteiras e é aberto no lugar certo. Veja o Ponder (&eW&r).'
        ); item = 'create:packager' }
        @{ t = 'Sapo-porto'; depois = 'Empacotador'; d = @(
            'O &esapo-porto&r pega e entrega pacotes pelas &ecorrentes transportadoras&r, mesmo longe.'
        ); item = 'create:package_frogport' }
        @{ t = 'Corrente transportadora'; depois = 'Sapo-porto'; d = @(
            'Ligue duas engrenagens com a corrente: pacotes viajam pendurados nela.'
        ); item = 'create:chain_conveyor'; q = 2 }
        @{ t = 'Painel de estoque'; depois = 'Empacotador'; marco = $true; d = @(
            'O &elink de estoque&r junta os baús em uma rede. O &epainel de estoque&r mostra tudo e &apede itens&r: eles chegam empacotados.'
        ); item = 'create:stock_ticker'; p = 'create:stock_link'; n = 2 }
        @{ t = 'Medidor de fábrica'; depois = 'Painel de estoque'; opcional = $true; d = @(
            'O &emedidor de fábrica&r pede ingredientes sozinho quando falta algo e manda produzir. Uma fábrica que se gerencia.'
        ); item = 'create:factory_gauge' }
    ) }
    @{ t = 'Create: ferramentas'; g = 'Tecnologia'; icone = 'create:copper_backtank'; sub = 'Equipamentos e construções prontas'; m = @(
        @{ t = 'Tanque de ar'; marco = $true; d = @(
            'O &etanque de ar&r nas costas guarda ar comprimido. Encha colocando ele no chão ligado a um giro.'
        ); item = 'create:copper_backtank' }
        @{ t = 'Capacete de mergulho'; depois = 'Tanque de ar'; d = @(
            'Com o tanque nas costas, o &ecapacete de mergulho&r deixa respirar embaixo da água.'
        ); item = 'create:copper_diving_helmet' }
        @{ t = 'Canhão de batata'; depois = 'Tanque de ar'; opcional = $true; d = @(
            'O &ecanhão de batata&r atira comida e outros itens usando o ar do tanque.'
        ); item = 'create:potato_cannon' }
        @{ t = 'Braço extensor'; depois = 'Tanque de ar'; d = @(
            'Com o &ebraço extensor&r em uma mão, você alcança blocos bem mais longe.'
        ); item = 'create:extendo_grip' }
        @{ t = 'Varinha de simetria'; solta = $true; opcional = $true; d = @(
            'Construa um lado e a &evarinha de simetria&r copia do outro lado. Ótima para castelos.'
        ); item = 'create:wand_of_symmetry' }
        @{ t = 'Mesa de esquemas'; solta = $true; marco = $true; sub = 'Construções prontas'; d = @(
            'A &emesa de esquemas&r carrega construções prontas (.nbt). Ponha os arquivos na pasta &eschematics&r do jogo; há muitas no site createmod.com.'
            'Grave as suas com o &eesquema e pena&r.'
        ); item = 'create:schematic_table' }
        @{ t = 'Canhão de esquemas'; depois = 'Mesa de esquemas'; marco = $true; d = @(
            'O &ecanhão de esquemas&r constrói o esquema inteiro sozinho, usando os blocos de um baú ao lado.'
        ); item = 'create:schematicannon'; p = 'create:empty_schematic'; n = 4 }
    ) }
    @{ t = 'Mochila e baús'; g = 'Começo'; icone = 'sophisticatedbackpacks:backpack'; sub = 'Guardar muito e achar tudo rápido'; m = @(
        @{ t = 'Arrumar o inventário'; mod = @('mouse-tweaks', 'inventory-essentials'); sub = 'Mouse Tweaks e Inventory Essentials'; d = @(
            'Truques que economizam muito tempo:'
            '&eRoda do mouse&r em cima de um item: passa ele para o outro lado (baú e inventário).'
            '&eSegure o botão direito e arraste&r: espalha um item por várias casas.'
            '&eShift + clique duplo&r: move todos os itens iguais de uma vez.'
            '&eBotão do meio do mouse&r dentro de um baú: organiza tudo.'
            ''
            '&7Clique em Concluir quando tiver testado.'
        ) }
        @{ t = 'Mochila'; depois = 'Arrumar o inventário'; marco = $true; sub = 'Sophisticated Backpacks'; d = @(
            'A &emochila&r é um baú que vai com você. Faça com couro, um baú e linha.'
            ''
            'Abra com o botão direito segurando ela, ou coloque no lugar do &epeitoral&r e abra com a tecla &eB&r.'
            ''
            '&eShift + botão direito&r no chão coloca a mochila como bloco. Quebre para pegar de volta: os itens continuam dentro.'
        ); item = 'sophisticatedbackpacks:backpack'; p = 'minecraft:leather'; n = 8 }
        @{ t = 'Base de melhoria'; depois = 'Mochila'; d = @(
            'Toda melhoria da mochila parte desta &ebase&r.'
            ''
            'Abra a mochila e coloque a melhoria nas casas da &eesquerda&r. Cada melhoria tem botões próprios para ajustar.'
        ); item = 'sophisticatedbackpacks:upgrade_base'; q = 2 }
        @{ t = 'Coletar sozinho'; depois = 'Base de melhoria'; sub = 'Melhoria de coleta'; d = @(
            'Com a &emelhoria de coleta&r, o que você pega do chão vai &adireto para a mochila&r.'
            ''
            'Dá para filtrar: só pedra, só minério, tudo menos lixo.'
        ); item = 'sophisticatedbackpacks:pickup_upgrade' }
        @{ t = 'Ímã'; depois = 'Base de melhoria'; d = @(
            'A &emelhoria de ímã&r puxa os itens de perto para a mochila. Ótima para minerar e caçar.'
        ); item = 'sophisticatedbackpacks:magnet_upgrade' }
        @{ t = 'Comer sozinho'; depois = 'Base de melhoria'; d = @(
            'A &emelhoria de alimentação&r come a comida da mochila quando você fica com fome. Nunca mais morra de fome na caverna.'
        ); item = 'sophisticatedbackpacks:feeding_upgrade' }
        @{ t = 'Compactar'; depois = 'Base de melhoria'; opcional = $true; d = @(
            'A &emelhoria de compactar&r transforma 9 itens em um bloco sozinha (ferro, carvão, redstone). Economiza muito espaço.'
        ); item = 'sophisticatedbackpacks:compacting_upgrade' }
        @{ t = 'Lixeira'; depois = 'Base de melhoria'; opcional = $true; d = @(
            'A &emelhoria de descarte&r apaga o que você escolher (terra, cascalho, pedra) assim que entra na mochila.'
            ''
            '&cCuidado:&r o que ela apaga não volta.'
        ); item = 'sophisticatedbackpacks:void_upgrade' }
        @{ t = 'Mesa de trabalho na mochila'; depois = 'Base de melhoria'; opcional = $true; d = @(
            'A &emelhoria de mesa de trabalho&r coloca uma mesa de trabalho dentro da mochila. Dá para fazer coisas em qualquer lugar.'
        ); item = 'sophisticatedbackpacks:crafting_upgrade' }
        @{ t = 'Mochila maior'; depois = 'Mochila'; d = @(
            'A mochila sobe de nível: &ecobre, ferro, ouro, diamante e netherite&r. Cada nível tem mais espaço e mais casas de melhoria.'
            ''
            'Faça o nível novo em volta da mochila antiga na mesa: &aos itens continuam dentro&r.'
        ); item = 'sophisticatedbackpacks:iron_backpack'; p = 'minecraft:gold_ingot'; n = 4 }
        @{ t = 'Mochila de diamante'; depois = 'Mochila maior'; marco = $true; d = @(
            'A &emochila de diamante&r já guarda mais que vários baús juntos.'
            ''
            'Dica: a &emelhoria de pilha&r deixa cada casa guardar muito mais itens que 64.'
        ); item = 'sophisticatedbackpacks:diamond_backpack' }
        @{ t = 'Baú que cresce'; depois = 'Arrumar o inventário'; sub = 'Sophisticated Storage'; d = @(
            'Os &ebaús e barris&r do Sophisticated Storage recebem as mesmas ideias da mochila: melhorias de coleta, compactar, filtrar.'
            ''
            'Eles sobem de nível (ferro, ouro, diamante, netherite) com um &eitem de melhoria de nível&r: clique no baú com ele e &aos itens não saem&r.'
        ); item = 'sophisticatedstorage:chest'; p = 'sophisticatedstorage:basic_to_iron_tier_upgrade' }
        @{ t = 'Barril de um item só'; depois = 'Baú que cresce'; opcional = $true; sub = 'Gaveta'; d = @(
            'O &ebarril limitado&r guarda muitas unidades de poucos tipos de item, e mostra na frente o que tem dentro.'
            ''
            'Clique na frente para guardar; clique com o botão esquerdo para tirar.'
        ); item = 'sophisticatedstorage:limited_barrel_1' }
        @{ t = 'Mudar o baú de lugar'; depois = 'Baú que cresce'; opcional = $true; d = @(
            'A &efita de empacotar&r deixa você quebrar um baú cheio e levar ele com tudo dentro.'
            ''
            'Ou use o &eCarry On&r: mãos vazias, Shift e botão direito no baú.'
        ); item = 'sophisticatedstorage:packing_tape' }
        @{ t = 'Baú de ferro'; depois = 'Arrumar o inventário'; sub = 'Iron Chests'; d = @(
            'O &eIron Chests&r tem baús maiores: cobre, ferro, ouro, diamante, cristal (mostra os itens por fora) e obsidiana (não explode).'
            ''
            'Use os &eupgrades&r do mod no baú comum para trocar de nível sem tirar os itens.'
        ); item = 'ironchest:iron_chest' }
        @{ t = 'Terminal de itens'; depois = 'Arrumar o inventário'; marco = $true; sub = 'Tom''s Simple Storage'; d = @(
            'Muitos baús? O &eterminal&r mostra &atodos os itens de todos os baús&r em uma tela só, com busca.'
            ''
            'Como montar: um &econector de inventário&r encostado nos baús, ligado por &ecabos&r até o terminal.'
            ''
            'Digite o nome na busca e tire o que quiser, sem abrir baú por baú.'
        ); item = 'toms_storage:storage_terminal'; p = 'toms_storage:inventory_cable'; n = 16 }
        @{ t = 'Conector de inventário'; depois = 'Terminal de itens'; d = @(
            'O &econector&r é o coração da rede: tudo o que encosta nele, ou nos cabos ligados a ele, entra no terminal.'
        ); item = 'toms_storage:inventory_connector' }
        @{ t = 'Terminal com mesa'; depois = 'Terminal de itens'; d = @(
            'O &eterminal de criação&r junta o terminal com uma mesa de trabalho que &apega os ingredientes direto dos baús&r.'
        ); item = 'toms_storage:crafting_terminal' }
        @{ t = 'Terminal sem fio'; depois = 'Terminal de itens'; opcional = $true; d = @(
            'O &eterminal sem fio&r abre a rede de baús de longe. Clique com ele no terminal para ligar.'
            ''
            'A tecla &eAlt + B&r abre o terminal sem fio que está no seu inventário.'
        ); item = 'toms_storage:wireless_terminal' }
    ) }
    @{ t = 'Cozinha e fazenda'; g = 'Começo'; icone = 'farmersdelight:cooking_pot'; sub = 'Comer bem deixa você mais forte'; m = @(
        @{ t = 'Variedade dá vida'; mod = @('cf:277616'); marco = $true; sub = 'Spice of Life'; d = @(
            'Comer sempre a mesma coisa não compensa: cada comida &enova&r que você prova pela primeira vez dá &acorações extras para sempre&r.'
            ''
            'Passe o mouse em uma comida: o texto diz se você já comeu. Segure uma comida para ver na barra de fome quanto ela enche (&eAppleSkin&r).'
            ''
            'Duas receitas com os mesmos ingredientes? Um botão aparece em cima do resultado para escolher qual fazer (&ePolymorph&r).'
        ) }
        @{ t = 'Faca'; depois = 'Variedade dá vida'; sub = 'Farmer''s Delight'; d = @(
            'A cozinha do &eFarmer''s Delight&r começa com uma &efaca&r. A mais simples é de sílex e graveto.'
            ''
            'Segredo: quebre &egrama alta&r, trigo ou arroz com a faca para ganhar &apalha&r. Com a mão não cai.'
        ); item = 'farmersdelight:flint_knife'; p = 'farmersdelight:straw'; n = 8 }
        @{ t = 'Tábua de corte'; depois = 'Faca'; d = @(
            'Coloque um ingrediente na &etábua de corte&r com o botão direito e clique de novo com a &efaca&r para fatiar carne, peixe e verdura.'
            ''
            'Funciona com outras ferramentas: um &emachado&r em um tronco na tábua dá tábuas e &acasca de árvore&r.'
        ); item = 'farmersdelight:cutting_board'; p = 'farmersdelight:iron_knife' }
        @{ t = 'Fogão'; depois = 'Variedade dá vida'; d = @(
            'O &efogão&r assa até 6 comidas na chapa de cima, sem gastar carvão.'
            ''
            'É também a melhor fonte de calor para colocar a &epanela&r ou a &efrigideira&r em cima.'
        ); item = 'farmersdelight:stove'; p = 'minecraft:coal'; n = 8 }
        @{ t = 'Cozinha'; depois = 'Fogão'; sub = 'A panela'; d = @(
            'Coloque a &epanela&r em cima de uma fonte de calor (fogão, fogueira ou magma) para cozinhar até 6 ingredientes juntos.'
            ''
            'Alguns pratos pedem &etigela&r ou &egarrafa&r no espaço do recipiente.'
            ''
            'Quebrou a panela com comida dentro? &aA comida vai junto&r: dá para levar em viagens.'
        ); item = 'farmersdelight:cooking_pot'; p = 'minecraft:bowl'; n = 8 }
        @{ t = 'Frigideira'; depois = 'Fogão'; d = @(
            'A &efrigideira&r frita uma comida por vez.'
            ''
            'No chão: coloque em cima de um fogão ou fogueira e clique com a comida.'
            'Na mão: perto de um fogo, segure a frigideira em uma mão e a comida crua na outra, e segure o botão direito.'
        ); item = 'farmersdelight:skillet'; p = 'farmersdelight:bacon_and_eggs'; n = 2 }
        @{ t = 'Banquete'; depois = 'Cozinha'; opcional = $true; d = @(
            'Vários pratos grandes, como o &efrango assado&r, viram um &ebloco&r na mesa.'
            ''
            'Clique com uma &etigela&r vazia para servir uma porção. Bolos e tortas se cortam com a &efaca&r. Ótimo para dividir com os amigos.'
        ); item = 'farmersdelight:roast_chicken_block'; p = 'farmersdelight:sweet_berry_cheesecake' }
        @{ t = 'Terra rica'; depois = 'Variedade dá vida'; sub = 'Plantas crescem mais rápido'; d = @(
            'O &ecomposto orgânico&r colocado no chão vira &aterra rica&r com o tempo. Fica mais rápido no sol, perto de água ou de cogumelos.'
            ''
            'Are a terra rica com a enxada: as plantas crescem &amais rápido&r e ela &anão estraga&r se alguém pular em cima.'
        ); item = 'farmersdelight:organic_compost'; p = 'farmersdelight:rich_soil'; n = 4 }
        @{ t = 'Colônia de cogumelos'; depois = 'Terra rica'; opcional = $true; d = @(
            'Plante um cogumelo em cima de &eterra rica&r em lugar escuro: ele vira uma &ecolônia&r.'
            ''
            'Use a &etesoura&r nela para colher cogumelos sem destruir a colônia.'
        ); item = 'farmersdelight:brown_mushroom_colony'; p = 'farmersdelight:red_mushroom_colony' }
        @{ t = 'Arroz e tomate'; depois = 'Faca'; sub = 'Plantas diferentes'; d = @(
            'O &earroz&r se planta na terra &edebaixo de um bloco de água&r, nunca em terra arada seca.'
            ''
            'O &etomate&r sobe por &ecorda&r: pendure corda em cima do pé para ele crescer e dar mais tomates.'
        ); item = 'farmersdelight:rice'; q = 4; p = 'farmersdelight:rope'; n = 8 }
        @{ t = 'Estações do ano'; depois = 'Variedade dá vida'; marco = $true; sub = 'Serene Seasons'; d = @(
            'O mundo tem &eprimavera, verão, outono e inverno&r. No inverno os dias são mais curtos e neva.'
            ''
            'Cada planta cresce bem só em certas estações. Passe o mouse na semente para ver quais.'
            ''
            'Truque: plantação com &evidro&r em cima (estufa) ou no subsolo cresce o ano inteiro.'
            ''
            'O &ecalendário&r mostra a estação e quantos dias faltam para a próxima.'
        ); item = 'sereneseasons:calendar'; p = 'minecraft:glass'; n = 16 }
        @{ t = 'Sensor de estação'; depois = 'Estações do ano'; opcional = $true; d = @(
            'O &esensor de estação&r manda sinal de &eredstone&r conforme a estação. Serve para ligar luzes ou máquinas na época certa.'
        ); item = 'sereneseasons:season_sensor'; p = 'minecraft:redstone'; n = 8 }
        @{ t = 'Frutas do mundo'; depois = 'Variedade dá vida'; sub = 'Croptopia'; d = @(
            'O &eCroptopia&r espalha dezenas de frutas, verduras e árvores frutíferas pelos biomas.'
            ''
            'Achou uma planta nova? Coloque a fruta na mesa de trabalho para fazer &asementes&r. Nas árvores frutíferas, clique nas folhas maduras.'
            ''
            'O &esal&r aparece em muitas receitas: veja como fazer com &eR&r em cima dele.'
        ); item = 'croptopia:salt'; q = 4; p = 'croptopia:cooking_pot' }
        @{ t = 'Utensílios que não quebram'; depois = 'Frutas do mundo'; sub = 'Croptopia'; d = @(
            'O Croptopia cozinha na &emesa de trabalho&r com 5 utensílios: pilão, prensa, panela, frigideira e faca.'
            ''
            'Eles &anunca quebram&r: ficam na mesa depois de cada receita.'
        ); item = 'croptopia:mortar_and_pestle'; p = 'croptopia:frying_pan' }
        @{ t = 'Comida do mundo todo'; depois = 'Variedade dá vida'; sub = 'Cultural Delights'; d = @(
            'O &eCultural Delights&r traz milho, pepino, berinjela e abacate, espalhados por planícies, pântanos e selvas.'
            ''
            'O &ebarril&r do mod fermenta comidas como picles e queijo. Veja as receitas com &eU&r em cima dele.'
        ); item = 'culturaldelights:vat'; p = 'culturaldelights:corn_cob'; n = 4 }
        @{ t = 'Armários de cozinha'; depois = 'Cozinha'; opcional = $true; sub = 'Storage Delight'; d = @(
            'Gavetas, armários com porta de vidro e balcões em todas as madeiras, para a cozinha ficar organizada e bonita.'
        ); item = 'storagedelight:oak_drawer'; p = 'storagedelight:oak_cabinet_with_glass_doors'; n = 2 }
        @{ t = 'Cozinha montada'; depois = 'Cozinha'; marco = $true; sub = 'Cooking for Blockheads'; d = @(
            'A &emesa de cozinha&r mostra tudo o que dá para cozinhar com o que você tem no inventário e nos blocos ligados a ela.'
            ''
            'Encoste &egeladeira, armários, balcões e forno&r do mod na mesa (ou ligue com &episo de cozinha&r) para formar uma cozinha só.'
            ''
            'Clique em um prato da lista e ele é feito na hora, sem procurar ingrediente baú por baú.'
        ); item = 'cookingforblockheads:cooking_table'; p = 'cookingforblockheads:white_fridge' }
        @{ t = 'Água e leite sem fim'; depois = 'Cozinha montada'; d = @(
            'A &epia&r ligada à cozinha dá &aágua infinita&r para as receitas.'
            ''
            'Leite infinito: coloque um &epote de leite&r no chão, leve uma vaca para cima e derrube uma &ebigorna&r nela. Ela vira uma &evaca no pote&r.'
        ); item = 'cookingforblockheads:sink'; p = 'cookingforblockheads:milk_jar' }
        @{ t = 'Melhorias da geladeira'; depois = 'Cozinha montada'; opcional = $true; d = @(
            'Clique na geladeira com a &eunidade de gelo&r para ter gelo e neve infinitos nas receitas.'
            ''
            'Veja as outras melhorias do forno e da geladeira com &eU&r em cima delas.'
        ); item = 'cookingforblockheads:ice_unit'; p = 'cookingforblockheads:heating_unit' }
        @{ t = 'Vaso de planta'; depois = 'Terra rica'; sub = 'Botany Pots'; d = @(
            'O &evaso&r planta lavoura e até árvore em &aum bloco só&r, dentro de casa e sem água.'
            ''
            'Coloque terra dentro (areia para cacto), depois a semente. Quando crescer, clique para colher.'
            ''
            'Terra rica dentro do vaso faz crescer mais rápido.'
        ); item = 'botanypots:terracotta_botany_pot'; p = 'farmersdelight:rich_soil'; n = 2 }
        @{ t = 'Vaso que colhe sozinho'; depois = 'Vaso de planta'; marco = $true; sub = 'Botany Pots'; d = @(
            'O &evaso com funil&r colhe e replanta &asozinho para sempre&r. Coloque em cima de um baú: a colheita vai para dentro.'
            ''
            'Dez vasos desses em cima de baús viram uma fazenda que nunca para.'
        ); item = 'botanypots:terracotta_hopper_botany_pot'; p = 'minecraft:hopper'; n = 2 }
        @{ t = 'Comida de viagem'; depois = 'Cozinha'; opcional = $true; sub = 'Ocean''s, End''s e Twilight Delight'; d = @(
            'Explorar libera pratos novos com efeitos bons:'
            '&eOcean''s Delight&r: lula, baiacu e sopas do mar.'
            '&eEnd''s Delight&r: fruta do coro e pratos do End.'
            '&eTwilight Delight&r: comidas da Twilight Forest.'
        ); item = 'oceansdelight:squid_rings' }
        @{ t = 'Cortadora do Create'; depois = 'Tábua de corte'; opcional = $true; sub = 'Slice & Dice'; d = @(
            'A &ecortadora&r faz o trabalho da tábua de corte com a rotação do Create. Dê uma &efaca&r para ela e mande os ingredientes por baixo.'
            ''
            'O &easpersor&r embaixo de um cano com água molha a plantação. Segure &eW&r em cima das peças para ver a animação.'
        ); item = 'sliceanddice:slicer'; p = 'sliceanddice:sprinkler'; n = 2 }
        @{ t = 'Cozinha automática'; mod = @('create-central-kitchen'); depois = 'Cortadora do Create'; opcional = $true; sub = 'Create: Central Kitchen'; d = @(
            'Com o &eCentral Kitchen&r, as máquinas do Create (braço mecânico, depositante) cozinham as receitas do Farmer''s Delight sozinhas.'
            ''
            'Um &equeimador de blaze&r embaixo da panela acelera o cozimento. Segure &eW&r nos itens para ver como montar.'
        ) }
        @{ t = 'Plantar minério'; depois = 'Vaso de planta'; opcional = $true; sub = 'Mystical Agriculture'; d = @(
            'O &eMystical Agriculture&r planta minério como se fosse trigo.'
            ''
            'Comece minerando &einferium&r nas cavernas. A essência dele faz as primeiras sementes. Veja o caminho todo com &eU&r em cima da essência.'
        ); item = 'mysticalagriculture:inferium_essence'; q = 8; p = 'mysticalagriculture:prosperity_seed_base'; n = 2 }
    ) }
    @{ t = 'Construir'; g = 'Começo'; icone = 'mcwroofs:oak_roof'; sub = 'Casas bonitas com móveis de verdade'; m = @(
        @{ t = 'Construir sem sofrer'; mod = @('effortless-building'); marco = $true; sub = 'Effortless Building'; d = @(
            'Segure &eAlt&r para abrir o menu de construção. Escolha uma forma: &elinha, parede, chão, cubo, círculo&r.'
            ''
            'Com um bloco na mão, clique onde começa, mire onde termina e clique de novo: a forma inteira aparece de uma vez. Funciona no sobrevivência, gastando os blocos do inventário.'
            ''
            'No mesmo menu tem &eespelho&r (constrói os dois lados iguais) e &erepetição&r. Para desligar, segure Alt e escolha desligar.'
        ) }
        @{ t = 'Bloco aleatório'; depois = 'Construir sem sofrer'; opcional = $true; sub = 'Effortless Building'; d = @(
            'A &esacola de blocos aleatórios&r coloca um bloco sorteado dos que estão dentro dela. Ótima para chão e parede com textura misturada (pedra, cascalho, andesito).'
        ); item = 'effortlessbuilding:randomizer_tool' }
        @{ t = 'Telhado de verdade'; depois = 'Construir sem sofrer'; sub = 'Macaw''s Roofs'; d = @(
            'Chega de telhado de escada: o &eMacaw''s Roofs&r tem telhados com inclinação, cumeeira e beiral em todas as madeiras e pedras.'
            ''
            'Procure &e@mcwroofs&r no JEI para ver todos.'
        ); item = 'mcwroofs:oak_roof'; q = 8 }
        @{ t = 'Janela'; depois = 'Construir sem sofrer'; sub = 'Macaw''s Windows'; d = @(
            'Janelas de verdade, persianas, venezianas e &ecortinas&r (coloque o varão e clique com lã).'
        ); item = 'mcwwindows:oak_window'; q = 4 }
        @{ t = 'Porta diferente'; depois = 'Construir sem sofrer'; sub = 'Macaw''s Doors'; d = @(
            'Portas de celeiro, de vidro, japonesa, de faroeste, de garagem e muitas outras.'
        ); item = 'mcwdoors:oak_barn_door' }
        @{ t = 'Cerca bonita'; depois = 'Construir sem sofrer'; opcional = $true; sub = 'Macaw''s Fences and Walls'; d = @(
            'Cercas de estaca, de fazenda, de arame e portões curvos, todos no estilo do Minecraft.'
        ); item = 'mcwfences:oak_picket_fence'; q = 8 }
        @{ t = 'Ponte'; depois = 'Construir sem sofrer'; opcional = $true; sub = 'Macaw''s Bridges'; d = @(
            'Pontes de corda, de tronco, de ferro e de vidro. Elas se ajustam sozinhas quando você coloca uma do lado da outra.'
        ); item = 'mcwbridges:rope_oak_bridge'; q = 8 }
        @{ t = 'Primeiros móveis'; depois = 'Construir sem sofrer'; sub = 'Macaw''s Furniture'; d = @(
            'Mesas, cadeiras, gavetas, guarda-roupas e armários de cozinha em todas as madeiras.'
            ''
            'Muitos guardam itens: gavetas e guarda-roupas funcionam como baús. Clique com o botão direito numa cadeira para sentar.'
        ); item = 'mcwfurnitures:oak_chair' }
        @{ t = 'Casa aconchegante'; depois = 'Primeiros móveis'; sub = 'Handcrafted'; d = @(
            'Sofás, camas bonitas, criados-mudos, prateleiras e almofadas no estilo do Minecraft.'
            ''
            'O &emartelo&r do Handcrafted muda o formato de alguns móveis: clique com ele no bloco.'
        ); item = 'handcrafted:oak_couch'; p = 'handcrafted:hammer' }
        @{ t = 'Troféu'; depois = 'Casa aconchegante'; opcional = $true; sub = 'Handcrafted'; d = @(
            'Pendure na parede o troféu de um bicho ou monstro que você venceu: urso, creeper, blaze e outros.'
        ); item = 'handcrafted:creeper_trophy' }
        @{ t = 'Móveis que funcionam'; depois = 'Primeiros móveis'; marco = $true; sub = 'Furniture Refurbished'; d = @(
            'O &eFurniture Refurbished&r tem móveis que fazem coisas: geladeira que guarda comida, fogão que cozinha, pia com água, TV, computador e campainha.'
            ''
            'Os móveis do mod saem da &ebancada&r dele. Alguns, como luzes e TV, precisam de &eenergia&r do próprio mod: veja com &eU&r em cima deles.'
        ); item = 'refurbished_furniture:light_fridge' }
        @{ t = 'Correio'; depois = 'Móveis que funcionam'; opcional = $true; sub = 'Furniture Refurbished'; d = @(
            'Coloque uma &ecaixa de correio&r na frente de casa e dê um nome a ela. Os amigos podem mandar itens para ela de longe. Veja como com &eU&r em cima da caixa.'
        ); item = 'refurbished_furniture:oak_mail_box' }
        @{ t = 'Pote'; depois = 'Construir sem sofrer'; sub = 'Supplementaries'; d = @(
            'O &epote&r guarda líquidos, biscoitos e até &abichinhos&r: vagalumes, peixes e lesmas. Clique no bicho com o pote vazio.'
        ); item = 'supplementaries:jar' }
        @{ t = 'Placa de direção'; depois = 'Pote'; sub = 'Supplementaries'; d = @(
            'A &eplaca de direção&r tem duas setas. Escreva nelas o nome dos lugares (casa, mina, vila) e gire para apontar o caminho.'
        ) }
        @{ t = 'Corda'; depois = 'Pote'; d = @(
            'A &ecorda&r do Supplementaries serve para &asubir e descer&r em buracos fundos. Clique com mais corda nela para ela descer mais.'
        ); item = 'supplementaries:rope'; q = 16 }
        @{ t = 'Estilingue'; depois = 'Pote'; opcional = $true; sub = 'Supplementaries'; d = @(
            'O &eestilingue&r atira qualquer item. Com tochas, ele ilumina caverna de longe.'
        ); item = 'supplementaries:slingshot' }
        @{ t = 'Aljava'; depois = 'Pote'; opcional = $true; sub = 'Supplementaries'; d = @(
            'A &ealjava&r guarda vários tipos de flecha num espaço só. A tecla &eAlt + V&r troca a flecha.'
        ); item = 'supplementaries:quiver' }
        @{ t = 'Globo e enfeites'; depois = 'Pote'; opcional = $true; sub = 'Supplementaries'; d = @(
            'Globo que gira, relógio de parede, fole, torneira, vaso de flor, cofre: o Supplementaries tem dezenas de blocos. Veja com &e@supplementaries&r no JEI.'
        ); item = 'supplementaries:globe' }
        @{ t = 'Decoração'; depois = 'Construir sem sofrer'; sub = 'Beautify'; d = @(
            'Persianas, porta-retratos, treliça para plantas, lâmpadas e vasos pendurados.'
        ); item = 'beautify:oak_picture_frame' }
        @{ t = 'Vaso pendurado'; depois = 'Decoração'; opcional = $true; sub = 'Beautify'; d = @(
            'Pendure no teto e coloque uma flor dentro.'
        ); item = 'beautify:hanging_pot' }
        @{ t = 'Móveis do Create'; depois = 'Primeiros móveis'; opcional = $true; sub = 'Create: Interiors'; d = @(
            'Bancos e cadeiras no estilo do Create. Dá para sentar, inclusive em trens e máquinas que andam.'
        ); item = 'interiors:kelp_chair' }
    ) }
    @{ t = 'Animais'; g = 'Começo'; icone = 'alexsmobs:banana'; sub = 'Bichos novos, pets e dragões'; m = @(
        @{ t = 'Dicionário animal'; marco = $true; sub = 'Alex''s Mobs'; d = @(
            'O pack tem &amais de 150 bichos novos&r. O &eDicionário animal&r explica cada um do Alex''s Mobs: onde vive, o que come e como domesticar.'
            ''
            'Mire em qualquer bicho para ver o nome e o mod no topo da tela. Bicho desconhecido? Procure o nome no JEI.'
        ); item = 'alexsmobs:animal_dictionary' }
        @{ t = 'Hamster'; depois = 'Dicionário animal'; sub = 'Adorable Hamster Pets'; d = @(
            'Hamsters vivem nos campos. Para domesticar, dê &epepino fatiado&r (corte o pepino na tábua de corte).'
            ''
            'Dá para carregar até &atrês nos ombros&r: eles avisam quando tem creeper perto e farejam diamante.'
            ''
            'O livro do hamster explica tudo: camas, armadura, comidas.'
        ); conquista = 'adorablehamsterpets:husbandry/tame_hamster'; p = 'adorablehamsterpets:sliced_cucumber'; n = 8 }
        @{ t = 'Hamster no ombro'; depois = 'Hamster'; opcional = $true; d = @(
            'Com um hamster domesticado, agache (&eShift&r) e clique nele para colocar no ombro.'
        ); conquista = 'adorablehamsterpets:husbandry/shoulder_hamster' }
        @{ t = 'Banana'; depois = 'Dicionário animal'; sub = 'Alex''s Mobs'; d = @(
            'Bananas caem das &efolhas da selva&r. Elas servem para domesticar macacos e gorilas.'
        ); item = 'alexsmobs:banana'; q = 4 }
        @{ t = 'Macaco-prego'; depois = 'Banana'; sub = 'Alex''s Mobs'; d = @(
            'O &emacaco-prego&r vive na selva. Dê &ebananas&r para domesticar. Ele senta no ombro e ajuda a atacar.'
        ); conquista = 'alexsmobs:alexsmobs/tame_capuchin' }
        @{ t = 'Gorila'; depois = 'Banana'; sub = 'Alex''s Mobs'; d = @(
            'O &egorila&r vive em grupos na selva, com um gorila-de-costas-prateadas no comando. Dê &ebananas&r para domesticar.'
        ); conquista = 'alexsmobs:alexsmobs/tame_gorilla' }
        @{ t = 'Urso amigo'; depois = 'Dicionário animal'; opcional = $true; sub = 'Alex''s Mobs'; d = @(
            'O &eurso-pardo&r é perigoso, mas dá para domesticar com &emel&r e &esalmão&r. Depois ele aceita sela!'
        ); conquista = 'alexsmobs:alexsmobs/tame_grizzly_bear' }
        @{ t = 'Elefante'; depois = 'Dicionário animal'; opcional = $true; sub = 'Alex''s Mobs'; d = @(
            'O &eelefante&r vive na savana. Domesticado, carrega você e um baú nas costas. Veja como no Dicionário animal.'
        ); conquista = 'alexsmobs:alexsmobs/tame_elephant' }
        @{ t = 'Águia caçadora'; depois = 'Dicionário animal'; opcional = $true; sub = 'Alex''s Mobs'; d = @(
            'A &eáguia-careca&r pode ser treinada para caçar com uma &eluva de falcoaria&r.'
        ); conquista = 'alexsmobs:alexsmobs/tame_bald_eagle' }
        @{ t = 'Rede de captura'; depois = 'Dicionário animal'; sub = 'Naturalist'; d = @(
            'O &eNaturalist&r traz bichos realistas: urso, cervo, leão, elefante, cobra, borboleta.'
            ''
            'A &erede de captura&r pega bichinhos (borboletas, vagalumes, caracóis) para levar para casa.'
        ); item = 'naturalist:capture_net' }
        @{ t = 'Urso com mel'; depois = 'Rede de captura'; opcional = $true; sub = 'Naturalist'; d = @(
            'Os ursos do Naturalist adoram mel. Dê um &efavo de mel&r para um urso.'
        ); conquista = 'naturalist:husbandry/feed_bear_honeycomb' }
        @{ t = 'Hipopótamo'; depois = 'Rede de captura'; opcional = $true; sub = 'Naturalist'; d = @(
            'Dê uma &emelancia&r para um hipopótamo no pântano ou rio.'
        ); conquista = 'naturalist:husbandry/feed_hippo_melon' }
        @{ t = 'Golem de cobre'; depois = 'Dicionário animal'; sub = 'Friends&Foes'; d = @(
            'O &egolem de cobre&r aperta botões de cobre sozinho. Ele é montado no mundo com blocos de cobre, como o golem de ferro.'
            ''
            'Cuidado: ele enferruja com o tempo. Encere com favo de mel para parar.'
        ); conquista = 'friendsandfoes:adventure/summon_copper_golem' }
        @{ t = 'Moobloom'; depois = 'Golem de cobre'; opcional = $true; sub = 'Friends&Foes'; d = @(
            'A &emoobloom&r é uma vaca com flores nas costas. Use a tesoura nela para pegar flores amarelas.'
        ); conquista = 'friendsandfoes:husbandry/shear_a_moobloom' }
        @{ t = 'Glare'; depois = 'Golem de cobre'; opcional = $true; sub = 'Friends&Foes'; d = @(
            'O &eglare&r é um bichinho de musgo que mostra os lugares escuros onde monstros podem nascer. Domestique com &ebagas brilhantes&r.'
        ); conquista = 'friendsandfoes:husbandry/tame_a_glare' }
        @{ t = 'Gancho'; depois = 'Dicionário animal'; opcional = $true; sub = 'Critters and Companions'; d = @(
            'O &eCritters and Companions&r traz lontras, libélulas, furões e coelhinhos-do-mar.'
            ''
            'O &egancho&r puxa você até onde ele prender. Ótimo para escalar.'
        ); item = 'crittersandcompanions:grappling_hook' }
        @{ t = 'Vila dos sapos'; depois = 'Dicionário animal'; opcional = $true; sub = 'Ribbits'; d = @(
            'Nos &epântanos&r existem vilas de sapos. Os sapos tocam música e trocam itens.'
        ); estrutura = 'ribbits:ribbit_village' }
        @{ t = 'Troféu de caça'; depois = 'Dicionário animal'; opcional = $true; sub = 'Wilder Nature'; d = @(
            'O &eWilder Nature&r traz bisões, cervos e lobos-vermelhos. Os troféus enfeitam a parede.'
        ); item = 'wildernature:deer_trophy' }
        @{ t = 'Dinossauros'; mod = @('archies-dinosaurs'); depois = 'Dicionário animal'; opcional = $true; sub = 'Archie''s Dinosaurs'; d = @(
            'Dinossauros vivem soltos pelo mundo, dos herbívoros grandes aos predadores. &cCuidado&r com os carnívoros.'
            ''
            '&7Clique em Concluir quando vir o primeiro.'
        ) }
        @{ t = 'Ovo de dragão'; depois = 'Dicionário animal'; marco = $true; sub = 'Dragon Mounts'; d = @(
            'Dragões vivem no mundo normal, no Nether e no End. Também dá para achar &eovos de dragão&r.'
            ''
            'Coloque o ovo no chão e espere chocar: o filhote já nasce seu.'
        ); conquista = 'dmr:hatch_1_dragon_egg' }
        @{ t = 'Domar um dragão'; depois = 'Ovo de dragão'; marco = $true; sub = 'Dragon Mounts'; d = @(
            'Dragão adulto se doma dando &epeixe&r até aparecerem corações.'
            ''
            'Coloque uma &esela&r e monte: &eespaço&r sobe, &eShift&r desce. O &eapito&r chama o dragão de longe.'
        ); conquista = 'dmr:tame_dragon'; p = 'minecraft:saddle' }
    ) }
    @{ t = 'Mekanism 1: começo'; g = 'Tecnologia'; icone = 'mekanism:metallurgic_infuser'; sub = 'Máquinas elétricas e aço'; m = @(
        @{ t = 'O que é o Mekanism'; marco = $true; sub = 'Comece por aqui'; d = @(
            'O &eMekanism&r tem máquinas elétricas que processam minério, gases e muito mais.'
            'É mais complexo que o Create. Faça o Create primeiro: a &eenergia&r vem do &ealternador&r (capítulo Create: energia).'
            ''
            'Dica: no JEI (&eU&r em um item) você vê em qual máquina ele é usado.'
        ) }
        @{ t = 'Ósmio'; depois = 'O que é o Mekanism'; d = @(
            'O &eósmio&r é o metal do Mekanism. O minério azulado aparece em cavernas.'
        ); item = 'mekanism:ingot_osmium'; q = 8 }
        @{ t = 'Infusor metalúrgico'; depois = 'Ósmio'; marco = $true; d = @(
            'O &einfusor metalúrgico&r junta um item com outro material: ferro com &ecarvão&r vira ferro enriquecido e depois &eaço&r; com &eredstone&r vira liga infundida.'
            'Precisa de energia ligada nele.'
        ); item = 'mekanism:metallurgic_infuser' }
        @{ t = 'Aço'; depois = 'Infusor metalúrgico'; d = @(
            'Pó de aço (do infusor) derretido na fornalha vira &elingote de aço&r.'
        ); item = 'mekanism:ingot_steel'; q = 8 }
        @{ t = 'Revestimento de aço'; depois = 'Aço'; marco = $true; d = @(
            'O &erevestimento de aço&r é a base de quase toda máquina do Mekanism.'
        ); item = 'mekanism:steel_casing'; p = 'mekanism:ingot_steel'; n = 8 }
        @{ t = 'Circuito básico'; depois = 'Infusor metalúrgico'; d = @(
            'O &ecircuito de controle&r vai em muitas receitas. Ósmio com liga infundida.'
        ); item = 'mekanism:basic_control_circuit'; q = 4 }
        @{ t = 'Cabo universal'; depois = 'Revestimento de aço'; d = @(
            'O &ecabo universal&r leva energia entre máquinas. Ligue o alternador do Create nele.'
        ); item = 'mekanism:basic_universal_cable'; q = 8 }
        @{ t = 'Cubo de energia'; depois = 'Cabo universal'; d = @(
            'O &ecubo de energia&r guarda energia. Dá para subir de nível depois.'
        ); item = 'mekanism:basic_energy_cube' }
        @{ t = 'Configurador'; depois = 'Revestimento de aço'; d = @(
            'O &econfigurador&r escolhe o que entra e sai em cada lado da máquina. Na própria máquina, a aba de lados faz o mesmo.'
        ); item = 'mekanism:configurator' }
        @{ t = 'Fornalha elétrica'; depois = 'Revestimento de aço'; d = @(
            'A &efornalha energizada&r cozinha rápido, sem carvão, só com energia.'
        ); item = 'mekanism:energized_smelter' }
        @{ t = 'Triturador'; depois = 'Revestimento de aço'; opcional = $true; d = @(
            'O &etriturador&r mói lingotes em pó e pedra em cascalho e areia.'
        ); item = 'mekanism:crusher' }
        @{ t = 'Melhorias'; depois = 'Revestimento de aço'; d = @(
            'As &emelhorias&r de velocidade e energia vão na aba de melhorias da máquina.'
        ); item = 'mekanism:upgrade_speed' }
        @{ t = 'Fábrica'; depois = 'Melhorias'; opcional = $true; d = @(
            'O &einstalador de nível&r vira uma máquina comum em &efábrica&r: processa vários itens de uma vez.'
        ); item = 'mekanism:basic_smelting_factory' }
        @{ t = 'Baú pessoal'; depois = 'Revestimento de aço'; opcional = $true; d = @(
            'O &ebaú pessoal&r só abre para você. Bom no servidor.'
        ); item = 'mekanism:personal_chest' }
    ) }
    @{ t = 'Mekanism 2: minérios'; g = 'Tecnologia'; icone = 'mekanism:enrichment_chamber'; sub = 'De 2 a 5 lingotes por minério'; m = @(
        @{ t = 'Câmara de enriquecimento'; marco = $true; sub = '2 lingotes por minério'; d = @(
            'A &ecâmara de enriquecimento&r transforma um minério em &edois pós&r. Derreta os pós: dobro de lingotes.'
        ); item = 'mekanism:enrichment_chamber' }
        @{ t = 'Separador eletrolítico'; depois = 'Câmara de enriquecimento'; d = @(
            'O &eseparador eletrolítico&r quebra &eágua&r em &ehidrogênio&r e &eoxigênio&r. Os gases andam em &etubos pressurizados&r.'
            'Use a &ebomba elétrica&r para puxar água.'
        ); item = 'mekanism:electrolytic_separator'; p = 'mekanism:basic_pressurized_tube'; n = 8 }
        @{ t = 'Câmara de purificação'; depois = 'Separador eletrolítico'; marco = $true; sub = '3 lingotes por minério'; d = @(
            'Com &eoxigênio&r, a &ecâmara de purificação&r faz &etrês pedaços&r por minério. Os pedaços seguem para o triturador e a câmara de enriquecimento.'
        ); item = 'mekanism:purification_chamber' }
        @{ t = 'Câmara de injeção'; depois = 'Câmara de purificação'; marco = $true; sub = '4 lingotes por minério'; d = @(
            'Com &ecloreto de hidrogênio&r (feito no infusor químico com hidrogênio e cloro), a &ecâmara de injeção química&r faz &equatro fragmentos&r por minério.'
            'Veja a cadeia toda no JEI.'
        ); item = 'mekanism:chemical_injection_chamber' }
        @{ t = 'Dissolução e cristais'; depois = 'Câmara de injeção'; marco = $true; sub = '5 lingotes por minério'; d = @(
            'O último nível: &ecâmara de dissolução&r, &elavador químico&r e &ecristalizador&r. Cinco lingotes por minério.'
            'Precisa de ácido sulfúrico e água limpa. Veja tudo no JEI.'
        ); item = 'mekanism:chemical_crystallizer' }
        @{ t = 'Transportador'; depois = 'Câmara de enriquecimento'; d = @(
            'O &etransportador logístico&r leva itens entre máquinas. Com o configurador escolha a cor e a ordem.'
        ); item = 'mekanism:basic_logistical_transporter'; q = 8 }
        @{ t = 'Cano mecânico'; depois = 'Câmara de enriquecimento'; opcional = $true; d = @(
            'O &ecano mecânico&r leva líquidos.'
        ); item = 'mekanism:basic_mechanical_pipe'; q = 8 }
        @{ t = 'Leitor sísmico'; depois = 'Câmara de enriquecimento'; opcional = $true; d = @(
            'O &evibrador sísmico&r com o &eleitor sísmico&r mostra os minérios de baixo da terra, até o fundo.'
        ); item = 'mekanism:seismic_reader' }
    ) }
    @{ t = 'Mekanism 3: avançado'; g = 'Tecnologia'; icone = 'mekanism:digital_miner'; sub = 'Mineradora, teletransporte e armadura'; m = @(
        @{ t = 'Circuito avançado'; marco = $true; d = @(
            'Os circuitos sobem de nível: &eavançado&r, &eelite&r, &eultimate&r. Cada um usa uma liga melhor do infusor.'
        ); item = 'mekanism:advanced_control_circuit'; q = 2 }
        @{ t = 'Liga reforçada'; depois = 'Circuito avançado'; d = @(
            'Liga infundida com &ediamante&r no infusor vira &eliga reforçada&r.'
        ); item = 'mekanism:alloy_reinforced'; q = 4 }
        @{ t = 'Mineradora digital'; depois = 'Liga reforçada'; marco = $true; sub = 'Minera sozinha'; d = @(
            'A &emineradora digital&r tira só os blocos que você filtrar (ex.: todos os minérios) em uma área grande.'
            'Gasta muita energia. Ponha um baú atrás dela.'
        ); item = 'mekanism:digital_miner' }
        @{ t = 'Desintegrador atômico'; depois = 'Circuito avançado'; d = @(
            'O &edesintegrador atômico&r é picareta, pá, machado e espada em um, carregado com energia.'
        ); item = 'mekanism:atomic_disassembler' }
        @{ t = 'Jetpack de hidrogênio'; depois = 'Circuito avançado'; d = @(
            'O &ejetpack&r do Mekanism voa com &ehidrogênio&r. Encha no separador eletrolítico.'
        ); item = 'mekanism:jetpack' }
        @{ t = 'Teletransporte'; depois = 'Liga reforçada'; marco = $true; d = @(
            'O &eteletransportador&r leva você entre bases. Monte a moldura (veja no JEI) e dê a mesma frequência aos dois.'
            'O &eteletransportador portátil&r vai no bolso.'
        ); item = 'mekanism:teleporter' }
        @{ t = 'Armazenamento QIO'; depois = 'Liga reforçada'; d = @(
            'O &eQIO&r guarda itens em discos e mostra tudo em um painel, até de longe.'
        ); item = 'mekanism:qio_drive_array' }
        @{ t = 'Liga atômica'; depois = 'Liga reforçada'; d = @(
            'Liga reforçada com &eobsidiana refinada&r vira &eliga atômica&r, para as coisas mais fortes.'
        ); item = 'mekanism:alloy_atomic'; q = 4 }
        @{ t = 'MekaSuit'; depois = 'Liga atômica'; marco = $true; opcional = $true; sub = 'O fim do Mekanism'; d = @(
            'A &eMekaSuit&r é a armadura mais forte do Mekanism, com módulos (voar, visão noturna, mais vida).'
            'Feita no &eformulário&r com muita energia. Projeto para o fim do jogo.'
        ); item = 'mekanism:mekasuit_helmet' }
    ) }
    @{ t = 'Fornalhas'; g = 'Tecnologia'; icone = 'ironfurnaces:iron_furnace'; sub = 'Iron Furnaces: cozinhar mais rápido'; m = @(
        @{ t = 'Fornalha de ferro'; marco = $true; d = @(
            'A &efornalha de ferro&r cozinha mais rápido que a comum. As de ouro, diamante e acima são ainda mais rápidas.'
        ); item = 'ironfurnaces:iron_furnace' }
        @{ t = 'Melhorar sem quebrar'; depois = 'Fornalha de ferro'; d = @(
            'Clique com a &emelhoria&r na fornalha já colocada: ela sobe de nível sem perder o que está dentro.'
        ); item = 'ironfurnaces:upgrade_gold' }
        @{ t = 'Fornalha de diamante'; depois = 'Melhorar sem quebrar'; d = @(
            'Mais rápida ainda. Vale para quem cozinha muito.'
        ); item = 'ironfurnaces:diamond_furnace' }
        @{ t = 'Aumentos'; depois = 'Fornalha de ferro'; d = @(
            'Os &eaumentos&r dão poderes à fornalha: &evelocidade&r, &eeconomia de combustível&r, &ealto-forno&r ou &edefumador&r.'
        ); item = 'ironfurnaces:augment_speed' }
        @{ t = 'Fornalha geradora'; depois = 'Aumentos'; opcional = $true; d = @(
            'O &eaumento gerador&r faz a fornalha queimar combustível para gerar energia. Veja no JEI.'
        ); item = 'ironfurnaces:augment_generator' }
        @{ t = 'Fornalha de netherita'; depois = 'Fornalha de diamante'; opcional = $true; d = @(
            'A mais rápida de todas. Projeto para quem já tem netherita sobrando.'
        ); item = 'ironfurnaces:netherite_furnace' }
    ) }
    @{ t = 'Dimensões'; g = 'Dimensões'; icone = 'minecraft:ender_eye'; sub = 'Outros mundos para visitar'; m = @(
        @{ t = 'Além do mundo normal'; marco = $true; sub = 'Comece por aqui'; d = @(
            'Além do Nether e do End, o pack tem vários &emundos novos&r, cada um com bichos, minérios, chefes e itens próprios.'
            ''
            'Cada mundo tem o seu &ecapítulo&r neste grupo, com o passo a passo do começo ao fim.'
            ''
            '&7Leve comida, cama e uma arma boa. Quem morre em outro mundo volta para a cama, mas os itens ficam lá.'
        ) }
        @{ t = 'Nether'; depois = 'Além do mundo normal'; d = @(
            'Moldura de &eobsidiana&r (4 de largura, 5 de altura) acesa com um &eisqueiro&r.'
            ''
            'Lá tem &aouro, quartzo e netherite&r, e os fortes do Nether.'
        ); dim = 'minecraft:the_nether' }
        @{ t = 'Aether'; depois = 'Além do mundo normal'; sub = 'O céu'; d = @(
            'Moldura de &eglowstone&r no formato do portal do Nether, acesa com um &ebalde de água&r.'
            ''
            'Ilhas flutuantes, três masmorras e chefes. Capítulo &eAether&r.'
        ); dim = 'aether:the_aether' }
        @{ t = 'Twilight Forest'; depois = 'Além do mundo normal'; sub = 'A floresta do crepúsculo'; d = @(
            'Faça uma poça de água &e2x2&r, cerque com &eflores&r e jogue um &ediamante&r dentro (tecla &eQ&r).'
            ''
            'Uma floresta em eterno pôr do sol, cheia de chefes. Capítulo &eTwilight Forest&r.'
        ); dim = 'twilightforest:twilight_forest' }
        @{ t = 'Undergarden'; depois = 'Além do mundo normal'; sub = 'O mundo de baixo'; d = @(
            'Moldura de &etijolos de pedra&r ativada com o &ecatalisador&r do mod.'
            ''
            'Escuro, perigoso e com metais novos. Capítulo &eUndergarden&r.'
        ); dim = 'undergarden:undergarden' }
        @{ t = 'Eternal Starlight'; depois = 'Além do mundo normal'; sub = 'O mundo das estrelas'; d = @(
            'Procure as &eruínas de portal&r pelo mundo e vença o desafio do &eGuardião&r para ganhar o orbe que abre o portal.'
            ''
            'Capítulo &eEternal Starlight&r.'
        ); dim = 'eternal_starlight:starlight' }
        @{ t = 'Espaço'; depois = 'Além do mundo normal'; sub = 'Lua, planetas e foguetes'; d = @(
            'Com o &eAd Astra&r você monta foguetes e voa para a Lua e outros planetas.'
            ''
            'É o mundo mais demorado: precisa de energia, aço e combustível. Capítulo &eEspaço&r.'
        ); dim = 'ad_astra:moon' }
        @{ t = 'Masmorras infinitas'; depois = 'Além do mundo normal'; sub = 'Dimensional Dungeons'; opcional = $true; d = @(
            'Uma dimensão só de &emasmorras&r que se renovam, abertas com uma &echave de portal&r.'
            ''
            'Como montar o portal e preparar a chave: veja o &eguia&r do mod e as receitas no JEI (&eR&r e &eU&r).'
        ); item = 'dimdungeons:item_portal_key' }
        @{ t = 'Entrar nas masmorras'; depois = 'Masmorras infinitas'; opcional = $true; d = @(
            'Cada chave leva a uma masmorra diferente, com baús e inimigos. Saia antes de a chave acabar.'
        ); dim = 'dimdungeons:dungeon_dimension' }
        @{ t = 'End'; depois = 'Nether'; marco = $true; sub = 'O fim do jogo normal'; d = @(
            'Faça &eolhos de ender&r (pérola de ender e pó de blaze do Nether) e jogue para cima: eles voam até a &efortaleza&r com o portal do End.'
            ''
            'Lá mora o &edragão&r. Leve muitos blocos, arco e poções.'
        ); dim = 'minecraft:the_end' }
    ) }
    @{ t = 'Aether'; g = 'Dimensões'; icone = 'aether:ambrosium_shard'; sub = 'Ilhas no céu, três masmorras e um chefe final'; m = @(
        @{ t = 'Chegar no Aether'; marco = $true; d = @(
            'Faça uma moldura de &eglowstone&r no formato do portal do Nether e despeje um &ebalde de água&r dentro.'
            ''
            'Cuidado com a beira das ilhas: cair do Aether leva de volta ao mundo normal, de bem alto. O mod dá um &eparaquedas&r na primeira visita.'
        ); dim = 'aether:the_aether' }
        @{ t = 'Ferramentas do céu'; depois = 'Chegar no Aether'; d = @(
            'Ferramentas normais rendem pouco aqui. Faça as do Aether:'
            ''
            '&eskyroot&r (madeira) e depois &eholystone&r (pedra).'
        ); item = 'aether:holystone_pickaxe' }
        @{ t = 'Ambrosium'; depois = 'Ferramentas do céu'; d = @(
            'Os &efragmentos de ambrosium&r saem de um minério amarelo.'
            ''
            'Servem de &acombustível&r para as máquinas do Aether e &acuram&r um pouco quando comidos.'
        ); item = 'aether:ambrosium_shard'; q = 8 }
        @{ t = 'Zanite'; depois = 'Ferramentas do céu'; d = @(
            'A &egema de zanite&r é o ferro do Aether: ferramentas, armadura e anéis.'
            ''
            'Ferramentas de zanite ficam &amais rápidas&r quanto mais gastas.'
        ); conquista = 'aether:zanite' }
        @{ t = 'Altar'; depois = @('Ambrosium', 'Zanite'); d = @(
            'O &ealtar&r usa ambrosium para &aencantar&r itens do Aether e consertar ferramentas.'
            ''
            'Veja o que ele faz com &eU&r no JEI.'
        ); conquista = 'aether:craft_altar' }
        @{ t = 'Gravitite'; depois = 'Altar'; d = @(
            'O minério rosa de &egravitite&r fica nas ilhas mais altas. Encante no altar para ter a &egravitite encantada&r.'
            ''
            'Com ela vem a melhor armadura do Aether: a &aarmadura de gravitite&r dá pulo alto.'
        ); conquista = 'aether:enchanted_gravitite' }
        @{ t = 'Gelo nos acessórios'; depois = 'Altar'; opcional = $true; d = @(
            'O &econgelador&r usa &eicestone&r para transformar anéis e pingentes em versões de gelo.'
        ); conquista = 'aether:ice_accessory' }
        @{ t = 'Nuvem azul'; depois = 'Chegar no Aether'; opcional = $true; d = @(
            'Pule em uma &enuvem azul&r para ser lançado bem alto. Ótimo para chegar em ilhas.'
        ); conquista = 'aether:blue_aercloud' }
        @{ t = 'Ovo de moa'; depois = 'Nuvem azul'; d = @(
            'As &emoas&r são aves grandes do Aether. Pegue um &eovo&r e choque na &eincubadora&r.'
            ''
            'Uma moa domada vira &amontaria&r. A moa preta voa.'
        ); conquista = 'aether:incubate_moa' }
        @{ t = 'Voar de moa preta'; depois = 'Ovo de moa'; opcional = $true; conquista = 'aether:black_moa'; d = @(
            'Monte em uma &emoa preta&r: ela plana e pula várias vezes no ar.'
        ) }
        @{ t = 'Porco voador'; depois = 'Nuvem azul'; opcional = $true; d = @(
            'Coloque uma &esela&r em um &ephyg&r, o porco com asas, e voe com ele.'
        ); conquista = 'aether:mount_phyg' }
        @{ t = 'Masmorra de bronze'; depois = 'Gravitite'; marco = $true; sub = 'Primeiro chefe'; d = @(
            'A masmorra de bronze fica dentro de uma ilha. O chefe é o &eSlider&r, um bloco que desliza: ele só leva dano de &epicareta&r.'
            ''
            'Saia do caminho quando ele avançar. O baú do fim dá a &echave de bronze&r e itens fortes.'
        ); conquista = 'aether:bronze_dungeon' }
        @{ t = 'Martelo dos deuses'; depois = 'Masmorra de bronze'; opcional = $true; d = @(
            'O &eMartelo de Kingbdogz&r sai da masmorra de bronze e lança raios.'
        ); item = 'aether:hammer_of_kingbdogz' }
        @{ t = 'Masmorra de prata'; depois = 'Masmorra de bronze'; marco = $true; sub = 'A Rainha Valquíria'; d = @(
            'Um templo nas nuvens, guardado por &evalquírias&r. No fim está a &eRainha Valquíria&r.'
            ''
            'O prêmio inclui a &apedra de regeneração&r e equipamento de valquíria.'
        ); conquista = 'aether:silver_dungeon' }
        @{ t = 'Masmorra de ouro'; depois = 'Masmorra de prata'; marco = $true; sub = 'O chefe final do Aether'; d = @(
            'Uma ilha de fogo onde vive o &eEspírito do Sol&r. É o fim do Aether.'
            ''
            'Vencer ele libera &adormir no Aether&r e dá a armadura de fênix.'
        ); conquista = 'aether:gold_dungeon' }
        @{ t = 'Armadura de fênix'; depois = 'Masmorra de ouro'; opcional = $true; d = @(
            'A &earmadura de fênix&r protege do fogo e da lava.'
        ); conquista = 'aether:phoenix_armor' }
        @{ t = 'Deep Aether'; depois = 'Chegar no Aether'; sub = 'Mais Aether'; d = @(
            'O &eDeep Aether&r adiciona biomas, bichos e uma masmorra nova ao Aether.'
            ''
            'Visite todos os biomas do Aether para cumprir esta.'
        ); conquista = 'deep_aether:explore_aether' }
        @{ t = 'Masmorra de latão'; depois = @('Deep Aether', 'Masmorra de bronze'); sub = 'Deep Aether'; d = @(
            'A masmorra de latão do Deep Aether guarda o chefe das tempestades.'
        ); conquista = 'deep_aether:brass_dungeon' }
        @{ t = 'Armadura de stratus'; depois = @('Deep Aether', 'Gravitite'); opcional = $true; d = @(
            'O &elingote de stratus&r do Deep Aether faz uma armadura ainda melhor que a de gravitite.'
        ); conquista = 'deep_aether:stratus_armor' }
    ) }
    @{ t = 'Twilight Forest'; g = 'Dimensões'; icone = 'twilightforest:naga_scale'; sub = 'Chefes em ordem: cada um libera a próxima região'; m = @(
        @{ t = 'Entrar no crepúsculo'; marco = $true; d = @(
            'Faça uma poça de água &e2x2&r, cerque com &eflores&r e jogue um &ediamante&r dentro (tecla &eQ&r). Um raio cria o portal.'
            ''
            'Aqui as regiões têm &ebarreiras&r: tentar pular um chefe dá efeitos ruins. Siga a ordem deste capítulo.'
        ); dim = 'twilightforest:twilight_forest' }
        @{ t = 'Caçar bichos'; depois = 'Entrar no crepúsculo'; d = @(
            'A floresta tem bichos próprios. Cace alguns para ter os materiais do mapa mágico.'
        ); conquista = 'twilightforest:twilight_hunter' }
        @{ t = 'Foco do mapa'; depois = 'Caçar bichos'; d = @(
            'O &efoco de mapa mágico&r usa uma pena de &ecorvo&r, &etorchberries&r e pó de glowstone (receita no JEI).'
        ); conquista = 'twilightforest:magic_map_focus' }
        @{ t = 'Mapa mágico'; depois = 'Foco do mapa'; d = @(
            'O &emapa mágico&r mostra os &abiomas e onde ficam os chefes&r. Fica muito mais fácil achar o próximo.'
        ); conquista = 'twilightforest:magic_map' }
        @{ t = 'Mesa de desmontar'; depois = 'Entrar no crepúsculo'; opcional = $true; d = @(
            'A &emesa de desmontar&r transforma um item de volta nos materiais dele. Cuidado: gasta XP.'
        ); item = 'twilightforest:uncrafting_table' }
        @{ t = 'Equipamento de viajante'; depois = 'Entrar no crepúsculo'; opcional = $true; d = @(
            'Faça uma peça de &earmadura de viajante&r, leve e barata para o começo.'
        ); conquista = 'twilightforest:craft_travellers_gear' }
        @{ t = 'Colinas ocas'; depois = 'Entrar no crepúsculo'; opcional = $true; d = @(
            'As &ecolinas ocas&r têm minério e baús, guardados por bichos. Vença o guardião de uma colina pequena.'
        ); conquista = 'twilightforest:hill1' }
        @{ t = 'Naga'; depois = 'Entrar no crepúsculo'; marco = $true; sub = 'Chefe 1'; d = @(
            'A &eNaga&r é uma cobra gigante que vive em um &epátio de pedra&r. Desvie das investidas e bata nas costas.'
            ''
            'Ela deixa &eescamas de naga&r, que abrem a barreira da torre do Lich.'
        ); conquista = 'twilightforest:progress_naga' }
        @{ t = 'Armadura de naga'; depois = 'Naga'; opcional = $true; d = @(
            'Com as escamas você faz &epeitoral e calças de naga&r.'
        ); conquista = 'twilightforest:naga_armors' }
        @{ t = 'Lich'; depois = 'Naga'; marco = $true; sub = 'Chefe 2'; d = @(
            'O &eLich&r mora no topo de uma torre. Quebre os escudos dele antes de atacar.'
            ''
            'Ele deixa um &ecetro&r. Ter um cetro libera o pântano, a floresta escura e a neve.'
        ); conquista = 'twilightforest:progress_lich' }
        @{ t = 'Quatro cetros'; depois = 'Lich'; opcional = $true; d = @(
            'Junte os &equatro cetros&r do Lich.'
        ); conquista = 'twilightforest:lich_scepters' }
        @{ t = 'Estrogonofe de Meef'; depois = 'Lich'; sub = 'Labirinto do pântano'; d = @(
            'No fundo do &elabirinto&r do pântano vive o &eMinoshroom&r. Ele deixa o &eestrogonofe de Meef&r.'
            ''
            'Comer o estrogonofe protege do calor do &epântano de fogo&r.'
        ); conquista = 'twilightforest:progress_labyrinth' }
        @{ t = 'Hidra'; depois = 'Estrogonofe de Meef'; marco = $true; sub = 'Chefe do pântano de fogo'; d = @(
            'A &eHidra&r tem três cabeças. Leve &eresistência ao fogo&r e acerte as cabeças quando abrirem a boca.'
        ); conquista = 'twilightforest:progress_hydra' }
        @{ t = 'Ferramentas de fogo'; depois = 'Hidra'; opcional = $true; d = @(
            'O sangue da Hidra faz os &elingotes de fogo&r: ferramentas e armadura que queimam o inimigo.'
        ); conquista = 'twilightforest:fiery_set' }
        @{ t = 'Cavaleiros fantasmas'; depois = 'Lich'; sub = 'Floresta escura'; d = @(
            'Na &efloresta escura&r fica a tumba dos &ecavaleiros fantasmas&r. Vença todos.'
            ''
            'Isso libera as máquinas da &etorre de carminita&r.'
        ); conquista = 'twilightforest:progress_knights' }
        @{ t = 'Ur-Ghast'; depois = 'Cavaleiros fantasmas'; marco = $true; sub = 'Chefe da torre escura'; d = @(
            'No topo da &etorre escura&r, mate os ghasts em volta da armadilha e ative ela para puxar o &eUr-Ghast&r do céu.'
        ); conquista = 'twilightforest:progress_ur_ghast' }
        @{ t = 'Yeti alfa'; depois = 'Lich'; sub = 'Floresta de neve'; d = @(
            'Na caverna da floresta de neve vive o &eYeti alfa&r. O pelo dele protege do frio do &eglaciar&r.'
        ); conquista = 'twilightforest:progress_yeti' }
        @{ t = 'Rainha da Neve'; depois = 'Yeti alfa'; marco = $true; sub = 'Palácio da Aurora'; d = @(
            'No topo do &ePalácio da Aurora&r, no glaciar, está a &eRainha da Neve&r.'
        ); conquista = 'twilightforest:progress_glacier' }
        @{ t = 'Planaltos'; depois = @('Hidra', 'Ur-Ghast', 'Rainha da Neve'); marco = $true; sub = 'Fim da chuva ácida'; d = @(
            'Vencer a Hidra, o Ur-Ghast e a Rainha da Neve limpa a chuva ácida e abre os &eplanaltos&r.'
        ); conquista = 'twilightforest:progress_merge' }
        @{ t = 'Pé de feijão'; depois = 'Planaltos'; d = @(
            'Nas cavernas dos trolls ache os &efeijões mágicos&r e plante na terra brilhante embaixo das nuvens. Suba até os &egigantes&r.'
        ); conquista = 'twilightforest:beanstalk' }
        @{ t = 'Lâmpada de cinzas'; depois = 'Pé de feijão'; marco = $true; d = @(
            'Pegue o que o gigante deixa, volte às cavernas dos trolls e ache a &elâmpada de cinzas&r: ela queima as barreiras de espinhos.'
            ''
            '&7Por enquanto este é o fim da história do Twilight. O resto dos planaltos ainda está em construção no mod.'
        ); conquista = 'twilightforest:progress_troll' }
    ) }
    @{ t = 'Undergarden'; g = 'Dimensões'; icone = 'undergarden:catalyst'; sub = 'Um mundo escuro embaixo de tudo'; m = @(
        @{ t = 'Catalisador'; marco = $true; d = @(
            'O &ecatalisador&r abre o portal. Veja a receita com &eR&r no JEI.'
            ''
            'Faça uma moldura de &etijolos de pedra&r no formato do portal do Nether e use o catalisador nela.'
        ); item = 'undergarden:catalyst' }
        @{ t = 'Entrar no Undergarden'; depois = 'Catalisador'; d = @(
            'Um mundo &eescuro&r e cheio de criaturas podres. Leve &etochas&r, comida e armadura.'
        ); dim = 'undergarden:undergarden' }
        @{ t = 'Estilingue'; depois = 'Entrar no Undergarden'; d = @(
            'O &eestilingue&r atira pedrinhas, frutas e outras coisas que você acha por lá.'
        ); item = 'undergarden:slingshot' }
        @{ t = 'Feijões'; depois = 'Entrar no Undergarden'; opcional = $true; d = @(
            'Colha um pé de &efeijões do Undergarden&r: comida para a viagem.'
        ); conquista = 'undergarden:undergarden/underbeans' }
        @{ t = 'Abóbora roxa'; depois = 'Entrar no Undergarden'; opcional = $true; d = @(
            'Plante uma semente de &egloomgourd&r, a abóbora roxa do Undergarden.'
        ); conquista = 'undergarden:undergarden/plant_gloomgourd' }
        @{ t = 'Negociar com Stoneborn'; depois = 'Entrar no Undergarden'; opcional = $true; d = @(
            'Os &eStoneborn&r são gigantes de pedra que negociam. Troque algo com um deles.'
        ); conquista = 'undergarden:undergarden/stoneborn_trade' }
        @{ t = 'Cloggrum'; depois = 'Entrar no Undergarden'; d = @(
            'O &ecloggrum&r é o primeiro metal do Undergarden: ferramentas e armadura.'
        ); item = 'undergarden:cloggrum_ingot'; q = 4 }
        @{ t = 'Froststeel'; depois = 'Cloggrum'; d = @(
            'O &efroststeel&r é um metal gelado: as armas &adeixam o inimigo lento&r.'
        ); item = 'undergarden:froststeel_ingot' }
        @{ t = 'Utherium'; depois = 'Cloggrum'; d = @(
            'O cristal de &eutherium&r faz armas &afortes contra as criaturas podres&r.'
            ''
            '&cCuidado:&r mexer com utherium pode passar a &einfecção utérica&r. Ache um jeito de segurar ela.'
        ); item = 'undergarden:utherium_crystal' }
        @{ t = 'Tocha de fragmento'; depois = 'Utherium'; opcional = $true; d = @(
            'A &etocha de fragmento&r machuca as criaturas podres que chegam perto.'
        ); item = 'undergarden:shard_torch' }
        @{ t = 'Catacumbas'; depois = 'Cloggrum'; d = @(
            'Ache as &ecatacumbas&r: corredores antigos guardados pelos &eesquecidos&r.'
        ); conquista = 'undergarden:undergarden/catacombs' }
        @{ t = 'Guardião esquecido'; depois = 'Catacumbas'; marco = $true; sub = 'Chefe'; d = @(
            'Vença um &eGuardião Esquecido&r. Ele deixa pepitas para o &elingote esquecido&r.'
        ); conquista = 'undergarden:undergarden/kill_forgotten_guardian' }
        @{ t = 'Lingote esquecido'; depois = 'Guardião esquecido'; d = @(
            'O &elingote esquecido&r melhora as ferramentas de cloggrum: as &aferramentas esquecidas&r são as melhores do Undergarden.'
        ); item = 'undergarden:forgotten_ingot' }
        @{ t = 'As profundezas'; depois = 'Lingote esquecido'; marco = $true; d = @(
            'Quebre a barreira de &edreadrock&r no fundo do Undergarden e entre nas &eprofundezas&r.'
        ); conquista = 'undergarden:undergarden/enter_depths' }
        @{ t = 'Infusor'; depois = 'As profundezas'; d = @(
            'O &einfusor&r é a máquina das profundezas. Veja o que ele faz com &eU&r no JEI.'
        ); item = 'undergarden:infuser' }
        @{ t = 'Acampamento dos Denizens'; depois = 'As profundezas'; opcional = $true; d = @(
            'Ache um acampamento dos &eDenizens&r, o povo das profundezas.'
        ); conquista = 'undergarden:undergarden/enter_denizen_camp' }
    ) }
    @{ t = 'Eternal Starlight'; g = 'Dimensões'; icone = 'eternal_starlight:orb_of_prophecy'; sub = 'Um mundo de estrelas, cristais e golens'; m = @(
        @{ t = 'Desafio do Guardião'; marco = $true; d = @(
            'Procure as &eruínas de portal&r pelo mundo normal. Lá está o &eGuardião&r: vença o desafio dele.'
        ); conquista = 'eternal_starlight:challenge_gatekeeper' }
        @{ t = 'Orbe da profecia'; depois = 'Desafio do Guardião'; d = @(
            'O &eorbe da profecia&r é a chave do portal do Eternal Starlight. Veja como usar com &eU&r no JEI.'
        ); item = 'eternal_starlight:orb_of_prophecy' }
        @{ t = 'Céu de mil estrelas'; depois = 'Orbe da profecia'; marco = $true; d = @(
            'Entre no &eEternal Starlight&r: noite eterna, plantas que brilham e bichos estranhos.'
        ); dim = 'eternal_starlight:starlight' }
        @{ t = 'Diamante estrelado'; depois = 'Céu de mil estrelas'; d = @(
            'O &ediamante estrelado&r é um dos minérios desta dimensão.'
        ); item = 'eternal_starlight:starlit_diamond' }
        @{ t = 'Prata profunda'; depois = 'Céu de mil estrelas'; d = @(
            'O &elingote de prata profunda&r (deepsilver) vem do minério do fundo da dimensão.'
        ); item = 'eternal_starlight:deepsilver_ingot' }
        @{ t = 'Chuva de meteoros'; depois = 'Céu de mil estrelas'; d = @(
            'Às vezes caem &emeteoros&r do céu. Assista a uma chuva de meteoros.'
        ); conquista = 'eternal_starlight:witness_meteor_shower' }
        @{ t = 'Presente do céu'; depois = 'Chuva de meteoros'; d = @(
            'O &elingote de aethersent&r vem dos meteoros.'
        ); item = 'eternal_starlight:aethersent_ingot' }
        @{ t = 'Deserto de cristal'; depois = 'Céu de mil estrelas'; opcional = $true; d = @(
            'Visite o bioma &edeserto cristalizado&r.'
        ); conquista = 'eternal_starlight:enter_crystallized_desert' }
        @{ t = 'Abismo'; depois = 'Céu de mil estrelas'; opcional = $true; d = @(
            'Mergulhe no bioma &eabismo&r, o fundo do mar desta dimensão.'
        ); conquista = 'eternal_starlight:enter_abyss' }
        @{ t = 'Olho que procura'; depois = 'Céu de mil estrelas'; d = @(
            'O &eolho que procura&r mostra o caminho para a &eforja dos golens&r.'
        ); item = 'eternal_starlight:seeking_eye' }
        @{ t = 'Forja dos golens'; depois = 'Olho que procura'; d = @(
            'Entre na &eforja dos golens&r, a estrutura do primeiro chefe.'
        ); conquista = 'eternal_starlight:enter_golem_forge' }
        @{ t = 'Golem Estelar'; depois = 'Forja dos golens'; marco = $true; sub = 'Chefe'; d = @(
            'O &eGolem Estelar&r se protege com &eblocos de energia&r. Desligue os blocos para ele ficar vulnerável.'
            ''
            'Ele deixa o &elingote de aço de golem&r.'
        ); conquista = 'eternal_starlight:kill_golem' }
        @{ t = 'Monstruosidade Lunar'; depois = 'Golem Estelar'; marco = $true; sub = 'Chefe'; d = @(
            'A &eMonstruosidade Lunar&r só leva dano quando está &epegando fogo&r.'
            ''
            'Ela libera a &aarmadura de unrealium&r e a lança crescente.'
        ); conquista = 'eternal_starlight:kill_lunar_monstrosity' }
        @{ t = 'Armadura de unrealium'; depois = 'Monstruosidade Lunar'; opcional = $true; d = @(
            'Monte a armadura completa de &eunrealium&r.'
        ); conquista = 'eternal_starlight:full_unrealium_armor' }
        @{ t = 'Explorador estelar'; depois = 'Céu de mil estrelas'; opcional = $true; d = @(
            'Visite &etodos os biomas&r do Eternal Starlight.'
        ); conquista = 'eternal_starlight:all_starlight_biomes' }
    ) }
    @{ t = 'Espaço'; g = 'Dimensões'; icone = 'ad_astra:tier_1_rocket'; sub = 'Foguetes, oxigênio e outros planetas'; m = @(
        @{ t = 'Gerador a carvão'; marco = $true; sub = 'Energia'; d = @(
            'As máquinas do &eAd Astra&r gastam energia. O começo mais simples é o &egerador a carvão&r.'
            ''
            'Ligue as máquinas com cabos e veja as receitas com &eR&r no JEI.'
        ); item = 'ad_astra:coal_generator' }
        @{ t = 'Compressor'; depois = 'Gerador a carvão'; d = @(
            'O &ecompressor&r transforma lingotes em &echapas&r, usadas em quase tudo do foguete.'
        ); item = 'ad_astra:compressor' }
        @{ t = 'Aço'; depois = 'Compressor'; d = @(
            'O &ealto-forno etriônico&r usa energia para fazer &elingote de aço&r.'
        ); item = 'ad_astra:steel_ingot'; q = 8 }
        @{ t = 'Bancada da NASA'; depois = 'Aço'; marco = $true; d = @(
            'A &ebancada da NASA&r monta os foguetes.'
        ); item = 'ad_astra:nasa_workbench' }
        @{ t = 'Petróleo'; depois = 'Gerador a carvão'; d = @(
            'Encha um balde com &epetróleo&r: ele aparece em poças no oceano.'
        ); item = 'ad_astra:oil_bucket' }
        @{ t = 'Combustível'; depois = 'Petróleo'; d = @(
            'A &erefinaria&r transforma petróleo em &ecombustível de foguete&r.'
        ); item = 'ad_astra:fuel_bucket' }
        @{ t = 'Traje espacial'; depois = 'Aço'; d = @(
            'Fora da Terra não tem ar. Faça o traje completo: &ecapacete, traje, calças e botas espaciais&r.'
            ''
            'O &ecarregador de oxigênio&r enche o traje.'
        ); item = 'ad_astra:space_suit' }
        @{ t = 'Carregador de oxigênio'; depois = 'Traje espacial'; d = @(
            'Encha o tanque do traje no &ecarregador de oxigênio&r antes de cada viagem.'
        ); item = 'ad_astra:oxygen_loader' }
        @{ t = 'Foguete nível 1'; depois = @('Bancada da NASA', 'Combustível', 'Carregador de oxigênio'); marco = $true; d = @(
            'Monte o &efoguete nível 1&r, ponha em uma &eplataforma de lançamento&r e abasteça com combustível.'
            ''
            'Entre e aperte espaço para decolar. Ele vai até a &eLua&r.'
        ); item = 'ad_astra:tier_1_rocket' }
        @{ t = 'Lua'; depois = 'Foguete nível 1'; marco = $true; sub = 'Um pequeno passo'; d = @(
            'Chegue na &eLua&r. A gravidade é baixa: os pulos ficam enormes.'
            ''
            'Lá tem &edesh&r, o metal do próximo foguete.'
        ); dim = 'ad_astra:moon' }
        @{ t = 'Vila lunar'; depois = 'Lua'; opcional = $true; d = @(
            'Os &elunarianos&r têm vilas na Lua e trocam itens como aldeões.'
        ); estrutura = 'ad_astra:lunarian_village' }
        @{ t = 'Painel solar'; depois = 'Lua'; opcional = $true; d = @(
            'O &epainel solar&r gera energia de graça com a luz do Sol.'
        ); item = 'ad_astra:solar_panel' }
        @{ t = 'Distribuidor de oxigênio'; depois = 'Painel solar'; opcional = $true; d = @(
            'O &edistribuidor de oxigênio&r enche uma sala fechada de ar: dá para morar em outro planeta sem traje.'
        ); item = 'ad_astra:oxygen_distributor' }
        @{ t = 'Desh'; depois = 'Lua'; d = @(
            'Com &edesh&r você faz o &efoguete nível 2&r.'
        ); item = 'ad_astra:desh_ingot' }
        @{ t = 'Marte'; depois = 'Desh'; marco = $true; d = @(
            'O foguete nível 2 leva até &eMarte&r. Lá tem &eostrum&r, o metal do nível 3.'
        ); dim = 'ad_astra:mars' }
        @{ t = 'Traje de netherite'; depois = 'Marte'; d = @(
            'O &etraje espacial de netherite&r aguenta calor extremo. É preciso para Vênus e Mercúrio.'
        ); item = 'ad_astra:netherite_space_suit' }
        @{ t = 'Foguete nível 3'; depois = 'Traje de netherite'; d = @(
            'Com &eostrum&r monte o &efoguete nível 3&r.'
        ); item = 'ad_astra:tier_3_rocket' }
        @{ t = 'Vênus'; depois = 'Foguete nível 3'; d = @(
            'Vênus é &equente e ácida&r. Lá tem &ecalorite&r, o metal do nível 4.'
        ); dim = 'ad_astra:venus' }
        @{ t = 'Mercúrio'; depois = 'Foguete nível 3'; opcional = $true; d = @(
            'O planeta mais perto do Sol.'
        ); dim = 'ad_astra:mercury' }
        @{ t = 'Traje a jato'; depois = 'Vênus'; opcional = $true; d = @(
            'O &etraje a jato&r empurra você para a frente com força.'
        ); item = 'ad_astra:jet_suit' }
        @{ t = 'Foguete nível 4'; depois = 'Vênus'; d = @(
            'Com &ecalorite&r monte o &efoguete nível 4&r, o mais forte.'
        ); item = 'ad_astra:tier_4_rocket' }
        @{ t = 'Glacio'; depois = 'Foguete nível 4'; marco = $true; sub = 'Outro sistema solar'; d = @(
            'O foguete nível 4 chega em &eGlacio&r, o planeta gelado de outro sistema solar.'
        ); dim = 'ad_astra:glacio' }
    ) }
    @{ t = 'Utilidades'; g = 'Começo'; icone = 'justhammers:iron_hammer'; sub = 'Ferramentas e truques que facilitam a vida'; m = @(
        @{ t = 'Minerar em bloco'; mod = @('cf:386134'); marco = $true; sub = 'FTB Ultimine'; d = @(
            'Segure a &etecla ao lado do 1&r e quebre um bloco: todos os blocos iguais grudados vêm junto (até 64). Funciona com minério, tronco e o que mais quiser.'
            ''
            'Um contorno mostra o que vai quebrar. Com a tecla segurada, &erole o mouse&r para trocar o formato (veio, túnel, área).'
            ''
            '&7Clique em Concluir quando tiver testado.'
        ) }
        @{ t = 'Martelo'; depois = 'Minerar em bloco'; sub = 'Just Hammers'; d = @(
            'O &emartelo&r quebra uma área de &e3x3&r de uma vez. Ótimo para túneis e minas.'
            ''
            'Tem martelos de pedra a netherite.'
        ); item = 'justhammers:iron_hammer' }
        @{ t = 'Fornalha rápida'; depois = 'Minerar em bloco'; sub = 'Iron Furnaces'; d = @(
            'Fornalhas de &eferro, ouro, diamante&r e mais: cozinham e derretem &amuito mais rápido&r que a comum.'
            ''
            'Dá para melhorar uma fornalha já colocada com os &eupgrades&r do mod, sem perder o que está dentro.'
        ); item = 'ironfurnaces:iron_furnace'; p = 'minecraft:coal'; n = 16 }
        @{ t = 'Altura dos minérios'; mod = @('just-enough-resources-jer'); depois = 'Minerar em bloco'; sub = 'Just Enough Resources'; d = @(
            'No JEI, aperte &eU&r em cima de um minério: uma aba mostra &aem que altura ele aparece mais&r.'
            ''
            'Em cima de um bicho ou monstro, mostra o que ele deixa cair.'
        ) }
        @{ t = 'Encantamentos explicados'; mod = @('enchantment-descriptions'); depois = 'Minerar em bloco'; sub = 'Enchantment Descriptions'; d = @(
            'Passe o mouse em um livro encantado: aparece o que &ecada encantamento faz&r.'
            ''
            'A bigorna não tem mais o limite de "Caro demais" (&eEasy Anvils&r).'
        ) }
        @{ t = 'Saco de dormir'; depois = 'Minerar em bloco'; sub = 'Comforts'; d = @(
            'O &esaco de dormir&r passa a noite sem mudar o seu ponto de renascimento. Perfeito para viagens.'
            ''
            'A &erede&r faz o contrário: dorme de dia.'
        ); item = 'comforts:sleeping_bag_white' }
        @{ t = 'Zoom'; mod = @('ok-zoomer'); depois = 'Minerar em bloco'; sub = 'Ok Zoomer'; d = @(
            'Segure &eC&r para dar zoom. Role o mouse para ajustar.'
        ) }
        @{ t = 'Tocha na mão'; depois = 'Minerar em bloco'; sub = 'Dynamic Torches'; d = @(
            'Segurar uma &etocha&r ou lanterna ilumina em volta de você. Ótimo para explorar caverna sem colocar tocha em todo lugar.'
        ); item = 'minecraft:torch'; q = 16 }
        @{ t = 'Baús de saque'; depois = 'Minerar em bloco'; sub = 'Lootr'; d = @(
            'Baús de estruturas (templos, masmorras, vilas) têm &asaque próprio para cada jogador&r. Todo mundo pode abrir o mesmo baú e ganhar itens.'
            ''
            'Esses baús têm um brilho diferente.'
        ) }
        @{ t = 'Trocar ofertas do aldeão'; mod = @('trade-cycling'); depois = 'Minerar em bloco'; opcional = $true; sub = 'Trade Cycling'; d = @(
            'Aldeão com ofertas ruins? Na tela de troca tem um &ebotão&r que sorteia ofertas novas, enquanto ele ainda não negociou com ninguém.'
        ) }
        @{ t = 'Netherite melhor'; depois = 'Martelo'; sub = 'Advanced Netherite'; d = @(
            'Depois da netherite ainda tem mais: lingotes de netherite com ferro, ouro, esmeralda e diamante. Cada um dá ferramentas e armaduras com bônus próprios.'
            ''
            'Veja as receitas com &eU&r em cima do lingote de netherite.'
        ); item = 'advancednetherite:netherite_diamond_ingot' }
        @{ t = 'Construção gigante'; depois = 'Minerar em bloco'; opcional = $true; sub = 'Building Gadgets'; d = @(
            'O &egadget de construção&r coloca vários blocos de uma vez, e o de cópia copia e cola construções inteiras.'
            ''
            'Eles gastam energia (FE). Veja com &eU&r em cima deles como carregar.'
        ); item = 'buildinggadgets2:gadget_building' }
        @{ t = 'Portal gun'; depois = 'Minerar em bloco'; opcional = $true; sub = 'Aperture Innovations'; d = @(
            'A &eportal gun&r do jogo Portal: atire um portal &bazul&r e um &6laranja&r e atravesse de um para o outro.'
        ); item = 'aperture_innovations:portal_gun' }
        @{ t = 'Fumar'; mod = @('cf:1410391', 'cf:896915', 'ciggycraft'); depois = 'Minerar em bloco'; opcional = $true; sub = 'Smoking Pipe e Tobacconist'; d = @(
            'Plante tabaco, seque e fume no cachimbo. É só diversão: dá um pouco de experiência.'
        ) }
    ) }
    @{ t = 'Create: energia'; g = 'Tecnologia'; icone = 'createaddition:electric_motor'; sub = 'Create Crafts & Additions: eletricidade'; m = @(
        @{ t = 'Giro vira energia'; marco = $true; sub = 'Alternador'; d = @(
            'O &ealternador&r recebe giro do Create e faz &eenergia elétrica&r (FE).'
            'É a energia que as máquinas do Mekanism e de outros mods usam.'
        ); item = 'createaddition:alternator' }
        @{ t = 'Laminador'; depois = 'Giro vira energia'; d = @(
            'O &elaminador&r gira e transforma lingotes em &ehastes&r e chapas em &efios&r.'
        ); item = 'createaddition:rolling_mill' }
        @{ t = 'Fio de cobre'; depois = 'Laminador'; d = @(
            'O &efio de cobre&r enrolado no &ecarretel&r liga os conectores e leva energia.'
        ); item = 'createaddition:copper_spool'; q = 2 }
        @{ t = 'Conectores'; depois = 'Fio de cobre'; d = @(
            'Ponha um &econector&r em cada máquina. Clique com o carretel em um e depois no outro: o fio liga os dois.'
            'O &econector grande&r leva mais energia e mais longe.'
        ); item = 'createaddition:connector'; q = 4 }
        @{ t = 'Acumulador'; depois = 'Conectores'; d = @(
            'O &eacumulador&r é uma bateria grande. Guarda energia para a noite e para quando o giro para.'
        ); item = 'createaddition:modular_accumulator' }
        @{ t = 'Motor elétrico'; depois = 'Conectores'; marco = $true; d = @(
            'O &emotor elétrico&r faz o contrário: energia vira giro. Dá para escolher a velocidade.'
            'Assim uma fábrica longe recebe força só por fio.'
        ); item = 'createaddition:electric_motor' }
        @{ t = 'Bobina de Tesla'; depois = 'Acumulador'; opcional = $true; d = @(
            'A &ebobina de Tesla&r carrega itens com energia que passam embaixo dela.'
        ); item = 'createaddition:tesla_coil' }
        @{ t = 'Biocombustível'; depois = 'Giro vira energia'; opcional = $true; d = @(
            'Sementes na prensa dão &eóleo de sementes&r; misturado vira &ebiocombustível&r.'
            'Com o &equeimador com canudo&r, o queimador de blaze é alimentado por líquido. Veja tudo no JEI.'
        ); item = 'createaddition:straw' }
        @{ t = 'Electrum'; depois = 'Laminador'; opcional = $true; d = @(
            'Ouro e prata no misturador viram &eelectrum&r, um fio melhor para levar energia.'
        ); item = 'createaddition:electrum_ingot'; q = 4 }
    ) }
    @{ t = 'Create: addons'; g = 'Tecnologia'; icone = 'create_jetpack:jetpack'; sub = 'Mais máquinas, encantos e equipamentos'; m = @(
        @{ t = 'Jetpack'; marco = $true; sub = 'Create Jetpack'; d = @(
            'O &ejetpack&r usa o ar do tanque de ar para &avoar&r. Feito a partir do tanque de ar de cobre.'
            'Encha de ar como o tanque normal. A versão de netherita aguenta mais.'
        ); item = 'create_jetpack:jetpack'; p = 'minecraft:copper_ingot'; n = 8 }
        @{ t = 'Capacete com óculos'; sub = 'Create Goggles'; depois = 'Jetpack'; d = @(
            'Junte os &eóculos de engenheiro&r com um capacete e use os dois de uma vez.'
            'Os &etanques de ar&r de ferro, ouro e diamante protegem como peitoral.'
        ); item = 'creategoggles:goggle_iron_helmet' }
        @{ t = 'Exoesqueleto'; sub = 'Create Stuff Additions'; depois = 'Jetpack'; d = @(
            'O Create Stuff Additions traz &ejetpacks&r de outros materiais, &eexoesqueleto&r (pula e corre mais), broca e ferramentas.'
        ); item = 'create_sa:andesite_exoskeleton_chestplate' }
        @{ t = 'Broca portátil'; depois = 'Exoesqueleto'; opcional = $true; d = @(
            'A &ebroca portátil&r quebra blocos rápido usando ar ou combustível.'
        ); item = 'create_sa:portable_drill' }
        @{ t = 'Gancho'; depois = 'Exoesqueleto'; opcional = $true; d = @(
            'O &egancho&r puxa você até onde ele prende. Ótimo para escalar.'
        ); item = 'create_sa:grapplin_whisk' }
        @{ t = 'Encantar com máquinas'; marco = $true; sub = 'Create Enchantment Industry'; solta = $true; d = @(
            'O &eencantador de blaze&r encanta itens sozinho, usando &eXP líquido&r.'
            'Veja no JEI e no Ponder (&eW&r) como juntar XP líquido e montar a linha.'
        ); item = 'create_enchantment_industry:blaze_enchanter' }
        @{ t = 'Esmeril mecânico'; depois = 'Encantar com máquinas'; d = @(
            'O &eesmeril mecânico&r tira encantos de itens e devolve o XP.'
        ); item = 'create_enchantment_industry:mechanical_grindstone' }
        @{ t = 'Impressora'; depois = 'Encantar com máquinas'; opcional = $true; d = @(
            'A &eimpressora&r copia livros encantados e livros escritos usando XP líquido.'
        ); item = 'create_enchantment_industry:printer' }
        @{ t = 'Lanterna de XP'; depois = 'Encantar com máquinas'; opcional = $true; d = @(
            'A &elanterna de experiência&r ilumina e guarda XP. Bonita na base.'
        ); item = 'create_enchantment_industry:experience_lantern' }
        @{ t = 'Minério infinito'; marco = $true; sub = 'Create Ore Excavation'; solta = $true; d = @(
            'Há &everos de minério&r escondidos embaixo dos chunks. O &elocalizador de veios&r diz o que tem no chunk.'
        ); item = 'createoreexcavation:vein_finder' }
        @{ t = 'Perfuratriz'; depois = 'Minério infinito'; d = @(
            'A &eperfuratriz&r em cima de um veio, com uma &ebroca&r e giro, tira minério &asem acabar&r.'
            'Veja no Ponder (&eW&r) como montar.'
        ); item = 'createoreexcavation:drilling_machine'; p = 'createoreexcavation:drill'; n = 1 }
        @{ t = 'Atlas de veios'; depois = 'Minério infinito'; opcional = $true; d = @(
            'O &eatlas&r guarda os veios que você já achou.'
        ); item = 'createoreexcavation:vein_atlas' }
        @{ t = 'Bateria cinética'; sub = 'Create Connected'; solta = $true; d = @(
            'O Create Connected traz peças que faltam: &ebateria cinética&r (guarda giro), freio, embreagens e caixas novas.'
        ); item = 'create_connected:kinetic_battery' }
        @{ t = 'Silo de itens'; depois = 'Bateria cinética'; opcional = $true; d = @(
            'O &esilo&r guarda muito item, empilhando em altura. O &evaso de fluido&r faz o mesmo com líquidos.'
        ); item = 'create_connected:item_silo' }
        @{ t = 'Caixa de 6 lados'; depois = 'Bateria cinética'; opcional = $true; d = @(
            'A &ecaixa de engrenagens de 6 lados&r leva o giro para todas as direções.'
        ); item = 'create_connected:six_way_gearbox' }
        @{ t = 'Cortadora'; sub = 'Slice and Dice'; solta = $true; d = @(
            'A &ecortadora&r segura uma faca e corta comida no depósito: as receitas da tábua do Farmer''s Delight sozinhas.'
            'O &eregador&r molha a plantação e faz crescer mais rápido.'
        ); item = 'sliceanddice:slicer' }
        @{ t = 'Cozinha automática'; mod = @('create-central-kitchen'); sub = 'Create Central Kitchen'; depois = 'Cortadora'; opcional = $true; d = @(
            'Com o Central Kitchen, &ebicos&r, &ebraços&r e &edeployers&r cozinham as receitas da panela e da frigideira dos mods de comida.'
            '&7Clique em Concluir quando montar algo.'
        ) }
        @{ t = 'Velas especiais'; sub = 'Dreams and Desires'; solta = $true; d = @(
            'As &evelas catalisadoras&r dão processos novos ao vento do ventilador: congelar, lixar, ferver e mais.'
            'Veja no Ponder (&eW&r).'
        ); item = 'dndesires:freezing_sail' }
        @{ t = 'Prensa hidráulica'; depois = 'Velas especiais'; opcional = $true; d = @(
            'A &eprensa hidráulica&r e o &eventilador industrial&r são versões mais fortes das máquinas do Create.'
        ); item = 'dndesires:hydraulic_press' }
        @{ t = 'Milk-shake'; depois = 'Velas especiais'; opcional = $true; d = @(
            'O Dreams and Desires tem &emilk-shakes&r. Misture no misturador e encha com o bico.'
        ); item = 'dndesires:vanilla_milkshake' }
        @{ t = 'Blocos que copiam'; sub = 'Copycats+'; solta = $true; d = @(
            'Os blocos &ecopycat&r copiam a textura de qualquer bloco: clique neles com o bloco na mão.'
            'Degraus, rampas, portas e cercas de qualquer material.'
        ); item = 'copycats:copycat_slope'; q = 4 }
        @{ t = 'Decoração industrial'; sub = 'Create Deco'; depois = 'Blocos que copiam'; d = @(
            'Passarelas, grades, janelas e chapas no estilo do Create. Veja tudo no JEI.'
        ); item = 'createdeco:andesite_catwalk'; q = 8 }
        @{ t = 'Cadeiras'; sub = 'Interiors'; depois = 'Blocos que copiam'; opcional = $true; d = @(
            'Cadeiras e sofás no estilo do Create. Funcionam também dentro de trens.'
        ); item = 'interiors:kelp_chair' }
        @{ t = 'Navegador'; sub = 'Create Railways Navigator'; solta = $true; opcional = $true; d = @(
            'O &enavegador&r acha a rota de trem entre duas estações, com horários.'
        ); item = 'createrailwaysnavigator:navigator' }
        @{ t = 'Terminal no trem'; mod = @('create-contraption-terminals'); sub = 'Contraption Terminals'; depois = 'Navegador'; opcional = $true; d = @(
            'O terminal do &eTom''s Storage&r funciona dentro de trens e máquinas que andam.'
            '&7Clique em Concluir quando testar.'
        ) }
        @{ t = 'Dirigíveis'; mod = @('create-aeronautics'); sub = 'Create Aeronautics'; solta = $true; marco = $true; d = @(
            'Com o Aeronautics, construções do Create &avoam&r: dirigíveis, aviões, barcos e carros.'
            'Veja os blocos novos no JEI e o Ponder (&eW&r) de cada um.'
            '&7Clique em Concluir quando montar seu primeiro veículo.'
        ) }
    ) }
    @{ t = 'Explorar'; g = 'Aventura'; icone = 'naturescompass:naturescompass'; sub = 'Ferramentas para achar tudo pelo mundo'; m = @(
        @{ t = 'Pé na estrada'; marco = $true; sub = 'Comece por aqui'; d = @(
            'O mundo do Minezada tem &ecentenas de estruturas&r novas e quase &e200 biomas&r. Os capítulos deste grupo mostram o que procurar.'
            ''
            'Os &ebaús de estruturas&r são de cada jogador (&eLootr&r): quem chega depois também ganha o tesouro.'
            ''
            '&7Leve cama, comida, tochas e blocos. Marque o caminho no mapa (tecla &fM&7).'
        ) }
        @{ t = 'Bússola de biomas'; depois = 'Pé na estrada'; d = @(
            'A &eNature''s Compass&r aponta para o bioma que você escolher.'
            ''
            'Clique com o botão direito para abrir a lista, escolha o bioma e siga a agulha.'
        ); item = 'naturescompass:naturescompass' }
        @{ t = 'Bússola de estruturas'; depois = 'Pé na estrada'; d = @(
            'A &eExplorer''s Compass&r faz o mesmo com &eestruturas&r: vilas, templos, masmorras e castelos.'
        ); item = 'explorerscompass:explorerscompass' }
        @{ t = 'Atlas'; depois = 'Pé na estrada'; opcional = $true; d = @(
            'O &eMap Atlases&r junta mapas de papel em um livro. Na mão secundária vira um mapa que se desenha sozinho.'
        ); item = 'map_atlases:atlas' }
        @{ t = 'Pergaminho de volta'; depois = 'Pé na estrada'; d = @(
            'O &epergaminho de retorno&r leva de volta para a última waystone ou cama. Bom para voltar de uma viagem longa.'
        ); item = 'waystones:return_scroll' }
    ) }
    @{ t = 'Masmorras e tesouros'; g = 'Aventura'; icone = 'artifacts:cloud_in_a_bottle'; sub = 'Masmorras, templos e minas reformulados'; m = @(
        @{ t = 'Baú só seu'; marco = $true; d = @(
            'Abra um baú de estrutura. Com o &eLootr&r cada jogador tem o próprio tesouro em cada baú.'
            ''
            'Baú do Lootr tem um contorno diferente. Não quebre: é só abrir.'
        ); conquista = 'lootr:1chest' }
        @{ t = 'Caçador de baús'; depois = 'Baú só seu'; opcional = $true; d = @(
            'Abra &e25 baús&r de estruturas diferentes.'
        ); conquista = 'lootr:25loot' }
        @{ t = 'Masmorra'; depois = 'Baú só seu'; d = @(
            'As masmorras pequenas (YUNG''s Better Dungeons) mudam conforme o bicho: zumbi, esqueleto ou aranha.'
            ''
            'Quebre o &egerador de monstros&r ou ponha tochas em volta para ele parar.'
        ); conquista = 'betterdungeons:small_dungeon' }
        @{ t = 'Todas as masmorras'; depois = 'Masmorra'; opcional = $true; d = @(
            'Visite todos os tipos de masmorra do YUNG''s Better Dungeons.'
        ); conquista = 'betterdungeons:all_dungeons' }
        @{ t = 'Mina abandonada'; depois = 'Baú só seu'; d = @(
            'As minas abandonadas mudam com o bioma: de gelo, de deserto, de selva, de cogumelo.'
            ''
            'Têm trilhos, carrinhos com baú e elevadores.'
        ); estrutura = 'bettermineshafts:mineshaft_oak' }
        @{ t = 'Templo do deserto'; depois = 'Baú só seu'; d = @(
            'O templo do deserto virou um &elabirinto com armadilhas&r e uma câmara do tesouro no fim.'
            ''
            '&cOlhe onde pisa.&r'
        ); conquista = 'betterdeserttemples:temple_clear' }
        @{ t = 'Templo da selva'; depois = 'Baú só seu'; d = @(
            'O templo da selva ficou maior, com quebra-cabeças.'
        ); estrutura = 'betterjungletemples:jungle_temple' }
        @{ t = 'Cabana da bruxa'; depois = 'Baú só seu'; opcional = $true; d = @(
            'Cada tipo de pântano tem a sua cabana de bruxa.'
        ); estrutura = 'betterwitchhuts:witch_hut' }
        @{ t = 'Taverna'; depois = 'Baú só seu'; d = @(
            'O &eDungeons and Taverns&r espalha &etavernas&r pelo mundo. Os aldeões de lá vendem &emapas de tesouro&r.'
        ); conquista = 'nova_structures:adventure/find_tavern' }
        @{ t = 'Artefato'; depois = 'Baú só seu'; marco = $true; d = @(
            'Os &eArtifacts&r são itens mágicos achados em baús de estruturas: &enuvem na garrafa&r (pulo duplo), &etênis de corrida&r, &eamuleto de fogo&r e muito mais.'
            ''
            'Eles vão nos espaços de acessório do inventário.'
        ); item = 'artifacts:cloud_in_a_bottle' }
        @{ t = 'Baú que morde'; depois = 'Artefato'; opcional = $true; d = @(
            'Às vezes um baú é um &emímico&r. Mate um: ele deixa artefatos.'
        ); conquista = 'artifacts:chest_slayer' }
    ) }
    @{ t = 'Grandes estruturas'; g = 'Aventura'; icone = 'minecraft:netherite_sword'; sub = 'When Dungeons Arise: castelos, navios e torres gigantes'; m = @(
        @{ t = 'Estruturas gigantes'; marco = $true; d = @(
            'O &eWhen Dungeons Arise&r espalha construções enormes, cheias de inimigos e baús.'
            ''
            'Vá com &earmadura de ferro ou melhor&r, comida e amigos. A bússola de estruturas acha cada uma.'
        ) }
        @{ t = 'Moinho dos illagers'; depois = 'Estruturas gigantes'; d = @(
            'Um &emoinho dos illagers&r, guardado por saqueadores.'
        ); estrutura = 'dungeons_arise:illager_windmill' }
        @{ t = 'Forte illager'; depois = 'Moinho dos illagers'; d = @(
            'Um &eforte&r inteiro de illagers.'
        ); estrutura = 'dungeons_arise:illager_fort' }
        @{ t = 'Galé illager'; depois = 'Forte illager'; opcional = $true; d = @(
            'Os illagers também navegam: ache uma &egalé&r no mar.'
        ); estrutura = 'dungeons_arise:illager_galley' }
        @{ t = 'Vila dos bandidos'; depois = 'Estruturas gigantes'; d = @(
            'Uma &evila de bandidos&r no deserto.'
        ); estrutura = 'dungeons_arise:bandit_village' }
        @{ t = 'Palácio Shiraz'; depois = 'Vila dos bandidos'; d = @(
            'Um &epalácio&r enorme no deserto.'
        ); estrutura = 'dungeons_arise:shiraz_palace' }
        @{ t = 'Coliseu'; depois = 'Estruturas gigantes'; d = @(
            'Uma &earena&r gigante, cheia de inimigos.'
        ); estrutura = 'dungeons_arise:coliseum' }
        @{ t = 'Templo infestado'; depois = 'Coliseu'; d = @(
            'Um templo tomado por &etraças&r.'
        ); estrutura = 'dungeons_arise:infested_temple' }
        @{ t = 'Navio pirata fantasma'; depois = 'Estruturas gigantes'; d = @(
            'Um &enavio pirata morto-vivo&r no mar.'
        ); estrutura = 'dungeons_arise:undead_pirate_ship' }
        @{ t = 'Farol'; depois = 'Navio pirata fantasma'; opcional = $true; d = @(
            'Um &efarol&r na beira do mar.'
        ); estrutura = 'dungeons_arise:lighthouse' }
        @{ t = 'Dirigível'; depois = 'Estruturas gigantes'; d = @(
            'Um &edirigível&r voando alto no céu.'
        ); estrutura = 'dungeons_arise:small_blimp' }
        @{ t = 'Conquistador celeste'; depois = 'Dirigível'; d = @(
            'O &eHeavenly Conqueror&r é um navio voador gigante.'
        ); estrutura = 'dungeons_arise:heavenly_conqueror' }
        @{ t = 'Minas profundas'; depois = 'Estruturas gigantes'; d = @(
            'Um &ecomplexo de mineração&r abandonado.'
        ); estrutura = 'dungeons_arise:mining_system' }
        @{ t = 'Vila dos cogumelos'; depois = 'Estruturas gigantes'; opcional = $true; d = @(
            'Uma &evila de cogumelos&r gigantes.'
        ); estrutura = 'dungeons_arise:mushroom_village' }
        @{ t = 'Monastério'; depois = 'Estruturas gigantes'; opcional = $true; d = @(
            'Um &emonastério&r nas montanhas.'
        ); estrutura = 'dungeons_arise:monastery' }
        @{ t = 'Torres espinhosas'; depois = 'Templo infestado'; d = @(
            'As &eThornborn Towers&r ficam no mar, cheias de espinhos.'
        ); estrutura = 'dungeons_arise:thornborn_towers' }
        @{ t = 'Asilo da praga'; depois = @('Templo infestado', 'Minas profundas'); marco = $true; sub = 'O lugar mais assustador do pack'; d = @(
            'O &eAsilo da Praga&r é a estrutura mais perigosa. Vá bem preparado.'
        ); estrutura = 'dungeons_arise:plague_asylum' }
    ) }
    @{ t = 'Pelo mundo'; g = 'Aventura'; icone = 'minecraft:filled_map'; sub = 'Vilas, ruínas, torres e acampamentos'; m = @(
        @{ t = 'Viajante'; marco = $true; d = @(
            'Vários mods espalham &eestruturas pequenas&r pelo mundo: ruínas, torres, acampamentos, pontes e vilas novas.'
            ''
            'Quase todas têm baú. Vale parar para olhar.'
        ) }
        @{ t = 'Vila nova'; depois = 'Viajante'; d = @(
            'O &eTowns and Towers&r traz vilas de estilos diferentes. Ache uma &evila sueca&r.'
        ); estrutura = 'towns_and_towers:exclusives/village_swedish' }
        @{ t = 'Vila mediterrânea'; depois = 'Vila nova'; opcional = $true; d = @(
            'Outra vila do Towns and Towers, com casas brancas.'
        ); estrutura = 'towns_and_towers:exclusives/village_mediterranean' }
        @{ t = 'Vila dos sapos'; depois = 'Viajante'; opcional = $true; d = @(
            'O &eRibbits&r tem vilas de sapos no pântano. Eles negociam.'
        ); estrutura = 'ribbits:ribbit_village' }
        @{ t = 'Torre do mago'; depois = 'Viajante'; d = @(
            'O &eStructory Towers&r espalha torres por bioma. Ache a &etorre do mago&r.'
        ); estrutura = 'structory_towers:wizard_tower' }
        @{ t = 'Mansão velha'; depois = 'Viajante'; d = @(
            'O &eStructory&r tem ruínas com história. Ache a &emansão velha&r.'
        ); estrutura = 'structory:old_manor' }
        @{ t = 'Cemitério'; depois = 'Mansão velha'; opcional = $true; d = @(
            'Um &ecemitério&r abandonado do Structory.'
        ); estrutura = 'structory:graveyard' }
        @{ t = 'Ruínas antigas'; depois = 'Viajante'; d = @(
            'O &ePhilips Ruins&r espalha ruínas com tesouros. Ache a &ecripta antiga&r.'
        ); estrutura = 'philipsruins:ancient_crypt' }
        @{ t = 'Cidade das almas perdidas'; depois = 'Ruínas antigas'; opcional = $true; d = @(
            'A &eLost Soul City&r é uma das maiores ruínas do Philips Ruins.'
        ); estrutura = 'philipsruins:lost_soul_city' }
        @{ t = 'Acampamento'; depois = 'Viajante'; d = @(
            'O &eExplorify&r tem acampamentos, mausoléus e torres de vigia. Ache um &eacampamento&r.'
        ); estrutura = 'explorify:campsite' }
        @{ t = 'Mausoléu'; depois = 'Acampamento'; opcional = $true; d = @(
            'Um &emausoléu&r do Explorify.'
        ); estrutura = 'explorify:mausoleum' }
        @{ t = 'Mansão illager'; depois = 'Viajante'; d = @(
            'O &eDungeons and Taverns&r tem uma &emansão illager&r nova.'
        ); conquista = 'nova_structures:adventure/find_illager_manor' }
        @{ t = 'Vila do pântano'; depois = 'Viajante'; opcional = $true; d = @(
            'Uma &evila no pântano&r do Dungeons and Taverns.'
        ); conquista = 'nova_structures:adventure/find_swamp_village' }
        @{ t = 'Ruínas de cristal'; depois = 'Viajante'; opcional = $true; d = @(
            'O &eGalosphere&r tem ruínas esquecidas nas cavernas de cristal.'
        ); conquista = 'galosphere:adventure/find_forgotten_ruins' }
        @{ t = 'Cidade antiga'; depois = 'Viajante'; marco = $true; d = @(
            'No subsolo escuro ficam as &ecidades antigas&r. Ande agachado: barulho chama o &eWarden&r.'
        ); estrutura = 'minecraft:ancient_city' }
        @{ t = 'Câmaras de desafio'; depois = 'Viajante'; d = @(
            'Salas com &egeradores de desafio&r. Vença as ondas para ganhar chaves e abrir os cofres.'
        ); estrutura = 'minecraft:trial_chambers' }
        @{ t = 'Monumento do oceano'; depois = 'Viajante'; d = @(
            'O monumento do oceano tem mais salas (YUNG''s). Leve poção de respirar na água.'
        ); estrutura = 'betteroceanmonuments:ocean_monument' }
    ) }
    @{ t = 'Nether e End'; g = 'Aventura'; icone = 'minecraft:end_crystal'; sub = 'Fortalezas, castelos e a luta com o dragão'; m = @(
        @{ t = 'Fortaleza do Nether'; marco = $true; d = @(
            'A fortaleza do Nether ficou maior e mais bonita (YUNG''s). Lá nascem os &eblazes&r e os &eesqueletos wither&r.'
            ''
            'Os blazes deixam a &evara de blaze&r, que faz os olhos de ender.'
        ); estrutura = 'betterfortresses:fortress' }
        @{ t = 'Vara de blaze'; depois = 'Fortaleza do Nether'; d = @(
            'Mate blazes para pegar &evaras de blaze&r.'
        ); item = 'minecraft:blaze_rod'; q = 6 }
        @{ t = 'Castelo proibido'; depois = 'Fortaleza do Nether'; d = @(
            'O &eIncendium&r tem estruturas grandes no Nether. O &ecastelo proibido&r é a maior.'
        ); estrutura = 'incendium:forbidden_castle' }
        @{ t = 'Vila piglin'; depois = 'Fortaleza do Nether'; opcional = $true; d = @(
            'Uma &evila de piglins&r do Incendium. Use algo de ouro para eles não atacarem.'
        ); estrutura = 'incendium:piglin_village' }
        @{ t = 'Fortaleza dos piglins'; depois = 'Fortaleza do Nether'; opcional = $true; d = @(
            'O &eDungeons and Taverns&r tem um &edonjon&r dos piglins.'
        ); conquista = 'nova_structures:nether/find_donjon' }
        @{ t = 'Seguir o olho'; depois = 'Vara de blaze'; d = @(
            'Faça um &eolho de ender&r e jogue para cima: ele voa na direção da fortaleza do End.'
        ); conquista = 'minecraft:story/follow_ender_eye' }
        @{ t = 'Fortaleza do End'; depois = 'Seguir o olho'; d = @(
            'A fortaleza ficou &emaior e mais perigosa&r (YUNG''s), com bibliotecas e salas novas. O portal fica no fundo.'
        ); estrutura = 'betterstrongholds:stronghold' }
        @{ t = 'Dragão do Ender'; depois = 'Fortaleza do End'; marco = $true; sub = 'Ilha do dragão reformulada'; d = @(
            'A ilha do dragão ficou mais bonita (YUNG''s Better End Island). Destrua os &ecristais&r nas torres antes de bater no dragão.'
            ''
            'Leve arco, muitos blocos e um &ebalde de água&r.'
        ); mata = 'minecraft:ender_dragon'; p = 'minecraft:diamond'; n = 8 }
        @{ t = 'Cidade do End'; depois = 'Dragão do Ender'; d = @(
            'Depois do dragão, o portal pequeno leva às &eilhas de fora&r. Lá ficam as &ecidades do End&r, com baús e o navio.'
        ); estrutura = 'minecraft:end_city' }
        @{ t = 'Elytra'; depois = 'Cidade do End'; marco = $true; d = @(
            'O navio da cidade do End guarda as &eelytra&r: asas para planar. Com foguetes, você voa.'
        ); item = 'minecraft:elytra' }
        @{ t = 'Castelo do End'; depois = 'Dragão do Ender'; opcional = $true; d = @(
            'O &eDungeons and Taverns&r tem um &ecastelo&r nas ilhas do End.'
        ); conquista = 'nova_structures:end/find_end_castle' }
        @{ t = 'Navio gigante do End'; depois = 'Dragão do Ender'; opcional = $true; d = @(
            'O &eMES&r espalha estruturas pelo End. Ache um &enavio gigante&r.'
        ); estrutura = 'mes:mega_ship' }
        @{ t = 'Esqueleto de dragão'; depois = 'Dragão do Ender'; opcional = $true; d = @(
            'O &eNullscape&r deixa o End mais estranho. Ache um &eesqueleto de dragão&r gigante.'
        ); estrutura = 'nullscape:dragon_skeleton' }
    ) }
    @{ t = 'Caçador de chefes'; g = 'Aventura'; icone = 'minecraft:wither_skeleton_skull'; sub = 'Os monstros mais fortes do pack'; m = @(
        @{ t = 'Armado até os dentes'; marco = $true; d = @(
            'Chefes batem forte. Antes de ir: &earmadura de diamante&r ou melhor, comida boa, poções e um &etotem&r se tiver.'
            ''
            'Os chefes do Aether, da Twilight, do Undergarden e do Eternal Starlight estão nos capítulos de &eDimensões&r.'
        ) }
        @{ t = 'Guardião ancião'; depois = 'Armado até os dentes'; d = @(
            'Mora no &emonumento do oceano&r. Ele deixa você com &efadiga de mineração&r: mate os três para tirar.'
        ); mata = 'minecraft:elder_guardian'; p = 'minecraft:sponge'; n = 4 }
        @{ t = 'Wither'; depois = 'Armado até os dentes'; marco = $true; d = @(
            'Três &ecrânios de esqueleto wither&r em cima de &eareia das almas&r em forma de T. Faça &elonge de casa&r: ele explode tudo.'
        ); mata = 'minecraft:wither'; p = 'minecraft:diamond'; n = 8 }
        @{ t = 'Warden'; depois = 'Armado até os dentes'; d = @(
            'Mora nas &ecidades antigas&r. Ele é cego e acha você pelo barulho. Melhor fugir do que lutar.'
        ); mata = 'minecraft:warden'; p = 'minecraft:diamond'; n = 8; opcional = $true }
        @{ t = 'Cavaleiro de ferro'; depois = 'Armado até os dentes'; sub = 'Mowzie''s Mobs'; d = @(
            'O &eFerrous Wroughtnaut&r guarda uma câmara no subsolo. Desvie do machado e acerte as &ecostas&r depois que ele errar o golpe.'
        ); mata = 'mowziesmobs:ferrous_wroughtnaut' }
        @{ t = 'Frostmaw'; depois = 'Armado até os dentes'; sub = 'Mowzie''s Mobs'; d = @(
            'Um gigante de gelo que &edorme&r nos biomas de neve.'
        ); mata = 'mowziesmobs:frostmaw' }
        @{ t = 'Umvuthi'; depois = 'Armado até os dentes'; sub = 'Mowzie''s Mobs'; d = @(
            'O pássaro do sol que lidera o povo da &esavana&r.'
        ); mata = 'mowziesmobs:umvuthi' }
        @{ t = 'Escultor'; depois = 'Armado até os dentes'; sub = 'Mowzie''s Mobs'; opcional = $true; d = @(
            'O &eEscultor&r espera no topo de um monastério nas montanhas.'
        ); mata = 'mowziesmobs:sculptor' }
        @{ t = 'Capitã Cornélia'; depois = 'Armado até os dentes'; sub = 'Aquamirae'; d = @(
            'O fantasma da capitã mora nos &enavios piratas&r do oceano gelado.'
        ); mata = 'aquamirae:captain_cornelia' }
        @{ t = 'Maw'; depois = 'Capitã Cornélia'; sub = 'Aquamirae'; opcional = $true; d = @(
            'Um monstro das &eáguas geladas&r.'
        ); mata = 'aquamirae:maw' }
        @{ t = 'Chefes das estruturas'; depois = 'Armado até os dentes'; sub = 'Dungeons and Taverns'; d = @(
            'Várias estruturas do Dungeons and Taverns têm um &eminichefe&r. Vença todos.'
        ); conquista = 'nova_structures:adventure/kill_all_minibosses' }
    ) }
    @{ t = 'Volta ao mundo'; g = 'Aventura'; icone = 'minecraft:compass'; sub = 'Biomas novos do Terralith, Biomes O'' Plenty e mais'; m = @(
        @{ t = 'Mundo novo'; marco = $true; d = @(
            'O &eTerralith&r, o &eBiomes O'' Plenty&r e o &eTectonic&r mudaram o mundo: montanhas altas, vales, ilhas no céu e cavernas novas.'
            ''
            'Use a &ebússola de biomas&r para achar cada um.'
        ) }
        @{ t = 'Cerejeiras'; depois = 'Mundo novo'; d = @('Um vale de &ecerejeiras&r rosa.'); bioma = 'terralith:sakura_valley' }
        @{ t = 'Cânion vermelho'; depois = 'Mundo novo'; d = @('O cânion de &epedra vermelha&r.'); bioma = 'terralith:bryce_canyon' }
        @{ t = 'Vulcão'; depois = 'Mundo novo'; d = @('A cratera de um &evulcão&r.'); bioma = 'terralith:volcanic_crater' }
        @{ t = 'Ilhas no céu'; depois = 'Mundo novo'; marco = $true; d = @('Ilhas que &eflutuam&r acima das nuvens.'); bioma = 'terralith:skylands_summer' }
        @{ t = 'Penhascos brancos'; depois = 'Mundo novo'; opcional = $true; d = @('Penhascos de pedra branca no mar.'); bioma = 'terralith:white_cliffs' }
        @{ t = 'Oásis'; depois = 'Mundo novo'; opcional = $true; d = @('Um oásis no meio do deserto.'); bioma = 'terralith:desert_oasis' }
        @{ t = 'Floresta de sequoias'; depois = 'Mundo novo'; d = @('Árvores gigantes do &eBiomes O'' Plenty&r.'); bioma = 'biomesoplenty:redwood_forest' }
        @{ t = 'Bosque místico'; depois = 'Mundo novo'; d = @('Um bosque mágico e colorido do Biomes O'' Plenty.'); bioma = 'biomesoplenty:mystic_grove' }
        @{ t = 'Campo de lavanda'; depois = 'Mundo novo'; opcional = $true; d = @('Tudo roxo de lavanda.'); bioma = 'biomesoplenty:lavender_field' }
        @{ t = 'Fontes termais'; depois = 'Mundo novo'; opcional = $true; d = @('Fontes de água quente nas montanhas.'); bioma = 'biomesoplenty:hot_springs' }
        @{ t = 'Selva subterrânea'; depois = 'Mundo novo'; sub = 'Cavernas'; d = @('Uma &eselva inteira&r dentro de uma caverna.'); bioma = 'terralith:cave/underground_jungle' }
        @{ t = 'Cânion de cristal'; depois = 'Selva subterrânea'; sub = 'Galosphere'; d = @(
            'O &eGalosphere&r tem cavernas de cristal. Lá tem &eallurite&r e &elumiere&r, cristais para itens de exploração.'
        ); bioma = 'galosphere:crystal_canyons' }
        @{ t = 'Cristal de allurite'; depois = 'Cânion de cristal'; opcional = $true; d = @('Pegue um fragmento de &eallurite&r.'); item = 'galosphere:allurite_shard' }
        @{ t = 'Cavernas de gelo'; depois = 'Selva subterrânea'; sub = 'YUNG''s Cave Biomes'; d = @('Cavernas congeladas com gelo encantado.'); bioma = 'yungscavebiomes:frosted_caves' }
        @{ t = 'Cavernas perdidas'; depois = 'Selva subterrânea'; sub = 'YUNG''s Cave Biomes'; d = @('Um deserto embaixo da terra, com tempestades de areia.'); bioma = 'yungscavebiomes:lost_caves' }
        @{ t = 'Floresta invertida'; depois = 'Mundo novo'; sub = 'Nether'; d = @('No Nether, o &eIncendium&r tem uma floresta de cabeça para baixo.'); bioma = 'incendium:inverted_forest' }
        @{ t = 'Vale do choro'; depois = 'Floresta invertida'; opcional = $true; d = @('Outro bioma do Nether do Incendium.'); bioma = 'incendium:weeping_valley' }
    ) }
    @{ t = 'Colecionador'; g = 'Aventura'; icone = 'minecraft:diamond'; sub = 'Os itens mais raros do jogo'; m = @(
        @{ t = 'Montinho de diamante'; marco = $true; d = @(
            'Junte &e64 diamantes&r. Segure a tecla &eao lado do 1&r para minerar o veio inteiro (FTB Ultimine).'
        ); item = 'minecraft:diamond'; q = 64; p = 'minecraft:diamond_block'; n = 1 }
        @{ t = 'Netherite'; depois = 'Montinho de diamante'; d = @(
            'Os &erestos antigos&r ficam no fundo do Nether. Derreta, junte com ouro e vire &elingote de netherite&r.'
        ); item = 'minecraft:netherite_ingot' }
        @{ t = 'Totem'; depois = 'Montinho de diamante'; d = @(
            'O &etotem da imortalidade&r salva da morte uma vez. Vem dos &eevocadores&r das mansões.'
        ); item = 'minecraft:totem_of_undying' }
        @{ t = 'Tridente'; depois = 'Montinho de diamante'; opcional = $true; d = @(
            'Os &eafogados&r às vezes deixam cair um tridente.'
        ); item = 'minecraft:trident' }
        @{ t = 'Cabeça de dragão'; depois = 'Montinho de diamante'; opcional = $true; d = @(
            'Fica na proa dos navios das cidades do End.'
        ); item = 'minecraft:dragon_head' }
        @{ t = 'Estrela do Nether'; depois = 'Montinho de diamante'; d = @(
            'O prêmio do &eWither&r.'
        ); item = 'minecraft:nether_star' }
        @{ t = 'Sinalizador'; depois = 'Estrela do Nether'; marco = $true; d = @(
            'Um &esinalizador&r em cima de uma pirâmide de blocos de ferro, ouro ou diamante dá efeitos bons para quem está perto.'
        ); item = 'minecraft:beacon' }
    ) }
)

# Confere os ids nos jars do pack (tools/jars, baixados pelo montar-pack): item que nao existe deixaria a missao
# impossivel. Ids do Minecraft (minecraft:) ficam de fora. Sem tools/jars, avisa e segue.
$jarsDir = Join-Path $root 'tools/jars'
if (Test-Path $jarsDir) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $existe = New-Object 'Collections.Generic.HashSet[string]'
    # Item vale pelo nome item.<mod>.<id> ou block.<mod>.<id> no idioma do mod (modelo interno, como
    # refurbished_furniture:fridge, nao e item). Mod sem idioma: vale o modelo.
    $nomes = New-Object 'Collections.Generic.HashSet[string]'; $comNome = New-Object 'Collections.Generic.HashSet[string]'
    foreach ($j in Get-ChildItem $jarsDir -Filter *.jar) {
        try { $z = [IO.Compression.ZipFile]::OpenRead($j.FullName) } catch { continue }
        foreach ($e in $z.Entries) {
            if ($e.FullName -match '^assets/([a-z0-9_.-]+)/models/item/([a-z0-9_/.-]+)\.json$') { [void]$existe.Add("$($matches[1]):$($matches[2])") }
            elseif ($e.FullName -match '^data/([a-z0-9_.-]+)/(dimension|worldgen/structure|worldgen/biome|advancement)/([a-z0-9_/.-]+)\.json$') { [void]$existe.Add("$($matches[1]):$($matches[3])") }
            elseif ($e.FullName -match '^assets/([a-z0-9_.-]+)/lang/en_us\.json$') {
                # Bichos: o id vem das chaves entity.<mod>.<nome> do arquivo de idioma.
                [void]$comNome.Add($matches[1])
                $r = New-Object IO.StreamReader $e.Open(); $txt = $r.ReadToEnd(); $r.Dispose()
                foreach ($k in [regex]::Matches($txt, '"entity\.([a-z0-9_]+)\.([a-z0-9_]+)"')) { [void]$existe.Add("$($k.Groups[1].Value):$($k.Groups[2].Value)") }
                foreach ($k in [regex]::Matches($txt, '"(?:item|block)\.([a-z0-9_]+)\.([a-z0-9_/]+)"')) { [void]$nomes.Add("$($k.Groups[1].Value):$($k.Groups[2].Value)") }
            }
        }
        $z.Dispose()
    }
    $faltam = @(foreach ($c in $capitulos) {
        foreach ($id in @($c.icone) + @($c.m | ForEach-Object { $_['item']; $_['p'] })) {
            if ($id -and $id -notlike 'minecraft:*' -and -not $(if ($comNome.Contains($id.Split(':')[0])) { $nomes.Contains($id) } else { $existe.Contains($id) })) { "$($c.t): $id" } }
        foreach ($id in @($c.m | ForEach-Object { $_['dim']; $_['mata']; $_['estrutura']; $_['bioma']; $_['conquista'] })) {
            if ($id -and $id -notlike 'minecraft:*' -and -not $existe.Contains($id)) { "$($c.t): $id" } } })
    if ($faltam) { throw "Ids que nao existem no pack:`n$($faltam -join "`n")" }
}
else { Write-Warning 'Sem tools/jars (rode o montar-pack): ids nao conferidos.' }

# Id fixo pelo nome (16 hex), para o progresso dos jogadores nao se perder quando o livro for gerado de novo.
# O nome entra sem acento: acentuar um titulo antigo nao muda o id.
$md5 = [Security.Cryptography.MD5]::Create()
function Sem($s) { -join ($s.Normalize([Text.NormalizationForm]::FormD).ToCharArray() | Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' }) }
# Primeiro byte abaixo de 0x80: id que comeca com 8 a F vira numero negativo e o jogo nao acha o texto dele no lang.
function Id($s) { $h = $md5.ComputeHash([Text.Encoding]::UTF8.GetBytes((Sem $s)))[0..7]; $h[0] = $h[0] -band 0x7F; -join ($h | ForEach-Object { $_.ToString('X2') }) }
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
    # Desenho em arvore: x pela profundidade (missao depois da outra vai para a direita). Cada ramo ganha uma faixa
    # propria na vertical e o pai fica no meio dos filhos, assim as linhas nao se cruzam. Com mais de um pai, o ramo
    # segue o primeiro. Soltas (sem dependencia) ficam em grade embaixo da arvore.
    $qs = @(); $antT = $null; $tit = @{}; $prof = @{}; $posY = @{}; $filhos = @{}; $raizes = @()
    foreach ($m in $c.m) {
        $qid = Id "missao/$($c.t)/$($m.t)"
        $q = if ($m['q']) { $m['q'] } else { 1 }
        $tarefa = if ($m['item']) { "{ id: `"$(Id "tarefa/$qid")`", item: { count: $q, id: `"$($m['item'])`" }, type: `"item`" }" }
            elseif ($m['mata']) { "{ entity: `"$($m['mata'])`", id: `"$(Id "tarefa/$qid")`", type: `"kill`", value: $($q)L }" }
            elseif ($m['estrutura']) { "{ id: `"$(Id "tarefa/$qid")`", structure: `"$($m['estrutura'])`", type: `"structure`" }" }
            elseif ($m['bioma']) { "{ biome: `"$($m['bioma'])`", id: `"$(Id "tarefa/$qid")`", type: `"biome`" }" }
            elseif ($m['conquista']) { "{ advancement: `"$($m['conquista'])`", criterion: `"`", id: `"$(Id "tarefa/$qid")`", type: `"advancement`" }" }
            elseif ($m['dim']) { "{ dimension: `"$($m['dim'])`", id: `"$(Id "tarefa/$qid")`", type: `"dimension`" }" }
            else { "{ id: `"$(Id "tarefa/$qid")`", type: `"checkmark`" }" }
        $xp = if ($m['xp']) { $m['xp'] } elseif ($m['marco']) { 100 } else { 20 }
        $premios = @("{ id: `"$(Id "xp/$qid")`", type: `"xp`", xp: $xp }")
        if ($m['p']) { $premios += "{ id: `"$(Id "premio/$qid")`", item: { count: $(if ($m['n']) { $m['n'] } else { 1 }), id: `"$($m['p'])`" }, type: `"item`" }" }
        $extra = "`n`t`t`trewards: [$($premios -join ', ')]"
        if ($m['marco']) { $extra += "`n`t`t`tshape: `"gear`"`n`t`t`tsize: 1.5d" }
        if ($m['opcional']) { $extra += "`n`t`t`toptional: true" }
        $pais = if ($m.ContainsKey('depois')) { @(@($m['depois']) | Where-Object { $_ }) } elseif ($m['solta'] -or -not $antT) { @() } else { @($antT) }
        $pais = @($pais)  # um pai so viraria texto, e $pais[0] seria a primeira letra
        foreach ($pai in $pais) { if (-not $tit.ContainsKey($pai)) { throw "Capitulo $($c.t), missao $($m.t): depois de '$pai', que nao vem antes dela" } }
        $lista = ($pais | ForEach-Object { '"' + $tit[$_] + '"' }) -join ', '
        $dep = if ($pais) { "`n`t`t`tdependencies: [$lista]" } else { '' }
        if ($pais -or (-not $m['solta'] -and (-not $tit.Count -or $m.ContainsKey('depois')))) {
            $prof[$m.t] = if ($pais) { 1 + ($pais | ForEach-Object { $prof[$_] } | Measure-Object -Maximum).Maximum } else { 0 }
            if ($pais) { $filhos[$pais[0]] = @($filhos[$pais[0]]) + $m.t | Where-Object { $_ } } else { $raizes += $m.t }
            $pos = "arvore|$($m.t)"
        }
        else { $prof[$m.t] = 0; $pos = 'solta' }
        $qs += "`t`t{$dep`n`t`t`tid: `"$qid`"$extra`n`t`t`ttasks: [$tarefa]`n`t`t`t@POS@`n`t`t}@@SEP@@$pos"
        $lang += "`tquest.$qid.title: $(Txt $m.t)"
        if ($m['sub']) { $lang += "`tquest.$qid.quest_subtitle: $(Txt $m['sub'])" }
        $lang += "`tquest.$qid.quest_desc: [$((@($m.d) | ForEach-Object { Txt $_ }) -join ', ')]"
        $tit[$m.t] = $qid; $antT = $m.t
    }
    $script:proxY = 0
    function Pos-Ramo($n) {
        $f = @($filhos[$n])
        if (-not $filhos[$n]) { $posY[$n] = $script:proxY; $script:proxY += 1.75 }
        else { foreach ($k in $f) { Pos-Ramo $k }; $posY[$n] = ($posY[$f[0]] + $posY[$f[-1]]) / 2 }
    }
    foreach ($r in $raizes) { Pos-Ramo $r; $script:proxY += 0.75 }
    $base = $script:proxY + 1
    $k = 0
    $qs = for ($i = 0; $i -lt $qs.Count; $i++) {
        $texto, $pos = $qs[$i] -split '@@SEP@@'
        if ($pos -eq 'solta') { $pos = "$(($k % 5) * 2)d|$($base + [math]::Floor($k / 5) * 1.75)d"; $k++ }
        elseif ($pos -like 'arvore|*') { $n = $pos.Substring(7); $pos = "$($prof[$n] * 2.5)d|$($posY[$n])d" }
        $px, $py = $pos -split '\|'
        $texto.Replace('@POS@', "x: $px`n`t`t`ty: $py")
    }
    $cap = "{`n`tdefault_hide_dependency_lines: false`n`tdefault_quest_shape: `"`"`n`tfilename: `"$nome`"`n`tgroup: `"$grupo`"`n`ticon: { id: `"$($c.icone)`" }`n`tid: `"$cid`"`n`torder_index: $ordem`n`tquest_links: [ ]`n`tquests: [`n$($qs -join "`n")`n`t]`n}`n"
    [IO.File]::WriteAllText((Join-Path $destino "chapters/$nome.snbt"), $cap, $utf8)
    $ordem++
}
# pt_br para o jogo em portugues; en_us igual, para quem trocou o idioma nao ver chaves no lugar do texto.
foreach ($l in 'pt_br', 'en_us') { [IO.File]::WriteAllText((Join-Path $destino "lang/$l.snbt"), "{`n$($lang -join "`n")`n}`n", $utf8) }
Write-Host "$($capitulos.Count) capitulos, $(@($capitulos | ForEach-Object { $_.m }).Count) missoes -> $destino"

# Cobertura: quantas missoes cada mod do mods.txt tem, em docs/missoes.md. Missao conta para um mod quando
# um id dela (item, bicho, estrutura, bioma, dimensao, conquista) e do mod, ou quando ela tem mod = 'slug'.
# Mod que nao precisa de missao fica em $semMissao com o motivo. Mod novo no mods.txt aparece como "falta".
$semMissao = @{
    'desempenho' = 'sodium', 'lithium', 'ferrite-core', 'modernfix', 'immediatelyfast', 'entityculling', 'moreculling', 'createbetterfps', 'cf:1091339', 'clumps', 'yeetus-experimentus', 'c2me-neoforge', 'noisium'
    'visual ou som' = 'iris', 'distanthorizons', 'fresh-animations', 'entity-model-features', 'entity-texture-features', '3dskinlayers', 'ambientsounds', 'sound-physics-remastered', 'not-enough-animations', 'cubes-without-borders', 'chat-heads', 'pick-up-notifier'
    'servidor, login ou skin' = 'modflared', 'mixauth', 'skinrestorer', 'customskinloader', 'crash-assistant'
    'biblioteca' = 'cf:404465', 'cf:404468', 'cf:885449', 'cf:943925', 'cf:889915'
    'o proprio livro' = 'cf:289412'
    'funciona sozinho ou so muda a tela' = 'bettersearch', 'appleskin', 'better-advancements', 'yungs-menu-tweaks', 'polymorph', 'travelers-titles', 'dynamic-torches', 'tectonic', 'yungs-bridges', 'yungs-extras', 'easy-anvils'
}
# Meta fixa para mod com muitas variantes (madeira, cor) que inflam a contagem de itens.
$metaFixa = @{ 'storage-delight' = 3; 'botany-pots' = 4; 'cf:415438' = 8; 'macaws-furniture' = 4; 'macaws-roofs' = 2; 'macaws-windows' = 2; 'macaws-doors' = 2; 'macaws-bridges' = 2; 'macaws-fences-and-walls' = 2; 'handcrafted' = 4; 'sophisticated-storage' = 6; 'createdeco' = 3; 'create-deco' = 3; 'copycats' = 2; 'advanced-netherite' = 3; 'interiors' = 2 }
$motivo = @{}; foreach ($k in $semMissao.Keys) { foreach ($s in $semMissao[$k]) { $motivo[$s] = $k } }
if (Test-Path $jarsDir) {
    # slug -> jar (sha1 do .pw.toml) -> modIds do neoforge.mods.toml (com os mods embutidos).
    $pwDir = Join-Path $root 'modpack/pack'
    $porCf = @{}; $porSlug = @{}
    foreach ($f in Get-ChildItem $pwDir -Recurse -Filter *.pw.toml) {
        $t = [IO.File]::ReadAllText($f.FullName)
        $sha = [regex]::Match($t, 'hash = "([0-9a-f]{40})"').Groups[1].Value
        $porSlug[$f.Name -replace '\.pw\.toml$', ''] = $sha
        $cf = [regex]::Match($t, 'project-id = (\d+)'); if ($cf.Success) { $porCf["cf:$($cf.Groups[1].Value)"] = $sha }
    }
    $modIds = @{}; $itens = @{}
    foreach ($sha in @($porSlug.Values) + @($porCf.Values) | Sort-Object -Unique) {
        $j = Join-Path $jarsDir "$sha.jar"; if (-not (Test-Path $j)) { continue }
        $z = [IO.Compression.ZipFile]::OpenRead($j); $ids = @(); $qtd = 0
        foreach ($e in $z.Entries | Where-Object { $_.FullName -match '^META-INF/(neoforge\.)?mods\.toml$' }) {
            $r = New-Object IO.StreamReader $e.Open(); $ids += [regex]::Matches($r.ReadToEnd(), 'modId\s*=\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }; $r.Dispose() }
        foreach ($e in $z.Entries | Where-Object { $_.FullName -match '^assets/[^/]+/lang/en_us\.json$' }) {
            $r = New-Object IO.StreamReader $e.Open(); $qtd += [regex]::Matches($r.ReadToEnd(), '"(?:item|block)\.[a-z0-9_]+\.[a-z0-9_]+"\s*:').Count; $r.Dispose() }
        $itens[$sha] = $qtd
        # Namespaces dos assets e data contam tambem (mod com id diferente do namespace, como o Aeronautics).
        $ids += $z.Entries | ForEach-Object { if ($_.FullName -match '^(?:assets|data)/([a-z0-9_.-]+)/') { $matches[1] } }
        $z.Dispose()
        $modIds[$sha] = @($ids | Where-Object { $_ -notin 'minecraft', 'neoforge', 'c', 'forge' } | Sort-Object -Unique)
    }
    $linhas = @(); $cat = ''; $resumo = @{ falta = 0; pouco = 0; ok = 0; nao = 0 }
    foreach ($l in [IO.File]::ReadAllLines((Join-Path $root 'modpack/mods.txt'))) {
        if ($l -match '^## (.+)') { $cat = $matches[1]; continue }
        if ($cat -match '^(Pacotes de recursos|Shaders|Desempenho)') { $resumo.nao++; continue }
        if ($l -match '^\s*(#|$)') { continue }
        $slug, $desc = $l -split '\s*\|\s*', 2; $slug = $slug.Trim()
        $sha = if ($slug -like 'cf:*') { $porCf[$slug] } else { $porSlug[$slug] }
        # Namespace usado por outro mod do pack (ex.: create) so conta para o dono do jar.
        $ns = if ($sha -and $modIds[$sha]) { $modIds[$sha] } else { @() }
        if ($slug -ne 'create') { $ns = @($ns | Where-Object { $_ -ne 'create' }) }
        $caps = @{}; $n = 0
        foreach ($c in $capitulos) { foreach ($m in $c.m) {
            $ids = @($m['item'], $m['mata'], $m['estrutura'], $m['bioma'], $m['dim'], $m['conquista']) | Where-Object { $_ }
            if (@($m['mod']) -contains $slug -or @($ids | Where-Object { $ns -contains $_.Split(':')[0] }).Count) { $n++; $caps[$c.t] = 1 } } }
        # Meta pelo tamanho do mod: itens com nome no idioma do jar.
        $qi = if ($sha) { [int]$itens[$sha] } else { 0 }
        $meta = if ($metaFixa[$slug]) { $metaFixa[$slug] } elseif ($qi -eq 0) { 1 } elseif ($qi -le 30) { 3 } elseif ($qi -le 150) { 5 } else { 10 }
        $st = if ($motivo[$slug] -and $n -eq 0) { $resumo.nao++; "nao precisa ($($motivo[$slug]))" } elseif ($n -eq 0) { $resumo.falta++; '**falta**' } elseif ($n -lt $meta) { $resumo.pouco++; 'pouco' } else { $resumo.ok++; 'ok' }
        $linhas += "| $cat | ``$slug`` | $qi | $n/$meta | $st | $(($caps.Keys | Sort-Object) -join ', ') |"
    }
    $doc = @(
        '# Cobertura do livro de missoes'
        ''
        'Gerado pelo `scripts/missoes.ps1`. Nao edite a mao: rode o script depois de mexer no livro ou no `mods.txt`.'
        ''
        "$($capitulos.Count) capitulos, $(@($capitulos | ForEach-Object { $_.m }).Count) missoes. Mods: $($resumo.ok) ok, $($resumo.pouco) abaixo da meta, $($resumo.falta) faltando, $($resumo.nao) sem necessidade de missao."
        ''
        'Meta de missoes pelo tamanho do mod: sem itens 1, ate 30 itens 3, ate 150 itens 5, mais que isso 10 (menos os de $metaFixa no missoes.ps1, com muitas variantes de madeira ou cor).'
        ''
        '| Categoria | Mod | Itens | Missoes/meta | Status | Capitulos |'
        '|---|---|---|---|---|---|'
    ) + $linhas
    [IO.File]::WriteAllText((Join-Path $root 'docs/missoes.md'), ($doc -join "`n") + "`n", (New-Object Text.UTF8Encoding $false))
    Write-Host "Cobertura: $($resumo.ok) ok, $($resumo.pouco) pouco, $($resumo.falta) falta, $($resumo.nao) nao precisa -> docs/missoes.md"
}
