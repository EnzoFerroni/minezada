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
    java_ok "$JAVA" || die "Java nao instalado. Veja docs/requisitos.md"
  fi

  # 4. Pack -> servidor, tudo via Java. O mrpack-install (Go) tem DNS proprio e falha em roteador com
  # DNS IPv6 quebrado (comum na operadora); o Java usa o DNS do macOS.
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
  unzip -o -q -j "$root/modpack/minezada-prism.zip" .minecraft/packwiz-installer-bootstrap.jar -d "$server"
  # Idempotente: sem mudanca no pack, nao baixa nada. "-s server" pula os mods so de cliente.
  (cd "$server" && "$JAVA" -jar packwiz-installer-bootstrap.jar -g -s server "file://${root// /%20}/modpack/pack/pack.toml") \
    || die "Instalacao dos mods falhou."

  if ! grep -qs 'eula=true' "$server/eula.txt"; then
    read -rp 'Voce aceita o EULA do Minecraft (https://aka.ms/MinecraftEULA)? [s/N] ' r
    [ "$r" = "s" ] || die "EULA nao aceito."
    echo 'eula=true' > "$server/eula.txt"
  fi
  cp "$root"/server-config/* "$server/"

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

  # 6. Rede: porta (UPnP) e endereco.
  # IP da placa da rota padrao (en0 nem sempre e a que vai para a internet).
  ifc="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
  ip="$(ipconfig getifaddr "${ifc:-en0}" 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
  # Roteador sem NAT loopback (ex.: operadora) nao deixa quem esta na mesma casa entrar pelo endereco publico.
  echo "Na mesma casa: entre por localhost (nesta maquina) ou $ip (outro computador)."
  tunel_pid=""
  if porta_upnp abrir "$ip" $porta; then
    echo "Porta $porta aberta via UPnP."
  else
    echo "Esta rede nao deixou abrir a porta $porta (UPnP indisponivel)."
    iniciar_tunel
  fi

  ddns_pid=""
  if [ -n "$DUCKDNS_TOKEN" ]; then
    url="https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}"
    # Reaponta o nome para este host e repete a cada 5 min caso o IP mude durante a sessao.
    ( while true; do curl -fsS "$url" >/dev/null 2>&1 || true; sleep 300; done ) &
    ddns_pid=$!
    echo "Endereco do servidor: ${DUCKDNS_DOMAIN}.duckdns.org"
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
  trap 'kill $ddns_pid $lan_pid $tunel_pid 2>/dev/null || true' EXIT

  echo "Iniciando servidor com $RAM de RAM. Digite 'stop' para desligar e salvar."
  # caffeinate impede o Mac de dormir enquanto o servidor roda. String sem aspas de proposito:
  # array vazio com set -u quebra no bash 3.2 do macOS.
  cafe=""; command -v caffeinate >/dev/null && cafe="caffeinate -i"
  trap 'true' INT  # Ctrl+C derruba so o java (que salva o mundo); o script segue para o envio
  # Flags do Aikar: coleta de lixo G1 ajustada para servidor de Minecraft (menos travadas).
  flags="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
  (cd "$server" && $cafe "$JAVA" "-Xms$RAM" "-Xmx$RAM" $flags "@libraries/net/neoforged/neoforge/$neo/unix_args.txt" nogui) || true
  trap - INT

  kill $ddns_pid $lan_pid $tunel_pid 2>/dev/null || true
  porta_upnp fechar "$ip" $porta || true

  if [ -n "$SYNC_DIR" ]; then
    echo "Enviando mundo para a pasta sincronizada..."
    itens=()
    for f in world ops.json whitelist.json banned-players.json banned-ips.json; do [ -e "$server/$f" ] && itens+=("$f"); done
    # COPYFILE_DISABLE: o tar do macOS nao embute arquivos ._* (metadados) que iriam parar no Windows.
    if COPYFILE_DISABLE=1 tar -czf "$estado.tmp" -C "$server" "${itens[@]}"; then
      mv -f "$estado.tmp" "$estado"
      # Guarda os 5 ultimos mundos com data, caso um envio saia corrompido.
      mkdir -p "$SYNC_DIR/backups"
      cp "$estado" "$SYNC_DIR/backups/mundo-$(date +%Y%m%d-%H%M).tar.gz"
      ls -1 "$SYNC_DIR"/backups/mundo-*.tar.gz | sort -r | tail -n +6 | while read -r f; do rm -f "$f"; done
      rm -f "$lock"
      echo "Pronto. Outro host ja pode iniciar."
    else
      echo "AVISO: falha ao enviar o mundo. Trava mantida em $eu; rode de novo nesta maquina." >&2
    fi
  fi
}

die() { echo "ERRO: $*" >&2; exit 1; }

# Abre (ou fecha) a porta no roteador por UPnP, falando SSDP/SOAP direto com ele (mesmo jeito do
# iniciar.ps1), sem miniupnpc nem Homebrew. Uso: porta_upnp abrir|fechar IP PORTA
porta_upnp() {
  # Sem as ferramentas de linha de comando, o python3 do macOS abre um dialogo de instalacao.
  if [ "$(uname -s)" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then return 1; fi
  command -v python3 >/dev/null || return 1
  python3 - "$@" >/dev/null 2>&1 <<'PY'
import re, socket, sys, urllib.request
from urllib.parse import urljoin
abrir, ip, porta = sys.argv[1] == "abrir", sys.argv[2], sys.argv[3]
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind((ip, 0))  # sai pela placa da internet, nao por VPN
s.settimeout(3)
s.sendto(b'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 2\r\n'
         b'ST: urn:schemas-upnp-org:device:InternetGatewayDevice:1\r\n\r\n', ("239.255.255.250", 1900))
loc = re.search(r"(?im)^location:\s*(\S+)", s.recv(4096).decode(errors="ignore")).group(1)
xml = urllib.request.urlopen(loc, timeout=5).read().decode(errors="ignore")
acao = "AddPortMapping" if abrir else "DeletePortMapping"
campos = f"<NewRemoteHost></NewRemoteHost><NewExternalPort>{porta}</NewExternalPort><NewProtocol>TCP</NewProtocol>"
if abrir:
    campos += (f"<NewInternalPort>{porta}</NewInternalPort><NewInternalClient>{ip}</NewInternalClient>"
               "<NewEnabled>1</NewEnabled><NewPortMappingDescription>minezada</NewPortMappingDescription>"
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

# Tunel playit.gg para hospedar de redes que nao deixam abrir porta (faculdade, laboratorio, 4G).
# O segredo do agente fica em playit.txt na pasta do Drive: todo host usa o mesmo tunel e endereco
# (anotado em playit-endereco.txt). Preenche tunel_pid.
iniciar_tunel() {
  local seg="$SYNC_DIR/playit.txt" dir="$tools/playit" tgz
  if [ -z "$SYNC_DIR" ] || [ ! -f "$seg" ]; then
    echo "Sem tunel playit.gg (precisa da pasta do Drive): so quem esta nesta rede consegue entrar."
    return 0
  fi
  if [ "$(uname -s)" != "Darwin" ]; then echo "Tunel playit.gg automatico so no Mac e no Windows."; return 0; fi
  if [ ! -x "$dir/playitd" ]; then
    echo "Baixando o playit.gg..."
    mkdir -p "$dir"; tgz="$dir/playit.tar.gz"
    curl -fsSL "https://github.com/playit-cloud/playit-agent/releases/download/v2.0.2/playit-macos-universal.tar.gz" -o "$tgz"
    # SHA-256 publicado na release: so roda o binario se bater.
    if [ "$(shasum -a 256 "$tgz" | awk '{print $1}')" != d3da262f8c58bfc13797a1bbf2e3fcc6d487e4e6832f54b35c00daeb59e1cce2 ]; then
      rm -f "$tgz"; echo "AVISO: checksum do playit.gg nao confere; tunel nao ligado." >&2; return 0
    fi
    tar -xzf "$tgz" -C "$dir" --strip-components 1; rm -f "$tgz"
  fi
  # Socket em TMPDIR: o macOS limita o caminho de socket a ~104 caracteres.
  mkdir -p "$server/logs"
  "$dir/playitd" --secret-path "$seg" --socket-path "${TMPDIR:-/tmp}/minezada-playit.sock" \
    -l "$server/logs/playit.log" >/dev/null 2>&1 &
  tunel_pid=$!
  echo "Tunel playit.gg ligado. Quem esta fora desta rede entra por:"
  echo "  $(cat "$SYNC_DIR/playit-endereco.txt" 2>/dev/null || echo 'endereco do tunel no painel do playit.gg')"
}

# Link da pasta minezada no Drive: quem nao tem acesso ve o botao "Solicitar acesso".
drive_url="https://drive.google.com/drive/folders/1Kw45U0B-b906dnDsUH8bLy9nDg7HfWzh"

# Libera na whitelist os nicks de jogadores.txt (um por linha; "op" depois do nick tambem da admin),
# com o UUID offline do nick (online-mode=false). Sem o arquivo, cria com o dono e quem ja esta
# liberado. So adiciona; tirar alguem e no console. Uso: sincronizar_whitelist LISTA PASTA_DO_SERVIDOR
sincronizar_whitelist() {
  if [ "$(uname -s)" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then return 0; fi
  command -v python3 >/dev/null || return 0
  python3 - "$@" <<'PY' || echo "AVISO: falha ao atualizar a whitelist." >&2
import hashlib, json, os, re, sys, uuid
lista, pasta = sys.argv[1], sys.argv[2]
def offline(nome):  # mesmo UUID que o servidor da ao nick sem conta Microsoft (maiusculas contam)
    return str(uuid.UUID(bytes=hashlib.md5(b"OfflinePlayer:" + nome.encode()).digest(), version=3))
def ler(nome):
    arq = os.path.join(pasta, nome)
    return json.load(open(arq)) if os.path.exists(arq) else []
wl, ops = ler("whitelist.json"), ler("ops.json")
# Entradas com UUID da Mojang (de quando era online-mode=true) viram offline e levam o progresso junto.
mundo = os.path.join(pasta, "world")
for e in wl + ops:
    novo = offline(e["name"])
    if e["uuid"] == novo:
        continue
    for sub, ext in (("playerdata", ".dat"), ("playerdata", ".dat_old"),
                     ("advancements", ".json"), ("stats", ".json")):
        de, para = (os.path.join(mundo, sub, u + ext) for u in (e["uuid"], novo))
        if os.path.exists(de) and not os.path.exists(para):
            os.rename(de, para)
            print(f"Progresso de {e['name']} levado para o UUID offline: {sub}/{novo}{ext}")
    e["uuid"] = novo
if not os.path.exists(lista):
    with open(lista, "w") as f:
        f.write("# Um nick por linha, igual ao do jogo (maiusculas contam); 'op' depois tambem da admin.\n"
                "# O servidor libera todos ao iniciar.\nEnzobullet op\n")
        f.writelines(e["name"] + "\n" for e in wl if e["name"].lower() != "enzobullet")
conhecidos = {e["name"].lower(): e for e in wl + ops}
for linha in open(lista, encoding="utf-8-sig"):
    partes = linha.split("#")[0].split()
    if not partes:
        continue
    if not re.fullmatch(r"[A-Za-z0-9_]{1,16}", partes[0]):  # nick valido do Java
        print(f"AVISO: nick invalido em jogadores.txt: {partes[0]}")
        continue
    k, op = partes[0].lower(), "op" in [x.lower() for x in partes[1:]]
    falta_wl = k not in {e["name"].lower() for e in wl}
    falta_op = op and k not in {e["name"].lower() for e in ops}
    if not (falta_wl or falta_op):
        continue
    if k not in conhecidos:
        conhecidos[k] = {"uuid": offline(partes[0]), "name": partes[0]}
    e = conhecidos[k]
    if falta_wl:
        wl.append({"uuid": e["uuid"], "name": e["name"]})
        print(f"Liberado na whitelist: {e['name']}")
    if falta_op:
        ops.append({"uuid": e["uuid"], "name": e["name"], "level": 4, "bypassesPlayerLimit": False})
        print(f"Admin (op): {e['name']}")
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

main "$@"
exit
