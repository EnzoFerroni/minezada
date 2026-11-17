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
   packwiz (o mrpack-install falha no DNS de roteadores como o da operadora)
5. Baixa o mundo do Drive e trava para ninguém mais hospedar junto
6. Libera o firewall, abre a porta no roteador (UPnP) e aponta `minezada-mc.duckdns.org` para
   esta máquina
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
- Quem não tem: `/register senha senha` na primeira vez e `/login senha` depois. No mesmo IP fica
  logado por 7 dias. Peça para registrar logo que for liberado, senão outro pode registrar o nick.
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
- Downloads com checksum: launcher sem original (versão fixa), playit e mrpack-install. Os mods vêm
  do Modrinth com hash conferido pelo packwiz.
- O servidor só abre a porta do jogo (25565 e a 443 do roteador, fechadas no `stop`). RCON e query
  ficam desligados.

**Skins.** Sem conta verificada a Mojang não manda a skin, então o SkinRestorer busca pelo nick ao
entrar pela primeira vez: Mojang e, se ela bloquear (`429` em rede compartilhada, como a de
laboratório), a imagem do mc-heads assinada pelo MineSkin. A skin fica salva no mundo e não é
buscada de novo. Trocar: `/skin set nick SeuNick` ou `/skin set web classic <link>` (`slim` para
braço fino). A configuração fica em `server-config/config/skinrestorer/config.json`.

**Jogador em rede que bloqueia (faculdade).** Algumas redes só deixam sair pelas portas 80 e 443. Com UPnP o
script abre também a 443 do roteador apontando para o servidor, e o jogo já traz a entrada
**Minezada (rede da faculdade)** (`minezada-mc.duckdns.org:443`). Se o roteador do host já usa a 443, só
a 25565 abre.

**Lista de servidores do jogo.** Vem pronta e se atualiza a cada abertura (packwiz): Minezada,
Minezada (rede da faculdade), Minezada (túnel playit) e Minezada (neste computador, para quem joga na
máquina do host). Servidor adicionado à mão some na próxima abertura. Mudou o endereço do playit?
Troque `$tunel` em `scripts/montar-pack.ps1` e gere o pack.

**Host em rede que bloqueia (faculdade, laboratório).** Sem UPnP o script liga o túnel playit.gg: quem
está fora, ou na mesma rede se ela isola os computadores, entra pelo endereço de
`playit-endereco.txt` no Drive. O host entra por `localhost`; o servidor não aparece sozinho em
Multijogador porque a rede bloqueia o anúncio de LAN.

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
3. Anote no histórico de [decisoes.md](decisoes.md), commit e push.

Os jogadores recebem ao abrir o jogo; o servidor, no próximo start. Se mudar a versão do NeoForge, cada
um roda o comando de instalação de novo.
