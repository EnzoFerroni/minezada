# Hospedar o servidor

## Primeira vez numa máquina

Rode o comando de hospedar do [README](../README.md). Ele instala o Git (Windows) ou as ferramentas
de linha de comando da Apple (Mac), baixa o repo em `Minezada-servidor` na pasta do usuário e cria o
atalho **Hospedar Minezada**. Na primeira vez ele oferece configurar o Google Drive: clique em
"Solicitar acesso" na pasta e avise o dono.

## Rodar

Clique em **Hospedar Minezada** (ou `iniciar.bat` / `iniciar.command` na pasta do repo). O script:

1. Atualiza o repo (`git pull`)
2. Na primeira vez: cria `config.env` (RAM, pasta do Drive, token do DuckDNS) e pergunta do EULA
3. Instala o Java se faltar
4. Instala/atualiza servidor, NeoForge e mods: no Windows com o
   [mrpack-install](https://github.com/nothub/mrpack-install); no Mac com o instalador do NeoForge e o
   packwiz (o mrpack-install falha no DNS de roteadores de operadora)
5. Baixa o mundo do Drive e trava para ninguém mais hospedar junto
6. Libera a porta no firewall só para a rede local e liga o túnel playit.gg (endereço principal).
   Só se o túnel não conectar: abre a porta no roteador (UPnP) e aponta `minezada-mc.duckdns.org`
   para esta máquina (reserva)
7. Sobe o servidor sem deixar a máquina suspender

**Desligue sempre digitando `stop`.** Aí o mundo volta para o Drive (com backup dos 5 últimos) e a
trava é liberada. Fechar a janela não envia o mundo.

**Whitelist ligada.** Para liberar alguém:

1. Abra `jogadores.txt` na pasta `minezada` do Drive.
2. Escreva o nick numa linha nova, **igual ao do jogo, com as maiúsculas** (`Nick op` também dá
   admin). Não sabe o nick exato? Peça para a pessoa tentar entrar: o console mostra
   `Disconnecting Nick (...): You are not white-listed`.
3. Reinicie o servidor (`stop` e abrir de novo). O start libera todos da lista, em qualquer host.
4. Quem tem original entra direto. Quem não tem roda `/register senha senha` na hora.

**Use o `jogadores.txt`, não `whitelist add` nem `op` no console.** O start pergunta à Mojang se o nick
tem conta original. Se tiver, libera só o UUID oficial (e copia o progresso antigo do UUID offline para
ele). Se não tiver, libera o UUID offline, e a pessoa usa senha. Amigo sem original com um nick que
por acaso existe como conta de outra pessoa: escreva `Nick sem-original`. Se a Mojang não responder,
o nick fica como estava até o próximo start. Tirar alguém continua sendo no console
(`whitelist remove Nick`) e na lista.

**Login (MixAuth).** O servidor aceita Minecraft não original (`online-mode=false`), então o nick
sozinho não prova quem é a pessoa. O MixAuth resolve assim:
- Quem tem original: a Mojang confirma a conta e a pessoa entra direto, com o UUID oficial e a skin.
  Se a Mojang estiver fora do ar, esse jogador não entra até ela voltar.
- Quem não tem: `/register senha senha` na primeira vez e `/login senha` sempre que entrar (o "lembrar
  por IP" fica desligado: pelo túnel e em rede de faculdade todos chegam com o mesmo IP, e qualquer um
  entraria com o nick de outro). Peça para registrar logo que for liberado, senão outro pode registrar o nick.
- Esqueceu a senha: `auth setpassword Nick nova nova` no console. Recomeçar do zero:
  `auth remove Nick`.
- Antes do login a pessoa fica em espectador, parada e cega. Morreu e saiu? Ao voltar ela consegue
  renascer e logar (o SimpleLogin, usado antes, travava nessa hora).

O nick em `jogadores.txt` tem de ser igual ao do jogo, com as maiúsculas, porque o UUID offline sai
dele. Senha mínima de 6 caracteres; 5 erros bloqueiam o nick por 5 minutos. Configuração em
`server-config/config/mixauth-server.toml`.

**Segurança, em resumo.**
- Quem tem original só entra com a conta verificada pela Mojang. Nunca libere o UUID offline de um
  nick com original: o MixAuth só pede senha a quem chega como offline, e qualquer um poderia
  registrar uma senha e entrar com aquele nick (e com o op dele). O start já cuida disso.
- O repositório é público e o comando de jogar e o de hospedar rodam direto dele no PC de todos:
  **mantenha a verificação em duas etapas ligada no GitHub** e não dê acesso de escrita a ninguém.
- A pasta `minezada` do Drive guarda o mundo, o token do DuckDNS (`duckdns.txt`) e o segredo do
  túnel (`playit.txt`). Compartilhe só com quem hospeda; quem tem o token pode apontar o endereço
  para outro lugar. Vazou? Gere token novo no site do DuckDNS e troque o `duckdns.txt`.
- Downloads com checksum: launcher sem original, playit, mrpack-install e packwiz-installer (todos
  em versão fixa; o packwiz-installer não se atualiza sozinho). Os mods vêm do Modrinth com hash
  conferido pelo packwiz. O `montar-pack` lista os mods que mudaram de versão: confira antes do push.
- `main` protegido no GitHub: ninguém (nem o dono) consegue force push ou apagar o branch.
- Com o túnel, nenhuma porta fica aberta no roteador e o IP de casa não aparece: o host limpa o
  DuckDNS ao ligar o túnel. O firewall do Windows só aceita a 25565 da rede local. Só na reserva
  (túnel fora do ar) o `iniciar` abre a 25565 e a 443 por UPnP e uma regra de firewall para a
  internet, e fecha tudo no `stop`. RCON e query ficam desligados.
- Pelo túnel todos chegam com o mesmo IP: banir por IP não funciona, use `whitelist remove Nick` e
  tire o nick do `jogadores.txt`.
- Mais seguro ainda: desligue o UPnP no roteador. A reserva deixa de funcionar, mas nenhum aparelho
  da casa consegue abrir porta sozinho.

**Skins.** Sem conta verificada a Mojang não manda a skin, então o SkinRestorer busca pelo nick ao
entrar pela primeira vez: Mojang e, se ela bloquear (`429` em rede compartilhada, como a de
laboratório), a imagem do mc-heads assinada pelo MineSkin. A skin fica salva no mundo e não é
buscada de novo. Trocar: `/skin set nick SeuNick` ou `/skin set web classic <link>` (`slim` para
braço fino). A configuração fica em `server-config/config/skinrestorer/config.json`.

**Túnel playit.gg (endereço principal).** O jogo entra sozinho por `molecule-spindle.tun.ply.gg`.
Funciona com o host em qualquer rede (casa, faculdade, 4G) sem abrir porta. O segredo do agente fica
em `playit.txt` no Drive e o endereço em `playit-endereco.txt`, então todo host usa o mesmo túnel. O
agente baixa sozinho com checksum para `tools/playit` e para no `stop`. Plano grátis: a rota não é
garantida para quem está longe (testado: do Brasil entra; um verificador nos EUA/Europa não). O host
entra por `localhost`; outro computador da mesma casa vê o servidor sozinho na parte de LAN.

**Jogador em rede que bloqueia (faculdade).** Algumas redes só deixam sair pelas portas 80 e 443, e o
túnel usa outra porta. A entrada **Minezada (rede da faculdade)** (`minezada-mc.duckdns.org:443`) só
funciona na reserva e com um roteador que repasse a 443. No PC de casa (18/11) o roteador aceitou a
443 e a 80 por UPnP mas não repassou quem vinha de fora (a 25565 e a 8443 passaram). Para quem joga
da faculdade com o host em casa, falta uma saída na 443 (ver a [issue #8](https://github.com/EnzoFerroni/minezada/issues/8)).

**Lista de servidores do jogo.** Vem pronta e se atualiza a cada abertura (packwiz): Minezada (túnel),
Minezada (reserva), Minezada (rede da faculdade) e Minezada (neste computador, para quem joga na
máquina do host). Servidor adicionado à mão some na próxima abertura. Mudou o endereço do playit?
Troque `$tunel` em `scripts/montar-pack.ps1` e gere o pack.

**Mundo novo? Pré-gere o terreno** para ninguém travar explorando (Terralith e as estruturas pesam na geração). No console, uma vez: `chunky radius 1500` e `chunky start`. Leva um tempo; dá para jogar enquanto roda. `chunky pause` / `chunky continue` controlam.

Servidor lento? `spark profiler start`, espere 1 minuto e `spark profiler stop`: ele gera um link mostrando o que está pesando.

## Trocar de host

- Espere o Drive sincronizar antes de iniciar em outra máquina.
- Máquina caiu sem `stop`? Rode de novo nela: o mundo local é mantido e enviado no próximo `stop`.
- Só use `iniciar.bat -Forcar` / `iniciar.command --forcar` em outra máquina se a original não tiver
  volta (perde o que não foi enviado).

## Mudar o pack

1. Edite [`modpack/mods.txt`](../modpack/mods.txt): uma linha `slug-do-modrinth | descrição`.
2. Rode `powershell -ExecutionPolicy Bypass -File scripts\montar-pack.ps1`.
   Perfis de gráfico: edite a tabela em `scripts/perfis.ps1`, rode ele e depois o `montar-pack.ps1`
   (no Mac: `pwsh scripts/perfis.ps1`; os dois scripts rodam no PowerShell do Mac e do Windows).
3. Siga o checklist de [CONTRIBUTING.md](../.github/CONTRIBUTING.md) (testar servidor e jogo, commit, push e Release).

Os jogadores recebem ao abrir o jogo; o servidor, no próximo start. Se mudar a versão do NeoForge, cada
um roda o comando de instalação de novo.
