#!/usr/bin/env bash
# Roda estado, placar, pontos e calor no servidor de mentira de testdata/servidor (um jogador, no Nether, com o
# dragao derrotado; uma vila, uma cama e um portal; tres chunks com tempo de jogador por perto; tres mortes;
# conquistas feitas, por fazer, receitas e de um jogador fora da whitelist; estruturas em chunks prontos e
# em geracao; um lobo, um gato de quem nao esta na whitelist e um papagaio no ombro) e compara com o que tem que sair. Da pasta sword/, com os programas
# em bin/.
set -euo pipefail
cd "$(dirname "$0")/.."
t="$(mktemp -d)"
trap 'rm -rf "$t"' EXIT
bin/estado testdata/servidor/world "$t/estado.json"
bin/placar testdata/servidor "$t/placar.json" > /dev/null
bin/placar testdata/servidor "$t/placar-posicoes.json" --posicoes > /dev/null
bin/pontos testdata/servidor/world "$t/pontos.json" --portais > /dev/null
bin/calor testdata/servidor/world "$t/calor.json" > /dev/null
bin/mortes testdata/servidor/world "$t/mortes.json" > /dev/null
bin/conquistas testdata/servidor "$t/conquistas.json" > /dev/null
bin/estruturas testdata/servidor/world "$t/estruturas.json" > /dev/null
bin/bichos testdata/servidor "$t/bichos.json" > /dev/null
bin/bichos testdata/servidor "$t/bichos-posicoes.json" --posicoes > /dev/null
for f in estado placar placar-posicoes pontos calor mortes conquistas estruturas bichos bichos-posicoes; do
  diff -u "testdata/$f.json" "$t/$f.json" || { echo "FALHA $f"; exit 1; }
done
echo "ok    estado, placar, pontos, calor, mortes, conquistas, estruturas e bichos"
