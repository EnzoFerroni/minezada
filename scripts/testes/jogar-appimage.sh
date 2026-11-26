#!/usr/bin/env bash
# Testa no Linux o download de verdade dos launchers pelo jogar.sh, em um HOME falso e sem Prism instalado:
# o Prism oficial (AppImage da release mais nova) e o de conta offline (AppImage fixo, conferido pelo SHA-256).
# Confere que cada AppImage e um executavel que roda (--version, sem tela). Nao abre o jogo.
set -euo pipefail
raiz="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'pkill -f "$tmp" 2>/dev/null || true; rm -rf "$tmp"' EXIT
falhou=0
confere() { if eval "$2"; then echo "ok: $1"; else echo "FALHOU: $1"; falhou=1; fi; }
[ "$(uname -s)" = Linux ] || { echo "So no Linux."; exit 0; }
# PATH sem prismlauncher nem flatpak, para o jogar.sh ter que baixar.
limpo="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '/flatpak' | paste -sd: -)"
roda() { HOME="$1" PATH="$limpo" bash "$raiz/jogar.sh" < /dev/null > "$1.log" 2>&1 || { cat "$1.log"; return 1; }; }
versao() { APPIMAGE_EXTRACT_AND_RUN=1 QT_QPA_PLATFORM=offscreen timeout 120 "$1" --version 2>&1 | grep -qi prism; }

# Oficial: sem terminal para responder, o jogar.sh assume conta original.
mkdir -p "$tmp/oficial"
confere "jogar.sh baixa o Prism oficial" 'roda "$tmp/oficial"'
a="$tmp/oficial/.local/share/minezada/PrismLauncher.AppImage"
confere "AppImage oficial executavel" '[ -x "$a" ] && head -c4 "$a" | grep -q ELF'
confere "AppImage oficial roda (--version)" 'versao "$a"'

# Offline: um fork.AppImage velho na pasta faz o jogar.sh tratar como conta offline e baixar a versao fixa.
mkdir -p "$tmp/offline/.local/share/minezada"
: > "$tmp/offline/.local/share/minezada/fork.AppImage"
confere "jogar.sh baixa o launcher offline e o checksum confere" 'roda "$tmp/offline"'
b="$tmp/offline/.local/share/minezada/fork.AppImage"
confere "AppImage offline executavel" '[ -x "$b" ] && head -c4 "$b" | grep -q ELF'
confere "AppImage offline roda (--version)" 'versao "$b"'

exit $falhou
