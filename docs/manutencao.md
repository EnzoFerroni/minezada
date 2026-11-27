# Manutenção (só o dono)

Configuração feita uma vez só, ou quando um token vence. Quem hospeda não precisa disto: veja [hospedar.md](hospedar.md).

## Túneis

- **Cloudflare:** conta do dono, domínio grátis `minezada.dpdns.org` (DigitalPlat), túnel `minezada` com a rota
  `mc.minezada.dpdns.org` → `tcp://localhost:25565`. Perdeu o token? Painel → Tunnels → `minezada` → gerar de novo
  e salvar em `cloudflare.txt` na pasta do Drive.
- **playit:** perdeu o segredo? `playit claim generate`, `playit claim url <código>`, aprove no site e
  `playit claim exchange <código>`: a última linha da saída é o segredo novo. Salve em `playit.txt` na pasta do Drive.
- Contas da Cloudflare e da DigitalPlat com verificação em duas etapas: quem entrar nelas pode redirecionar o endereço.

## Página (mapa e placar)

A página do GitHub Pages mostra o mapa do mundo, o placar e o céu como o mundo ficou. Ela sai do mundo que o
`iniciar` sobe para o GitHub a cada `stop`, depois de mandar para o Drive, e a cada 30 minutos com o servidor
ligado (um `save-off` e `save-all flush` no console antes da cópia, e `save-on` depois). Sem `github.txt` na
pasta do Drive o `iniciar` não sobe nada, e a página fica sem mapa e sem placar; o resto funciona igual.
Configurado uma vez só:

1. O mundo vai para um repositório privado (o padrão está em `scripts/MundoGithub.java`; outro repositório vai
   na segunda linha do `github.txt`). Crie com um README: sem nenhum commit o GitHub não aceita o release.
2. Token: https://github.com/settings/personal-access-tokens/new, com **Only select repositories** →
   o repositório do mundo e **Repository permissions → Contents: Read and write**. Nada mais.
3. Na pasta `minezada` do Drive, um arquivo `github.txt` com o token na primeira linha. Todo host usa o mesmo.
4. No repositório do pack: Settings → Secrets and variables → Actions → aba do environment **producao**
   (só libera os segredos no `main`), nome `MUNDO_TOKEN`, o mesmo token.
5. Settings → Pages → Source: **GitHub Actions**.

A Action **Pagina** olha a cada meia hora se chegou mundo novo, e o envio ainda pede ela na hora quando existe o
`dispatch.txt` do selo (seção abaixo). Token vencido: o `iniciar` avisa no fim
("mundo não enviado para o GitHub") e o mundo do Drive continua salvo; gere outro e troque nos passos 3 e 4.
O mapa tem uma aba para cada dimensão onde alguém já foi: Superfície, Nether, End e as dos mods (o Aether, a Lua,
Marte, Vênus, Mercúrio e Glacio do Ad Astra, as órbitas, o Undergarden), sozinhas a partir da primeira visita.
O mapa marca as vilas (pelo sino). O resto mostra as bases e fica desligado: onde cada um saiu do jogo, os
portais do Nether acesos, onde o pessoal passa mais tempo (o botão "Onde o pessoal fica") e onde cada um
morreu (o botão "Mortes", dos registros do mod Corpse). O botão "Estruturas" mostra as estruturas já encontradas. Para ligar: Settings → Secrets and variables → Actions
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

## Logs e erros

- **Servidor:** a cada desligamento o iniciar guarda em `logs/AAAAMMDD-HHMM` no Drive o `latest.log`, um `erros.txt` só com as linhas WARN/ERROR/FATAL e os relatórios de crash da sessão (pasta `crash-reports` e `hs_err_pid*.log`). Ficam as 20 sessões mais novas. Se o host cair sem desligar, o log fica em `server/logs` da máquina dele.
- **Jogo:** quando o jogo de alguém fecha com erro, o Crash Assistant abre uma janela que manda o log e gera um link do mclo.gs. Sem a janela, o comando de logs do README faz o mesmo.

## Recomeçar o mundo do zero

Para abrir o servidor para todos com mundo novo e progresso zerado (inventários, missões, conquistas, waystones):

1. Desligue o servidor com `stop` e espere o envio do mundo terminar.
2. Rode `bash scripts/resetar.sh` (Mac) ou `powershell -ExecutionPolicy Bypass -File scripts\resetar.ps1` (Windows) e digite `RESETAR`. Ele recusa se o servidor estiver ligado em algum host. Guarda o mundo atual em `arquivo/` no Drive, apaga `mundo.tar.gz`, `backups/` e o `server/world` da máquina e troca o `modpack/arquivos/mundo-id.txt`.
3. Rode `scripts/montar-pack.ps1`, faça commit e push. Na próxima abertura, o jogo de cada um apaga os mapas do Xaero e o cache do Distant Horizons do mundo velho (o `minezada.ps1`/`.sh` compara o `mundo-id.txt` com o último que viu).
4. Ligue pelo `iniciar`: sem `mundo.tar.gz` no Drive, ele cria um mundo novo.
5. Pré-gere no console: `chunky radius 1500` e `chunky start`. Leva horas; deixe ligado até `Task finished`.
6. Desligue com `stop`: o mundo pré-gerado vai para o Drive. Entre pelo túnel para conferir e crie a Release do dia.

## Segurança do repositório

- O repositório é público e os comandos de jogar e hospedar rodam direto dele no PC de todos: **mantenha a
  verificação em duas etapas ligada no GitHub** e não dê acesso de escrita a ninguém. O `main` é protegido: ninguém
  consegue force push ou apagar o branch.
- Vazou um segredo do Drive? Token novo no túnel da Cloudflare e no playit.
- Downloads com checksum e versão fixa: launcher sem original, cloudflared, playit e packwiz-installer. Os mods vêm
  com hash conferido pelo packwiz. A cada push no pack, a Action **Servidor de teste** sobe o servidor e o jogo no
  GitHub e avisa se algo falhar.
