# Decisões

Registro do que escolhemos e por quê, para lembrar no futuro o que estamos jogando.

## Objetivo do pack

Vanilla melhorado para até 8 jogadores, a maioria iniciante e no Mac (M1+ com 16 GB).
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
| Dragão pet que voa | Wyrmroost (choca ovo, cria, cresce, monta e voa) | Cobblemon (Pokémon fugia do estilo do pack), Ice and Fire e Dragon Mounts (sem versão NeoForge 1.21.1), Tiny Dragons (não voa) |
| Upgrade de baú | Sophisticated Storage já faz: itens de upgrade de tier (madeira → ferro → ouro → diamante → netherite) aplicados no baú sem tirar os itens | Iron Chests (redundante) |
| Dimensões novas | The Aether | Twilight Forest (só no CurseForge, e o `.mrpack` só baixa do Modrinth), Blue Skies e Deeper and Darker (sem versão NeoForge 1.21.1), Bumblezone (disponível; fica como opção) |
| Biomas e terreno | Terralith + Tectonic (vanilla+, roda só no servidor) | Biomes O' Plenty e Oh The Biomes We've Gone (mais pesados e fogem do visual vanilla) |
| Estruturas | Série YUNG's, Towns and Towers, Explorify (só no servidor) | Repurposed Structures (muita coisa, pesa na geração) |
| Visual e ambiente | Fresh Animations (ligado por padrão) + EMF/ETF, 3D Skin Layers, Ambient Sounds, Sodium Dynamic Lights | Continuity (no NeoForge exige o Sinytra Connector, instável), Falling Leaves (port NeoForge pouco usado) |
| Shaders | Complementary Reimagined e MakeUp Ultra Fast, instalados e desligados | Ligados por padrão (pesam em Mac e PC fraco) || Facilidade | Waystones, Xaero's Minimap/World Map, Corpse, Mouse Tweaks, Inventory Profiles Next, Farmer's Delight | Gravestone (Corpse é mais simples) |
| Desempenho | Sodium, Lithium, FerriteCore, ModernFix, EntityCulling, ImmediatelyFast, Iris (shaders opcionais) | - |

Lista completa com versões e links: seção **Mods** do [README](../README.md).

## Como o pack é montado

- Fonte da verdade: [`modpack/mods.txt`](../modpack/mods.txt). O script
  [`scripts/montar-pack.ps1`](../scripts/montar-pack.ps1) pega no Modrinth a versão release mais
  nova de cada mod para NeoForge 1.21.1, adiciona dependências obrigatórias e gera o `.mrpack`.
- Mods marcados "server unsupported" no Modrinth (Sodium, Iris, minimapa de cliente...) ficam só no
  cliente; o mrpack-install pula eles no servidor.

## Hospedagem e rede

| Tema | Decisão | Alternativas descartadas |
|---|---|---|
| Onde hospedar | PC de casa (Windows, cabo); Mac ou amigo quando o PC estiver desligado | Host pago em SP (~R$ 41/mês), exaroton (sem região Brasil, ping alto) |
| Mundo entre hosts | Google Drive (`mundo.tar.gz` + trava `host.lock` + 5 backups) | GitHub (arquivo > 100 MB, histórico pesado), Git LFS (1 GB grátis), GitHub Releases (exige `gh` e login em cada host) |
| Endereço fixo | DuckDNS `minezada-mc`, atualizado pelo host durante a sessão | DDNS do roteador (só DynDNS pago / No-IP com confirmação mensal) |
| Porta | UPnP pelo próprio script (SOAP direto no roteador) | playit.gg (túnel grátis fora do Brasil, 300-400 ms), e4mc (feito para LAN) |
| Instalar servidor | mrpack-install a cada start (idempotente) | baixar mods à mão |
| Instalar no jogador | Prism Launcher + `minezada-prism.zip`; packwiz no pre-launch sincroniza os mods a cada abertura pelo link raw do GitHub (por isso o repo é **público**) | Modrinth App (sem atualização automática; pack não listado passa por moderação), launcher oficial (não instala mods), repo público separado (mais coisa para manter) |

## Histórico do pack

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
| 2026-11-17 | 2026.11.17.9 | Correção: dependência herda os lados de quem precisa dela (Lithostitched faltava no cliente); + Reese's Sodium Options (exigido pela luz dinâmica). |
