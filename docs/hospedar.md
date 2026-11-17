# Hospedar o servidor

## Primeira vez numa máquina

Peça a pasta `minezada` do Google Drive para quem já hospeda (ver [requisitos](requisitos.md)).

```sh
git clone https://github.com/EnzoFerroni/minezada
```

Windows sem Git: `winget install -e --id Git.Git` antes.

## Rodar

Duplo clique em `iniciar.bat` (Windows) ou `iniciar.command` (Mac). O script:

1. Atualiza o repo (`git pull`)
2. Na primeira vez: cria `config.env` (RAM, pasta do Drive, token do DuckDNS) e pergunta do EULA
3. Instala o Java se faltar
4. Instala/atualiza servidor, NeoForge e mods ([mrpack-install](https://github.com/nothub/mrpack-install))
5. Baixa o mundo do Drive e trava para ninguém mais hospedar junto
6. Libera o firewall, abre a porta no roteador (UPnP) e aponta `minezada-mc.duckdns.org` para
   esta máquina
7. Sobe o servidor sem deixar a máquina suspender

**Desligue sempre digitando `stop`.** Aí o mundo volta para o Drive (com backup dos 5 últimos) e a
trava é liberada. Fechar a janela não envia o mundo.

Whitelist ligada. No console: `whitelist add Nome` e `op Nome`.

## Trocar de host

- Espere o Drive sincronizar antes de iniciar em outra máquina.
- Máquina caiu sem `stop`? Rode de novo nela: o mundo local é mantido e enviado no próximo `stop`.
- Só use `iniciar.bat -Forcar` / `iniciar.command --forcar` em outra máquina se a original não tiver
  volta (perde o que não foi enviado).

## Mudar o pack

1. Edite [`modpack/mods.txt`](../modpack/mods.txt): uma linha `slug-do-modrinth | descrição`.
2. Rode `powershell -ExecutionPolicy Bypass -File scripts\montar-pack.ps1`.
3. Anote no histórico de [decisoes.md](decisoes.md), commit e push.

Os jogadores recebem ao abrir o jogo; o servidor, no próximo start. Se mudar a versão do NeoForge, cada
um roda o comando de instalação de novo.
