#!/usr/bin/env bash
# Testa o sincronizar_whitelist do iniciar.sh (Mac) com o caso de scripts/testes/whitelist/. O whitelist.ps1 roda o
# mesmo caso no Sincronizar-Whitelist do iniciar.ps1 (Windows): as duas versoes tem que dar o mesmo resultado.
# Uso: scripts/testes/whitelist.sh
set -euo pipefail
aqui="$(cd "$(dirname "$0")" && pwd)"
t="$(mktemp -d)"
trap 'rm -rf "$t"' EXIT
cp -R "$aqui/whitelist/." "$t/"
MINEZADA_TESTE=1 . "$aqui/../iniciar.sh"
sincronizar_whitelist "$t/jogadores.txt" "$t"
python3 - "$t" "$aqui/whitelist/esperado.json" <<'PY'
import json, os, sys
pasta, esperado = sys.argv[1], json.load(open(sys.argv[2]))
def chaves(lista, campos):
    return sorted(tuple(e[c] for c in campos) for e in lista)
erros = []
for nome, campos in (("whitelist", ("uuid", "name")), ("ops", ("uuid", "name", "level"))):
    obtido = chaves(json.load(open(os.path.join(pasta, nome + ".json"))), campos)
    if obtido != chaves(esperado[nome], campos):
        erros.append(f"{nome}.json: esperado {chaves(esperado[nome], campos)}, veio {obtido}")
for arq in esperado["copiados"]:
    if not os.path.exists(os.path.join(pasta, arq)):
        erros.append(f"progresso nao copiado: {arq}")
if erros:
    print("FALHA whitelist:\n  " + "\n  ".join(erros))
    sys.exit(1)
print("ok    whitelist")
PY
