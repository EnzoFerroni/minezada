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

- **Não conectou no servidor**: o host pode estar desligado. Tente os outros Minezada da lista de servidores.
- **Mac: o jogo fecha ao entrar no mundo ou os shaders não abrem**: rode o comando de jogar de novo. No Mac ele
  desliga o Distant Horizons, que causa os dois.
- **Texto de site (HTML) na tela ao entrar**: a verificação de conta da Mojang recusou a sua rede (comum em rede de
  faculdade ou empresa). Tente outra rede, como o 4G do celular, ou espere um pouco.
- **Faltou mod, o jogo não abre ou algo ficou estranho**: rode o comando de novo. Ele repara a instalação sem
  apagar o mundo, as opções e os servidores.

## Achou um erro?

Abra uma [issue](https://github.com/EnzoFerroni/minezada/issues/new?template=problema.md) (precisa de conta no
GitHub) ou mande direto para o Enzo. Em qualquer caso, envie:

- o que aconteceu e o que você estava fazendo;
- Windows ou Mac, e o modelo do computador;
- print da tela ou da mensagem de erro;
- se o jogo fechou sozinho: o arquivo mais novo de `crash-reports`, ou o `logs/latest.log`. Para achar: no Prism,
  botão direito em Minezada, **Pasta**, depois `.minecraft`.

## Mais

- [Mods e primeiros passos](docs/mods.md)
- [Hospedar](docs/hospedar.md)
- [Tarefas](https://github.com/users/EnzoFerroni/projects/3) · [Versões](https://github.com/EnzoFerroni/minezada/releases) · [Decisões](docs/decisoes.md) · [Como mexer](.github/CONTRIBUTING.md)
