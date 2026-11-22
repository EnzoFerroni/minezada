#!/usr/bin/env bash
# Roda estado, placar e pontos no servidor de mentira de testdata/servidor (um jogador, no Nether, com o dragao
# derrotado; uma vila, uma cama e um portal) e compara com o que tem que sair. Da pasta sword/, com os programas
# em bin/.
set -euo pipefail
cd "$(dirname "$0")/.."
t="$(mktemp -d)"
trap 'rm -rf "$t"' EXIT
bin/estado testdata/servidor/world "$t/estado.json"
bin/placar testdata/servidor "$t/placar.json" > /dev/null
bin/placar testdata/servidor "$t/placar-posicoes.json" --posicoes > /dev/null
bin/pontos testdata/servidor/world "$t/pontos.json" --portais > /dev/null
for f in estado placar placar-posicoes pontos; do
  diff -u "testdata/$f.json" "$t/$f.json" || { echo "FALHA $f"; exit 1; }
done
echo "ok    estado, placar e pontos"
