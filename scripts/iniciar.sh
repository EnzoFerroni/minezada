#!/usr/bin/env bash
# Faz tudo para hospedar: atualiza o repo, instala Java, cria config.env, instala/atualiza o pack,
# puxa o mundo da pasta sincronizada, liga os tuneis (Cloudflare e playit), roda e devolve o mundo.
# Uso: ./iniciar.command (Mac, duplo clique) ou ./scripts/iniciar.sh [--forcar]
set -euo pipefail

# Tudo dentro de main: o bash le o arquivo enquanto executa, e o git pull pode reescreve-lo.
main() {
  root="$(cd "$(dirname "$0")/.." && pwd)"
  server="$root/server"
  tools="$root/tools"
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
    printf 'RAM=%s\nSYNC_DIR=""\nJAVA=java\n' "$ram" > "$root/config.env"
  fi

  RAM=6G; SYNC_DIR=""; JAVA=java; SEM_DRIVE=""
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

  # 3. JDK 21+ (o JDK roda o scripts/Whitelist.java direto; no macOS /usr/bin/java existe mesmo sem JDK, por isso
  # testa rodando). Faltou, e antigo ou so JRE: baixa o Temurin 25 para tools/, sem Homebrew nem senha de administrador.
  if ! java_ok "$JAVA"; then
    jdk="$tools/jdk/Contents/Home/bin/java"; [ "$(uname -s)" = "Darwin" ] || jdk="$tools/jdk/bin/java"
    if ! java_ok "$jdk"; then
      echo "Instalando Java 25..."
      case "$(uname -s)" in Darwin) os=mac ;; *) os=linux ;; esac
      case "$(uname -m)" in arm64|aarch64) arch=aarch64 ;; *) arch=x64 ;; esac
      rm -rf "$tools/jdk" "$tools/jre"; mkdir -p "$tools/jdk"
      curl -fsSL "https://api.adoptium.net/v3/binary/latest/25/ga/$os/$arch/jdk/hotspot/normal/eclipse" \
        | tar -xz -C "$tools/jdk" --strip-components 1 || die "Download do Java falhou."
    fi
    JAVA="$jdk"
    java_ok "$JAVA" || die "Java nao instalado. Veja docs/hospedar.md"
  fi

  # 4. Pack -> servidor, tudo via Java: instalador oficial do NeoForge e packwiz (igual ao iniciar.ps1).
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
    # Drive fechado: a pasta off-line continua no disco com a copia velha (mundo, trava, dispatch.txt), e o
    # servidor abriria o mundo antigo e depois o enviaria por cima do bom.
    case "$SYNC_DIR" in
      */CloudStorage/GoogleDrive-*)
        if ! pgrep -x "Google Drive" > /dev/null; then
          echo "O Google Drive estava fechado. Abrindo agora..."
          open -a "Google Drive" || die "Nao deu para abrir o Google Drive. Abra ele e rode de novo."
          echo "Espere o icone do Drive na barra de menus parar de sincronizar e aperte Enter."
          read -r _ < /dev/tty
        fi ;;
    esac
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

  # 6. Rede: tuneis da Cloudflare e do playit. Quem esta nesta maquina entra por localhost; o resto, pelo tunel.
  cf_pid=""; tunel_pid=""
  iniciar_cloudflare || true
  iniciar_tunel || true
  [ -n "$cf_pid$tunel_pid" ] || echo "AVISO: nenhum tunel conectou: so esta maquina consegue entrar (localhost)." >&2
  trap 'kill $tunel_pid $cf_pid 2>/dev/null || true' EXIT

  echo "Iniciando servidor com $RAM de RAM. Para desligar e salvar: digite 'stop', aperte Ctrl+C ou feche esta janela."
  # Flags do Aikar: coleta de lixo G1 ajustada para servidor de Minecraft (menos travadas).
  flags="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
  rodar_servidor "$JAVA" "-Xms$RAM" "-Xmx$RAM" $flags "@libraries/net/neoforged/neoforge/$neo/unix_args.txt" nogui

  kill $tunel_pid $cf_pid 2>/dev/null || true
  avisar_selo desligou

  [ -z "$SYNC_DIR" ] || enviar_mundo
}

die() { echo "ERRO: $*" >&2; exit 1; }

# Roda o servidor (comando nos argumentos, dentro de $server) ate ele desligar por stop, Ctrl+C ou janela fechada.
# O java fica em segundo plano com o teclado (pelo FIFO) e o script esperando por ele: assim os sinais chegam no script,
# que repassa SIGTERM ao java, e a JVM salva o mundo antes de sair. Com o java em primeiro plano o bash so trata o
# sinal depois que ele sai, e o macOS manda o SIGHUP da janela fechada so para o bash (issue #7). Processo em
# segundo plano nasce ignorando SIGINT (a JVM respeita), por isso o Ctrl+C tambem vira SIGTERM pelo trap.
# O console do java e um FIFO: o teclado (cat) e a conferencia do jogadores.txt escrevem nele (issue #16). O fd 4
# fica aberto ate o fim, entao o java nunca ve o console fechar.
rodar_servidor() {
  mkdir -p "$server/logs"
  local fifo="$server/logs/console.fifo" n=0 teclado_pid
  rm -f "$fifo"; mkfifo "$fifo"
  (cd "$server" && exec "$@") < "$fifo" &
  java_pid=$!
  exec 4> "$fifo"
  cat <&0 >&4 &
  teclado_pid=$!
  # Escrever no console depois que o java saiu daria SIGPIPE e mataria o script antes de enviar o mundo.
  trap '' PIPE
  lista_visto="$(modificado "${lista:-}")"; jogo_visto="$(datas_jogo)"
  inicio="$(date +%s)"; pronto=""
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
  while kill -0 "$java_pid" 2>/dev/null; do
    sleep 1 || true
    # || true: o Ctrl+C tambem mata o $(...) que estiver rodando na conferencia, e com set -e o script saia sem
    # enviar o mundo (o java morria pelo fim da sessao e a trava ficava presa).
    n=$((n + 1)); [ $((n % ${intervalo:-30})) -ne 0 ] || recarregar_whitelist || true
    durante_sessao "$n" || true
  done
  wait "$java_pid" 2>/dev/null || true
  kill "$teclado_pid" 2>/dev/null || true
  exec 4>&-; rm -f "$fifo"
  trap - INT TERM PIPE
  # Janela fechada durante o envio do mundo: o envio termina, com a saida no registro.
  trap 'exec >>"$server/logs/iniciar.log" 2>&1' HUP
}

# Com o servidor ligado: avisa o selo quando ele termina de abrir e depois a cada 10 minutos, e a cada 30 minutos
# manda uma foto do mundo para a pagina. Em segundo plano: o laco que espera o java nao pode parar.
# O latest.log da sessao anterior ainda tem o "Done": so conta o log escrito depois do start.
durante_sessao() {
  local n=$1 t log="$server/logs/latest.log"
  if [ -z "$pronto" ]; then
    [ "$(modificado "$log")" -ge "$inicio" ] 2>/dev/null && grep -qs 'Done (' "$log" || return 0
    pronto=$n
    avisar_selo ligou &
    # Explosao dropa tudo que quebra (creeper, TNT, cama no Nether). Vale no mundo; reaplicado a cada partida.
    { echo "gamerule mobExplosionDropDecay false"; echo "gamerule tntExplosionDropDecay false"; echo "gamerule blockExplosionDropDecay false"; } >&4 2>/dev/null || true
    return 0
  fi
  t=$((n - pronto))
  [ $((t % 600)) -ne 0 ] || avisar_selo ligado &
  [ $((t % 1800)) -ne 0 ] || [ $t -eq 0 ] || foto_do_mundo &
}

# Pede a consulta do selo agora (scripts/Selo.java). Sem dispatch.txt no Drive, nada.
avisar_selo() {
  [ -n "${SYNC_DIR:-}" ] && [ -f "$SYNC_DIR/dispatch.txt" ] || return 0
  "${JAVA:-java}" "$(dirname "${BASH_SOURCE[0]}")/Selo.java" "$SYNC_DIR" "$1" || true
}

# Copia do mundo com o servidor ligado, para a pagina (o do Drive so muda no stop). save-off para o jogo nao
# gravar no meio da copia, save-all flush para o que esta na memoria ir para o disco; sem a confirmacao
# "Saved the game" em um minuto, desiste. Sem github.txt no Drive, nada.
foto_do_mundo() {
  [ -n "${SYNC_DIR:-}" ] && [ -f "$SYNC_DIR/github.txt" ] || return 0
  local log="$server/logs/latest.log" foto="$server/logs/mundo-agora.tar.gz" antes f itens=() ok=1
  antes="$(grep -c 'Saved the game' "$log" 2>/dev/null)" || true
  { echo "save-off"; echo "save-all flush"; } >&4 2>/dev/null || return 0
  for _ in $(seq 1 60); do
    [ "$(grep -c 'Saved the game' "$log" 2>/dev/null)" -gt "${antes:-0}" ] && { ok=0; break; }
    sleep 1
  done
  if [ $ok -eq 0 ]; then
    for f in world ops.json whitelist.json banned-players.json banned-ips.json; do [ -e "$server/$f" ] && itens+=("$f"); done
    COPYFILE_DISABLE=1 tar -czf "$foto.tmp" -C "$server" "${itens[@]}" || ok=1
  fi
  echo "save-on" >&4 2>/dev/null || true
  [ $ok -eq 0 ] && mv -f "$foto.tmp" "$foto" || { rm -f "$foto.tmp"; return 0; }
  # Copia de seguranca no Drive (backups/sessao-atual.tar.gz): se a maquina cair, outro host ainda tem a sessao.
  mkdir -p "$SYNC_DIR/backups" && cp -f "$foto" "$SYNC_DIR/backups/sessao-atual.tar.gz" || echo "Nao copiei a sessao para o Drive." >&2
  "${JAVA:-java}" "$(dirname "${BASH_SOURCE[0]}")/MundoGithub.java" "$foto" "$SYNC_DIR" > /dev/null || true
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
    # Depois da trava: um envio lento ao GitHub nao segura o proximo host. Sem github.txt, nao faz nada.
    "${JAVA:-java}" "$(dirname "${BASH_SOURCE[0]}")/MundoGithub.java" "$estado" "$SYNC_DIR" || true
  else
    echo "AVISO: falha ao enviar o mundo. Trava mantida em $eu; rode de novo nesta maquina." >&2
  fi
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

# Libera na whitelist os nicks de jogadores.txt: mesma logica no Windows e no Mac (scripts/Whitelist.java).
# Uso: sincronizar_whitelist LISTA PASTA_DO_SERVIDOR (com o servidor rodando, depois: whitelist reload no console)
sincronizar_whitelist() {
  "${JAVA:-java}" "$(dirname "${BASH_SOURCE[0]}")/Whitelist.java" "$1" "$2" || echo "AVISO: falha ao atualizar a whitelist." >&2
}

# Data de modificacao em segundos (vazio se o arquivo nao existe). stat do macOS ou do Linux.
modificado() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || true; }

datas_jogo() { echo "$(modificado "$server/whitelist.json") $(modificado "$server/ops.json")"; }

# Com o servidor ligado: se o jogadores.txt mudou, libera os novos e avisa o servidor pelo console (fd 4). Se o
# whitelist.json ou o ops.json mudou (/whitelist add ou /op no jogo), copia o nick para a lista antes.
recarregar_whitelist() {
  local agora saida jogo
  [ -n "${lista:-}" ] || return 0
  jogo="$(datas_jogo)"
  if [ "$jogo" != "$jogo_visto" ]; then
    jogo_visto="$jogo"
    "${JAVA:-java}" "$(dirname "${BASH_SOURCE[0]}")/Whitelist.java" --do-jogo "$lista" "$server" || true
  fi
  agora="$(modificado "$lista")"
  [ -n "$agora" ] && [ "$agora" != "$lista_visto" ] || return 0
  lista_visto="$agora"
  echo "jogadores.txt mudou: atualizando a whitelist."
  saida="$(sincronizar_whitelist "$lista" "$server")"
  [ -z "$saida" ] || echo "$saida"
  jogo_visto="$(datas_jogo)"
  # Sem "op Nick" aqui: o servidor resolve nick offline em minusculas e daria admin a outro UUID.
  case "$saida" in *"Admin (op): "*) echo "Admin novo vale no proximo start (ou /op Nick no jogo com a pessoa online)." ;; esac
  echo "whitelist reload" >&4 2>/dev/null || true
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

# Java >= 21 (NeoForge 1.21.1; "1.8.0" vira 1) e JDK (jdk.compiler roda o Whitelist.java).
java_ok() {
  local v
  v="$("$1" -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -n 1)"
  [ "${v:-0}" -ge 21 ] && "$1" --list-modules 2>/dev/null | grep '^jdk.compiler' >/dev/null  # sem -q: o java nao leva SIGPIPE (pipefail)
}

# MINEZADA_TESTE=1: so carrega as funcoes, para os testes (scripts/testes/).
[ -n "${MINEZADA_TESTE:-}" ] || { main "$@"; exit; }
