#!/usr/bin/env bash
# Baixa/atualiza o servidor do Minezada, cria o atalho "Hospedar Minezada" na Mesa e sobe o servidor.
# Rode no Terminal (serve para instalar, atualizar e hospedar):
#   curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/hospedar.sh | bash
set -euo pipefail
dir="$HOME/Minezada-servidor"

# git vem nas ferramentas de linha de comando da Apple (que tambem trazem o python3 do UPnP e do tunel).
if [ "$(uname -s)" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then
  echo "Instalando as ferramentas de linha de comando da Apple: clique em 'Instalar' na janela que abriu."
  xcode-select --install >/dev/null 2>&1 || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

if [ -d "$dir/.git" ]; then
  git -C "$dir" pull --ff-only || echo "AVISO: git pull falhou; seguindo com a versao local." >&2
else
  git clone --depth 1 https://github.com/EnzoFerroni/minezada "$dir"
fi

# Atalho na Mesa (Mac): abre o Terminal ja rodando o servidor.
if [ "$(uname -s)" = "Darwin" ]; then
  rm -rf "$HOME/Desktop/Hospedar Minezada.app"
  osacompile -o "$HOME/Desktop/Hospedar Minezada.app" \
    -e "do shell script \"open -a Terminal \" & quoted form of \"$dir/iniciar.command\"" || true
fi

# curl | bash deixa o stdin no pipe: o servidor precisa do teclado para perguntas e para o "stop".
exec "$dir/iniciar.command" </dev/tty
