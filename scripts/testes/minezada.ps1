# Testa o minezada.ps1 (roda antes de abrir o jogo) em uma pasta .minecraft falsa, sem rede nem packwiz:
# perfis antigos apagados, tabela de configs, shader que saiu do pack e pacotes de recursos forcados.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/testes/minezada.ps1
$ErrorActionPreference = 'Stop'
$script = (Resolve-Path (Join-Path $PSScriptRoot '..\..\modpack\arquivos\minezada.ps1')).Path
$d = Join-Path ([IO.Path]::GetTempPath()) "minezada-teste-$PID"
New-Item -ItemType Directory -Force "$d\config\xaero\minimap", "$d\shaderpacks", "$d\options-profiles\Mac 5 - Shader Bonito", "$d\options-profiles\6 - Shader" | Out-Null
$utf8 = New-Object Text.UTF8Encoding $false
function Gravar($rel, $txt) { [IO.File]::WriteAllText((Join-Path $d $rel), $txt, $utf8) }
Gravar 'options.txt' "key_key.pingwheel.ping_location:key.mouse.5`nresourcePacks:[`"vanilla`"]`n"
Gravar 'config\amc.json' "{`n    `"giveBookOnStartup`": true,`n    `"outra`": 1`n}`n"
Gravar 'config\aether-common.toml' "[gui]`n`t`"Show Patreon message`" = true`n"
Gravar 'config\xaero\minimap\client.cfg' "update_notifications = true`n"
Gravar 'shaderpacks\ComplementaryReimagined_r5.10.zip' ''
Gravar 'config\iris.properties' "enableShaders=true`nshaderPack=ComplementaryUnbound_r5.9.3.zip`n"
Gravar 'options-profiles\6 - Shader\iris.properties' "shaderPack=ComplementaryReimagined_r5.10.zip`n"

$erros = 0
function Conferir($nome, $ok) { if (-not $ok) { Write-Host "FALHOU: $nome"; $script:erros++ } }
Push-Location $d
try {
    $env:MINEZADA_SEM_PACKWIZ = '1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $script | Out-Null
    Conferir 'termina sem erro' ($LASTEXITCODE -eq 0)
    Conferir 'perfil antigo apagado' (-not (Test-Path 'options-profiles\Mac 5 - Shader Bonito'))
    Conferir 'perfil novo mantido' (Test-Path 'options-profiles\6 - Shader')
    Conferir 'livro do Alex desligado' ((Get-Content config\amc.json -Raw) -match '"giveBookOnStartup": false,')
    Conferir 'resto do JSON intacto' ((Get-Content config\amc.json -Raw) -match '"outra": 1')
    Conferir 'opcao com espaco (Aether)' ((Get-Content config\aether-common.toml -Raw) -match '"Show Patreon message" = false')
    Conferir 'aviso do Xaero desligado' ((Get-Content config\xaero\minimap\client.cfg -Raw) -match 'update_notifications = false')
    Conferir 'shader removido vira o Reimagined' ((Get-Content config\iris.properties -Raw) -match 'shaderPack=ComplementaryReimagined_r5.10.zip')
    $o = Get-Content options.txt -Raw
    Conferir 'tecla do Ping Wheel trocada' ($o -match 'key_key.pingwheel.ping_location:key.mouse.middle')
    Conferir 'Deep Aether Tooltips ligado' ($o -match 'resourcePacks:\[.*builtin/client/deep_aether_tooltips')
    Conferir 'Deep Aether Tooltips aceito como incompativel' ($o -match 'incompatibleResourcePacks:\[.*builtin/client/deep_aether_tooltips')
}
finally {
    Pop-Location
    Remove-Item Env:MINEZADA_SEM_PACKWIZ -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $d
}
if ($erros) { exit 1 }
Write-Host 'minezada.ps1: ok'
