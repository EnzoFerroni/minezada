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
    if [ $((bytes / 1073741824)) -ge 24 ]; then ram=8G; else ram=6G; fi
    read -rp "Token do DuckDNS (peca ao dono do repo; Enter para pular): " token
    printf 'RAM=%s\nSYNC_DIR=""\nJAVA=java\nDUCKDNS_TOKEN=%s\n' "$ram" "$token" > "$root/config.env"
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
    # shortcut: a trava depende da nuvem ja ter sincronizado; dois hosts iniciando no mesmo minuto podem passar os dois.
    echo "$eu" > "$lock"
    # Trava ja era desta maquina = ultima sessao caiu sem enviar; o mundo local e o mais novo.
    if [ "$dono" != "$eu" ] && [ -f "$estado" ]; then
      echo "Baixando mundo da pasta sincronizada..."
      if [ -d "$server/world" ]; then rm -rf "$server/world.bak"; mv "$server/world" "$server/world.bak"; fi
      tar -xzf "$estado" -C "$server"
    fi
  fi

  # 6. Rede: porta (UPnP via miniupnpc) e endereco.
  if ! command -v upnpc >/dev/null && command -v brew >/dev/null; then brew install miniupnpc >/dev/null 2>&1 || true; fi
  # IP da placa da rota padrao (en0 nem sempre e a que vai para a internet).
  ifc="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
  ip="$(ipconfig getifaddr "${ifc:-en0}" 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
  if command -v upnpc >/dev/null && upnpc -e minezada -a "$ip" $porta $porta TCP >/dev/null 2>&1; then
    echo "Porta $porta aberta via UPnP."
  else
    echo "UPnP indisponivel: vale o redirecionamento manual do roteador (docs/requisitos.md)."
  fi

  ddns_pid=""
  if [ -n "$DUCKDNS_TOKEN" ]; then
    url="https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}"
    # Reaponta o nome para este host e repete a cada 5 min caso o IP mude durante a sessao.
    ( while true; do curl -fsS "$url" >/dev/null 2>&1 || true; sleep 300; done ) &
    ddns_pid=$!
    trap 'kill $ddns_pid 2>/dev/null || true' EXIT
    echo "Endereco do servidor: ${DUCKDNS_DOMAIN}.duckdns.org"
  fi

  echo "Iniciando servidor com $RAM de RAM. Digite 'stop' para desligar e salvar."
  # caffeinate impede o Mac de dormir enquanto o servidor roda. String sem aspas de proposito:
  # array vazio com set -u quebra no bash 3.2 do macOS.
  cafe=""; command -v caffeinate >/dev/null && cafe="caffeinate -i"
  trap 'true' INT  # Ctrl+C derruba so o java (que salva o mundo); o script segue para o envio
  # Flags do Aikar: coleta de lixo G1 ajustada para servidor de Minecraft (menos travadas).
  flags="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
  (cd "$server" && $cafe "$JAVA" "-Xms$RAM" "-Xmx$RAM" $flags "@libraries/net/neoforged/neoforge/$neo/unix_args.txt" nogui) || true
  trap - INT

  [ -n "$ddns_pid" ] && kill "$ddns_pid" 2>/dev/null || true
  command -v upnpc >/dev/null && upnpc -d $porta TCP >/dev/null 2>&1 || true

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

# Link da pasta minezada no Drive: quem nao tem acesso ve o botao "Solicitar acesso".
drive_url="https://drive.google.com/drive/shared-with-me"

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
      sudo installer -pkg "$tmp/m/GoogleDrive.pkg" -target / >/dev/null || echo "AVISO: instalacao do Google Drive falhou." >&2
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
