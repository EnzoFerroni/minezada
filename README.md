# Minezada

**Servidor:** `minezada-mc.duckdns.org`

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
Na faculdade não conecta? Entre em **Minezada (rede da faculdade)** na lista de servidores.

**Login no servidor.** Com Minecraft original você entra direto, sem senha. Sem original: na primeira
vez digite `/register suasenha suasenha`; nas outras, `/login suasenha` (no mesmo Wi-Fi ele lembra de
você por 7 dias). Sem isso não dá para andar nem mexer em nada.

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
- [Planos](docs/planos.md): o que vem a seguir (livro de missões, mais mods)