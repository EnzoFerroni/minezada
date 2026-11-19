#!/usr/bin/env bash
# Faz tudo para hospedar: atualiza o repo, instala Java, cria config.env, instala/atualiza o pack,
# puxa o mundo da pasta sincronizada, abre a porta (UPnP), atualiza o DuckDNS, roda e devolve o mundo.
# Uso: ./iniciar.command (Mac, duplo clique) ou ./scripts/iniciar.sh [--forcar]
set -euo pipefail

# Tudo dentro de main: o bash le o arquivo enquanto executa, e o git pull pode reescreve-lo.
main() {
  root="$(cd "$(dirname "$0")/.." && pwd)"
  server="$root/server"
  tools="$root/tools"
  porta=25565
  eu="$(hostname -s)"
  forcar=0; [ "${1:-}" = "--forcar" ] && forcar=1
  shopt -s nullglob

  # 1. Repo atualizado: pack e scripts novos chegam sozinhos.
  if [ -d "$root/.git" ] && command -v git >/dev/null; then
    git -C "$root" pull --ff-only || echo "AVISO: git pull falhou; seguindo com a versao local." >&2
  fi

  # 2. config.env na primeira vez, com o que der para detectar.
  if [ ! -f "$root/config.env" ]; then
    echo "Primeira vez nesta maquina: criando config.env."
    bytes="$(sysctl -n hw.memsize 2>/dev/null || awk '/MemTotal/{print $2*1024}' /proc/meminfo)"
    gb=$((bytes / 1073741824))
    if [ $gb -ge 24 ]; then ram=8G; elif [ $gb -ge 12 ]; then ram=6G; else ram=4G; fi
    printf 'RAM=%s\nSYNC_DIR=""\nJAVA=java\nDUCKDNS_TOKEN=\n' "$ram" > "$root/config.env"
  fi

  RAM=6G; SYNC_DIR=""; JAVA=java; DUCKDNS_DOMAIN=minezada-mc; DUCKDNS_TOKEN=""; SEM_DRIVE=""
  . "$root/config.env"

  # Pasta do Drive: acha sozinho; faltou, oferece instalar e configurar ("n" nao pergunta mais).
  if [ -z "$SYNC_DIR" ]; then
    SYNC_DIR="$(achar_drive)"
    [ -n "$SYNC_DIR" ] || [ "$SEM_DRIVE" = 1 ] || configurar_drive
    if [ -n "$SYNC_DIR" ]; then
      echo "Pasta do Google Drive: $SYNC_DIR"
      { grep -v '^SYNC_DIR=' "$root/config.env" || true; echo "SYNC_DIR=\"$SYNC_DIR\""; } > "$root/config.env.tmp"
      mv -f "$root/config.env.tmp" "$root/config.env"
    fi
  fi

  # Token do DuckDNS mora na pasta do Drive (fora do git): quem tem o token no config.env grava la,
  # e os outros hosts pegam de la sem precisar perguntar a ninguem.
  if [ -n "$SYNC_DIR" ] && [ -d "$SYNC_DIR" ]; then
    if [ -n "$DUCKDNS_TOKEN" ]; then
      [ -f "$SYNC_DIR/duckdns.txt" ] || echo "$DUCKDNS_TOKEN" > "$SYNC_DIR/duckdns.txt"
    elif [ -f "$SYNC_DIR/duckdns.txt" ]; then
      DUCKDNS_TOKEN="$(tr -d '[:space:]' < "$SYNC_DIR/duckdns.txt")"
    fi
  fi

  # 3. Java 21+ (no macOS /usr/bin/java existe mesmo sem JDK, por isso testa rodando). Faltou ou e
  # antigo: baixa o Temurin 25 para tools/, sem Homebrew nem senha de administrador.
  if ! java_ok "$JAVA"; then
    jre="$tools/jre/Contents/Home/bin/java"; [ "$(uname -s)" = "Darwin" ] || jre="$tools/jre/bin/java"
    if ! java_ok "$jre"; then
      echo "Instalando Java 25..."
      case "$(uname -s)" in Darwin) os=mac ;; *) os=linux ;; esac
      case "$(uname -m)" in arm64|aarch64) arch=aarch64 ;; *) arch=x64 ;; esac
      rm -rf "$tools/jre"; mkdir -p "$tools/jre"
      curl -fsSL "https://api.adoptium.net/v3/binary/latest/25/ga/$os/$arch/jre/hotspot/normal/eclipse" \
        | tar -xz -C "$tools/jre" --strip-components 1 || die "Download do Java falhou."
    fi
    JAVA="$jre"
    java_ok "$JAVA" || die "Java nao instalado. Veja docs/hospedar.md"
  fi

  # 4. Pack -> servidor, tudo via Java. O mrpack-install (Go) tem DNS proprio e falha em roteador com
  # DNS IPv6 quebrado (comum em roteador de operadora); o Java usa o DNS do macOS.
  neo="$(sed -n 's/^neoforge = "\(.*\)"/\1/p' "$root/modpack/pack/pack.toml")"
  [ -n "$neo" ] || die "Versao do NeoForge nao encontrada em modpack/pack/pack.toml."
  mkdir -p "$server"
  if [ ! -f "$server/libraries/net/neoforged/neoforge/$neo/unix_args.txt" ]; then
    echo "Instalando NeoForge $neo..."
    curl -fsSL "https://maven.neoforged.net/releases/net/neoforged/neoforge/$neo/neoforge-$neo-installer.jar" \
      -o "$server/neoforge-installer.jar"
    (cd "$server" && "$JAVA" -jar neoforge-installer.jar --installServer . >/dev/null) || die "Instalacao do NeoForge falhou."
    rm -f "$server/neoforge-installer.jar" "$server/neoforge-installer.jar.log"
  fi
  # Servidor montado pelo mrpack-install antigo: limpa os mods para o packwiz assumir sem duplicar.
  [ -f "$server/packwiz.json" ] || rm -rf "$server/mods"
  unzip -o -q -j "$root/modpack/minezada-prism.zip" .minecraft/packwiz-installer-bootstrap.jar .minecraft/packwiz-installer.jar -d "$server"
  # Idempotente: sem mudanca no pack, nao baixa nada. "-s server" pula os mods so de cliente.
  (cd "$server" && "$JAVA" -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -g -s server "file://${root// /%20}/modpack/pack/pack.toml") \
    || die "Instalacao dos mods falhou."

  if ! grep -qs 'eula=true' "$server/eula.txt"; then
    read -rp 'Voce aceita o EULA do Minecraft (https://aka.ms/MinecraftEULA)? [s/N] ' r
    [ "$r" = "s" ] || die "EULA nao aceito."
    echo 'eula=true' > "$server/eula.txt"
  fi
  cp -R "$root"/server-config/. "$server/"

  # 5. Mundo da pasta sincronizada, com trava para so um host por vez.
  if [ -n "$SYNC_DIR" ]; then
    [ -d "$SYNC_DIR" ] || die "SYNC_DIR nao existe: $SYNC_DIR"
    lock="$SYNC_DIR/host.lock"
    estado="$SYNC_DIR/mundo.tar.gz"
    dono=""; [ -f "$lock" ] && dono="$(tr -d '[:space:]' < "$lock")"
    if [ -n "$dono" ] && [ "$dono" != "$eu" ] && [ $forcar -eq 0 ]; then
      die "Servidor ja esta ativo em '$dono'. Se tiver certeza que nao esta, rode com --forcar."
    fi
    # Trava ja era desta maquina = ultima sessao caiu sem enviar; o mundo local e o mais novo.
    if [ "$dono" != "$eu" ] && [ -f "$estado" ]; then
      echo "Baixando mundo da pasta sincronizada..."
      # Extrai a parte e confere antes de mexer no mundo local ou pegar a trava: um arquivo corrompido
      # nao pode virar o mundo desta maquina (ele seria enviado por cima do bom no proximo stop).
      novo="$server/.mundo-novo"; rm -rf "$novo"; mkdir -p "$novo"
      if ! tar -xzf "$estado" -C "$novo" || [ ! -d "$novo/world" ]; then
        rm -rf "$novo"
        die "mundo.tar.gz corrompido. Copie o mais novo de $SYNC_DIR/backups por cima dele e rode de novo."
      fi
      if [ -d "$server/world" ]; then rm -rf "$server/world.bak"; mv "$server/world" "$server/world.bak"; fi
      for f in "$novo"/*; do rm -rf "${server:?}/$(basename "$f")"; mv "$f" "$server/"; done
      rm -rf "$novo"
    fi
    # shortcut: a trava depende da nuvem ja ter sincronizado; dois hosts iniciando no mesmo minuto podem passar os dois.
    echo "$eu" > "$lock"
  fi
  # Whitelist e admins: lista na pasta do Drive (vale para todos os hosts) ou, sem Drive, no servidor.
  lista="$server/jogadores.txt"; [ -z "$SYNC_DIR" ] || lista="$SYNC_DIR/jogadores.txt"
  sincronizar_whitelist "$lista" "$server"

  # 6. Rede: tunel playit e, so se ele falhar, porta no roteador (UPnP) e DuckDNS.
  # IP da placa da rota padrao (en0 nem sempre e a que vai para a internet).
  ifc="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
  ip="$(ipconfig getifaddr "${ifc:-en0}" 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
  echo "Na mesma casa: entre por localhost (nesta maquina) ou $ip (outro computador)."
  cf_pid=""; tunel_pid=""; ddns_pid=""; reserva=""
  url="https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}"
  iniciar_cloudflare || true
  iniciar_tunel || true
  if [ -n "$cf_pid$tunel_pid" ]; then
    # Tira o IP desta casa do DuckDNS: o endereco de reserva so aponta para um host quando ele precisa.
    [ -z "$DUCKDNS_TOKEN" ] || curl -fsS "$url&clear=true" >/dev/null 2>&1 || true
  else
    reserva=1
    echo "Reserva: abrindo a porta $porta no roteador (UPnP)."
    if porta_upnp abrir "$ip" $porta; then
      echo "Porta $porta aberta via UPnP."
    else
      echo "AVISO: UPnP indisponivel: so quem esta nesta rede consegue entrar (ou redirecione a porta no roteador)." >&2
    fi
    if [ -n "$DUCKDNS_TOKEN" ]; then
      # Reaponta o nome para este host e repete a cada 5 min caso o IP mude durante a sessao.
      ( while true; do curl -fsS "$url" >/dev/null 2>&1 || true; sleep 300; done ) &
      ddns_pid=$!
      echo "Endereco do servidor (reserva): ${DUCKDNS_DOMAIN}.duckdns.org (na lista do jogo: Minezada (reserva))"
    fi
  fi

  # Anuncia o servidor na rede local como o "Abrir para LAN" do jogo: quem esta na mesma rede ve
  # "Minezada" sozinho em Multijogador, sem digitar IP.
  lan_pid=""
  if [ "$(uname -s)" != "Darwin" ] || xcode-select -p >/dev/null 2>&1; then
    if command -v python3 >/dev/null; then
      python3 -c '
import socket, sys, time
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 1)
try:
    s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_IF, socket.inet_aton(sys.argv[1]))
except OSError:
    pass
msg = ("[MOTD]Minezada[/MOTD][AD]" + sys.argv[2] + "[/AD]").encode()
while True:
    try:
        s.sendto(msg, ("224.0.2.60", 4445))
    except OSError:
        pass
    time.sleep(1.5)' "${ip:-0.0.0.0}" "$porta" >/dev/null 2>&1 &
      lan_pid=$!
    fi
  fi
  trap 'kill $ddns_pid $lan_pid $tunel_pid $cf_pid 2>/dev/null || true' EXIT

  echo "Iniciando servidor com $RAM de RAM. Para desligar e salvar: digite 'stop', aperte Ctrl+C ou feche esta janela."
  # Flags do Aikar: coleta de lixo G1 ajustada para servidor de Minecraft (menos travadas).
  flags="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
  rodar_servidor "$JAVA" "-Xms$RAM" "-Xmx$RAM" $flags "@libraries/net/neoforged/neoforge/$neo/unix_args.txt" nogui

  kill $ddns_pid $lan_pid $tunel_pid $cf_pid 2>/dev/null || true
  if [ -n "$reserva" ]; then
    porta_upnp fechar "$ip" $porta || true
    # Servidor desligado: o IP desta casa sai do DuckDNS.
    [ -z "$ddns_pid" ] || curl -fsS "$url&clear=true" >/dev/null 2>&1 || true
  fi

  [ -z "$SYNC_DIR" ] || enviar_mundo
}

die() { echo "ERRO: $*" >&2; exit 1; }

# Roda o servidor (comando nos argumentos, dentro de $server) ate ele desligar por stop, Ctrl+C ou janela fechada.
# O java fica em segundo plano com o teclado (<&0) e o script esperando por ele: assim os sinais chegam no script,
# que repassa SIGTERM ao java, e a JVM salva o mundo antes de sair. Com o java em primeiro plano o bash so trata o
# sinal depois que ele sai, e o macOS manda o SIGHUP da janela fechada so para o bash (issue #7). Processo em
# segundo plano nasce ignorando SIGINT (a JVM respeita), por isso o Ctrl+C tambem vira SIGTERM pelo trap.
rodar_servidor() {
  mkdir -p "$server/logs"
  (cd "$server" && exec "$@") <&0 &
  java_pid=$!
  # caffeinate -w (Mac acordado enquanto o java viver) fica ao lado, nao na frente do java: na frente, o SIGTERM
  # matava o caffeinate e o java seguia rodando com a trava presa.
  if command -v caffeinate >/dev/null; then caffeinate -i -w "$java_pid" & fi
  trap 'kill -TERM "$java_pid" 2>/dev/null || true' INT TERM
  # Janela fechada: o terminal sumiu, e escrever nele da erro (com set -e o envio do mundo parava). O resto da
  # saida vai para o registro.
  # O SIGHUP pode chegar mais de uma vez: o trap '' HUP faz o aviso sair uma vez so.
  trap 'trap "" HUP; exec >>"$server/logs/iniciar.log" 2>&1; echo "Janela fechada: desligando o servidor."; kill -TERM "$java_pid" 2>/dev/null || true' HUP
  # Espera com sleep em primeiro plano: o Ctrl+C mata o sleep e o trap roda na hora, em qualquer bash (o do macOS
  # e o 3.2). Testado em scripts/testes/desligar.sh.
  while kill -0 "$java_pid" 2>/dev/null; do sleep 1 || true; done
  wait "$java_pid" 2>/dev/null || true
  trap - INT TERM
  # Janela fechada durante o envio do mundo: o envio termina, com a saida no registro.
  trap 'exec >>"$server/logs/iniciar.log" 2>&1' HUP
}

# Envia o mundo para a pasta sincronizada, guarda os 5 ultimos e libera a trava.
enviar_mundo() {
  local estado="$SYNC_DIR/mundo.tar.gz" f itens
  itens=()
  echo "Enviando mundo para a pasta sincronizada..."
  for f in world ops.json whitelist.json banned-players.json banned-ips.json; do [ -e "$server/$f" ] && itens+=("$f"); done
  # COPYFILE_DISABLE: o tar do macOS nao embute arquivos ._* (metadados) que iriam parar no Windows.
  if COPYFILE_DISABLE=1 tar -czf "$estado.tmp" -C "$server" "${itens[@]}"; then
    mv -f "$estado.tmp" "$estado"
    # Guarda os 5 ultimos mundos com data, caso um envio saia corrompido.
    mkdir -p "$SYNC_DIR/backups"
    cp "$estado" "$SYNC_DIR/backups/mundo-$(date +%Y%m%d-%H%M).tar.gz"
    ls -1 "$SYNC_DIR"/backups/mundo-*.tar.gz | sort -r | tail -n +6 | while read -r f; do rm -f "$f"; done
    rm -f "$SYNC_DIR/host.lock"
    echo "Pronto. Outro host ja pode iniciar."
  else
    echo "AVISO: falha ao enviar o mundo. Trava mantida em $eu; rode de novo nesta maquina." >&2
  fi
}

# Abre (ou fecha) a porta no roteador por UPnP, falando SSDP/SOAP direto com ele (mesmo jeito do
# iniciar.ps1), sem miniupnpc nem Homebrew. Uso: porta_upnp abrir|fechar IP PORTA [PORTA_EXTERNA]
porta_upnp() {
  # Sem as ferramentas de linha de comando, o python3 do macOS abre um dialogo de instalacao.
  if [ "$(uname -s)" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then return 1; fi
  command -v python3 >/dev/null || return 1
  python3 - "$@" >/dev/null 2>&1 <<'PY'
import re, socket, sys, urllib.request
from urllib.parse import urljoin
abrir, ip, porta = sys.argv[1] == "abrir", sys.argv[2], sys.argv[3]
externa = sys.argv[4] if len(sys.argv) > 4 else porta
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind((ip, 0))  # sai pela placa da internet, nao por VPN
s.settimeout(3)
s.sendto(b'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 2\r\n'
         b'ST: urn:schemas-upnp-org:device:InternetGatewayDevice:1\r\n\r\n', ("239.255.255.250", 1900))
loc = re.search(r"(?im)^location:\s*(\S+)", s.recv(4096).decode(errors="ignore")).group(1)
xml = urllib.request.urlopen(loc, timeout=5).read().decode(errors="ignore")
acao = "AddPortMapping" if abrir else "DeletePortMapping"
campos = f"<NewRemoteHost></NewRemoteHost><NewExternalPort>{externa}</NewExternalPort><NewProtocol>TCP</NewProtocol>"
if abrir:
    campos += (f"<NewInternalPort>{porta}</NewInternalPort><NewInternalClient>{ip}</NewInternalClient>"
               "<NewEnabled>1</NewEnabled><NewPortMappingDescription>minezada {externa}</NewPortMappingDescription>"
               "<NewLeaseDuration>0</NewLeaseDuration>")
servicos = re.findall(r"<serviceType>(urn:schemas-upnp-org:service:WAN(?:IP|PPP)Connection:\d)</serviceType>"
                      r".*?<controlURL>([^<]+)</controlURL>", xml, re.S)
for tipo, ctrl in servicos:  # roteador pode anunciar WANIP e WANPPP; so um aceita
    corpo = (f'<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
             f's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
             f'<u:{acao} xmlns:u="{tipo}">{campos}</u:{acao}></s:Body></s:Envelope>')
    req = urllib.request.Request(urljoin(loc, ctrl), corpo.encode(),
                                 {"Content-Type": 'text/xml; charset="utf-8"', "SOAPAction": f'"{tipo}#{acao}"'})
    try:
        urllib.request.urlopen(req, timeout=5)
        sys.exit(0)
    except Exception:
        pass
sys.exit(1)
PY
}

# Tunel da Cloudflare: endereco principal (minezada.dpdns.org). O jogador conecta como HTTPS na 443 (o mod
# Modflared liga o cloudflared nele), entao passa em rede de faculdade e Wi-Fi publico. O host so faz conexao
# de saida (porta 7844). O token fica em cloudflare.txt na pasta do Drive. Preenche cf_pid; falha (1) se nao conectar.
iniciar_cloudflare() {
  local tok="$SYNC_DIR/cloudflare.txt" dir="$tools/cloudflared" log="$server/logs/cloudflared.log" arq sha
  if [ -z "$SYNC_DIR" ] || [ ! -f "$tok" ]; then echo "Sem tunel da Cloudflare (precisa de cloudflare.txt na pasta do Drive)."; return 1; fi
  if [ "$(uname -s)" != "Darwin" ]; then echo "Tunel da Cloudflare automatico so no Mac e no Windows."; return 1; fi
  # Versao fixa com o SHA-256 do release oficial. Atualizar: trocar a versao e os hashes (campo digest da API).
  case "$(uname -m)" in
    arm64) arq=arm64; sha=3586ccf397e98e5f437e60e7c307ca6ac463e110580503af8bb8e6f9ebf831bd ;;
    *) arq=amd64; sha=02f3edfd87684dd5b705607688e4eb4b323f6e777b81e7b3a85af556aa356848 ;;
  esac
  if [ ! -x "$dir/cloudflared" ] || [ "$(cat "$dir/versao" 2>/dev/null)" != "2026.10.7-$arq" ]; then
    echo "Baixando o cloudflared..."
    mkdir -p "$dir"
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/download/2026.10.7/cloudflared-darwin-$arq.tgz" -o "$dir/cf.tgz"
    if [ "$(shasum -a 256 "$dir/cf.tgz" | awk '{print $1}')" != "$sha" ]; then
      rm -f "$dir/cf.tgz"; echo "AVISO: checksum do cloudflared nao confere; tunel nao ligado." >&2; return 1
    fi
    tar -xzf "$dir/cf.tgz" -C "$dir" && rm -f "$dir/cf.tgz" && chmod +x "$dir/cloudflared" && echo "2026.10.7-$arq" > "$dir/versao"
  fi
  pkill -f "$dir/cloudflared" 2>/dev/null || true
  mkdir -p "$server/logs"; rm -f "$log"
  # --token-file: o token nao aparece na lista de processos. Opcoes globais antes do "run".
  "$dir/cloudflared" tunnel --no-autoupdate --logfile "$log" run --token-file "$tok" >/dev/null 2>&1 &
  cf_pid=$!
  echo "Ligando o tunel da Cloudflare..."
  for _ in $(seq 1 40); do grep -q 'Registered tunnel connection' "$log" 2>/dev/null && break; sleep 0.5; done
  if ! grep -q 'Registered tunnel connection' "$log" 2>/dev/null; then
    kill "$cf_pid" 2>/dev/null || true; cf_pid=""
    echo "AVISO: o tunel da Cloudflare nao conectou (detalhes em $log)." >&2
    return 1
  fi
  echo "Endereco do servidor: minezada.dpdns.org (tunel da Cloudflare)"
}

# Tunel playit.gg: segunda entrada (o jogador entra por ele se a Cloudflare falhar). Sem porta aberta no roteador
# e sem expor o IP do host. O segredo do agente fica em playit.txt na pasta do Drive: todo host usa o
# mesmo tunel e endereco (anotado em playit-endereco.txt). Preenche tunel_pid; falha (1) se nao conectar.
iniciar_tunel() {
  local seg="$SYNC_DIR/playit.txt" dir="$tools/playit" tgz log="$server/logs/playit.log"
  if [ -z "$SYNC_DIR" ] || [ ! -f "$seg" ]; then
    echo "Sem tunel playit.gg (precisa da pasta do Drive)."
    return 1
  fi
  if [ "$(uname -s)" != "Darwin" ]; then echo "Tunel playit.gg automatico so no Mac e no Windows."; return 1; fi
  if [ ! -x "$dir/playitd" ]; then
    echo "Baixando o playit.gg..."
    mkdir -p "$dir"; tgz="$dir/playit.tar.gz"
    curl -fsSL "https://github.com/playit-cloud/playit-agent/releases/download/v2.0.2/playit-macos-universal.tar.gz" -o "$tgz"
    # SHA-256 publicado na release: so roda o binario se bater.
    if [ "$(shasum -a 256 "$tgz" | awk '{print $1}')" != d3da262f8c58bfc13797a1bbf2e3fcc6d487e4e6832f54b35c00daeb59e1cce2 ]; then
      rm -f "$tgz"; echo "AVISO: checksum do playit.gg nao confere; tunel nao ligado." >&2; return 1
    fi
    tar -xzf "$tgz" -C "$dir" --strip-components 1; rm -f "$tgz"
  fi
  # Agente que sobrou de uma sessao fechada sem stop (janela fechada).
  pkill -f "$dir/playitd" 2>/dev/null || true
  # Socket em TMPDIR: o macOS limita o caminho de socket a ~104 caracteres.
  mkdir -p "$server/logs"; rm -f "$log"
  # --cert-dir: sem ele o playit cria a pasta certs ao lado do segredo, dentro do Drive.
  "$dir/playitd" --secret-path "$seg" --socket-path "${TMPDIR:-/tmp}/minezada-playit.sock" --cert-dir "$dir/certs" \
    -l "$log" >/dev/null 2>&1 &
  tunel_pid=$!
  echo "Ligando o tunel playit.gg..."
  for _ in $(seq 1 40); do grep -q 'playit connected' "$log" 2>/dev/null && break; sleep 0.5; done
  if ! grep -q 'playit connected' "$log" 2>/dev/null; then
    kill "$tunel_pid" 2>/dev/null || true; tunel_pid=""
    echo "AVISO: o tunel playit.gg nao conectou (detalhes em $log)." >&2
    return 1
  fi
  echo "Endereco do servidor (tunel): $(cat "$SYNC_DIR/playit-endereco.txt" 2>/dev/null || echo 'veja no painel do playit.gg')"
}

# Link da pasta minezada no Drive: quem nao tem acesso ve o botao "Solicitar acesso".
drive_url="https://drive.google.com/drive/folders/1Kw45U0B-b906dnDsUH8bLy9nDg7HfWzh"

# Libera na whitelist os nicks de jogadores.txt (um por linha; "op" depois do nick tambem da admin),
# MixAuth: quem tem original entra com o UUID oficial (so ele e liberado); sem original, com o offline. Sem o arquivo, cria com o dono e quem ja esta
# liberado. So adiciona; tirar alguem e no console. Uso: sincronizar_whitelist LISTA PASTA_DO_SERVIDOR
sincronizar_whitelist() {
  if [ "$(uname -s)" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then return 0; fi
  command -v python3 >/dev/null || return 0
  python3 - "$@" <<'PY' || echo "AVISO: falha ao atualizar a whitelist." >&2
import hashlib, json, os, re, shutil, sys, urllib.error, urllib.request, uuid
lista, pasta = sys.argv[1], sys.argv[2]
def offline(nome):  # mesmo UUID que o servidor da ao nick sem conta Microsoft (maiusculas contam)
    return str(uuid.UUID(bytes=hashlib.md5(b"OfflinePlayer:" + nome.encode()).digest(), version=3))
def ler(nome):
    arq = os.path.join(pasta, nome)
    return json.load(open(arq)) if os.path.exists(arq) else []
wl, ops = ler("whitelist.json"), ler("ops.json")
mundo = os.path.join(pasta, "world")
# UUID oficial ja conhecido (whitelist/ops) evita consultar a Mojang a cada start.
oficiais = {e["name"].lower(): e["uuid"] for e in wl + ops if e["uuid"] != offline(e["name"])}
FALHA = object()  # a Mojang nao respondeu: nao mexe nas entradas deste nick neste start
def oficial(nome):
    if nome.lower() in oficiais:
        return oficiais[nome.lower()]
    # Dois enderecos da Mojang: rede compartilhada (faculdade) costuma levar 429 em um deles.
    for url in ("https://api.mojang.com/users/profiles/minecraft/",
                "https://api.minecraftservices.com/minecraft/profile/lookup/name/"):
        try:
            return str(uuid.UUID(json.load(urllib.request.urlopen(url + nome, timeout=5))["id"]))
        except urllib.error.HTTPError as e:
            if e.code == 404:  # nick sem conta original
                return None
        except Exception:
            pass
    print(f"AVISO: a Mojang nao respondeu sobre {nome}; whitelist dele fica como estava ate o proximo start.")
    return FALHA
if not os.path.exists(lista):
    with open(lista, "w") as f:
        f.write("# Um nick por linha, igual ao do jogo (maiusculas contam); 'op' depois tambem da admin.\n"
                "# 'sem-original' depois: joga sem Minecraft original com um nick que existe como conta original.\n"
                "# O servidor libera todos ao iniciar: depois de editar, reinicie. Nao use whitelist add no console.\nEnzobullet op\n")
        f.writelines(e["name"] + "\n" for e in wl if e["name"].lower() != "enzobullet")
for linha in open(lista, encoding="utf-8-sig"):
    partes = linha.split("#")[0].split()
    if not partes:
        continue
    nome = partes[0]
    if not re.fullmatch(r"[A-Za-z0-9_]{1,16}", nome):  # nick valido do Java
        print(f"AVISO: nick invalido em jogadores.txt: {nome}")
        continue
    flags = [x.lower() for x in partes[1:]]
    op, off = "op" in flags, offline(nome)
    on = None if "sem-original" in flags else oficial(nome)
    if on is FALHA:
        continue
    if on:
        # Nick com original: so o UUID oficial. O offline liberado deixaria qualquer um sem original
        # entrar com esse nick (o MixAuth so pede senha) e herdar op e progresso.
        for nome_arq, dados in (("whitelist", wl), ("ops", ops)):
            if any(e["uuid"] == off for e in dados):
                dados[:] = [e for e in dados if e["uuid"] != off]
                print(f"UUID offline de {nome} tirado de {nome_arq} (ele tem original).")
        # Progresso de antes (UUID offline) copiado para o oficial, so se o oficial ainda nao tem nada.
        for sub, ext in (("playerdata", ".dat"), ("advancements", ".json"), ("stats", ".json")):
            de, para = (os.path.join(mundo, sub, u + ext) for u in (off, on))
            if os.path.exists(de) and not os.path.exists(para):
                shutil.copy2(de, para)
                print(f"Progresso de {nome} copiado para o UUID oficial: {sub}/{on}{ext}")
    u = on or off
    if u not in {e["uuid"] for e in wl}:
        wl.append({"uuid": u, "name": nome})
        print(f"Liberado na whitelist: {nome} ({'original' if on else 'sem original'})")
    if op and u not in {e["uuid"] for e in ops}:
        ops.append({"uuid": u, "name": nome, "level": 4, "bypassesPlayerLimit": False})
        print(f"Admin (op): {nome}")
for nome, dados in (("whitelist.json", wl), ("ops.json", ops)):
    with open(os.path.join(pasta, nome), "w") as f:
        json.dump(dados, f, indent=2)
PY
}

achar_drive() {
  local d
  for d in "$HOME"/Library/CloudStorage/GoogleDrive-*/"Meu Drive"/minezada \
           "$HOME"/Library/CloudStorage/GoogleDrive-*/"My Drive"/minezada; do
    [ -d "$d" ] && { echo "$d"; break; }
  done
  true
}

# Instala o Google Drive, abre o login e a pasta, e espera ela aparecer no Mac. Preenche SYNC_DIR.
configurar_drive() {
  local r tmp
  echo
  echo "Recomendado: Google Drive com a pasta 'minezada'. Ele guarda o mundo compartilhado, entao"
  echo "qualquer pessoa pode hospedar e continuar de onde a outra parou. Sem ele o mundo fica so aqui."
  read -rp "Configurar o Google Drive agora? [S/n] " r
  case "$r" in n|N) echo "SEM_DRIVE=1" >> "$root/config.env"; return ;; esac
  if [ "$(uname -s)" != "Darwin" ]; then echo "Instale o Google Drive e rode de novo."; return; fi
  if [ ! -d "/Applications/Google Drive.app" ]; then
    echo "Instalando o Google Drive (o Mac vai pedir a sua senha)..."
    tmp="$(mktemp -d)"
    if curl -fsSL https://dl.google.com/drive-file-stream/GoogleDrive.dmg -o "$tmp/drive.dmg" \
      && hdiutil attach -nobrowse -quiet -mountpoint "$tmp/m" "$tmp/drive.dmg"; then
      # So instala com sudo se o pacote for assinado pela Google (Team ID EQHXZ8M8AV).
      if pkgutil --check-signature "$tmp/m/GoogleDrive.pkg" | grep -q 'Developer ID Installer: Google LLC (EQHXZ8M8AV)'; then
        sudo installer -pkg "$tmp/m/GoogleDrive.pkg" -target / >/dev/null || echo "AVISO: instalacao do Google Drive falhou." >&2
      else
        echo "AVISO: instalador do Google Drive sem a assinatura da Google; nao instalado." >&2
      fi
      hdiutil detach -quiet "$tmp/m" || true
    else
      echo "AVISO: download do Google Drive falhou." >&2
    fi
    rm -rf "$tmp"
  fi
  open -a "Google Drive" 2>/dev/null || true
  open "$drive_url"
  echo
  echo "1. Entre com a sua conta Google no Google Drive que abriu."
  echo "2. No navegador, abra a pasta 'minezada' e clique em 'Adicionar atalho ao Drive' > 'Meu Drive'."
  echo "   Sem acesso? Clique em 'Solicitar acesso' e avise o Enzo."
  echo "Esperando a pasta aparecer neste Mac (Enter para pular e jogar com o mundo so aqui)..."
  while :; do
    SYNC_DIR="$(achar_drive)"
    [ -n "$SYNC_DIR" ] && return
    if read -rt 5; then echo "Pulado: na proxima vez o script pergunta de novo."; return; fi
  done
}

# Versao principal do Java >= 21 (NeoForge 1.21.1). "1.8.0" vira 1.
java_ok() {
  local v
  v="$("$1" -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -n 1)"
  [ "${v:-0}" -ge 21 ]
}

# MINEZADA_TESTE=1: so carrega as funcoes, para os testes (scripts/testes/).
[ -n "${MINEZADA_TESTE:-}" ] || { main "$@"; exit; }
