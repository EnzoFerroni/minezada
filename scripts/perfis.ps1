# Gera os perfis de grafico (mod Options Profiles) em modpack/arquivos/options-profiles a partir da tabela abaixo.
# Depois rode scripts\montar-pack.ps1. Cada perfil so aplica as opcoes listadas (nunca teclas, volume etc).
# Uso: powershell -ExecutionPolicy Bypass -File scripts\perfis.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$destino = Join-Path $root 'modpack\arquivos\options-profiles'

# Nome do arquivo de cada shader no pack (gerado pelo montar-pack).
$sh = @{}
Get-ChildItem (Join-Path $root 'modpack\pack\shaderpacks') -Filter *.pw.toml | ForEach-Object {
    $sh[$_.Name -replace '\.pw\.toml$', ''] = (Select-String '^filename = "(.+)"' $_.FullName).Matches.Groups[1].Value
}

# rd = distancia de renderizacao, sim = simulacao, gm = 0 rapido / 1 bonito, part = 0 todas / 1 menos / 2 minimo,
# bio = mistura de bioma, mip = mipmap, ent = distancia de entidades, nuv = nuvens, fps = 260 e ilimitado.
# Nomes sem acento: os arquivos sao baixados por link.
$perfis = @(
    @{ n = '1 - Minimo';            rd = 4;  sim = 5;  gm = 0; ao = $false; part = 2; somb = $false; bio = 0; mip = 0; ent = '0.5';  nuv = 'false'; fps = 60;  vs = $false; shader = '' }
    @{ n = '2 - Leve';              rd = 6;  sim = 5;  gm = 0; ao = $false; part = 2; somb = $false; bio = 0; mip = 0; ent = '0.75'; nuv = 'false'; fps = 60;  vs = $false; shader = '' }
    @{ n = '3 - Equilibrado';       rd = 10; sim = 8;  gm = 1; ao = $true;  part = 1; somb = $true;  bio = 2; mip = 4; ent = '1.0';  nuv = 'fast';  fps = 120; vs = $false; shader = '' }
    @{ n = '4 - Alto';              rd = 14; sim = 10; gm = 1; ao = $true;  part = 0; somb = $true;  bio = 3; mip = 4; ent = '1.0';  nuv = 'true';  fps = 260; vs = $false; shader = '' }
    @{ n = '5 - Bonito Shader';     rd = 12; sim = 8;  gm = 1; ao = $true;  part = 0; somb = $true;  bio = 3; mip = 4; ent = '1.0';  nuv = 'true';  fps = 260; vs = $true;  shader = 'complementary-reimagined' }
    @{ n = '6 - Muito Alto Shader'; rd = 16; sim = 10; gm = 1; ao = $true;  part = 0; somb = $true;  bio = 5; mip = 4; ent = '1.25'; nuv = 'true';  fps = 260; vs = $true;  shader = 'complementary-reimagined' }
    @{ n = '7 - Ultra Shader';      rd = 20; sim = 12; gm = 1; ao = $true;  part = 0; somb = $true;  bio = 7; mip = 4; ent = '1.5';  nuv = 'true';  fps = 260; vs = $true;  shader = 'photon-shader' }
    @{ n = '8 - FPS Maximo';        rd = 8;  sim = 6;  gm = 0; ao = $false; part = 1; somb = $false; bio = 0; mip = 2; ent = '0.75'; nuv = 'false'; fps = 260; vs = $false; shader = '' }
    @{ n = '9 - Bateria';           rd = 6;  sim = 5;  gm = 1; ao = $true;  part = 1; somb = $true;  bio = 1; mip = 2; ent = '0.75'; nuv = 'fast';  fps = 40;  vs = $true;  shader = '' }
)

$utf8 = New-Object Text.UTF8Encoding $false
if (Test-Path $destino) { Remove-Item -Recurse -Force $destino }
foreach ($x in $perfis) {
    $dir = Join-Path $destino $x.n
    New-Item -ItemType Directory -Force $dir | Out-Null
    $o = [ordered]@{
        renderDistance = $x.rd; simulationDistance = $x.sim; graphicsMode = $x.gm; ao = "$($x.ao)".ToLower()
        particles = $x.part; entityShadows = "$($x.somb)".ToLower(); biomeBlendRadius = $x.bio; mipmapLevels = $x.mip
        entityDistanceScaling = $x.ent; renderClouds = "`"$($x.nuv)`""; maxFps = $x.fps; enableVsync = "$($x.vs)".ToLower()
    }
    [IO.File]::WriteAllText((Join-Path $dir 'options.txt'), (($o.GetEnumerator() | ForEach-Object { "$($_.Key):$($_.Value)" }) -join "`n") + "`n", $utf8)
    $cfg = [ordered]@{ loadOnStartup = $false; keybindIndex = 0; optionsToLoad = @($o.Keys) }
    [IO.File]::WriteAllText((Join-Path $dir 'configuration.json'), ($cfg | ConvertTo-Json), $utf8)
    # Sem sodium-options.json: o Options Profiles 1.4.2 chama uma API que o Sodium 0.8 removeu e o jogo fecha.
    $arq = if ($x.shader) { $sh[$x.shader] } else { '' }
    if ($x.shader -and -not $arq) { throw "Shader $($x.shader) nao esta no pack" }
    $iris = "allowUnknownShaders=false`ncolorSpace=SRGB`ndisableUpdateMessage=true`nenableDebugOptions=false`nenableShaders=$(if ($arq) { 'true' } else { 'false' })`nmaxShadowRenderDistance=32`nshaderPack=$arq`n"
    [IO.File]::WriteAllText((Join-Path $dir 'iris.properties'), $iris, $utf8)
    Write-Host ('{0,-24} rd={1,-2} fps={2,-3} shader={3}' -f $x.n, $x.rd, $x.fps, $(if ($arq) { $arq } else { '-' }))
}
