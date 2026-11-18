# Planos

O que falta fazer, em ordem, e lições aprendidas para mexer no projeto sem quebrar nada.

## Próximos passos

Estado em 2026-11-18: pack `2026.11.18.1`. Testado num Mac M4 (17/11): servidor (subir, MixAuth,
whitelist com UUID oficial, voo), jogo (crash do Chunky + Distant Horizons corrigido, os 7 shaders de
Mac abrem, Photon e Solas não), instalação do `jogar.sh` numa cópia da instância e envio do mundo ao
Drive.

Testado no PC Windows (18/11), já com o túnel como endereço principal: `iniciar.ps1` com o Drive
(troca de host Mac → PC continuou o mesmo mundo, whitelist com UUID oficial, túnel conectado, DuckDNS
limpo, nenhuma porta no roteador, firewall só na rede local, `stop` enviou o mundo e liberou a trava),
`jogar.ps1` com original (memória 4096 com 16 GB, packwiz-installer fixo) e o jogo entrando sozinho
pelo túnel (`Enzobullet joined the game`). Launcher sem original: download e SHA-256 conferidos.
Mundo corrompido: para com aviso, sem trava e sem mexer no local.

1. **Testar no Mac o `iniciar.sh` novo** (túnel primeiro, espera conectar, reserva por UPnP só se
   falhar, DuckDNS limpo) e o `jogar.sh` (copia o `packwiz-installer.jar` fixo). Só a sintaxe foi
   conferida no Windows.
2. **Quem já instalou roda o comando de jogar de novo** (uma vez): o "entrar ao abrir" pelo túnel e o
   packwiz-installer fixo ficam no `instance.cfg`, que o packwiz não atualiza.
3. **Jogar da faculdade com o host em casa**: a rede de lá só libera 80/443 de saída, e o túnel grátis
   usa outra porta. O roteador de casa não repassa a 80 nem a 443 (a 25565 e a 8443 passam). Opções:
   desligar a gerência remota do roteador e testar a 443 de novo; um túnel que escute na 443; ou um
   servidor alugado. Por enquanto: roteador do celular (4G).
4. **Testar o caminho sem original de ponta a ponta**: responder `n`, o fork pede o nick, `/register`,
   morrer, sair e voltar (com o MixAuth deve renascer e pedir `/login`).
5. **Testar o comando de hospedar num PC sem o repo** (`hospedar.ps1`: instala o Git, clona, cria o
   atalho).
6. **Pré-gerar o mundo real** antes de chamar todo mundo: no console do servidor,
   `chunky radius 1500` e `chunky start`. O mundo atual foi gerado antes dos mods de aventura;
   minérios, mobs e estruturas novas só aparecem em terreno ainda não explorado. Se preferir tudo
   desde o início, apagar `mundo.tar.gz` no Drive e `server/world` (os backups ficam).
7. **Convidar os jogadores**: mandar o comando de jogar (README) e liberar cada nick no
   `jogadores.txt` do Drive + restart (não `whitelist add`, ver [hospedar.md](hospedar.md)). Quem
   não tem original e já tinha senha do SimpleLogin registra de novo (senhas não migram). Amigo sem
   original com nick que existe como conta de outra pessoa: `Nick sem-original`. Quem for hospedar
   recebe a pasta `minezada` do Drive.
8. **Livro de missões** (abaixo), depois que a lista de mods estabilizar.

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

1. Editar `modpack/mods.txt` (ou `scripts/perfis.ps1` para perfis) e rodar `scripts/montar-pack.ps1`
   (no Mac `pwsh scripts/montar-pack.ps1`; shader novo: montar, `perfis.ps1`, montar de novo).
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
- **Options Profiles 1.4.2**: só `options.txt` e `iris.properties` nos perfis. `sodium-options.json`,
  `sodium-extra-options.json` e `DistantHorizons.toml` fecham o jogo (APIs removidas no Sodium 0.8,
  Sodium Extra 0.9, DH 3; conferido com `javap`). Do Iris ele só aplica shader e liga/desliga.
  Salvar/Criar perfil no jogo copia essas configs e quebra o perfil.
- **Mod de servidor no cliente** pode quebrar outro mod: Chunky no jogo + Distant Horizons = crash ao
  entrar no mundo. Ferramentas de servidor vão em `$soServidor`.
- **Shader no Mac**: conferir o zip (`#version` acima de 410 ou compute obrigatório não roda) e
  testar sem o Distant Horizons: só de estar instalado ele estoura as 16 texturas do Mac.
- **Rede de faculdade** testada libera só TCP 80/443 de saída: 25565 e playit ficam bloqueados.
- **Tela de HTML ao entrar no servidor**: é a verificação de conta da Mojang falhando (limite de
  logins seguidos ou instabilidade). Esperar alguns minutos ou refazer o login no Prism.
- **PowerShell 5.1**: arrays JSON vêm como um item só (achatar com `ForEach-Object`), `-eq`
  ignora maiúsculas (usar `-ceq`), zip grava `\` (montar à mão com `/`), `.ps1` com acento
  precisa de BOM, `H` é apelido de `Get-History`.

- **Whitelist com MixAuth**: quem tem original entra com o UUID oficial e quem não tem com o
  offline. O `jogadores.txt` + restart libera os dois; `whitelist add` grava só um.
- **SimpleLogin travava quem voltava morto**: ele bloqueia o pacote de renascer antes do login e a
  tela de morte não tem chat. Mod de login novo: conferir se o respawn passa antes do login.
- **Mojang em rede compartilhada** (laboratório) responde `429` na consulta de skin assinada
  (`sessionserver ... ?unsigned=false`); a sem assinatura passa. Por isso a reserva do SkinRestorer.
- **Mod sem lado no Modrinth** (`unknown`, ex: o antigo SimpleLogin) entra nos dois lados; mod só de servidor
  vai em `$soServidor` no `montar-pack.ps1`, senão pede login até no singleplayer.
- **Login lembrado por IP é inseguro com túnel**: pelo playit (e numa faculdade) muitos jogadores
  chegam com o mesmo IP. Com o "mesmo nick + mesmo IP sem senha" qualquer um entrava como outro;
  por isso `trusted_login_window_hours = 0`.
- **Porta aceita por UPnP não quer dizer porta aberta**: o roteador de casa aceitou a 80 e a 443 e não
  repassou. Conferir sempre de fora (`https://api.mcsrvstat.us/3/<host>:<porta>`). O playit grátis
  não responde a esse verificador (fora do Brasil), mas responde de dentro do Brasil.
- **`instance.cfg` não atualiza sozinho**: o packwiz só mexe em `.minecraft`. Mudou o "entrar ao
  abrir", a memória ou o comando do packwiz? Cada um roda o comando de jogar de novo.
- **Logs do PowerShell 5.1 redirecionados com `*>` saem em UTF-16**: ler com `iconv -f UTF-16LE`.

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
