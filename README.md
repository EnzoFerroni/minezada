# Minezada

**Servidor:** `minezada-mc.duckdns.org`

## Jogar

Precisa do Minecraft Java original. Rode uma vez:

**Windows** (PowerShell)

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
```

**Mac** (Terminal)

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
```

No Prism: confirme a importação, entre com a conta Microsoft e abra **Minezada**. O jogo entra
direto no servidor e os mods se atualizam sozinhos.

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