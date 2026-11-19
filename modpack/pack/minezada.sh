#!/bin/bash
# Roda antes de cada abertura do jogo (PreLaunchCommand da instancia, na pasta .minecraft).
# Vem pelo pack: uma mudanca aqui chega em todos sem rodar o comando de jogar de novo (vale a partir da
# abertura seguinte). Tudo entre chaves: o bash le o bloco inteiro antes de rodar, e o packwiz pode trocar
# este arquivo no meio.
{
set -e
java="${INST_JAVA:-java}"
# -t 0: sem a espera de 10 s do "Reconfigure optional mods?". Opcional novo continua abrindo a lista.
"$java" -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -t 0 \
  https://raw.githubusercontent.com/EnzoFerroni/minezada/main/modpack/pack/pack.toml
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
