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

**Use o `jogadores.txt`, não `whitelist add` nem `op` no console.** Cada nick precisa de dois UUIDs: o
oficial (quem entra com original) e o offline (quem entra sem). O start libera os dois e, na
primeira vez, copia o progresso do UUID offline para o oficial. O console só grava um deles. Tirar
alguém continua sendo no console (`whitelist remove Nick`) e na lista.

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
dele. Nick sem original que existe como conta original de outra pessoa: o UUID oficial dele também é
liberado. Risco pequeno, porque o dono da conta precisaria saber o endereço. Configuração em
`server-config/config/mixauth-server.toml`.

**Skins.** Sem conta verificada a Mojang não manda a skin, então o SkinRestorer busca pelo nick ao
entrar pela primeira vez: Mojang e, se ela bloquear (`429` em rede compartilhada, como a de
laboratório), a imagem do mc-heads assinada pelo MineSkin. A skin fica salva no mundo e não é
buscada de novo. Trocar: `/skin set nick SeuNick` ou `/skin set web classic <link>` (`slim` para
braço fino). A configuração fica em `server-config/config/skinrestorer/config.json`.

**Jogador em rede que bloqueia (faculdade).** Algumas redes só deixam sair pelas portas 80 e 443. Com UPnP o
script abre também a 443 do roteador apontando para o servidor, e o jogo já traz a entrada
**Minezada (rede da faculdade)** (`minezada-mc.duckdns.org:443`). Quem já tinha o jogo adiciona essa
entrada à mão. Se o roteador do host já usa a 443, só a 25565 abre.

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
