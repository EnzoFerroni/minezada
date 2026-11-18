# Como mexer no projeto

## Onde fica cada coisa

- **O que falta fazer**: [issues](https://github.com/EnzoFerroni/minezada/issues), no [quadro do projeto](https://github.com/users/EnzoFerroni/projects/3) (Ideias, A fazer, Fazendo, Feito). Milestone
  **Abrir para os amigos** = o que falta antes de chamar todo mundo; **Depois** = melhorias. Label
  `ideia` = ainda não decidido. Labels de área: `servidor`, `jogo`, `rede`, `mac`, `windows`.
- **O que mudou em cada versão do pack**: [Releases](https://github.com/EnzoFerroni/minezada/releases)
  (antes de `2026.11.18.1`: histórico em [docs/decisoes.md](../docs/decisoes.md)).
- **Por que cada coisa é assim**: [docs/decisoes.md](../docs/decisoes.md). Mudou uma decisão? Atualize lá.
- **Como usar**: [README](../README.md) e [docs/](../docs).
- **Pack**: `modpack/mods.txt` é a lista de mods (fonte da verdade). `modpack/minezada.mrpack`, `modpack/pack/`,
  `modpack/minezada-prism.zip` e `docs/mods.md` são gerados pelo `scripts/montar-pack.ps1`: não edite à mão.
  Perfis de gráfico: tabela em `scripts/perfis.ps1` (gera `modpack/arquivos/`). Configuração do servidor:
  `server-config/` (copiada para `server/` a cada start). O servidor no Windows instala o `.mrpack`; o do
  Mac e os jogadores instalam pelo `pack/` (packwiz).

Commits sem dados pessoais: autor com o e-mail `noreply` do GitHub
(`git config user.email 125482399+EnzoFerroni@users.noreply.github.com`) e nada de IP local,
operadora, token ou e-mail nos arquivos. O `main` é protegido: sem force push.

## Checklist para mudar o pack

1. Editar `modpack/mods.txt` (ou `scripts/perfis.ps1` para perfis) e rodar `scripts/montar-pack.ps1 -Versao AAAA.MM.DD.N`
   (no Mac `pwsh scripts/montar-pack.ps1`; shader novo: montar, `perfis.ps1`, montar de novo).
2. As versões ficam fixas: cada mod repete a do pack atual e só mod novo pega a mais nova. Para atualizar
   tudo, rode com `-Atualizar`. Ler a lista **Mudanças desde o pack anterior**: versão nova de mod é código novo no
   PC de todos. Conferir se não entrou `connector` / `forgified-fabric-api` (mod Fabric disfarçado).
3. Testar o **servidor** (`iniciar`) até aparecer `Done`. A Action **Servidor de teste** também faz isso
   sozinha a cada push que mexe no pack (aba Actions; falhou, o GitHub avisa por e-mail).
4. Testar o **jogo**: push, esperar o link raw do GitHub atualizar (até 5 min de cache), abrir o
   jogo e entrar no servidor. Erros de dependência só aparecem no jogo.
5. Criar o Release: `gh release create vAAAA.MM.DD.N --title "Pack AAAA.MM.DD.N" --notes "o que mudou"`.
   Mudou o `instance.cfg` (memória, endereço, comando do packwiz)? Avisar para todos rodarem o
   comando de jogar de novo.

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

- **Modflared precisa que o nome resolva**: ele intercepta depois que o jogo resolve o endereço. O nome do
  jogador (`minezada.dpdns.org`) tem CNAME do túnel **e** o TXT `cloudflared-route=...`. Subdomínio não aceita
  CNAME e TXT juntos; o domínio raiz aceita (a Cloudflare achata o CNAME).
- **`cloudflared`: opções globais antes do `run`** (`tunnel --no-autoupdate --logfile X run --token-file Y`);
  na ordem errada ele fecha na hora. O host precisa de saída na 7844; o jogador só na 443.
- **Simular rede de faculdade**: regras de saída no firewall bloqueando, só para o Java do Prism e o
  `cloudflared` do Modflared, as portas `1-52,54-79,81-442,444-65535` para `Internet`. Conferir com um
  teste de porta rodando no mesmo `javaw`.
- **Mod novo com lado do servidor: testar entrando num servidor dedicado de verdade.** O Odyssey Quests
  funciona em mundo de um jogador e derruba todo jogador em servidor dedicado (Heracles#292). A Action só
  sobe o servidor; o erro só aparece no jogo, então push só depois de entrar e ficar no servidor.
- **Logo depois de um push o link raw pode entregar o pack antigo por alguns minutos** (cada servidor de
  borda do GitHub atualiza numa hora). Jogo e servidor com packs diferentes = "Incompatible client". Fechar
  e abrir de novo depois de uns minutos resolve.
- **Servidor na janela própria (Windows)**: a etapa do servidor roda escondida (`iniciar.ps1 -Rodar`); para
  desligar por script, feche a janela "Minecraft server" (`(Get-Process java).CloseMainWindow()`).
