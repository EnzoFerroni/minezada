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

## Mods: escolhas e descartes

| Pedido | Escolhido | Descartado (motivo) |
|---|---|---|
| Create com tutorial | Create (Ponder embutido: animações explicando cada bloco) | - |
| Guias e receitas | JEI, Jade, AppleSkin, Better Advancements | EMI (JEI tem integração com Create) |
| Livro de missões | **Pendente**: Odyssey Quests com trilha em português escrita por nós | FTB Quests (não está no Modrinth, e `.mrpack` só baixa de lá) |
| Baús maiores | Sophisticated Storage + Backpacks | - |
| Sistema de baú | Tom's Simple Storage (terminal com busca, fácil) | Refined Storage e AE2 (complexos para iniciantes) |
| Ferramentas melhores | Just Hammers (3x3), Advanced Netherite, Veinminer | Tinkers' Construct (sem versão 1.21.1), Silent Gear (complexo) |
| Dragão pet que voa | Dragon Mounts Remastered (desde 2026-11-19): o mais simples e com cara de vanilla, doma com peixe, apito para chamar, só precisa do GeckoLib | Wyrmroost (poucos dragões prontos e difícil de domar), Ice and Fire CE (o mais famoso, mas pesado, com dragões que quebram o terreno e muitas outras criaturas), Book of Dragons (estilo Como Treinar o Seu Dragão, domar é um processo longo), Cobblemon (Pokémon fugia do estilo do pack), Tiny Dragons (não voa) |
| Upgrade de baú | Sophisticated Storage já faz: itens de upgrade de tier (madeira → ferro → ouro → diamante → netherite) aplicados no baú sem tirar os itens | Iron Chests (redundante) |
| Dimensões novas | The Aether | Twilight Forest (só no CurseForge, e o `.mrpack` só baixa do Modrinth), Blue Skies e Deeper and Darker (sem versão NeoForge 1.21.1), Bumblezone (derrubava o servidor e confunde iniciantes) |
| Biomas e terreno | Terralith + Tectonic (vanilla+, roda só no servidor) | Biomes O' Plenty e Oh The Biomes We've Gone (mais pesados e fogem do visual vanilla) |
| Estruturas | Série YUNG's, Towns and Towers, Explorify (só no servidor) | Repurposed Structures (muita coisa, pesa na geração) |
| Visual e ambiente | Fresh Animations (ligado por padrão) + EMF/ETF, 3D Skin Layers, Ambient Sounds | Continuity (no NeoForge exige o Sinytra Connector, instável), Sodium Dynamic Lights (o Options API dele exige o Reese's, que se declara incompatível com ele), Falling Leaves (port NeoForge pouco usado) |
| Perfis de gráfico | Options Profiles com 19 perfis gerados por `scripts/perfis.ps1` em `modpack/arquivos/options-profiles`: 1-9 (Minimo a Ultra Shader, FPS Maximo, Bateria), Mac 1-7 (Apple Silicon, VSync ligado), Shader - (um por shader) e PC - (shaders que não rodam no Mac). Aplicam só `options.txt` e o shader do Iris | Configurar só o `options.txt` inicial (não deixa trocar de perfil no jogo). Sodium, Sodium Extra e Distant Horizons nos perfis: o Options Profiles 1.4.2 chama APIs que o Sodium 0.8, o Sodium Extra 0.9 e o DH 3 removeram (conferido nos jars) e o jogo fecha; pelo mesmo motivo Salvar/Criar perfil no jogo quebra |
| Mac | Sodium Extra com `reduce_resolution_on_mac` ligado na primeira instalação (sem Retina: bem mais FPS) | Retina ligado (FPS baixo em Mac base) |
| Shaders | Instalados e desligados. Rodam no Mac (GLSL até 4.10, conferido nos zips e todos testados no jogo num Mac M4): Complementary Reimagined, MakeUp, BSL. Só PC (exige OpenGL 4.3): Photon (testado: não abre no Mac, o jogo segue sem shader); Bliss abriu no M4, mas o autor diz suporte limitado no Mac | Ligados por padrão (pesam em Mac e PC fraco), Mellow e Noble (sem Mac e pouco usados). Complementary Unbound, Sildur's Vibrant, Super Duper Vanilla, Miniature, Solas e Rethinking Voxels (saíram em 2026-11-19: escolha demais para iniciante) |
| Ver longe | Distant Horizons só no jogo de cada um; Chunky só no servidor (com os dois no jogo, o DH chama a API do Chunky e o jogo fecha ao entrar). Opcional no PC (janela do packwiz na primeira abertura, vem desmarcado); desligado no Mac pelo `jogar.sh` (fechou o jogo em um M4): no Mac o Iris reserva as texturas do DH só por ele estar instalado, mesmo com a renderização desligada, e passa do limite de 16 (testado no M4) | DH no servidor (gera terreno distante para todos: pesado com Terralith/Tectonic num PC de casa) |
| Pacotes de recursos | Todos ligados: Faithful 32x (base), Default Dark Mode, Fast Better Grass, Simple Grass Flowers, Better Leaves, 3D Crops, Better Lanterns, Cubic Sun & Moon, Fresh Waystones, Low Shield, Low On Fire, Fresh Animations + Extensions | Visual Armor Trims e pacotes de livros encantados (precisam de CIT Resewn, sem NeoForge), Dramatic Skys (precisa de mod de céu) |
| Aventura | Dimensões: Undergarden, Ad Astra, Deep Aether, Incendium (Nether), Nullscape (End). Cavernas: Galosphere. Mobs: Naturalist, Mowzie's Mobs, Aquamirae, Adorable Hamster Pets. Estruturas e tesouro: When Dungeons Arise, Artifacts | Spelunkery e L_Ender's Cataclysm (saíram em 2026-11-19: mudam a mineração e chefes difíceis demais para iniciantes), Alex's Mobs, Friends & Foes, Bosses of Mass Destruction (sem 1.21.1), Iron's Spells (complexo para iniciantes), Eternal Starlight (novo, menos testado) |
| Facilidade | Waystones, Xaero's Minimap/World Map, Corpse, Mouse Tweaks, Inventory Essentials, Farmer's Delight; QoL de servidor: Controlling (busca de teclas), bússolas de bioma e estrutura, Ping Wheel, Carry On, Clumps, Pick Up Notifier, Chat Heads, Comforts, Trade Cycling, Easy Anvils | Gravestone (Corpse é mais simples), Inventory Profiles Next (setas roxas na hotbar), Simple Voice Chat (exige abrir outra porta UDP; os jogadores usam Discord) |
| Desempenho | Sodium, Lithium, FerriteCore, ModernFix, EntityCulling, ImmediatelyFast, Iris, Sodium Extra, More Culling, Dynamic FPS; servidor: Noisium, Chunky (pré-geração), spark (medição), flags do Aikar, view 8 / simulação 6, sync-chunk-writes=false | C2ME e ServerCore (só Fabric), Krypton e FastQuit (sem 1.21.1) |

Lista completa com versões e links: [mods.md](mods.md).

## Como o pack é montado

- Fonte da verdade: [`modpack/mods.txt`](../modpack/mods.txt). O script
  [`scripts/montar-pack.ps1`](../scripts/montar-pack.ps1) pega no Modrinth a versão release mais
  nova de cada mod para NeoForge 1.21.1, adiciona dependências obrigatórias e gera o `.mrpack`.
- Mods marcados "server unsupported" no Modrinth (Sodium, Iris, minimapa de cliente...) ficam só no
  cliente; o servidor pula eles (mrpack-install no Windows, packwiz `-s server` no Mac).

## Hospedagem e rede

| Tema | Decisão | Alternativas descartadas |
|---|---|---|
| Onde hospedar | PC de casa (Windows, cabo); Mac ou amigo quando o PC estiver desligado | Host pago em SP (~R$ 41/mês), exaroton (sem região Brasil, ping alto) |
| Mundo entre hosts | Google Drive (`mundo.tar.gz` + trava `host.lock` + 5 backups) | GitHub (arquivo > 100 MB, histórico pesado), Git LFS (1 GB grátis), GitHub Releases (exige `gh` e login em cada host) |
| Endereço | **Cloudflare Tunnel** `minezada.dpdns.org` (18/11, grátis): domínio grátis da DigitalPlat na conta grátis da Cloudflare, `cloudflared` no host e o mod Modflared no jogador. A conexão vai como HTTPS na 443, então passa em rede de faculdade (testado simulando só 80/443) e até com inspeção de tráfego. Host em qualquer rede com saída na 7844, nenhuma porta aberta, IP de casa escondido. Depois: playit.gg (`molecule-spindle.tun.ply.gg`). Reserva: DuckDNS `minezada-mc` com UPnP, só se nenhum túnel conectar | Domínio pago (sem gasto por enquanto), playit Premium com IP dedicado (~US$ 9/mês, não passa inspeção de tráfego), VPS grátis da Oracle (pede cartão, servidor público para manter, não passa inspeção), Cloudflare Spectrum (US$ 20/mês), quick tunnel da Cloudflare (só HTTP), GitHub Pages (só site estático), DuckDNS + UPnP como principal (expõe o IP de casa) |
| Porta (reserva) | UPnP pelo próprio script (SOAP direto no roteador) só na 25565, com regra de firewall para a internet só durante a reserva. A 443 saiu: o roteador de casa não repassa a 80 nem a 443 (testado em 18/11) e a Cloudflare cobre a faculdade | Porta aberta sempre (firewall da 25565 fica só para a rede local), e4mc (feito para LAN) |
| Instalar servidor | A cada start (idempotente): mrpack-install no Windows; no Mac instalador do NeoForge + packwiz, porque o mrpack-install usa DNS próprio e falha com o DNS IPv6 quebrado de roteadores de operadora | baixar mods à mão |
| Conta | `online-mode=false` + MixAuth: original entra direto (Mojang confirma, UUID oficial, skin), sem original usa senha (BCrypt) a cada entrada; "lembrar por IP" desligado porque o túnel e redes de faculdade dão o mesmo IP a todos. Whitelist pelo `jogadores.txt`: nick com original libera só o UUID oficial (progresso copiado do offline), sem original o offline. Testado no Mac e no Windows | SimpleLogin (bloqueia o renascer antes do login: quem volta morto fica preso; sessão só na memória), PAuth e i-server-login (menos usados, sem histórico), `online-mode=true` (só original), offline sem login (qualquer um entra com o nick do admin) |
| Skins no modo offline | SkinRestorer no servidor: Mojang, depois mc-heads + MineSkin; skin salva no mundo, sem buscar de novo ao entrar | CustomSkinLoader no cliente (ideia na [issue #14](https://github.com/EnzoFerroni/minezada/issues/14)) |
| Instalar no jogador | Prism Launcher + `minezada-prism.zip`; packwiz no pre-launch sincroniza os mods a cada abertura pelo link raw do GitHub (por isso o repo é **público**) | Modrinth App (sem atualização automática; pack não listado passa por moderação), launcher oficial (não instala mods), repo público separado (mais coisa para manter) |
| Launcher sem original | O comando de jogar pergunta. Sem original instala o [PrismLauncher-Cracked](https://github.com/Diegiwg/PrismLauncher-Cracked) (fork do Prism sem exigir conta Microsoft; binários do GitHub Actions) em pasta própria (`~/Applications/Minezada`, `%LOCALAPPDATA%\Programs\Minezada Launcher`). Mesmo formato de instância e mesma pasta de dados do Prism: mesmo zip e atualização automática. Sem conta, ele pede o nick ao abrir. Baixado de novo a cada execução do comando | Prism oficial (conta offline sem Microsoft abre em modo Demo), Fjord Launcher (exige Microsoft também), HMCL (outro formato, sem packwiz), importar o `.mrpack` à mão (sem atualização), TLauncher (histórico de malware). Risco: fork mantido por uma pessoa só |

## Histórico do pack

Daqui em diante cada versão vira um [Release](https://github.com/EnzoFerroni/minezada/releases). Esta tabela guarda o histórico até `2026.11.18.1`.

| Data | Versão | Mudança |
|---|---|---|
| 2026-11-17 | 2026.11.17 | Primeira versão: Create, Sophisticated, Tom's Storage, Wyrmroost, ferramentas, QoL e desempenho. Servidor testado (sobe sem erros). |
| 2026-11-17 | 2026.11.17.1 | + The Aether. Servidor testado. |
| 2026-11-17 | 2026.11.17.2 | Projeto renomeado para Minezada: repo, instância, MOTD e pasta do Drive. |
| 2026-11-17 | 2026.11.17.3 | Endereço novo: `minezada-mc.duckdns.org`. |
| 2026-11-17 | 2026.11.17.4 | Endereço `minezada-mc.duckdns.org`; docs mais enxutas. Vitrine de mods em `docs/mods.md`. |
| 2026-11-17 | 2026.11.17.5 | Comando de jogar instala sem diálogo, pré-configura o Prism (pt-BR, Java automático), cria atalho e abre o jogo; checksum do mrpack-install. |
| 2026-11-17 | 2026.11.17.6 | NeoForge escolhido pelo meta do Prism (21.1.266): o 21.1.267 ainda não estava lá e a instância não abria. |
| 2026-11-17 | 2026.11.17.7 | Memória do jogo 4 GB (6 GB disparava o aviso de pouca RAM do Prism em máquinas de 16 GB). |
| 2026-11-17 | 2026.11.17.8 | + Terralith, Tectonic, estruturas (YUNG's, Towns and Towers, Explorify), Fresh Animations, 3D Skin Layers, Ambient Sounds, luz dinâmica e shaders desligados. Mundo novo. Servidor testado. |
| 2026-11-17 | 2026.11.17.9 | Correção: dependência herda os lados de quem precisa dela (Lithostitched faltava no cliente). Sem luz dinâmica (conflito Sodium Options API × Reese's). |
| 2026-11-17 | 2026.11.17.11 | + aventura: 5 dimensões/renovações, cavernas e minérios, mobs, chefes e masmorras. Servidor testado. |
| 2026-11-17 | 2026.11.17.12 | + QoL de servidor e 4 shaders; IPN trocado por Inventory Essentials; jogar liga os pacotes de recursos do pack em quem já tinha options.txt. |
| 2026-11-17 | 2026.11.17.13 | Perfis de gráfico, otimização do jogo e do servidor (flags do Aikar, distâncias, Noisium, Chunky, spark). |
| 2026-11-17 | 2026.11.17.14 | Perfis sem `sodium-options.json`: o Options Profiles 1.4.2 usa uma API que o Sodium 0.8 removeu e o jogo fechava ao aplicar o perfil. |
| 2026-11-17 | 2026.11.17.15 | 9 perfis de gráfico, gerados por `scripts/perfis.ps1`. |
| 2026-11-17 | 2026.11.17.16 | Minecraft não original: `online-mode=false`, + SimpleLogin (só servidor), whitelist com UUID offline e progresso migrado. + Better Search. Servidor testado. |
| 2026-11-17 | 2026.11.17.17 | + SkinRestorer (skins no modo offline). Servidor testado. |
| 2026-11-17 | 2026.11.17.18 | SkinRestorer com reserva mc-heads + MineSkin quando a Mojang bloqueia; `server-config/` copia subpastas. |
| 2026-11-17 | (pack igual) | Comando de jogar pergunta se tem original; sem original instala o PrismLauncher-Cracked e ganha atualização automática (pack igual). |
| 2026-11-17 | 2026.11.17.19 | `allow-flight` (voo de dragão e montaria); shaders conferidos para Mac + Complementary Unbound, Super Duper Vanilla, Miniature, Bliss, Rethinking Voxels; 13 pacotes de recursos ligados; Distant Horizons (só cliente, opcional); Chunky só no servidor; 24 perfis; porta 443; telas de primeira abertura puladas; NeoForge 21.1.267; SimpleLogin trocado pelo MixAuth. Servidor e jogo testados no Mac. |
| 2026-11-17 | 2026.11.17.20 | Lista de servidores (DuckDNS, :443, playit, localhost) pelo packwiz para todos; consulta de UUID oficial com dois endereços da Mojang e aviso quando falha. |
| 2026-11-17 | (pack igual) | Segurança: nick com original libera só o UUID oficial (o offline deixava qualquer um registrar senha com o nick de quem tem original e herdar o op); `sem-original` no `jogadores.txt`; launcher sem original com versão fixa e SHA-256; senha mínima 6. |
| 2026-11-18 | (pack igual) | Segurança: MixAuth pede senha toda vez (o "lembrar por IP" deixava entrar com o nick de outro pelo túnel); túnel playit no Windows. |
| 2026-11-18 | 2026.11.18.1 | Túnel playit como endereço principal (UPnP e DuckDNS só de reserva, firewall só na rede local); packwiz-installer com versão fixa e SHA-256; `montar-pack` mostra mods que mudaram; Bumblezone 7.19.1. Servidor e jogo testados no Windows (entrou pelo túnel). |
