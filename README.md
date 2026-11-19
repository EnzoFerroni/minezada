# Minezada

Modpack e servidor de Minecraft 1.21.1.

## Instalar (só uma vez)

**Windows**: abra o **PowerShell** e cole:

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.ps1 | iex
```

**Mac**: abra o **Terminal** e cole:

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
```

O comando instala tudo, oferece criar o atalho **Minezada** na Área de Trabalho (responda que sim) e abre o jogo.
Na primeira vez, entre com a sua conta (sem Minecraft original, só o seu nick) e espere os mods baixarem.

## Jogar

1. Abra sempre pelo atalho **Minezada**. A cada abertura ele atualiza o launcher, os mods e as configurações sozinho;
   não precisa rodar o comando de instalar de novo.
2. Clique em **Multijogador** e entre em **Minezada**.

## Problemas

- **Algo deu errado**: rode o comando de instalar de novo. Ele não apaga nada.
- **"You are not white-listed"**: mande o seu nick exato (com as maiúsculas) para quem está hospedando o servidor.
- **Pede senha** (só para quem joga sem Minecraft original; com original entra direto): na primeira vez, escolha uma
  senha e digite `/register senha senha`; nas próximas, `/login senha`.
- **Jogo lento**: **Opções** > **Perfis** > **1 - Minimo**.

Achou um erro? Mande um print para quem está hospedando. Se o jogo fechou ou não conectou, rode o comando do seu
sistema e mande os links que ele copia (ele envia os logs do jogo para o [mclo.gs](https://mclo.gs), só com o seu nick).

**Windows**, no **PowerShell**:

```powershell
irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/logs.ps1 | iex
```

**Mac**, no **Terminal**:

```sh
curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/logs.sh | bash
```

## Ajudar

O projeto é aberto a qualquer um:

- **Quer um mod?** Comente na [lista de mods candidatos](https://github.com/EnzoFerroni/minezada/issues/10).
- **Achou um problema ou tem uma ideia?** Abra uma [issue](https://github.com/EnzoFerroni/minezada/issues/new/choose).
- **Quer mexer no código ou no pack?** Pull requests são bem-vindos; o [guia](.github/CONTRIBUTING.md) explica como
  montar e testar.

Código e documentação sob a [licença MIT](LICENSE). Os mods não ficam neste repositório: o jogo baixa cada um do
Modrinth, com a licença do seu autor. O zip do Prism traz o [packwiz-installer](https://github.com/packwiz/packwiz-installer)
(MIT).

## Mais

[Mods](docs/mods.md) · [Hospedar](docs/hospedar.md) · [Tarefas](https://github.com/users/EnzoFerroni/projects/3) · [Versões](https://github.com/EnzoFerroni/minezada/releases) · [Decisões](docs/decisoes.md) · [Como mexer](.github/CONTRIBUTING.md)
