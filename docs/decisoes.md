# Decisões

Registro do que escolhemos e por quê, para lembrar no futuro o que estamos jogando.

## Objetivo do pack

Vanilla melhorado para até 10 jogadores, a maioria iniciante e no Mac (M1+ com 16 GB).
Pedidos: Create com tutorial, baús maiores e sistema de baú, ferramentas melhores,
dragão para domar, criar como pet e voar, mods que deixam o jogo mais leve e fácil de aprender.

## Versão: Minecraft 1.21.1 + NeoForge

- Pedido era "a mais recente possível". Em nov/2026 o Minecraft está na 26.3, mas o **Create**
  (pedido principal) só existe até a **1.21.1**, e só em NeoForge/Forge. Logo, 1.21.1 + NeoForge.
- Sophisticated, JEI, Jade, Sodium etc. já estão na 26.x, mas acompanham a 1.21.1 também.
- Quando o Create sair para 26.x, dá para reavaliar (rodar `montar-pack.ps1` com `$mc` novo e ver
  o que falta).
- Fabric descartado: Create oficial é NeoForge. Com isso ficam de fora os mods de renderização Metal
  para Mac (só Fabric 26.x); o Sodium cobre o desempenho no Mac.
- Revisto em 2026-11-25 (`scripts/comparar-versoes.ps1`): 1.21.1 tem todos os 130 mods do pack; a
  melhor versão mais nova (26.1.2) tem 92. No Modrinth, NeoForge 1.21.1 é a combinação com mais mods
  (22.903, contra 9.060 em NeoForge 26.1.2 e 14.333 em Fabric 26.1.2). Create, Farmer's Delight,
  Supplementaries, Aether, Deep Aether, When Dungeons Arise, Hamster e Dragon Mounts param na 1.21.1.
- Modrinth em vez de CurseForge: no CurseForge o autor pode bloquear download por outros programas, e
  aí cada jogador baixaria o mod na mão; a API dele também exige chave. Mod só do CurseForge (Twilight
  Forest, FTB Quests) só entra se o autor liberar o download por terceiros.

## Mods: escolhas e descartes

| Pedido | Escolhido | Descartado (motivo) |
|---|---|---|
| Create com tutorial | Create (Ponder embutido: animações explicando cada bloco) | - |
| Guias e receitas | JEI, Jade, AppleSkin, Better Advancements | EMI (JEI tem integração com Create) |
| Livro de missões | FTB Quests (CurseForge, download liberado pelo autor) com a trilha em português gerada por `scripts/missoes.ps1`; FTB XMod Compat (clicar no item abre a receita) e FTB Filter System | Odyssey Quests (derrubava todo jogador em servidor dedicado, Heracles#292) |
| Baús maiores | Sophisticated Storage + Backpacks | - |
| Sistema de baú | Tom's Simple Storage (terminal com busca, fácil) | Refined Storage e AE2 (complexos para iniciantes) |
| Ferramentas melhores | Just Hammers (3x3), Advanced Netherite, FTB Ultimine | Tinkers' Construct (sem versão 1.21.1), Silent Gear (complexo) |
| Dragão pet que voa | Dragon Mounts Remastered (desde 2026-11-19): o mais simples e com cara de vanilla, doma com peixe, apito para chamar, só precisa do GeckoLib | Wyrmroost (poucos dragões prontos e difícil de domar), Ice and Fire CE (o mais famoso, mas pesado, com dragões que quebram o terreno e muitas outras criaturas), Book of Dragons (estilo Como Treinar o Seu Dragão, domar é um processo longo), Cobblemon (Pokémon fugia do estilo do pack), Tiny Dragons (não voa) |
| Upgrade de baú | Sophisticated Storage (upgrade de tier aplicado no baú sem tirar os itens) e Iron Chests (pedido dos amigos) | - |
| Dimensões novas | The Aether e Deep Aether, Twilight Forest (pelo CurseForge, download liberado), Undergarden, Ad Astra, Eternal Starlight | Blue Skies e Deeper and Darker (sem versão NeoForge 1.21.1), Bumblezone (derrubava o servidor e confunde iniciantes) |
| Biomas e terreno | Terralith + Tectonic (vanilla+, roda só no servidor) e Biomes O' Plenty (pedido dos amigos) | Oh The Biomes We've Gone (pesado e foge do visual vanilla) |
| Estruturas | Série YUNG's completa (Better Dungeons, Mineshafts, Strongholds, Ocean Monuments, Desert e Jungle Temples, Witch Huts, Nether Fortresses, End Island, Bridges, Extras, Cave Biomes), Towns and Towers, Explorify, Dungeons and Taverns, Moogs Voyager e End Structures, Structory e Structory Towers, Philips Ruins (só no servidor) | Repurposed Structures (muita coisa, pesa na geração), YUNG's Better Caves (troca a geração de cavernas e briga com Terralith e Tectonic), CTOV e Villages and Pillages (repetem as vilas do Towns and Towers), The Lost Cities (troca o mundo inteiro) |
| Visual e ambiente | Hats Renewed (chapéus cosméticos ganhos ao derrotar mobs), Travelers' Titles, Fresh Animations (ligado por padrão) + EMF/ETF, 3D Skin Layers, Ambient Sounds (medido com JFR no cliente: 0,3% do processamento, fica ligado para todos) | Continuity (no NeoForge exige o Sinytra Connector, instável), Sodium Dynamic Lights (o Options API dele exige o Reese's, que se declara incompatível com ele), Falling Leaves (port NeoForge pouco usado) |
| Perfis de gráfico | Options Profiles com 7 perfis gerados por `scripts/perfis.ps1` em `modpack/arquivos/options-profiles`, uma escala só para PC e Mac (desde 26/11; antes eram 19 separados): 1 - Minimo a 4 - Alto sem shader, 5 - Shader Leve (MakeUp), 6 - Shader e 7 - Ultra (Complementary, roda no Mac). Aplicam só `options.txt` e o shader do Iris (com a distância das sombras) | Configurar só o `options.txt` inicial (não deixa trocar de perfil no jogo). Sodium, Sodium Extra e Distant Horizons nos perfis: o Options Profiles 1.4.2 chama APIs que o Sodium 0.8, o Sodium Extra 0.9 e o DH 3 removeram (conferido nos jars) e o jogo fecha; pelo mesmo motivo Salvar/Criar perfil no jogo quebra |
| Mac | Sodium Extra com `reduce_resolution_on_mac` ligado na primeira instalação (sem Retina: bem mais FPS) | Retina ligado (FPS baixo em Mac base) |
| Shaders | Instalados e desligados. Rodam no Mac (GLSL até 4.10, conferido nos zips e todos testados no jogo num Mac M4): Complementary Reimagined, MakeUp, BSL. Só PC (exige OpenGL 4.3): Photon (testado: não abre no Mac, o jogo segue sem shader); Bliss abriu no M4, mas o autor diz suporte limitado no Mac | Ligados por padrão (pesam em Mac e PC fraco), Mellow e Noble (sem Mac e pouco usados). Complementary Unbound, Sildur's Vibrant, Super Duper Vanilla, Miniature, Solas e Rethinking Voxels (saíram em 2026-11-19: escolha demais para iniciante) |
| Ver longe | Distant Horizons só no jogo de cada um; Chunky só no servidor (com os dois no jogo, o DH chama a API do Chunky e o jogo fecha ao entrar). Opcional no PC (janela do packwiz na primeira abertura, vem desmarcado); desligado no Mac pelo `jogar.sh` (fechou o jogo em um M4): no Mac o Iris reserva as texturas do DH só por ele estar instalado, mesmo com a renderização desligada, e passa do limite de 16 (testado no M4) | DH no servidor (gera terreno distante para todos: pesado com Terralith/Tectonic num PC de casa) |
| Pacotes de recursos | Pacote próprio opcional `modo-patinho` (desligado; em `modpack/arquivos/resourcepacks`): água-viva do Naturalist vira patinho de borracha (modelo do EMF em `emf/cem/jellyfish.jem`) e a do Alex's Mobs vira bolinha com carinha (só textura: o modelo dela é código próprio do mod, fora do alcance do EMF). Todos os outros ligados: Fast Better Grass, Simple Grass Flowers, Better Leaves, 3D Crops, Better Lanterns, Cubic Sun & Moon, Fresh Waystones, Low Shield, Low On Fire, Fresh Animations + Extensions, recursos do Bubblellaneous | Visual Armor Trims e pacotes de livros encantados (precisam de CIT Resewn, sem NeoForge), Dramatic Skys (precisa de mod de céu) |
| Aventura | Dimensões: Undergarden, Ad Astra, Deep Aether, Incendium (Nether), Nullscape (End). Cavernas: Galosphere. Mobs: Naturalist, Alex's Mobs Continued, Friends&Foes, Mowzie's Mobs, Aquamirae, Adorable Hamster Pets. Estruturas e tesouro: When Dungeons Arise, Artifacts | Spelunkery e L_Ender's Cataclysm (saíram em 2026-11-19: mudam a mineração e chefes difíceis demais para iniciantes), Bosses of Mass Destruction (sem 1.21.1), Iron's Spells e outros mods de magia (recusados pelo grupo) |
| Facilidade | Waystones, Xaero's Minimap/World Map, Corpse, Mouse Tweaks, Inventory Essentials, Farmer's Delight; QoL de servidor: Controlling (busca de teclas), bússolas de bioma e estrutura, Ping Wheel, Carry On, Clumps, Pick Up Notifier, Chat Heads, Comforts, Trade Cycling, Easy Anvils | Gravestone (Corpse é mais simples), Inventory Profiles Next (setas roxas na hotbar), Simple Voice Chat (exige abrir outra porta UDP; os jogadores usam Discord) |
| Desempenho | Sodium, Lithium, FerriteCore, ModernFix, EntityCulling, ImmediatelyFast, Iris, Sodium Extra, More Culling, Dynamic FPS; servidor: Chunky (pré-geração), spark (medição), flags do Aikar, view 8 / simulação 6, sync-chunk-writes=false | C2ME e ServerCore (só Fabric), Krypton e FastQuit (sem 1.21.1) |

Lista completa com versões e links: [mods.md](mods.md).

## Como o pack é montado

- Fonte da verdade: [`modpack/mods.txt`](../modpack/mods.txt). O script
  [`scripts/montar-pack.ps1`](../scripts/montar-pack.ps1) pega no Modrinth a versão release mais
  nova de cada mod para NeoForge 1.21.1, adiciona dependências obrigatórias e gera o `modpack/pack` (packwiz).
- Mods marcados "server unsupported" no Modrinth (Sodium, Iris, minimapa de cliente...) ficam só no
  cliente; o servidor pula eles (packwiz `-s server`).

## Launcher: Prism em vez do oficial

O launcher oficial da Mojang roda NeoForge, mas não sabe instalar nem atualizar um modpack. O Prism Launcher (grátis, código aberto) faz isso:

- **Atualiza sozinho.** A cada abertura o Prism roda o packwiz, que baixa do GitHub o pack atual: mod novo, removido ou com versão nova chega a todos sem ninguém fazer nada. No oficial, cada jogador teria que trocar os jars na mão a cada mudança, e um mod diferente do servidor impede a entrada.
- **Um comando instala tudo.** O `jogar` instala o Prism, cria a instância com o NeoForge certo, escolhe o Java e a memória pelo tamanho da RAM, liga os pacotes de recursos, cria o atalho e abre o jogo.
- **Ajustes antes de abrir.** O `minezada.ps1`/`.sh` roda antes de cada abertura: acerta teclas em conflito, desliga avisos de mods, troca shader que saiu do pack e, no Mac com chip Apple, deixa o túnel (Modflared) usar o `cloudflared` ARM.
- **Instâncias separadas.** O pack fica na própria pasta e não mexe no `.minecraft` de quem já joga vanilla ou outros packs.
- **Sem original.** Quem não tem a conta da Microsoft joga pelo fork do Prism. O launcher oficial só abre com conta original.

A conta original funciona igual no Prism: o login é o da Microsoft.

### Jogar pelo launcher oficial (sem suporte)

Dá, mas fica tudo na mão e sem os ajustes acima. Precisa de conta original.

1. Instale o Java 21 e rode o instalador do NeoForge da mesma versão do pack (está em `modpack/pack/pack.toml`, linha `neoforge`), opção "Install client". Ele cria o perfil NeoForge no launcher oficial.
2. No launcher, em Instalações, crie uma instalação nova com essa versão do NeoForge e uma pasta de jogo própria (por exemplo `minezada`), para não misturar com o `.minecraft`.
3. Em "Mais opções", troque `-Xmx2G` por `-Xmx4G` (o mesmo que o `jogar` usa em computador de até 23 GB de RAM).
4. Baixe o [packwiz-installer-bootstrap.jar](https://github.com/packwiz/packwiz-installer-bootstrap/releases) para essa pasta de jogo e, dentro dela, rode:
   `java -jar packwiz-installer-bootstrap.jar https://raw.githubusercontent.com/EnzoFerroni/minezada/main/modpack/pack/pack.toml`
   Ele baixa os mods, configs e pacotes de recursos. Repita esse comando antes de cada sessão, senão o pack fica velho e o servidor recusa a entrada.
5. Abra a instalação e entre em `minezada.dpdns.org`.

Fica faltando o que o Prism e o `minezada` fazem sozinhos: perfis de gráfico já escolhidos, teclas sem conflito, avisos desligados e, no Mac com chip Apple, o `cloudflared` ARM para o túnel (sem ele, só com a Rosetta instalada). Problema nesse caminho: volte para o comando de jogar do README.
## Hospedagem e rede

| Tema | Decisão | Alternativas descartadas |
|---|---|---|
| Onde hospedar | PC de casa (Windows, cabo); Mac ou amigo quando o PC estiver desligado | Host pago em SP (~R$ 41/mês), exaroton (sem região Brasil, ping alto) |
| Mundo entre hosts | Google Drive (`mundo.tar.gz` + trava `host.lock` + 5 backups) | GitHub (arquivo > 100 MB, histórico pesado), Git LFS (1 GB grátis), GitHub Releases (exige `gh` e login em cada host) |
| Endereço | **Cloudflare Tunnel** `minezada.dpdns.org` (18/11, grátis): domínio grátis da DigitalPlat na conta grátis da Cloudflare, `cloudflared` no host e o mod Modflared no jogador. A conexão vai como HTTPS na 443, então passa em rede de faculdade (testado simulando só 80/443) e até com inspeção de tráfego. Host em qualquer rede com saída na 7844, nenhuma porta aberta, IP de casa escondido. Reserva: playit.gg (`molecule-spindle.tun.ply.gg`) | Domínio pago (sem gasto por enquanto), playit Premium com IP dedicado (~US$ 9/mês, não passa inspeção de tráfego), VPS grátis da Oracle (pede cartão, servidor público para manter, não passa inspeção), Cloudflare Spectrum (US$ 20/mês), quick tunnel da Cloudflare (só HTTP), GitHub Pages (só site estático), DuckDNS + UPnP (expõe o IP de casa; foi reserva até 19/11, saiu porque o UPnP do roteador de casa fica desligado) |
| Instalar servidor | A cada start (idempotente), igual no Windows e no Mac: instalador oficial do NeoForge + packwiz `-s server`, a mesma ferramenta do jogo | mrpack-install (até 19/11 no Windows; usa DNS próprio e falha com o DNS IPv6 quebrado de roteadores de operadora, e era uma ferramenta a mais), baixar mods à mão |
| Conta | `online-mode=false` + MixAuth: original entra direto (Mojang confirma, UUID oficial, skin), sem original usa senha (BCrypt) a cada entrada; "lembrar por IP" desligado porque o túnel e redes de faculdade dão o mesmo IP a todos. Whitelist pelo `jogadores.txt`: nick com original libera só o UUID oficial (progresso copiado do offline), sem original o offline. Testado no Mac e no Windows | SimpleLogin (bloqueia o renascer antes do login: quem volta morto fica preso; sessão só na memória), PAuth e i-server-login (menos usados, sem histórico), `online-mode=true` (só original), offline sem login (qualquer um entra com o nick do admin) |
| Skins no modo offline | SkinRestorer no servidor (Mojang, depois mc-heads + MineSkin; skin salva no mundo) e, desde 2026-11-20, CustomSkinLoader 14.21.1-ForgeV3 no jogo, que busca pela consulta sem assinatura da Mojang: um cobre o outro quando a rede bloqueia | Só um dos dois; CustomSkinLoader Universal 15.x (derruba o jogo no NeoForge 1.21.1) |
| Instalar no jogador | Prism Launcher + `minezada-prism.zip`; packwiz no pre-launch sincroniza os mods a cada abertura pelo link raw do GitHub (por isso o repo é **público**) | Modrinth App (sem atualização automática; pack não listado passa por moderação), launcher oficial (não instala mods), repo público separado (mais coisa para manter) |
| Launcher sem original | O comando de jogar pergunta. Sem original instala o [PrismLauncher-Cracked](https://github.com/Diegiwg/PrismLauncher-Cracked) (fork do Prism sem exigir conta Microsoft; binários do GitHub Actions) em pasta própria (`~/Applications/Minezada`, `%LOCALAPPDATA%\Programs\Minezada Launcher`). Mesmo formato de instância e mesma pasta de dados do Prism: mesmo zip e atualização automática. Sem conta, ele pede o nick ao abrir. Baixado de novo a cada execução do comando | Prism oficial (conta offline sem Microsoft abre em modo Demo), Fjord Launcher (exige Microsoft também), HMCL (outro formato, sem packwiz), importar o `.mrpack` à mão (sem atualização), TLauncher (histórico de malware). Risco: fork mantido por uma pessoa só |
| Saber se o servidor está ligado | Selo no README, atualizado pela Action **Status do servidor**, que o `iniciar` dispara ao ligar, a cada 10 min com o servidor ligado e no `stop` (`scripts/Selo.java`, token só de Actions em `dispatch.txt` no Drive), com o horário de 10 em 10 min de reserva (o GitHub atrasa horas os agendados): um programa em [Sword](https://swordlang.com) (`sword/status/`) faz a mesma consulta da lista de Multijogador, pelo túnel da Cloudflare (`cloudflared access tcp`, como o Modflared), e publica `status.json` no branch `status` (um commit só, trocado a cada vez), que o shields.io desenha; o branch guarda também o histórico das consultas (60 dias) para a página. Os nicks não são publicados | mcsrvstat.us e parecidos (não entram pelo túnel da Cloudflare, e o playit grátis não responde de fora do Brasil), consultar pelo playit (mesmo motivo), o SVG gerado pelo programa (o GitHub guarda imagens em cache e o selo não atualizava) |
| Página com mapa e placar | GitHub Pages (`site/`), publicada pela Action **Pagina**. O `iniciar` sobe o `mundo.tar.gz` para o release `mundo` do repositório **privado** do mundo a cada stop (`scripts/MundoGithub.java`, com o token de `github.txt` no Drive); a Action baixa com o segredo `MUNDO_TOKEN` e os programas de `sword/` tiram dele o mapa, o placar e o céu do último salvamento. O mundo não é publicado, só o que sai dele. Onde cada um saiu do jogo só entra com a variável `MOSTRAR_POSICOES=sim`, porque mostra a base de cada um | Ler o Drive pela API do Google (pede projeto no Google Cloud e mexer no Drive por fora do script do host), mundo no próprio repositório (é público), Release no repositório do pack (público também) |

O que mudou em cada versão: [Releases](https://github.com/EnzoFerroni/minezada/releases). O histórico mais antigo fica no git.
