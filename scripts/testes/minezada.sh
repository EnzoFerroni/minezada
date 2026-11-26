#!/usr/bin/env bash
# Testa o minezada.sh (roda antes de abrir o jogo) em uma .minecraft falsa, sem o packwiz: teclas, pacotes de
# recursos, avisos dos mods, perfis antigos, Distant Horizons no Mac e troca do shader que saiu do pack.
set -euo pipefail
raiz="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
falhou=0
confere() { if eval "$2"; then echo "ok: $1"; else echo "FALHOU: $1"; falhou=1; fi; }

mc="$tmp/inst/.minecraft"
mkdir -p "$mc/config/xaero/minimap" "$mc/shaderpacks" "$mc/mods" \
  "$mc/options-profiles/8 - FPS Maximo" "$mc/options-profiles/6 - Shader"
cp "$raiz/modpack/arquivos/minezada.sh" "$mc/"
cat > "$mc/options.txt" <<'FIM'
key_key.pickItem:key.mouse.middle
key_key.veinminer_client.hold:key.keyboard.x
resourcePacks:["vanilla"]
incompatibleResourcePacks:[]
FIM
printf '{"cachedFiles":{"resourcepacks/3d-crops.pw.toml":{"cachedLocation":"resourcepacks/crops-3d(2).zip"},"mods/distanthorizons.pw.toml":{"isOptional":true,"optionValue":true}}}' > "$mc/packwiz.json"
printf 'showGarbageCollectorWarning = true\n' > "$mc/config/DistantHorizons.toml"
printf '{\n  "giveBookOnStartup": true,\n  "outra": 1\n}\n' > "$mc/config/amc.json"
printf '[geral]\n\t"Show Patreon message" = true\n' > "$mc/config/aether-common.toml"
printf 'update_notifications = true\n' > "$mc/config/xaero/minimap/client.cfg"
touch "$mc/mods/DistantHorizons-2.0.jar" "$mc/shaderpacks/ComplementaryReimagined_r5.10.zip" "$mc/shaderpacks/BSL_v8.4.zip" \
  "$mc/shaderpacks/BSL_v10.0.zip"
printf 'enableShaders=true\nshaderPack=ComplementaryUnbound_r5.9.3.zip\n' > "$mc/config/iris.properties"
printf 'shaderPack=BSL_v8.2.zip\n' > "$mc/options-profiles/6 - Shader/iris.properties"

mkdir -p "$mc/xaero/world-map/Multiplayer_minezada.dpdns.org" "$mc/xaero/minimap/Multiplayer_minezada.dpdns.org" "$mc/xaero/world-map/Novo mundo"
printf 'mundo-1\n' > "$mc/mundo-id.txt"
(cd "$mc" && MINEZADA_SEM_PACKWIZ=1 INST_JAVA=/nada /bin/bash minezada.sh) || { echo "FALHOU: minezada.sh saiu com erro"; exit 1; }

# shellcheck disable=SC2034 # usado dentro do eval do confere
o="$mc/options.txt"
confere "tecla nova onde estava sem tecla" 'grep -qx "key_key.pingwheel.ping_location:key.mouse.middle" "$o"'
confere "tecla no padrao do mod trocada" 'grep -qx "key_key.pickItem:key.mouse.5" "$o"'
confere "tecla escolhida pelo jogador mantida" 'grep -qx "key_key.veinminer_client.hold:key.keyboard.x" "$o"'
confere "3D Crops nas duas listas" '[ "$(grep -c "\"file/crops-3d(2).zip\"" "$o")" = 2 ]'
confere "lista vazia vira lista de um item" 'grep -q "^incompatibleResourcePacks:\[\"file/crops-3d(2).zip\"," "$o"'
confere "Distant Horizons: aviso desligado" 'grep -qx "showGarbageCollectorWarning = false" "$mc/config/DistantHorizons.toml"'
confere "JSON: livro do Alex desligado e resto intacto" 'grep -q "\"giveBookOnStartup\": false,$" "$mc/config/amc.json" && grep -q "\"outra\": 1" "$mc/config/amc.json"'
confere "TOML com espaco no nome" 'grep -q "\"Show Patreon message\" = false" "$mc/config/aether-common.toml"'
confere "Xaero sem aviso de versao" 'grep -qx "update_notifications = false" "$mc/config/xaero/minimap/client.cfg"'
confere "perfil antigo apagado" '[ ! -e "$mc/options-profiles/8 - FPS Maximo" ]'
confere "perfil novo mantido" '[ -d "$mc/options-profiles/6 - Shader" ]'
confere "shader que saiu vai para o Complementary" 'grep -qx "shaderPack=ComplementaryReimagined_r5.10.zip" "$mc/config/iris.properties"'
confere "perfil com dois zips do mesmo shader vai para o Complementary" 'grep -qx "shaderPack=ComplementaryReimagined_r5.10.zip" "$mc/options-profiles/6 - Shader/iris.properties"'
if [ "$(uname -s)" = "Darwin" ]; then
  confere "Mac: Distant Horizons desmarcado e jar apagado" 'grep -q "\"optionValue\":false" "$mc/packwiz.json" && [ ! -e "$mc/mods/DistantHorizons-2.0.jar" ]'
fi

# Rodar de novo nao duplica nada.
(cd "$mc" && MINEZADA_SEM_PACKWIZ=1 INST_JAVA=/nada /bin/bash minezada.sh)
confere "segunda vez nao duplica o 3D Crops" '[ "$(grep -o "crops-3d(2).zip" "$o" | wc -l | tr -d " ")" = 2 ]'
confere "segunda vez nao duplica teclas" '[ "$(grep -c "^key_key.pingwheel.ping_location:" "$o")" = 1 ]'

confere "primeira vez: mapas do Xaero mantidos e id gravado" '[ -d "$mc/xaero/world-map/Multiplayer_minezada.dpdns.org" ] && grep -qx mundo-1 "$mc/.minezada-mundo-id"'

# Mundo novo (resetar troca o mundo-id.txt): mapas de servidor saem, mundo sozinho fica.
mkdir -p "$mc/Distant_Horizons_server_data/x"
printf 'mundo-2\n' > "$mc/mundo-id.txt"
(cd "$mc" && MINEZADA_SEM_PACKWIZ=1 INST_JAVA=/nada /bin/bash minezada.sh)
confere "mundo novo: mapas e marcadores do servidor apagados" '[ ! -e "$mc/xaero/world-map/Multiplayer_minezada.dpdns.org" ] && [ ! -e "$mc/xaero/minimap/Multiplayer_minezada.dpdns.org" ] && [ ! -e "$mc/Distant_Horizons_server_data" ]'
confere "mundo novo: mapa de mundo sozinho mantido e id novo" '[ -d "$mc/xaero/world-map/Novo mundo" ] && grep -qx mundo-2 "$mc/.minezada-mundo-id"'

exit $falhou
