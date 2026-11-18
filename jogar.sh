#!/usr/bin/env bash
# Instala/atualiza o Minezada e abre o jogo. Rode no Terminal (serve para instalar, atualizar e reparar):
#   curl -fsSL https://raw.githubusercontent.com/EnzoFerroni/minezada/main/jogar.sh | bash
set -euo pipefail
zip_url="https://github.com/EnzoFerroni/minezada/raw/main/modpack/minezada-prism.zip"
# Fork do Prism que aceita conta offline sem conta Microsoft (o Prism oficial abre em modo Demo).
# Versao fixa com SHA-256: e mantido por uma pessoa so, entao so roda o binario conferido. Atualizar:
# trocar a versao e o sha256 (campo "digest" do arquivo na API de releases do GitHub).
fork_repo="Diegiwg/PrismLauncher-Cracked"
fork_url="https://github.com/$fork_repo/releases/download/11.1.1/PrismLauncher-macOS-11.1.1.zip"
fork_sha="f99e61328f1c9ed07788badc0e67277481309a0a2b97b8583bba4f89143aeb6c"

# 0. Conta. Launcher ja instalado responde sozinho (reparar nao pergunta de novo). stdin e o
# proprio script (curl | bash), por isso a resposta vem do terminal.
if [ -d "$HOME/Applications/Minezada/Prism Launcher.app" ]; then
  original=0
elif [ -d "/Applications/Prism Launcher.app" ] || [ -d "$HOME/Applications/Prism Launcher.app" ] \
  || command -v prismlauncher >/dev/null; then
  original=1
else
  printf 'Voce tem Minecraft original (conta Microsoft)? [s/n] '
  read -r resp </dev/tty || resp=s
  case "$resp" in [nN]*) original=0 ;; *) original=1 ;; esac
fi

# Baixa o zip do Prism ($1) para a pasta $2; com $3, so instala se o SHA-256 bater.
baixar_prism_mac() {
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL "$1" -o "$tmp/prism.zip"
  if [ -n "${3:-}" ] && [ "$(shasum -a 256 "$tmp/prism.zip" | awk '{print $1}')" != "$3" ]; then
    rm -rf "$tmp"; echo "ERRO: o launcher baixado nao confere (checksum). Avise o Enzo."; exit 1
  fi
  mkdir -p "$2"
  rm -rf "$2/Prism Launcher.app"
  ditto -x -k "$tmp/prism.zip" "$2"
  rm -rf "$tmp"
}

# 1. Launcher: Prism oficial com conta original; senao o fork, numa pasta separada para nao
# trocar o Prism de quem ja tem. Os dois usam a mesma pasta de dados.
if [ "$(uname -s)" = "Darwin" ]; then
  dados="$HOME/Library/Application Support/PrismLauncher"
  if [ $original = 1 ]; then
    app=""
    for d in "/Applications/Prism Launcher.app" "$HOME/Applications/Prism Launcher.app"; do [ -d "$d" ] && app="$d"; done
    if [ -z "$app" ]; then
      echo "Instalando o Prism Launcher..."
      url="$(curl -fsSL https://api.github.com/repos/PrismLauncher/PrismLauncher/releases/latest \
        | grep -o 'https://[^"]*PrismLauncher-macOS-[0-9.]*\.zip' | head -n 1)"
      baixar_prism_mac "$url" "$HOME/Applications"
      app="$HOME/Applications/Prism Launcher.app"
    fi
  else
    # Baixado a cada vez (versao fixa): rodar o comando de novo repara o launcher.
    echo "Instalando o launcher para conta offline..."
    baixar_prism_mac "$fork_url" "$HOME/Applications/Minezada" "$fork_sha"
    app="$HOME/Applications/Minezada/Prism Launcher.app"
  fi
  # Contents/MacOS tambem tem a pasta jars: o executavel certo vem do Info.plist.
  prism="$app/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print CFBundleExecutable' "$app/Contents/Info.plist")"
else
  dados="$HOME/.local/share/PrismLauncher"
  prism="$(command -v prismlauncher || true)"
  site="https://prismlauncher.org/download/"
  [ $original = 1 ] || site="https://github.com/$fork_repo/releases/latest"
  [ -n "$prism" ] || { echo "Instale o launcher ($site) como prismlauncher e rode de novo."; exit 1; }
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
# Memoria do jogo: 6 GB com 24 GB+ de RAM, 3 GB abaixo de 12 GB; senao fica a do zip (4 GB evita o
# aviso do Prism em 16 GB).
bytes="$(sysctl -n hw.memsize 2>/dev/null || awk '/MemTotal/{print $2*1024}' /proc/meminfo)"
gb=$((bytes / 1073741824)); mem=""
if [ $gb -ge 24 ]; then mem=6144; elif [ $gb -lt 12 ]; then mem=3072; fi
if [ -n "$mem" ]; then
  sed -i.bak "s/^MaxMemAlloc=.*/MaxMemAlloc=$mem/" "$inst/instance.cfg" && rm -f "$inst/instance.cfg.bak"
fi
# Mac Apple Silicon: o Modflared so baixa o cloudflared Intel, que sem Rosetta da "Bad CPU type".
# Ele prefere o "cloudflared" do PATH, entao o Prism recebe a pasta com o binario ARM.
# Versao fixa com o SHA-256 do release oficial (a mesma do scripts/iniciar.sh).
if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
  cf="$inst/bin"
  if [ "$(cat "$cf/versao" 2>/dev/null)" != "2026.10.7" ]; then
    mkdir -p "$cf"
    if curl -fsSL "https://github.com/cloudflare/cloudflared/releases/download/2026.10.7/cloudflared-darwin-arm64.tgz" -o "$tmp/cf.tgz" \
      && [ "$(shasum -a 256 "$tmp/cf.tgz" | awk '{print $1}')" = "3586ccf397e98e5f437e60e7c307ca6ac463e110580503af8bb8e6f9ebf831bd" ]; then
      tar -xzf "$tmp/cf.tgz" -C "$cf" && chmod +x "$cf/cloudflared" && echo 2026.10.7 > "$cf/versao"
    fi
  fi
  if [ -x "$cf/cloudflared" ]; then
    # O Prism so aplica Env no formato 1.3: sem ConfigVersion ele migra o Env com toMap() e grava {}.
    # O instance.cfg do zip (montar-pack.ps1) nao tem ConfigVersion, entao converte aqui.
    sed -i.bak '/^PreLaunchCommand=/s/"/\\"/g' "$inst/instance.cfg" && rm -f "$inst/instance.cfg.bak"
    printf 'ConfigVersion=1.3\nOverrideEnv=true\nEnv="{\\"PATH\\": \\"%s:/usr/bin:/bin:/usr/sbin:/sbin\\"}"\n' "$cf" >> "$inst/instance.cfg"
  elif ! arch -x86_64 /usr/bin/true 2>/dev/null; then
    # Reserva: sem o binario ARM, o Intel do Modflared so roda com a Rosetta.
    echo "Instalando a Rosetta (o Mac vai pedir a sua senha)..."
    sudo softwareupdate --install-rosetta --agree-to-license \
      || echo "AVISO: sem Rosetta. Se o jogo nao conectar, entre em 'Minezada (playit)' na lista de servidores." >&2
  fi
fi
cp "$tmp/x/.minecraft/packwiz-installer-bootstrap.jar" "$tmp/x/.minecraft/packwiz-installer.jar" "$inst/.minecraft/"
for f in servers.dat options.txt; do [ -f "$inst/.minecraft/$f" ] || cp "$tmp/x/.minecraft/$f" "$inst/.minecraft/"; done
# Liga os pacotes de recursos do pack em quem ja tinha options.txt, mantendo os que o jogador ligou.
# shortcut: nomes de pacote com virgula quebram este trecho; trocar por parser de JSON se aparecer um.
opt="$inst/.minecraft/options.txt"
want="$(sed -n 's/^resourcePacks:\[\(.*\)\]$/\1/p' "$tmp/x/.minecraft/options.txt" | tr ',' '\n')"
have="$(sed -n 's/^resourcePacks:\[\(.*\)\]$/\1/p' "$opt")"
[ -n "$have" ] || have='"vanilla"'
# Mantem os pacotes do jogador na ordem dele e poe os do pack por cima, na ordem do pack (Fresh
# Animations precisa ficar acima do Faithful). "vanilla" fica onde estava, na base.
wcsv=",$(printf '%s' "$want" | tr '\n' ','),"
nova=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  case "$wcsv" in *",$p,"*) [ "$p" = '"vanilla"' ] && nova="$nova,$p" ;; *) nova="$nova,$p" ;; esac
done <<EOF
$(printf '%s' "$have" | tr ',' '\n')
EOF
while IFS= read -r p; do
  [ -n "$p" ] && [ "$p" != '"vanilla"' ] && nova="$nova,$p"
done <<EOF
$want
EOF
have="${nova#,}"
# awk com ENVIRON: o nome do pacote vai literal (sed trataria & e | como especiais).
if grep -q '^resourcePacks:' "$opt"; then
  RP="resourcePacks:[$have]" awk '/^resourcePacks:/ { print ENVIRON["RP"]; next } { print }' "$opt" > "$opt.tmp" && mv "$opt.tmp" "$opt"
else
  echo "resourcePacks:[$have]" >> "$opt"
fi
rm -rf "$tmp"

# 4. Atalho na Mesa (Mac) que abre direto o jogo.
if [ "$(uname -s)" = "Darwin" ]; then
  rm -rf "$HOME/Desktop/Minezada.app"
  osacompile -o "$HOME/Desktop/Minezada.app" -e "do shell script quoted form of \"$prism\" & \" --launch Minezada >/dev/null 2>&1 &\"" || true
fi

nohup "$prism" --launch Minezada >/dev/null 2>&1 &
echo
if [ $original = 1 ]; then
  echo "Pronto! Na primeira vez entre com a conta Microsoft. Depois e so abrir 'Minezada' na Mesa."
else
  echo "Pronto! Na primeira vez o launcher pede um nome: use seu nick exatamente como esta na"
  echo "whitelist (maiusculas contam). Depois e so abrir 'Minezada' na Mesa."
fi
