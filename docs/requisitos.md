# Requisitos

O `iniciar` instala Java e ferramentas sozinho. Este arquivo cobre o que ele não consegue fazer.

## Jogadores

- **Minecraft Java Edition**, original ou não (o servidor roda com `online-mode=false` e senha pelo
  MixAuth para quem não tem original). Bedrock (celular/console) não entra.
- Nada mais: o comando do [README](../README.md) instala o launcher (Prism, ou o fork
  PrismLauncher-Cracked para quem não tem original), o Java e os mods.
- Mac: M1 ou mais novo com 16 GB roda bem; com 8 GB use o perfil Mac 1. O macOS só tem OpenGL 4.1:
  os shaders dos perfis Mac e Shader funcionam, os PC - não. Com o Distant Horizons instalado (é
  opcional) os shaders não cabem no limite de texturas do Mac: use um ou outro.

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

**Endereço principal: túnel [playit.gg](https://playit.gg)**, hoje `molecule-spindle.tun.ply.gg`
(sem porta). O `iniciar` liga o agente e espera ele conectar. Nada para configurar no roteador, o
host pode estar em qualquer rede (casa, faculdade, 4G, CGNAT) e o IP dele não aparece. O segredo do
agente fica em `playit.txt` na pasta do Drive e o endereço em `playit-endereco.txt`, então qualquer
host usa o mesmo túnel. Plano grátis: sem limite de uso, mas a rota não é garantida para quem está
longe (Premium fixa a região em São Paulo). Perdeu o segredo? `playit claim generate`,
`playit claim url <código>`, aprove no site e `playit claim exchange <código>`: a última linha da
saída é o segredo novo.

**Reserva (só se o túnel não conectar): `minezada-mc.duckdns.org`.** O host abre a porta 25565 TCP
(e a 443) no roteador por UPnP e reaponta o nome para o próprio IP (no start e a cada 5 min). Com o
túnel ligado, o host limpa o IP do DuckDNS. O token fica em `duckdns.txt` na pasta do Drive, nunca
no git: o primeiro host com `DUCKDNS_TOKEN` no `config.env` grava o arquivo lá, e os outros hosts
pegam de lá sozinhos. Se vazar: crie outro domínio no DuckDNS, troque o nome em `scripts/` e apague
o antigo. Sem UPnP, a reserva precisa de redirecionamento manual da 25565 TCP para o IP local do
host (com reserva de IP no DHCP). Ligar UPnP é uma troca de segurança: qualquer aparelho da rede pode
abrir portas. Para o máximo de segurança, deixe o UPnP desligado e fique só com o túnel.

Na mesma rede do host (casa, laboratório) o servidor aparece sozinho em **Multijogador**, na parte
de LAN: o `iniciar` anuncia ele como o "Abrir para LAN" do jogo (o firewall do Windows aceita a
25565 só da rede local). Se a rede bloquear o anúncio (Wi-Fi com isolamento entre aparelhos), use
`localhost` na máquina do host ou o IP local que o `iniciar` mostra.

**Jogar de rede que só libera 80/443** (faculdade testada): o túnel usa outra porta e fica
bloqueado. A entrada **Minezada (rede da faculdade)** (porta 443) só funciona na reserva e com um
roteador que repasse a 443; o de casa não repassa (testado em 18/11).

## Dicas de rede

- Com UPnP ligado, **não** crie regra manual na 25565: ela trava a porta numa máquina e impede o
  UPnP de apontar para outro host.
- Windows: deixe a rede de casa como **Privada** (Configurações → Rede e Internet → Ethernet/Wi-Fi);
  em rede pública (faculdade) o túnel funciona igual.
- VPNs (Radmin, Hamachi, ZeroTier) ligadas podem atrapalhar o UPnP e o IP detectado: desligue
  enquanto hospeda.
