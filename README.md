# Minezada

Modpack e servidor de Minecraft 1.21.1, com ou sem Minecraft original.

## Jogar

**Windows** (PowerShell)

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
```

**Mac** (Terminal)

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
```

Ele pergunta se você tem Minecraft original, instala tudo e abre o jogo. Na primeira vez entre com a
conta Microsoft ou, sem original, digite seu nick **exatamente como está na whitelist** (maiúsculas
contam). Depois é só clicar em **Minezada** na Área de Trabalho: o jogo entra direto no servidor e os
mods se atualizam sozinhos.

- **Sem original:** na primeira vez digite `/register suasenha suasenha`; nas outras,
  `/login suasenha`. Use uma senha só daqui, não a do seu e-mail ou de outro jogo.
- **Skin:** quem tem original já aparece com a sua. Para trocar:
  `/skin set web classic <link da imagem>` (`slim` para braço fino).
- **Mac:** M1 ou mais novo. Com 8 GB, use o perfil de gráfico **Mac 1**.
- **Faculdade:** a rede de lá costuma bloquear o servidor. Use o roteador do celular (4G).
- **Deu problema?** Rode o comando de novo. Não resolveu?
  [Abra uma issue](https://github.com/EnzoFerroni/minezada/issues/new/choose).

Só Minecraft Java Edition (celular e console não entram).

## Mais

- [Mods e primeiros passos](docs/mods.md)
- [Hospedar o servidor](docs/hospedar.md)
- [O que falta fazer](https://github.com/users/EnzoFerroni/projects/3) ·
  [O que mudou em cada versão](https://github.com/EnzoFerroni/minezada/releases)
- [Por que cada coisa é assim](docs/decisoes.md) · [Como mexer no projeto](.github/CONTRIBUTING.md)
