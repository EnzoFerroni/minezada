#!/usr/bin/env bash
# Recomeca o servidor do zero (mundo novo, inventarios, missoes e conquistas zerados), por exemplo na abertura
# para todos. Antes de apagar, guarda o mundo atual em arquivo/ na pasta do Drive. Depois troca o
# modpack/arquivos/mundo-id.txt: na proxima abertura, o jogo de cada um apaga os mapas do Xaero e o cache do DH
# do mundo velho. Uso: bash scripts/resetar.sh [--sim] (--sim responde a confirmacao, so para os testes).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
die() { echo "ERRO: $*" >&2; exit 1; }
sim=0; [ "${1:-}" = "--sim" ] && sim=1

SYNC_DIR=""
# shellcheck source=/dev/null
[ -f "$root/config.env" ] && . "$root/config.env"
[ -n "$SYNC_DIR" ] && [ -d "$SYNC_DIR" ] || die "Pasta do Drive nao encontrada (SYNC_DIR no config.env). Rode o iniciar uma vez antes."
server="$root/server"

# Servidor ligado (aqui ou em outro host) = mundo em uso: nao mexe.
[ ! -s "$SYNC_DIR/host.lock" ] || die "Servidor ligado em '$(tr -d '[:space:]' < "$SYNC_DIR/host.lock")'. Desligue com stop e rode de novo."
if pgrep -f "java.*$server" >/dev/null 2>&1; then die "Tem um servidor rodando nesta maquina. Desligue com stop e rode de novo."; fi

echo "Isto apaga o mundo do servidor e todo o progresso (inventarios, missoes, conquistas, waystones)."
echo "O mundo atual fica guardado em: $SYNC_DIR/arquivo/"
if [ $sim -eq 0 ]; then
  read -r -p "Digite RESETAR para continuar: " resp
  [ "$resp" = "RESETAR" ] || die "Cancelado."
fi

data="$(date +%Y%m%d-%H%M)"
mkdir -p "$SYNC_DIR/arquivo"
# cat em vez de cp: no Mac o arquivo do Drive pode estar so na nuvem e o cp da "Operation timed out".
guardar() {
  local destino="$SYNC_DIR/arquivo/$2"
  cat "$1" > "$destino.tmp" && [ -s "$destino.tmp" ] || { rm -f "$destino.tmp"; die "Nao consegui copiar $1 (Drive aberto?). Nada foi apagado."; }
  mv "$destino.tmp" "$destino"
  echo "Guardado: arquivo/$2"
}
guardou=0
[ -f "$SYNC_DIR/mundo.tar.gz" ] && { guardar "$SYNC_DIR/mundo.tar.gz" "mundo-antes-do-reset-$data.tar.gz"; guardou=1; }
[ -f "$SYNC_DIR/backups/sessao-atual.tar.gz" ] && { guardar "$SYNC_DIR/backups/sessao-atual.tar.gz" "sessao-antes-do-reset-$data.tar.gz"; guardou=1; }
# Sem mundo no Drive (host sem Drive ate agora): guarda o mundo local.
if [ $guardou -eq 0 ] && [ -d "$server/world" ]; then
  COPYFILE_DISABLE=1 tar -czf "$SYNC_DIR/arquivo/mundo-antes-do-reset-$data.tar.gz" --exclude session.lock -C "$server" world
  echo "Guardado: arquivo/mundo-antes-do-reset-$data.tar.gz (mundo local)"
fi

rm -f "$SYNC_DIR/mundo.tar.gz"
rm -rf "$SYNC_DIR/backups"
rm -rf "$server/world"
echo "Apagados: mundo.tar.gz e backups/ do Drive, server/world desta maquina."

printf 'mundo-%s\n' "$data" > "$root/modpack/arquivos/mundo-id.txt"
cat <<FIM

Pronto. Proximos passos:
1. Publicar o mundo-id novo: rode scripts/montar-pack.ps1, faca commit e push (os mapas velhos saem do jogo de cada um).
2. Ligue o servidor pelo iniciar: ele cria o mundo novo.
3. Pre-gere no console: chunky radius 1500 e chunky start (leva horas; deixe ligado ate "Task finished").
4. Desligue com stop: o mundo pre-gerado vai para o Drive.
FIM
