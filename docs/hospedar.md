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
   packwiz (o mrpack-install falha no DNS de roteadores como o da Vivo)
5. Baixa o mundo do Drive e trava para ninguém mais hospedar junto
6. Libera o firewall, abre a porta no roteador (UPnP) e aponta `minezada-mc.duckdns.org` para
   esta máquina
7. Sobe o servidor sem deixar a máquina suspender

**Desligue sempre digitando `stop`.** Aí o mundo volta para o Drive (com backup dos 5 últimos) e a
trava é liberada. Fechar a janela não envia o mundo.

**Whitelist ligada.** Para liberar alguém, adicione o nick em `jogadores.txt` na pasta do Drive (um
por linha; `op` depois do nick também dá admin). O servidor libera todos no próximo start, em
qualquer host. Com o servidor no ar, `whitelist add Nome` e `op Nome` no console valem na hora.
Amigo sem acesso aparece no console como `You are not white-listed`, com o nick.

**Modo offline com senha.** O servidor aceita Minecraft não original (`online-mode=false`), então o
nick não prova quem é a pessoa: o SimpleLogin pede `/register` na primeira vez e `/login` depois.
Peça para cada amigo entrar e registrar logo que for liberado, senão outro pode registrar o nick
antes. Esqueceu a senha: `changepass Nick novasenha` no console. O nick em `jogadores.txt` tem de
ser igual ao do jogo, com as maiúsculas, porque o UUID offline sai dele. Quem jogou antes da troca
tem o progresso levado para o UUID novo no primeiro start.

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
   Perfis de gráfico: edite a tabela em `scripts\perfis.ps1`, rode ele e depois o `montar-pack.ps1`.
3. Anote no histórico de [decisoes.md](decisoes.md), commit e push.

Os jogadores recebem ao abrir o jogo; o servidor, no próximo start. Se mudar a versão do NeoForge, cada
um roda o comando de instalação de novo.
