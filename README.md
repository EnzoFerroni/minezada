# Minezada

**Servidor:** `minezada-mc.duckdns.org`

## Jogar

Com Minecraft Java original, rode o comando abaixo. Sem o original, veja o fim desta seção.

**Windows** (PowerShell)

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
```

**Mac** (Terminal)

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
```

Ele instala tudo e abre o jogo. Na primeira vez entre com a conta Microsoft. Depois é só clicar
em **Minezada** na Área de Trabalho: o jogo entra direto no servidor e os mods se atualizam
sozinhos. Algo quebrou? Rode o comando de novo.

**No servidor, todo mundo tem senha.** Na primeira vez digite `/register suasenha suasenha`; nas
outras, `/login suasenha`. Sem isso não dá para andar nem mexer em nada.

**Sem Minecraft original:** use um launcher que aceite conta offline, importe o
[`minezada.mrpack`](modpack/minezada.mrpack) e entre com o nick exatamente como está na whitelist
(maiúsculas contam). Os mods não se atualizam sozinhos: baixe o `.mrpack` de novo quando mudar.
Para ter skin: `/skin set web classic <link da imagem da skin>` (`slim` para braço fino).

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
- [Planos](docs/planos.md): o que vem a seguir (livro de missões, mais mods)