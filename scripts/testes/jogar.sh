#!/usr/bin/env bash
# Testa o jogar.sh no Linux em um HOME falso, com um prismlauncher falso no PATH (anota os argumentos e nao abre nada):
# cria a instancia, liga o minezada.sh antes de abrir, cria o atalho do menu e abre a instancia. Depois, o modo do
# atalho (--abrir). Baixa o zip do pack do GitHub.
set -euo pipefail
raiz="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
falhou=0
confere() { if eval "$2"; then echo "ok: $1"; else echo "FALHOU: $1"; falhou=1; fi; }
[ "$(uname -s)" = Linux ] || { echo "So no Linux."; exit 0; }

mkdir -p "$tmp/home" "$tmp/bin"
printf '#!/bin/sh\necho "$*" >> "%s/abriu.txt"\n' "$tmp" > "$tmp/bin/prismlauncher"
chmod +x "$tmp/bin/prismlauncher"
roda() { HOME="$tmp/home" PATH="$tmp/bin:$PATH" bash "$raiz/jogar.sh" "$@" < /dev/null; }

roda > "$tmp/saida.txt" 2>&1 || { cat "$tmp/saida.txt"; echo "FALHOU: jogar.sh saiu com erro"; exit 1; }
sleep 1
d="$tmp/home/.local/share/PrismLauncher"
i="$d/instances/Minezada"
confere "prismlauncher.cfg em pt-BR" 'grep -q "^Language=pt_BR" "$d/prismlauncher.cfg"'
confere "instancia criada" '[ -f "$i/instance.cfg" ] && [ -f "$i/mmc-pack.json" ]'
confere "minezada.sh roda antes de abrir" 'grep -q "^PreLaunchCommand=/bin/bash minezada.sh" "$i/instance.cfg" && [ -f "$i/.minecraft/minezada.sh" ]'
confere "options.txt com os pacotes do pack" 'grep -q "^resourcePacks:\[" "$i/.minecraft/options.txt"'
confere "hash do zip anotado" '[ -s "$i/minezada-zip.txt" ]'
confere "atalho no menu de aplicativos" 'grep -q "jogar.sh | bash -s -- --abrir" "$tmp/home/.local/share/applications/minezada.desktop"'
confere "abriu a instancia" 'grep -qx -- "--launch Minezada" "$tmp/abriu.txt"'

# Atalho: o jogador mudou uma opcao; o zip nao mudou, entao nada e refeito e o jogo abre.
echo "fov:1.0" >> "$i/.minecraft/options.txt"
roda --abrir > "$tmp/saida2.txt" 2>&1 || { cat "$tmp/saida2.txt"; echo "FALHOU: jogar.sh --abrir saiu com erro"; exit 1; }
sleep 1
confere "--abrir mantem as opcoes do jogador" 'grep -qx "fov:1.0" "$i/.minecraft/options.txt"'
confere "--abrir abre de novo" '[ "$(grep -c -- "--launch Minezada" "$tmp/abriu.txt")" = 2 ]'

exit $falhou
