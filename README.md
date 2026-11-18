# Minezada

**Servidor:** `molecule-spindle.tun.ply.gg` (reserva: `minezada-mc.duckdns.org`)

## Jogar

Rode o comando abaixo, com ou sem Minecraft original.

**Windows** (PowerShell)

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
```

**Mac** (Terminal)

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
```

Ele pergunta se você tem Minecraft original, instala tudo e abre o jogo. Na primeira vez entre
com a conta Microsoft ou, sem original, digite seu nick **exatamente como está na whitelist**
(maiúsculas contam). Depois é só clicar em **Minezada** na Área de Trabalho: o jogo entra direto
no servidor e os mods se atualizam sozinhos. Algo quebrou? Rode o comando de novo.
Na faculdade não conecta? A rede de lá costuma bloquear o servidor: use o roteador do celular (4G).

**Login no servidor.** Com Minecraft original você entra direto, sem senha. Sem original: na primeira
vez digite `/register suasenha suasenha`; nas outras, `/login suasenha`. Use uma senha só daqui, não
a do seu e-mail ou de outro jogo. Sem login não dá para andar nem mexer em nada.

**Skin:** quem tem original já aparece com a sua. Para trocar:
`/skin set web classic <link da imagem da skin>` (`slim` para braço fino).

## Hospedar

**Windows** (PowerShell)

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/hospedar.ps1 | iex
```

**Mac** (Terminal)

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/hospedar.sh | bash
```

Ele baixa tudo, cria o atalho **Hospedar Minezada** na Área de Trabalho e sobe o servidor. Para
desligar, digite `stop` (é isso que devolve o mundo para o Drive).

## Mais

- [Mods](docs/mods.md): o que tem no pack e primeiros passos
- [Hospedar](docs/hospedar.md): como o servidor funciona, trocar de host, mudar o pack
- [Requisitos](docs/requisitos.md): o que instalar, Google Drive e rede
- [Decisões](docs/decisoes.md): por que cada versão e mod foi escolhido
- [O que falta fazer](https://github.com/EnzoFerroni/minezada/issues) e [o que mudou em cada versão](https://github.com/EnzoFerroni/minezada/releases)
- [Como mexer no projeto](.github/CONTRIBUTING.md): checklist para mudar o pack e lições aprendidas