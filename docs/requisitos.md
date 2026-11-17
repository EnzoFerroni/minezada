# Requisitos

O `iniciar` instala Java e ferramentas sozinho. Este arquivo cobre o que ele não consegue fazer.

## Jogadores

- **Minecraft Java Edition original** (conta Microsoft). Bedrock (celular/console) não entra.
- Nada mais: o comando do [README](../README.md) instala o Prism Launcher, o Java e os mods.
- Mac: M1 ou mais novo com 16 GB roda bem. O macOS só tem OpenGL 4.1, então alguns shaders não
  funcionam; mods de renderização Metal (Fabric) contornam isso.

## Host

| Item | Mínimo | Quem resolve |
|------|--------|--------------|
| Git | qualquer | Windows: `winget install -e --id Git.Git`. Mac: pede para instalar no primeiro `git`. |
| Java 21+ | - | `iniciar` instala o Java 25 se faltar ou for antigo (Windows: winget; Mac: baixa para `tools/`, sem Homebrew). |
| RAM | 16 GB | Servidor usa 6-8 GB. Jogar e hospedar na mesma máquina aperta. |
| Disco | SSD, ~10 GB | Mundo cresce com o tempo. |
| Rede | cabo, upload ≥ 10 Mbps | Wi-Fi funciona, mas oscila mais. |
| Repo | público | Só clonar; não precisa de conta no GitHub. |

## Google Drive (para alternar host)

Sem a pasta, o `iniciar` oferece fazer isso sozinho: instala o Google Drive, abre o login e a pasta
no navegador e espera ela aparecer. Responder `n` grava `SEM_DRIVE=1` no `config.env` e não pergunta
mais. Os passos manuais:

1. Instale o Google Drive para desktop (https://www.google.com/drive/download/) e faça login.
2. Dono: a pasta é `Meu Drive/minezada`, com acesso **restrito** (ela guarda o mundo e o token do
   DuckDNS). Quem vai hospedar abre o link pelo `iniciar`, clica em "Solicitar acesso" e o dono aprova
   como editor. Só quem hospeda precisa: jogador não usa o Drive.
3. Convidado: em drive.google.com → Compartilhados comigo → `minezada` → **Adicionar atalho ao Drive**
   (em "Meu Drive"). Sem o atalho a pasta não aparece no computador.
4. Mac: botão direito na pasta → **Disponível off-line**.

O `iniciar` acha a pasta sozinho em `X:\Meu Drive\minezada` (Windows) ou
`~/Library/CloudStorage/GoogleDrive-*/Meu Drive/minezada` (Mac). Pasta em outro lugar: edite
`SYNC_DIR` no `config.env`.

## Rede

**Endereço fixo:** `minezada-mc.duckdns.org`. Quem hospeda reaponta o nome para o próprio IP (no
start e a cada 5 min). O token fica em `duckdns.txt` na pasta do Drive, nunca no git: o primeiro
host com `DUCKDNS_TOKEN` no `config.env` grava o arquivo lá, e os outros hosts pegam de lá sozinhos. Se vazar: crie outro domínio no DuckDNS, troque o nome em `scripts/` e apague o antigo.

**Porta 25565 TCP** precisa chegar no host. Duas formas:

- **UPnP (automático):** se o roteador tiver UPnP ligado, o `iniciar` abre e fecha a porta sozinho
  para a máquina que estiver hospedando (Windows e Mac falam direto com o roteador; no Mac usa o
  `python3` das ferramentas de linha de comando, que o `git` já instala). Ligar UPnP é uma troca de
  segurança: qualquer aparelho da rede pode abrir portas.
- **Manual:** roteador → redirecionar porta `25565 TCP` para o IP local do host, com reserva de IP
  (DHCP) para ele não mudar. Trocou de host na mesma casa: troque o IP da regra.

Teste: com o servidor no ar, um celular no 4G (Wi-Fi desligado) consegue conectar.

Na mesma casa do host o endereço público pode não funcionar (roteador sem NAT loopback, como o da
Vivo): entre por `localhost` na máquina do host ou pelo IP local que o `iniciar` mostra.

**CGNAT** (IP WAN do roteador ≠ IP de https://api.ipify.org): abrir porta não funciona. Saída:
[playit.gg](https://playit.gg) (túnel). No plano grátis o túnel fica fora do Brasil (relatos de
300-400 ms); o plano pago tem região América do Sul.

## Dicas de rede

- Com UPnP ligado, **não** crie regra manual na 25565: ela trava a porta numa máquina e impede o
  UPnP de apontar para outro host.
- Windows: deixe a rede como **Privada** (Configurações → Rede e Internet → Ethernet/Wi-Fi).
- VPNs (Radmin, Hamachi, ZeroTier) ligadas podem atrapalhar o UPnP e o IP detectado: desligue
  enquanto hospeda.
