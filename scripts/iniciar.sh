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
  mrpack_version="0.23.0"
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
    sync=""
    for d in "$HOME"/Library/CloudStorage/GoogleDrive-*/"Meu Drive"/minezada "$HOME"/Library/CloudStorage/GoogleDrive-*/"My Drive"/minezada; do
      [ -d "$d" ] && { sync="$d"; break; }
    done
    if [ -n "$sync" ]; then echo "Pasta do Google Drive encontrada: $sync"
    else echo "Pasta minezada do Google Drive nao encontrada: o mundo fica so nesta maquina (ver docs/requisitos.md)."; fi
    read -rp "Token do DuckDNS (peca ao dono do repo; Enter para pular): " token
    printf 'RAM=%s\nSYNC_DIR="%s"\nJAVA=java\nDUCKDNS_TOKEN=%s\n' "$ram" "$sync" "$token" > "$root/config.env"
  fi

  RAM=6G; SYNC_DIR=""; JAVA=java; DUCKDNS_DOMAIN=minezada-mc; DUCKDNS_TOKEN=""
  . "$root/config.env"

  # 3. Java (no macOS /usr/bin/java existe mesmo sem JDK, por isso testa rodando).
  if ! "$JAVA" -version >/dev/null 2>&1; then
    command -v brew >/dev/null || die "Java nao encontrado. Instale o Homebrew (https://brew.sh) e rode de novo."
    echo "Instalando Java 25..."
    brew install --cask temurin@25
    "$JAVA" -version >/dev/null 2>&1 || die "Java nao instalado. Veja docs/requisitos.md"
  fi

  # 4. Pack -> servidor.
  packs=("$root"/modpack/*.mrpack)
  [ ${#packs[@]} -eq 1 ] || die "Precisa ter exatamente 1 arquivo .mrpack em modpack/ (achei ${#packs[@]})."

  exe="$tools/mrpack-install"
  if [ ! -x "$exe" ]; then
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    case "$(uname -m)" in x86_64|amd64) arch=amd64 ;; arm64|aarch64) arch=arm64 ;; *) die "Arquitetura nao suportada: $(uname -m)" ;; esac
    # SHA-256 do checksums.txt oficial da release: so roda o binario se bater.
    case "${os}_${arch}" in
      darwin_arm64) sum=35f4fa5d28ab3f30601d432957fae7f9050a371d55e6f518813f87361a13b710 ;;
      darwin_amd64) sum=2c1be13a4b0425bbf136dbb36dfd5058f6d97034fef06388b35a954c2d075eee ;;
      linux_amd64)  sum=a254184c0a9e6965dd3766caf0ea4f74c011f7ce77c04120c25623069cf72b85 ;;
      linux_arm64)  sum=68abf67220c3c514a0d20bd5062d2bf352467d90c2bd8bdafac46624079c2d0f ;;
      *) die "Sistema nao suportado: ${os}_${arch}" ;;
    esac
    echo "Baixando mrpack-install $mrpack_version..."
    mkdir -p "$tools"
    tgz="$tools/mrpack-install.tar.gz"
    curl -fsSL "https://github.com/nothub/mrpack-install/releases/download/v${mrpack_version}/mrpack-install_${mrpack_version}_${os}_${arch}.tar.gz" -o "$tgz"
    got="$( (shasum -a 256 "$tgz" 2>/dev/null || sha256sum "$tgz") | awk '{print $1}')"
    [ "$got" = "$sum" ] || { rm -f "$tgz"; die "Checksum do mrpack-install nao confere (download corrompido ou adulterado)."; }
    tar -xzf "$tgz" -C "$tools" mrpack-install
    rm -f "$tgz"
  fi

  # Idempotente: sem mudanca no pack, nao faz nada.
  "$exe" "${packs[0]}" --server-dir "$server" --server-file server.jar

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
  ip="$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
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
  (cd "$server" && $cafe "$JAVA" "-Xms$RAM" "-Xmx$RAM" $flags -jar server.jar nogui) || true
  trap - INT

  [ -n "$ddns_pid" ] && kill "$ddns_pid" 2>/dev/null || true
  command -v upnpc >/dev/null && upnpc -d $porta TCP >/dev/null 2>&1 || true

  if [ -n "$SYNC_DIR" ]; then
    echo "Enviando mundo para a pasta sincronizada..."
    itens=()
    for f in world ops.json whitelist.json banned-players.json banned-ips.json; do [ -e "$server/$f" ] && itens+=("$f"); done
    if tar -czf "$estado.tmp" -C "$server" "${itens[@]}"; then
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

main "$@"
exit
