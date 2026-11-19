# Minezada

Modpack e servidor de Minecraft 1.21.1.

## Jogar

Rode o comando uma vez. Ele instala o Prism Launcher e o Java, baixa os mods, pergunta se você quer um atalho
**Minezada** na Área de Trabalho e abre o jogo. Na primeira vez o Prism pede o login e o download dos mods demora alguns minutos.
No jogo, clique em **Multijogador**: a lista mostra quais servidores Minezada estão no ar.

**Windows**: abra o PowerShell (menu Iniciar, digite "PowerShell") e cole:

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
```

**Mac**: abra o Terminal (Cmd + Espaço, digite "Terminal") e cole:

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
```

Das próximas vezes, abra pelo atalho **Minezada**: ele confere a versão mais nova e atualiza tudo sozinho antes de abrir o jogo. Pelo Prism Launcher (instância Minezada) os mods também se atualizam a cada abertura.

## Problemas comuns

Primeiro, feche o jogo e abra pelo atalho **Minezada**. Não resolveu? Rode o comando de jogar de novo (não apaga nada).

- **Servidor fora do ar**: o host está desligado.
- **"You are not white-listed"**: mande o seu nick exato para o Enzo.
- **Pede senha**: na primeira vez, `/register senha senha`; depois, `/login senha`.
- **Texto de site na tela ao entrar**: clique em **Voltar** e entre de novo.
- **Jogo lento**: **Opções** > **Perfis** > **1 - Minimo**.

## Achou um erro?

Mande para o Enzo (ou abra uma [issue](https://github.com/EnzoFerroni/minezada/issues/new?template=problema.md)):
o que aconteceu, um print e se é Windows ou Mac. Se o jogo fechou, mande também o registro: no Prism, botão
direito em **Minezada** > **Pasta** > `.minecraft` > `logs` > `latest.log`. Cole o conteúdo em
[mclo.gs](https://mclo.gs) e mande o link.

## Mais

- [Mods e primeiros passos](docs/mods.md)
- [Hospedar](docs/hospedar.md)
- [Tarefas](https://github.com/users/EnzoFerroni/projects/3) · [Versões](https://github.com/EnzoFerroni/minezada/releases) · [Decisões](docs/decisoes.md) · [Como mexer](.github/CONTRIBUTING.md)
