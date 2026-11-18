# Minezada

Modpack e servidor de Minecraft 1.21.1.

## Jogar

Rode o comando uma vez. Ele instala o Prism Launcher e o Java, baixa os mods, cria o atalho **Minezada** na
Área de Trabalho e abre o jogo já entrando no servidor. Na primeira vez o Prism pede o login e o download dos mods
demora alguns minutos.

**Windows**: abra o PowerShell (menu Iniciar, digite "PowerShell") e cole:

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
```

**Mac**: abra o Terminal (Cmd + Espaço, digite "Terminal") e cole:

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
```

Das próximas vezes, abra pelo atalho **Minezada**. Os mods se atualizam sozinhos a cada abertura.

## Problemas comuns

- **Não conectou no servidor**: o host pode estar desligado. Tente os outros Minezada da lista de servidores.
- **Mac: o jogo fecha ao entrar no mundo ou os shaders não abrem**: desmarque o Distant Horizons. Apague
  `packwiz.json` na pasta `.minecraft` (como achar: no fim desta página) e abra de novo: a janela de opcionais aparece e ele vem desmarcado.
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
