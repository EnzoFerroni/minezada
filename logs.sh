#!/usr/bin/env bash
# Manda os logs do Minezada para o mclo.gs e copia os links. Rode no Terminal quando o jogo fechar ou nao conectar:
#   curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/logs.sh | bash
set -uo pipefail
if [ "$(uname)" = Darwin ]; then dados="$HOME/Library/Application Support/PrismLauncher"
else dados="$HOME/.local/share/PrismLauncher"; fi
mc="$dados/instances/Minezada/.minecraft"
arquivos=()
[ -f "$mc/logs/latest.log" ] && arquivos+=("$mc/logs/latest.log")
# Crash report so se for recente, para nao mandar um problema antigo.
crash="$(find "$mc/crash-reports" -name '*.txt' -mtime -2 2>/dev/null | sort | tail -n 1)"
[ -n "$crash" ] && arquivos+=("$crash")
[ -f "$dados/logs/PrismLauncher-0.log" ] && arquivos+=("$dados/logs/PrismLauncher-0.log")
if [ ${#arquivos[@]} = 0 ]; then echo "Nenhum log do Minezada neste computador. Rode o comando de jogar antes."; exit 0; fi

links=""
for a in "${arquivos[@]}"; do
  # Troca a pasta do usuario por ~ para nao mandar o nome do Mac. mclo.gs aceita ate 25 mil linhas.
  url="$(tail -n 25000 "$a" | sed "s|$HOME|~|g" | curl -fsS --data-urlencode content@- https://api.mclo.gs/1/log \
    | grep -o '"url":"[^"]*"' | cut -d'"' -f4 | sed 's|\\/|/|g')"
  if [ -n "$url" ]; then links+="$(basename "$a"): $url"$'\n'
  else echo "Nao consegui mandar $(basename "$a")."; fi
done
[ -n "$links" ] || exit 1
command -v pbcopy >/dev/null && printf '%s' "$links" | pbcopy
printf '\nLinks copiados. Cole na conversa com o Enzo:\n\n%s' "$links"
