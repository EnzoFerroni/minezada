#!/usr/bin/env bash
# Testa o desligamento do servidor no Mac/Linux (issue #7): stop digitado, Ctrl+C e janela do terminal fechada
# precisam salvar o mundo, envia-lo para a pasta sincronizada e liberar a trava. Roda o rodar_servidor e o
# enviar_mundo do iniciar.sh com um servidor falso em Java (Servidor.java) num terminal simulado pelo `script`.
# Uso: scripts/testes/desligar.sh   (precisa de Java 11+; o servidor roda no mesmo bash que rodou o teste)
set -euo pipefail
aqui="$(cd "$(dirname "$0")" && pwd)"
raiz="$(cd "$aqui/../.." && pwd)"
falhas=0

# caso NOME: stop | ctrlc | janela
caso() {
  local nome="$1" t spid erro=""
  t="$(mktemp -d)"
  mkdir -p "$t/server/world" "$t/sync"
  echo mundo > "$t/server/world/level.dat"
  cp "$aqui/Servidor.java" "$t/server/"
  echo teste > "$t/sync/host.lock"
  echo '# teste' > "$t/sync/jogadores.txt"
  # O fim do iniciar.sh: servidor e envio do mundo.
  cat > "$t/rodar.sh" <<EOF
#!/usr/bin/env bash
MINEZADA_TESTE=1 . "$raiz/scripts/iniciar.sh"
server="$t/server"; SYNC_DIR="$t/sync"; eu=teste; lista="$t/sync/jogadores.txt"; intervalo=1
rodar_servidor java Servidor.java
enviar_mundo
touch "$t/fim"
EOF
  : > "$t/entrada"
  # Terminal simulado: o que entra em $t/entrada vira teclado. O script do macOS nao aceita FIFO, por isso tail -f.
  # set -m: sem controle de jobs, o que roda em segundo plano nasce ignorando SIGINT, e o Ctrl+C nao chegaria (no
  # Terminal de verdade ele chega).
  set -m
  if script --version 2>/dev/null | grep -q util-linux; then
    tail -f "$t/entrada" | script -q -c "exec '$BASH' '$t/rodar.sh'" "$t/terminal.log" >/dev/null 2>&1 &
  else
    tail -f "$t/entrada" | script -q "$t/terminal.log" "$BASH" "$t/rodar.sh" >/dev/null 2>&1 &
  fi
  spid=$!
  set +m
  for _ in $(seq 1 120); do [ -f "$t/server/rodando" ] && break; sleep 0.5; done
  if [ ! -f "$t/server/rodando" ]; then
    erro="servidor nao subiu"
  else
    case "$nome" in
      stop) printf 'stop\n' >> "$t/entrada" ;;
      # Nick novo no jogadores.txt com o servidor ligado: o iniciar libera e manda whitelist reload (issue #16).
      whitelist)
        sleep 1.2; echo 'ZzTesteMz sem-original op' >> "$t/sync/jogadores.txt"
        for _ in $(seq 1 60); do grep -q 'whitelist reload' "$t/server/console.txt" 2>/dev/null && break; sleep 0.5; done
        printf 'stop\n' >> "$t/entrada" ;;
      ctrlc) printf '\003' >> "$t/entrada" ;;
      janela) kill -9 "$spid" ;;  # fecha o terminal: o sistema manda SIGHUP para a sessao
    esac
    for _ in $(seq 1 60); do [ -f "$t/fim" ] && break; sleep 0.5; done
    if [ ! -f "$t/server/salvo" ]; then erro="o servidor nao salvou o mundo"
    elif kill -0 "$(cat "$t/server/pid")" 2>/dev/null; then erro="o java continua rodando"
    elif [ ! -f "$t/fim" ]; then erro="o script nao terminou"
    elif [ -f "$t/sync/host.lock" ]; then erro="a trava ficou presa"
    elif ! tar -tzf "$t/sync/mundo.tar.gz" | grep -q 'world/level.dat'; then erro="o mundo nao foi enviado"
    elif [ "$nome" = janela ] && ! grep -q 'Janela fechada' "$t/server/logs/iniciar.log"; then erro="sem registro em iniciar.log"
    elif [ "$nome" = whitelist ] && ! grep -q 'whitelist reload' "$t/server/console.txt" 2>/dev/null; then erro="o servidor nao recebeu whitelist reload"
    elif [ "$nome" = whitelist ] && ! grep -q 'ZzTesteMz' "$t/server/whitelist.json" 2>/dev/null; then erro="o nick novo nao entrou no whitelist.json"
    fi
  fi
  if [ -z "$erro" ]; then
    echo "ok    $nome (salvou por: $(cat "$t/server/salvo"))"
  else
    echo "FALHA $nome: $erro"
    echo "--- terminal"; cat "$t/terminal.log" 2>/dev/null || true
    echo "--- iniciar.log"; cat "$t/server/logs/iniciar.log" 2>/dev/null || true
    falhas=$((falhas + 1))
  fi
  kill "$spid" 2>/dev/null || true
  [ ! -f "$t/server/pid" ] || kill -9 "$(cat "$t/server/pid")" 2>/dev/null || true
  pkill -f "tail -f $t/entrada" 2>/dev/null || true
  rm -rf "$t"
}

echo "bash $BASH_VERSION, $(uname -s)"
caso stop
caso ctrlc
caso janela
caso whitelist
[ $falhas -eq 0 ] || { echo "$falhas caso(s) falharam."; exit 1; }
