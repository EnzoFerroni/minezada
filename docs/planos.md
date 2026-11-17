# Planos

O que falta fazer, em ordem, e lições aprendidas para mexer no projeto sem quebrar nada.

## Próximos passos

1. **Testar no Mac**: `curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash`
   e, para hospedar, `iniciar.command`. Nada do lado do Mac rodou ainda (Prism no Mac, atalho
   `Minezada.app`, Homebrew/Java, UPnP via `miniupnpc`, `caffeinate`, pasta do Drive).
2. **Pré-gerar o mundo real** antes de chamar todo mundo: no console do servidor,
   `chunky radius 1500` e `chunky start`. O mundo atual foi gerado antes dos mods de aventura;
   minérios, mobs e estruturas novas só aparecem em terreno ainda não explorado. Se preferir tudo
   desde o início, apagar `mundo.tar.gz` no Drive e `server/world` (os backups ficam).
3. **Convidar os jogadores**: mandar o comando de jogar (README) e liberar cada nick no
   `jogadores.txt` do Drive + restart (não `whitelist add`, ver [hospedar.md](hospedar.md)). Quem
   for hospedar recebe a pasta `minezada` do Drive e o token do DuckDNS por mensagem privada.
4. **Testar o caminho sem original** nos dois sistemas: responder `n`, conferir que o fork abre a
   instância, pede o nick e entra no servidor.
5. **Primeiro teste com alguém de fora** entrando por `minezada-mc.duckdns.org` (dentro da casa do
   host o roteador não tem NAT loopback: lá se usa `localhost` ou o IP local).
6. **Livro de missões** (abaixo), depois que a lista de mods estabilizar.

## Livro de missões (tutorial completo do pack)

**Objetivo:** um livro de missões em português, dentro do jogo, que ensine a usar cada mod do pack
em detalhe, do primeiro dia até o fim, para quem nunca jogou com mods.

**Como deve ser**

- Uma trilha por mod ou conjunto de mods (ver [mods.md](mods.md)), cobrindo o que o mod faz, os
  primeiros itens, como evoluir e os truques menos óbvios.
- Ordem: primeiros passos (JEI, Jade, mapa, Waystones, Corpse, perfis de gráfico, Veinminer) →
  baús e mochilas → ferramentas → Create (do moinho às fábricas) → dragões (Wyrmroost) →
  dimensões (Aether, Undergarden, Bumblezone, Ad Astra) → cavernas e minérios → chefes e masmorras
  (Cataclysm, Mowzie's, When Dungeons Arise) → exploração (biomas, estruturas, bússolas).
- Cada missão com objetivo verificável (pegar item, construir bloco, visitar bioma/estrutura,
  matar mob) e recompensa pequena que ajude o próximo passo.
- Texto curto e direto, com dicas de tecla (`R`/`U` no JEI, `W` no Ponder do Create, `'` no
  Veinminer).
- Apontar para o Ponder do Create em vez de repetir o que ele já explica com animação.

**Referências para estudar antes de escrever**

- Livros de missões de modpacks conhecidos com Create, aventura e vanilla+ no Modrinth/CurseForge:
  estrutura das trilhas, tamanho das missões, recompensas.
- Guias oficiais e wikis de cada mod do pack.

**Ferramenta**

- Candidato: Odyssey Quests (está no Modrinth para NeoForge 1.21.1, então entra pelo pack).
- FTB Quests é o padrão dos modpacks, mas não está no Modrinth, e o `.mrpack`/packwiz só baixa
  de lá. Reavaliar se isso mudar.
- As missões entram em `modpack/arquivos/` (como os perfis de gráfico) e chegam a todos pela
  atualização automática. Atenção: lá os arquivos têm `preserve = true`; para missões que devem
  sempre atualizar, criar uma pasta separada sem `preserve`.

## Mais mods

Em aberto. Cada candidato precisa existir no Modrinth para NeoForge 1.21.1 e passar no checklist
abaixo. Ideias já levantadas e não colocadas: Simple Voice Chat (exige abrir porta UDP),
Iron's Spells (complexo para iniciantes), Eternal Starlight (dimensão nova, menos testada).

## Checklist para mudar o pack

1. Editar `modpack/mods.txt` (ou `scripts/perfis.ps1` para perfis) e rodar `scripts\montar-pack.ps1`.
2. Conferir na saída se não entrou `connector` / `forgified-fabric-api` (mod Fabric disfarçado).
3. Testar o **servidor** (`iniciar` numa cópia com mundo novo) até aparecer `Done`.
4. Testar o **jogo**: push, esperar o link raw do GitHub atualizar (até 5 min de cache), abrir o
   jogo e entrar num servidor de teste. Erros de dependência só aparecem no jogo.
5. Anotar no histórico de [decisoes.md](decisoes.md), commit e push.

## Lições aprendidas (para não repetir erro)

- **Dependências com o lado errado no Modrinth** (ex: Lithostitched marcado "só servidor"): o
  `montar-pack.ps1` já faz a dependência herdar os lados de quem precisa dela.
- **Dependência não declarada ou incompatível** (Sodium Dynamic Lights × Reese's Sodium Options):
  só aparece abrindo o jogo. Quando dois mods brigam, tirar o opcional.
- **NeoForge novo demais**: o Prism só abre versões que já estão no meta dele; o script escolhe o
  NeoForge pelo meta do Prism, não pelo último publicado.
- **Cache do GitHub raw**: o link normal demora até 5 minutos para mostrar o push novo; o
  packwiz usa o link normal, então testar só depois disso.
- **Renomear perfis** deixa os perfis antigos misturados no jogo de quem já tinha (arquivos com
  `preserve` não são apagados). Evitar renomear; se precisar, avisar para apagar os antigos.
- **Options Profiles + Sodium 0.8**: não colocar `sodium-options.json` nos perfis (o jogo fecha).
- **Tela de HTML ao entrar no servidor**: é a verificação de conta da Mojang falhando (limite de
  logins seguidos ou instabilidade). Esperar alguns minutos ou refazer o login no Prism.
- **PowerShell 5.1**: arrays JSON vêm como um item só (achatar com `ForEach-Object`), `-eq`
  ignora maiúsculas (usar `-ceq`), zip grava `\` (montar à mão com `/`), `.ps1` com acento
  precisa de BOM, `H` é apelido de `Get-History`.

- **`whitelist add` em modo offline** grava o UUID da Mojang quando o nick existe como conta
  original, e a pessoa fica barrada. Liberar sempre pelo `jogadores.txt` + restart.
- **Mojang em rede compartilhada** (laboratório) responde `429` na consulta de skin assinada
  (`sessionserver ... ?unsigned=false`); a sem assinatura passa. Por isso a reserva do SkinRestorer.
- **Mod sem lado no Modrinth** (`unknown`, ex: SimpleLogin) entra nos dois lados; mod só de servidor
  vai em `$soServidor` no `montar-pack.ps1`, senão pede login até no singleplayer.

## Ideias para melhorar no futuro

- **GitHub Action** que roda o `montar-pack` e sobe um servidor de teste a cada push, para pegar
  erro de dependência antes de chegar nos jogadores.
- **Changelog dentro do jogo** (ou no README) com o que mudou em cada versão do pack.
- **Fixar as versões dos mods** (hoje o `montar-pack` pega a versão mais nova a cada geração);
  útil quando o pack estiver estável, para atualizar só quando quiser.
- **Host dedicado** (VPS no Brasil) se o PC de casa virar gargalo ou os jogadores quiserem servidor
  sempre ligado: o mesmo `iniciar.sh` roda em Linux.
- **Skins sem depender de limite (CustomSkinLoader)**: hoje o SkinRestorer (servidor) assina as
  skins pela Mojang e, se ela bloquear (`429` em rede compartilhada, como no laboratório), pelo
  MineSkin, que tem limite sem chave de API. O `customskinloader` (só cliente, tem NeoForge 1.21.1)
  busca as skins em cada jogo pela consulta sem assinatura da Mojang, que não foi bloqueada, sem
  MineSkin. Sem original: skin em pasta local ou conta Ely.by. Custo: entra no pack de todos; quem
  não tiver o mod vê Steve. Dá para manter os dois (um cobre o outro). Alternativa menor: chave grátis
  do MineSkin guardada no Drive (não no repo público), como o segredo do playit.
