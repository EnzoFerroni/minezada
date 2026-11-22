#!/usr/bin/env bash
# Roda estado e placar no servidor de mentira de testdata/servidor (um jogador, no Nether, com o dragao derrotado)
# e compara com o que tem que sair. Da pasta sword/, com os programas em bin/.
set -euo pipefail
cd "$(dirname "$0")/.."
t="$(mktemp -d)"
trap 'rm -rf "$t"' EXIT
bin/estado testdata/servidor/world "$t/estado.json"
bin/placar testdata/servidor "$t/placar.json" > /dev/null
bin/placar testdata/servidor "$t/placar-posicoes.json" --posicoes > /dev/null
for f in estado placar placar-posicoes; do
  diff -u "testdata/$f.json" "$t/$f.json" || { echo "FALHA $f"; exit 1; }
done
echo "ok    estado e placar"
