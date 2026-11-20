#!/usr/bin/env bash
# Desinstala o Minezada do Mac (desfaz o jogar.sh). Rode no Terminal:
#   curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/desinstalar.sh | bash
# --sim: nao pergunta (necessario sem terminal).
set -euo pipefail

if [ "$(uname -s)" = "Darwin" ]; then
  dados="$HOME/Library/Application Support/PrismLauncher"
else
  dados="$HOME/.local/share/PrismLauncher"
fi
fork="$HOME/Applications/Minezada"
prism="$HOME/Applications/Prism Launcher.app"
atalho="$HOME/Desktop/Minezada.app"
inst_dir="$(sed -n 's/^InstanceDir=//p' "$dados/prismlauncher.cfg" 2>/dev/null | head -n 1 || true)"
inst_dir="${inst_dir:-instances}"
case "$inst_dir" in /*) ;; *) inst_dir="$dados/$inst_dir" ;; esac
inst="$inst_dir/Minezada"

# Outras instancias do Prism (pastas que nao comecam com ponto). Com alguma, o Prism e os dados ficam.
outras=""
if [ -d "$inst_dir" ]; then
  for d in "$inst_dir"/*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    [ "$n" = "Minezada" ] || outras="$outras $n"
  done
fi

echo "Vai apagar:"
for p in "$inst" "$atalho" "$fork"; do [ -e "$p" ] && echo "  $p"; done
if [ -z "$outras" ]; then
  for p in "$prism" "$dados"; do [ -e "$p" ] && echo "  $p"; done
fi
if [ "${1:-}" != "--sim" ]; then
  # stdin e o proprio script (curl | bash), por isso a resposta vem do terminal.
  printf 'Desinstalar o Minezada? O mundo de um jogador so tambem e apagado. [s/N] '
  { read -r resp </dev/tty; } 2>/dev/null || { echo; echo "Sem terminal: rode com --sim (... | bash -s -- --sim)."; exit 1; }
  case "$resp" in [sS]*) ;; *) echo "Nada foi apagado."; exit 0 ;; esac
fi

# 1. Fecha o jogo e o launcher, que regravaria a instancia ao sair.
pkill -f 'java.*instances/Minezada' 2>/dev/null || true
if [ "$(uname -s)" = "Darwin" ]; then
  for app in "$fork/Prism Launcher.app" "$prism" "/Applications/Prism Launcher.app"; do
    # So com o app aberto: "tell application" abriria um app fechado.
    if pgrep -f "$app/Contents/MacOS/" >/dev/null; then
      osascript -e "tell application \"$app\" to quit" >/dev/null 2>&1 || true
      sleep 2
    fi
  done
fi

# 2. Instancia, atalho e fork (o fork so existe para o Minezada).
rm -rf "$inst" "$atalho" "$fork"

# 3. Prism oficial em ~/Applications (o jogar.sh instala ali; /Applications foi o jogador) e os dados.
if [ -z "$outras" ]; then
  rm -rf "$prism" "$dados"
else
  echo "O Prism Launcher ficou instalado: ele tem outras instancias:$outras."
fi

echo
echo "Minezada desinstalado."
if [ -d "$HOME/Minezada-servidor" ]; then
  echo "Os arquivos de hospedar ficaram em $HOME/Minezada-servidor (e o atalho \"Hospedar Minezada\" na Mesa)."
  echo "Para apagar, desligue o servidor antes. O mundo fica no Drive."
fi
