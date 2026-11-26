#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034 # variaveis usadas dentro do eval do confere
# Testa o resetar.sh em um repo, servidor e pasta do Drive falsos: recusa com servidor ligado, guarda o mundo em
# arquivo/ antes de apagar e troca o mundo-id.txt.
set -euo pipefail
raiz="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
falhou=0
confere() { if eval "$2"; then echo "ok: $1"; else echo "FALHOU: $1"; falhou=1; fi; }

r="$tmp/repo"; drive="$tmp/drive"
mkdir -p "$r/scripts" "$r/modpack/arquivos" "$r/server/world/region" "$drive/backups"
cp "$raiz/scripts/resetar.sh" "$r/scripts/"
printf 'SYNC_DIR="%s"\n' "$drive" > "$r/config.env"
printf 'mundo-1\n' > "$r/modpack/arquivos/mundo-id.txt"
printf 'mundo velho' > "$drive/mundo.tar.gz"
printf 'sessao' > "$drive/backups/sessao-atual.tar.gz"
touch "$drive/backups/mundo-20261120.tar.gz" "$r/server/world/level.dat"

printf 'PC\n' > "$drive/host.lock"
if bash "$r/scripts/resetar.sh" --sim >/dev/null 2>&1; then lig=0; else lig=1; fi
confere "servidor ligado: recusa" '[ $lig = 1 ] && [ -f "$drive/mundo.tar.gz" ] && [ -d "$r/server/world" ]'
: > "$drive/host.lock"

bash "$r/scripts/resetar.sh" --sim >/dev/null
confere "mundo e sessao guardados em arquivo/" '[ "$(cat "$drive"/arquivo/mundo-antes-do-reset-*.tar.gz)" = "mundo velho" ] && [ -s "$(ls "$drive"/arquivo/sessao-antes-do-reset-*.tar.gz)" ]'
confere "mundo, backups e world local apagados" '[ ! -e "$drive/mundo.tar.gz" ] && [ ! -e "$drive/backups" ] && [ ! -e "$r/server/world" ]'
confere "mundo-id trocado" 'grep -q "^mundo-2[0-9]\{7\}-[0-9]\{4\}$" "$r/modpack/arquivos/mundo-id.txt"'

# Sem mundo no Drive: guarda o world local.
rm -rf "$drive/arquivo"; mkdir -p "$r/server/world"; touch "$r/server/world/level.dat"
bash "$r/scripts/resetar.sh" --sim >/dev/null
confere "sem Drive: world local guardado" 'tar -tzf "$(ls "$drive"/arquivo/mundo-antes-do-reset-*.tar.gz)" | grep -q "world/level.dat"'

exit $falhou
