# Minezada

**Servidor:** `minezada-mc.duckdns.org`

## Jogar

Precisa do Minecraft Java original. Rode o comando:

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

## Hospedar

```sh
git clone https://github.com/EnzoFerroni/minezada
```

Abra `iniciar.bat` (Windows) ou `iniciar.command` (Mac). Para desligar, digite `stop`.

## Mais

- [Mods](docs/mods.md): o que tem no pack e primeiros passos
- [Hospedar](docs/hospedar.md): como o servidor funciona, trocar de host, mudar o pack
- [Requisitos](docs/requisitos.md): o que instalar, Google Drive e rede
- [Decisões](docs/decisoes.md): por que cada versão e mod foi escolhido
- [Planos](docs/planos.md): o que vem a seguir (livro de missões, mais mods)