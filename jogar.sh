#!/usr/bin/env bash
# Instala o Prism Launcher (se faltar) e importa o modpack da Minezada. Rode no Terminal:
#   curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
set -euo pipefail
zip="https://github.com/EnzoFerroni/minezada/raw/main/modpack/minezada-prism.zip"

if [ "$(uname -s)" = "Darwin" ]; then
  app=""
  for d in "/Applications/Prism Launcher.app" "$HOME/Applications/Prism Launcher.app"; do [ -d "$d" ] && app="$d"; done
  if [ -z "$app" ]; then
    echo "Instalando o Prism Launcher..."
    url="$(curl -fsSL https://api.github.com/repos/PrismLauncher/PrismLauncher/releases/latest \
      | grep -o 'https://[^"]*PrismLauncher-macOS-[0-9.]*\.zip' | head -n 1)"
    tmp="$(mktemp -d)"
    curl -fsSL "$url" -o "$tmp/prism.zip"
    mkdir -p "$HOME/Applications"
    ditto -x -k "$tmp/prism.zip" "$HOME/Applications"
    rm -rf "$tmp"
    app="$HOME/Applications/Prism Launcher.app"
  fi
  # Se o Prism ja estiver aberto, o macOS ignora os argumentos: fecha antes.
  osascript -e 'quit app "Prism Launcher"' >/dev/null 2>&1 || true
  open -a "$app" --args --import "$zip"
else
  command -v prismlauncher >/dev/null || { echo "Instale o Prism Launcher (https://prismlauncher.org/download/) e rode de novo."; exit 1; }
  nohup prismlauncher --import "$zip" >/dev/null 2>&1 &
fi

cat <<'EOF'

No Prism:
  1. Confirme a importacao do "Minezada" (OK).
  2. Entre com a conta Microsoft (icone de conta, canto superior direito).
  3. Clique duas vezes em "Minezada". Na primeira vez aceite baixar o Java.
O jogo ja entra direto no servidor. Atualizacoes do pack sao automaticas.
EOF
