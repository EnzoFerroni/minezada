# Hospedar o servidor

**Windows** (PowerShell)

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/hospedar.ps1 | iex
```

**Mac** (Terminal)

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/hospedar.sh | bash
```

Ele instala o Git (Windows) ou as ferramentas de linha de comando da Apple (Mac), baixa o repo em
`Minezada-servidor` na pasta do usuário, cria o atalho **Hospedar Minezada** na Área de Trabalho e
sobe o servidor. Das próximas vezes, clique no atalho (ou em `iniciar.bat` / `iniciar.command`).

**Desligar: feche a janela do servidor ou digite `stop` nela.** No Windows é a janela "Minecraft server" (a do
`iniciar` pode ser fechada depois que o servidor abre); no Mac é a do Terminal, e Ctrl+C também serve. O servidor
salva, o mundo volta para o Drive (com backup dos 5 últimos) e a trava é liberada. Registro da rede e do envio:
`server/logs/iniciar.log` (no Mac, o que acontece depois de fechar a janela).

## Do que precisa

| Item | Mínimo | Quem resolve |
|------|--------|--------------|
| Git | qualquer | O comando de hospedar instala. |
| Java 21+ | - | O `iniciar` baixa o JDK 25 para `tools/` se faltar ou for antigo, sem instalador nem administrador (Windows e Mac). |
| RAM | 16 GB | O servidor usa 6-8 GB. Jogar e hospedar na mesma máquina aperta. |
| Disco | SSD, ~10 GB | O mundo cresce com o tempo. |
| Rede | cabo, upload ≥ 10 Mbps | Wi-Fi funciona, mas oscila mais. |
| Google Drive | pasta `minezada` | O `iniciar` oferece configurar (abaixo). Sem ele o mundo fica só nesta máquina. |

## O que o `iniciar` faz

1. Atualiza o repo (`git pull`).
2. Na primeira vez: cria `config.env` (RAM e pasta do Drive) e pergunta do EULA.
3. Baixa o Java (JDK 25) para `tools/` se faltar.
4. Instala/atualiza o NeoForge (instalador oficial) e os mods (packwiz, o mesmo do jogo), igual no
   Windows e no Mac.
5. Baixa o mundo do Drive e trava para ninguém mais hospedar junto.
6. Liga os túneis da Cloudflare e do playit.gg
   (veja **Rede**).
7. Libera na whitelist quem está no `jogadores.txt` e sobe o servidor sem deixar a máquina suspender.

## Liberar jogadores

1. Abra `jogadores.txt` na pasta `minezada` do Drive.
2. Escreva o nick numa linha nova, **igual ao do jogo, com as maiúsculas** (`Nick op` também dá
   admin). Não sabe o nick exato? Peça para a pessoa tentar entrar: o console mostra
   `Disconnecting Nick (...): You are not white-listed`.
3. Pronto: com o servidor ligado, em até 30 segundos o nick é liberado (o console mostra
   `jogadores.txt mudou`). Desligado, ele é liberado no próximo start, em qualquer host. Admin (`op`)
   novo pela lista vale a partir do próximo start.

Pelo jogo também dá: quem é op digita `/whitelist add Nick` no chat, e em até 30 segundos o nick vai
sozinho para o `jogadores.txt` e passa pela mesma conferência. Funciona para quem tem Minecraft
original. Sem original, o servidor grava o nick em minúsculas: se o nick tem maiúsculas, escreva ele
certo no `jogadores.txt`. Para dar admin na hora, use `/op Nick` com a pessoa online.

A conferência pergunta à Mojang se o nick tem conta original. Se tiver, libera só o UUID oficial (e
copia para ele o progresso antigo do UUID offline). Se não tiver, libera o UUID offline, e a pessoa usa
senha. Amigo sem original com um nick que por acaso existe como conta de outra pessoa: escreva
`Nick sem-original`. Se a Mojang não responder, o nick fica como estava até a próxima mudança ou start.
Tirar alguém: `/whitelist remove Nick` (ou `/deop Nick`) e tirar da lista.

**Login (MixAuth).** O servidor aceita Minecraft não original (`online-mode=false`), então o nick
sozinho não prova quem é a pessoa:
- Quem tem original: a Mojang confirma a conta e a pessoa entra direto, com o UUID oficial e a skin.
  Se a Mojang estiver fora do ar, esse jogador não entra até ela voltar.
- Quem não tem: `/register senha senha` na primeira vez e `/login senha` sempre que entrar. O
  "lembrar por IP" fica desligado: pelo túnel e em rede de faculdade todos chegam com o mesmo IP, e
  qualquer um entraria com o nick de outro. Peça para registrar logo que for liberado, senão outro
  pode registrar o nick.
- Antes do login a pessoa fica em espectador, parada e cega. Morreu e saiu? Ao voltar ela consegue
  renascer e logar.
- Senha mínima de 6 caracteres; 5 erros bloqueiam o nick por 5 minutos. Configuração em
  `server-config/config/mixauth-server.toml`.

**Skins.** Sem conta verificada a Mojang não manda a skin, então o SkinRestorer busca pelo nick ao
entrar pela primeira vez: Mojang e, se ela bloquear (`429` em rede compartilhada, como a de
laboratório), a imagem do mc-heads assinada pelo MineSkin. A skin fica salva no mundo. Configuração
em `server-config/config/skinrestorer/config.json`.

## Rede

Duas entradas, nesta ordem. Tudo grátis, o roteador não abre porta nenhuma e o IP de casa não aparece.

**1. Principal: `minezada.dpdns.org` (túnel da Cloudflare).** É o primeiro da lista de servidores do jogo. O mod
Modflared (no pack) lê o registro TXT do domínio (`cloudflared-route=mc.minezada.dpdns.org`), baixa o
`cloudflared` oficial (confere o hash) e conecta como HTTPS comum na porta 443. Por isso passa em
rede de faculdade, empresa e Wi-Fi público, até nas que inspecionam o tráfego. No host, o `iniciar`
baixa o `cloudflared` (versão fixa, SHA-256) para `tools/cloudflared` e liga o túnel com o token de
`cloudflare.txt` na pasta do Drive (`--token-file`, o token não aparece na lista de processos). O host
precisa de saída na porta 7844 (UDP ou TCP), livre em casa. Painel: conta Cloudflare do dono, domínio
grátis `minezada.dpdns.org` (DigitalPlat), túnel `minezada` com a rota `mc.minezada.dpdns.org` →
`tcp://localhost:25565`. Perdeu o token? Painel → Tunnels → `minezada` → gerar de novo e salvar em
`cloudflare.txt`.

**2. `molecule-spindle.tun.ply.gg` (túnel playit.gg).** Ligado junto, para quem não conseguir pela
Cloudflare (entrada **Minezada (playit)**). Usa outra porta, então não passa em rede que só libera
80/443. O segredo do agente fica em `playit.txt` e o endereço em `playit-endereco.txt`, na pasta do
Drive. Plano grátis: a rota não é garantida para quem está longe. Perdeu o segredo?
`playit claim generate`, `playit claim url <código>`, aprove no site e `playit claim exchange <código>`:
a última linha da saída é o segredo novo.

**Mesma casa.** O host entra por **Minezada (neste computador)** (`127.0.0.1`). Outro computador da mesma
casa entra pelo túnel, como todo mundo (**Minezada**).

**Lista de servidores do jogo.** Vem pronta e se atualiza a cada abertura (packwiz): Minezada
(Cloudflare), Minezada (playit) e Minezada (neste computador). Servidor adicionado
à mão some na próxima abertura. Mudou algum endereço? Troque `$servidor` ou `$tunel` em
`scripts/montar-pack.ps1` e gere o pack.

**Dicas.**
- Windows: deixe a rede de casa como **Privada**; em rede pública o túnel funciona igual.
- VPNs (Radmin, Hamachi, ZeroTier) ligadas podem atrapalhar o IP local detectado.

## Google Drive

Sem a pasta, o `iniciar` oferece configurar: instala o Google Drive, abre o login e a pasta no
navegador e espera ela aparecer. Responder `n` grava `SEM_DRIVE=1` no `config.env` e não pergunta
mais. Os passos manuais:

1. Instale o Google Drive para desktop (https://www.google.com/drive/download/) e faça login.
2. Dono: a pasta é `Meu Drive/minezada`, com acesso **restrito** (guarda o mundo e os segredos dos
   túneis). Quem vai hospedar clica em "Solicitar acesso" no link que o `iniciar` abre
   e o dono aprova como editor. Jogador não usa o Drive.
3. Convidado: em drive.google.com → Compartilhados comigo → `minezada` → **Adicionar atalho ao Drive**
   (em "Meu Drive"). Sem o atalho a pasta não aparece no computador.
4. Mac: botão direito na pasta → **Disponível off-line**.

O `iniciar` acha a pasta sozinho em `X:\Meu Drive\minezada` (Windows) ou
`~/Library/CloudStorage/GoogleDrive-*/Meu Drive/minezada` (Mac). Pasta em outro lugar: edite
`SYNC_DIR` no `config.env`.

## Página (mapa e placar)

A página do GitHub Pages mostra o mapa do mundo, o placar e o céu como o mundo ficou. Ela sai do mundo que o
`iniciar` sobe para o GitHub a cada `stop`, depois de mandar para o Drive, e a cada 30 minutos com o servidor
ligado (um `save-off` e `save-all flush` no console antes da cópia, e `save-on` depois). Sem `github.txt` na
pasta do Drive o `iniciar` não sobe nada, e a página fica sem mapa e sem placar; o resto funciona igual.
Configurado uma vez só:

1. O mundo vai para o repositório privado `PedroTessaro/minezada-mundo` (criado com um README; sem nenhum
   commit o GitHub não aceita o release).
2. Token: https://github.com/settings/personal-access-tokens/new, com **Only select repositories** →
   `minezada-mundo` e **Repository permissions → Contents: Read and write**. Nada mais.
3. Na pasta `minezada` do Drive, um arquivo `github.txt` com o token na primeira linha. Todo host usa o mesmo.
4. No repositório do pack: Settings → Secrets and variables → Actions → **New repository secret**, nome
   `MUNDO_TOKEN`, o mesmo token.
5. Settings → Pages → Source: **GitHub Actions**.

A Action **Pagina** olha a cada meia hora se chegou mundo novo, e o envio ainda pede ela na hora quando existe o
`dispatch.txt` do selo (seção abaixo). Token vencido: o `iniciar` avisa no fim
("mundo não enviado para o GitHub") e o mundo do Drive continua salvo; gere outro e troque nos passos 3 e 4.
O mapa tem uma aba para cada dimensão onde alguém já foi: Superfície, Nether, End e as dos mods (o Aether, a Lua,
Marte, Vênus, Mercúrio e Glacio do Ad Astra, as órbitas, o Undergarden), sozinhas a partir da primeira visita.
O mapa marca as vilas (pelo sino). O resto mostra as bases e fica desligado: onde cada um saiu do jogo, os
portais do Nether acesos, onde o pessoal passa mais tempo (o botão "Onde o pessoal fica") e onde cada um
morreu (o botão "Mortes", dos registros do mod Corpse). Para ligar: Settings → Secrets and variables → Actions
→ Variables, `MOSTRAR_POSICOES` = `sim`.

## Selo do README

A Action **Status do servidor** pergunta ao servidor se ele está ligado. O horário dela (de 10 em 10 minutos) o
GitHub roda quando quer, e já passou horas sem rodar; por isso o `iniciar` pede a consulta na hora quando o
servidor termina de abrir, a cada 10 minutos com ele ligado e depois do `stop`. O selo muda de 1 a 6 minutos
depois (o resto é o cache do GitHub e do shields.io). Configurado uma vez só:

1. Token do dono do repositório: https://github.com/settings/personal-access-tokens/new, com **Only select
   repositories** → `minezada` e **Repository permissions → Actions: Read and write**. Só isso: ele pede
   rodadas de Action e não mexe em arquivo nenhum.
2. Na pasta `minezada` do Drive, um arquivo `dispatch.txt` com o token na primeira linha.

Sem `dispatch.txt` o selo fica só com o horário do GitHub. Host que cai sem `stop` (falta de luz) não avisa: o
selo fica "ligado" até a próxima consulta do horário.

A cada 30 minutos com o servidor ligado, a cópia do mundo vai também para `backups/sessao-atual.tar.gz` no Drive (segurança se o host cair). O `mundo.tar.gz` e a trava só mudam no `stop`. Para recuperar uma sessão que caiu, extraia essa cópia por cima do mundo, no lugar do `mundo.tar.gz`.

## Trocar de host

- Espere o Drive sincronizar antes de iniciar em outra máquina.
- Máquina caiu sem `stop`? Rode de novo nela: o mundo local é mantido e enviado no próximo `stop`.
- Só use `iniciar.bat -Forcar` / `iniciar.command --forcar` em outra máquina se a original não tiver
  volta (perde o que não foi enviado).

## Segurança

- Quem tem original só entra com a conta verificada pela Mojang. Nunca libere o UUID offline de um
  nick com original: o MixAuth só pede senha a quem chega como offline, e qualquer um poderia
  registrar uma senha e entrar com aquele nick (e com o op dele). O start já cuida disso.
- O repositório é público e os comandos de jogar e hospedar rodam direto dele no PC de todos:
  **mantenha a verificação em duas etapas ligada no GitHub** e não dê acesso de escrita a ninguém.
  O `main` é protegido: ninguém (nem o dono) consegue force push ou apagar o branch.
- A pasta `minezada` do Drive guarda o mundo e os segredos dos túneis (`cloudflare.txt`, `playit.txt`). Compartilhe
  só com quem hospeda (com 2FA na conta Google): quem tem um deles pode apontar o endereço para um
  servidor falso e pegar as senhas do `/login`. Vazou? Token novo no túnel da Cloudflare e no playit.
- Contas da Cloudflare (domínio e túnel) e da DigitalPlat (domínio grátis) com 2FA: quem entrar nelas pode
  redirecionar o endereço.
- Downloads com checksum e versão fixa: launcher sem original, cloudflared, playit e
  packwiz-installer. Os mods vêm do Modrinth com hash conferido pelo packwiz. A cada push no pack, a
  Action **Servidor de teste** sobe o servidor no GitHub e avisa se ele não chegar no `Done`.
- Com os túneis, nenhuma porta fica aberta no roteador e o IP de casa não aparece (só conexões de saída). Nenhuma regra de
  firewall é criada: o túnel entrega o jogador em `localhost`. RCON e query ficam desligados.
- Pelo túnel todos chegam com o mesmo IP: banir por IP não funciona. Use `whitelist remove Nick` e
  tire o nick do `jogadores.txt`.
- Mais seguro ainda: desligue o UPnP no roteador. O servidor não precisa dele, e nenhum aparelho da
  casa consegue abrir porta sozinho.

## Comandos úteis (no campo de comando da janela do servidor)

| Comando | Para quê |
|---------|----------|
| `stop` (ou fechar a janela) | Desligar e enviar o mundo |
| `whitelist remove Nick` | Tirar alguém (e apagar do `jogadores.txt`) |
| `auth setpassword Nick nova nova` | Trocar a senha de quem esqueceu |
| `auth remove Nick` | Apagar o cadastro de senha |
| `chunky radius 1500` e `chunky start` | Pré-gerar o terreno de um mundo novo (`chunky pause` / `chunky continue`) |
| `spark profiler start`, 1 min, `spark profiler stop` | Servidor lento: gera um link mostrando o que pesa |

## Mudar o pack

Edite [`modpack/mods.txt`](../modpack/mods.txt) e siga o checklist do
[CONTRIBUTING.md](../.github/CONTRIBUTING.md). Os jogadores recebem ao abrir o jogo; o servidor, no
próximo start.
