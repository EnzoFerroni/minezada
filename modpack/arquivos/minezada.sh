#!/bin/bash
# Roda antes de cada abertura do jogo (PreLaunchCommand da instancia, na pasta .minecraft).
# Vem pelo pack: uma mudanca aqui chega em todos sem rodar o comando de jogar de novo (vale a partir da
# abertura seguinte). Tudo entre chaves: o bash le o bloco inteiro antes de rodar, e o packwiz pode trocar
# este arquivo no meio. --cloudflared: so o passo do cloudflared (o jogar.sh usa na instalacao).
{
set -e
inst="$(cd .. && pwd)"
# Mac Apple Silicon: o Modflared so baixa o cloudflared Intel, que sem Rosetta da "Bad CPU type". Ele prefere
# o "cloudflared" do PATH, e o jogar.sh poe esta pasta no PATH do Prism (Env da instancia). Versao fixa com o
# SHA-256 do release oficial (a mesma do scripts/iniciar.sh).
if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ] && [ "$(cat "$inst/bin/versao" 2>/dev/null)" != "2026.10.7" ]; then
  t="$(mktemp -d)"
  if curl -fsSL "https://github.com/cloudflare/cloudflared/releases/download/2026.10.7/cloudflared-darwin-arm64.tgz" -o "$t/cf.tgz" \
    && [ "$(shasum -a 256 "$t/cf.tgz" | awk '{print $1}')" = "3586ccf397e98e5f437e60e7c307ca6ac463e110580503af8bb8e6f9ebf831bd" ]; then
    mkdir -p "$inst/bin"
    tar -xzf "$t/cf.tgz" -C "$inst/bin" && chmod +x "$inst/bin/cloudflared" && echo 2026.10.7 > "$inst/bin/versao"
  fi
  rm -rf "$t"
fi
[ "${1:-}" != "--cloudflared" ] || exit 0
# Teclas do pack, trocadas so em quem ainda esta sem a tecla salva ou no padrao do mod (tecla padrao nova):
# Ping Wheel no botao do meio (o padrao e o lateral, que o trackpad nao tem) e o pegar bloco no lateral;
# VeinMiner na tecla ao lado do 1 (o padrao Z bate com o Xaero).
# shortcut: quem escolher de volta um padrao do mod perde a escolha na abertura seguinte; marcar a troca se alguem reclamar.
if [ -f options.txt ]; then
  while read -r k padrao nova; do
    atual="$(grep -m 1 "^$k:" options.txt || true)"
    if [ -z "$atual" ]; then
      echo "$k:$nova" >> options.txt
    elif [ "$atual" = "$k:$padrao" ]; then
      grep -v "^$k:" options.txt > options.txt.novo || true
      echo "$k:$nova" >> options.txt.novo
      mv options.txt.novo options.txt
    fi
  done <<'FIM'
key_key.pingwheel.ping_location key.mouse.5 key.mouse.middle
key_key.pickItem key.mouse.middle key.mouse.5
key_key.veinminer_client.hold key.keyboard.z key.keyboard.grave.accent
FIM
fi
# Na primeira abertura (instancia sem Java escolhido) o Prism passa a pasta de dados dele em INST_JAVA: usa o Java
# que ele baixou la dentro.
java="${INST_JAVA:-}"
[ -f "$java" ] || java="$(ls "${INST_JAVA:-/nada}"/java/*/bin/java "${INST_JAVA:-/nada}"/java/*/*/Contents/Home/bin/java 2>/dev/null | head -n 1)"
[ -n "$java" ] || java=java
# Pack pelo link do commit mais novo: o link do main fica ate 5 min velho no cache do GitHub depois de um push.
ref="$(curl -fsSL --max-time 10 -H 'Accept: application/vnd.github.sha' https://api.github.com/repos/EnzoFerroni/minezada/commits/main 2>/dev/null || true)"
case "$ref" in *[!0-9a-f]* | "") ref=main ;; esac
[ ${#ref} -eq 40 ] || ref=main
pack="https://raw.githubusercontent.com/EnzoFerroni/minezada/$ref/modpack/pack/pack.toml"
# -t 0: sem a espera de 10 s do "Reconfigure optional mods?". Opcional novo continua abrindo a lista.
"$java" -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -t 0 "$pack"
# Perfis de shaders que sairam do pack (o packwiz nao apaga arquivo com preserve).
rm -rf "options-profiles/Shader - Sildurs Vibrant" "options-profiles/Shader - Super Duper Vanilla" \
  "options-profiles/Shader - Miniature" "options-profiles/PC - Solas" "options-profiles/PC - Rethinking Voxels"
# Mac: Distant Horizons sempre desligado (fechou o jogo em um M4 e impede os shaders de abrir), mesmo que
# alguem marque na lista de opcionais. A escolha salva no packwiz.json evita baixar de novo.
if [ "$(uname -s)" = "Darwin" ]; then
  perl -pi -e 's/("mods\/distanthorizons\.pw\.toml":\{.*?"optionValue":)true/${1}false/' packwiz.json
  rm -f mods/DistantHorizons-*.jar
fi
exit 0
}
