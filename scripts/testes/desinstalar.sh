#!/usr/bin/env bash
# Testa o desinstalar.sh em um HOME falso: sem terminal nao apaga nada; com --sim apaga o Minezada e
# so leva o Prism e os dados quando nao ha outra instancia.
set -euo pipefail
raiz="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
falhou=0
confere() { if eval "$2"; then echo "ok: $1"; else echo "FALHOU: $1"; falhou=1; fi; }

montar() {
  h="$tmp/$1"
  if [ "$(uname -s)" = "Darwin" ]; then d="$h/Library/Application Support/PrismLauncher"; else d="$h/.local/share/PrismLauncher"; fi
  mkdir -p "$d/instances/Minezada/.minecraft" "$d/instances/.tmp" "$h/Desktop/Minezada.app" \
    "$h/Applications/Minezada/Prism Launcher.app" "$h/Applications/Prism Launcher.app"
  touch "$d/prismlauncher.cfg"
}

# No CI nao ha terminal; rodado no Terminal, este caso pergunta (e so mexe no HOME falso).
montar sem-tty
HOME="$h" bash "$raiz/desinstalar.sh" >/dev/null 2>&1 </dev/null || true
confere "sem terminal nao apaga" '[ -d "$d/instances/Minezada" ] && [ -d "$h/Applications/Minezada" ]'

montar sozinho
HOME="$h" bash -s -- --sim <"$raiz/desinstalar.sh" >/dev/null
confere "sem outra instancia leva tudo" '[ ! -e "$d" ] && [ ! -e "$h/Desktop/Minezada.app" ] && [ ! -e "$h/Applications/Minezada" ] && [ ! -e "$h/Applications/Prism Launcher.app" ]'

montar com-outra
mkdir -p "$d/instances/Vanilla"
HOME="$h" bash -s -- --sim <"$raiz/desinstalar.sh" >/dev/null
confere "com outra instancia mantem o Prism" '[ ! -e "$d/instances/Minezada" ] && [ -d "$d/instances/Vanilla" ] && [ -d "$h/Applications/Prism Launcher.app" ] && [ ! -e "$h/Applications/Minezada" ]'

exit $falhou
