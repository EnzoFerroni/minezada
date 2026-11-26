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

## Segurança do repositório

- O repositório é público e os comandos de jogar e hospedar rodam direto dele no PC de todos: **mantenha a
  verificação em duas etapas ligada no GitHub** e não dê acesso de escrita a ninguém. O `main` é protegido: ninguém
  consegue force push ou apagar o branch.
- Vazou um segredo do Drive? Token novo no túnel da Cloudflare e no playit.
- Downloads com checksum e versão fixa: launcher sem original, cloudflared, playit e packwiz-installer. Os mods vêm
  com hash conferido pelo packwiz. A cada push no pack, a Action **Servidor de teste** sobe o servidor e o jogo no
  GitHub e avisa se algo falhar.
