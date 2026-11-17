#!/usr/bin/env bash
# Instala/atualiza o Minezada e abre o jogo. Rode no Terminal (serve para instalar, atualizar e reparar):
#   curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
set -euo pipefail
zip_url="https://github.com/EnzoFerroni/minezada/raw/main/modpack/minezada-prism.zip"

# 1. Prism Launcher
if [ "$(uname -s)" = "Darwin" ]; then
  dados="$HOME/Library/Application Support/PrismLauncher"
  app=""
  for d in "/Applications/Prism Launcher.app" "$HOME/Applications/Prism Launcher.app"; do [ -d "$d" ] && app="$d"; done
  if [ -z "$app" ]; then
    echo "Instalando o Prism Launcher..."
    url="$(curl -fsSL https://api.github.com/repos/PrismLauncher/PrismLauncher/releases/latest \
      | grep -o 'https://[^"]*PrismLauncher-macOS-[0-9.]*\.zip' | head -n 1)"
    tmp="$(mktemp -d)"
    curl -fsSL "$url" -o "$tmp/prism.zip"
    mkdir -p "$HOME/Applications"
    ditto -x -k "$tmp/prism.zip" "$HOME/Applications"
    rm -rf "$tmp"
    app="$HOME/Applications/Prism Launcher.app"
  fi
  prism="$app/Contents/MacOS/$(ls "$app/Contents/MacOS" | head -n 1)"
else
  dados="$HOME/.local/share/PrismLauncher"
  prism="$(command -v prismlauncher || true)"
  [ -n "$prism" ] || { echo "Instale o Prism Launcher (https://prismlauncher.org/download/) e rode de novo."; exit 1; }
fi

# 2. Primeira vez: idioma, tema e Java automatico, para o assistente do Prism so pedir o login.
cfg="$dados/prismlauncher.cfg"
if [ ! -f "$cfg" ]; then
  mkdir -p "$dados"
  printf '[General]\nLanguage=pt_BR\nApplicationTheme=dark\nIconTheme=pe_colored\nAutomaticJavaDownload=true\nAutomaticJavaSwitch=true\nIgnoreJavaWizard=true\n' > "$cfg"
fi

# 3. Instancia: extrai direto na pasta do Prism (sem dialogo). Preserva mundo, opcoes e servidores do jogador.
inst_dir="$(sed -n 's/^InstanceDir=//p' "$cfg" | head -n 1)"
inst_dir="${inst_dir:-instances}"
case "$inst_dir" in /*) ;; *) inst_dir="$dados/$inst_dir" ;; esac
inst="$inst_dir/Minezada"
tmp="$(mktemp -d)"
curl -fsSL "$zip_url" -o "$tmp/pack.zip"
mkdir -p "$tmp/x" "$inst/.minecraft"
(cd "$tmp/x" && unzip -q ../pack.zip)
# shortcut: instance.cfg e sobrescrito (zera tempo de jogo do Prism); trocar por merge se incomodar.
cp "$tmp/x/instance.cfg" "$tmp/x/mmc-pack.json" "$inst/"
cp "$tmp/x/.minecraft/packwiz-installer-bootstrap.jar" "$inst/.minecraft/"
for f in servers.dat options.txt; do [ -f "$inst/.minecraft/$f" ] || cp "$tmp/x/.minecraft/$f" "$inst/.minecraft/"; done
# Liga os pacotes de recursos do pack em quem ja tinha options.txt, mantendo os que o jogador ligou.
# shortcut: nomes de pacote com espaco, & ou | quebram este trecho; trocar por parser de JSON se aparecer um.
opt="$inst/.minecraft/options.txt"
want="$(sed -n 's/^resourcePacks:\[\(.*\)\]$/\1/p' "$tmp/x/.minecraft/options.txt" | tr ',' '\n')"
have="$(sed -n 's/^resourcePacks:\[\(.*\)\]$/\1/p' "$opt")"
[ -n "$have" ] || have='"vanilla"'
for p in $want; do case ",$have," in *",$p,"*) ;; *) have="$have,$p" ;; esac; done
if grep -q '^resourcePacks:' "$opt"; then sed -i.bak "s|^resourcePacks:.*|resourcePacks:[$have]|" "$opt" && rm -f "$opt.bak"; else echo "resourcePacks:[$have]" >> "$opt"; fi
rm -rf "$tmp"

# 4. Atalho na Mesa (Mac) que abre direto o jogo.
if [ "$(uname -s)" = "Darwin" ]; then
  rm -rf "$HOME/Desktop/Minezada.app"
  osacompile -o "$HOME/Desktop/Minezada.app" -e "do shell script quoted form of \"$prism\" & \" --launch Minezada >/dev/null 2>&1 &\"" || true
fi

nohup "$prism" --launch Minezada >/dev/null 2>&1 &
echo
echo "Pronto! Na primeira vez entre com a conta Microsoft. Depois e so abrir 'Minezada' na Mesa."
