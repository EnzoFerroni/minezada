# Gera os perfis de grafico (mod Options Profiles) em modpack/arquivos/options-profiles a partir da tabela abaixo.
# Depois rode scripts/montar-pack.ps1. Cada perfil so aplica as opcoes listadas (nunca teclas, volume etc).
# Uso: powershell -ExecutionPolicy Bypass -File scripts/perfis.ps1 (Mac: pwsh scripts/perfis.ps1)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$destino = Join-Path $root 'modpack/arquivos/options-profiles'

# Nome do arquivo de cada shader no pack (gerado pelo montar-pack).
$sh = @{}
Get-ChildItem (Join-Path $root 'modpack/pack/shaderpacks') -Filter *.pw.toml | ForEach-Object {
    $sh[$_.Name -replace '\.pw\.toml$', ''] = (Select-String '^filename = "(.+)"' $_.FullName).Matches.Groups[1].Value
}

# rd = distancia de renderizacao, sim = simulacao, gm = 0 rapido / 1 bonito, part = 0 todas / 1 menos / 2 minimo,
# bio = mistura de bioma, mip = mipmap, ent = distancia de entidades, nuv = nuvens, fps = 260 e ilimitado,
# Perfis numerados e Mac usam so shaders que rodam no Mac (OpenGL 4.1); os "PC -" exigem OpenGL 4.3.
# Nomes sem acento nem parenteses: os arquivos sao baixados por link. Nao renomeie perfis existentes:
# o perfil antigo fica no jogo de quem ja tinha (preserve).
$perfis = @(
    @{ n = '1 - Minimo';            rd = 4;  sim = 5;  gm = 0; ao = $false; part = 2; somb = $false; bio = 0; mip = 0; ent = '0.5';  nuv = 'false'; fps = 60;  vs = $false; shader = '' }
    @{ n = '2 - Leve';              rd = 6;  sim = 5;  gm = 0; ao = $false; part = 2; somb = $false; bio = 0; mip = 0; ent = '0.75'; nuv = 'false'; fps = 60;  vs = $false; shader = '' }
    @{ n = '3 - Equilibrado';       rd = 10; sim = 8;  gm = 1; ao = $true;  part = 1; somb = $true;  bio = 2; mip = 4; ent = '1.0';  nuv = 'fast';  fps = 120; vs = $false; shader = '' }
    @{ n = '4 - Alto';              rd = 14; sim = 10; gm = 1; ao = $true;  part = 0; somb = $true;  bio = 3; mip = 4; ent = '1.0';  nuv = 'true';  fps = 260; vs = $false; shader = '' }
    @{ n = '5 - Bonito Shader';     rd = 12; sim = 8;  gm = 1; ao = $true;  part = 0; somb = $true;  bio = 3; mip = 4; ent = '1.0';  nuv = 'true';  fps = 260; vs = $true;  shader = 'complementary-reimagined' }
    @{ n = '6 - Muito Alto Shader'; rd = 16; sim = 10; gm = 1; ao = $true;  part = 0; somb = $true;  bio = 5; mip = 4; ent = '1.25'; nuv = 'true';  fps = 260; vs = $true;  shader = 'complementary-reimagined' }
    @{ n = '7 - Ultra Shader';      rd = 20; sim = 12; gm = 1; ao = $true;  part = 0; somb = $true;  bio = 7; mip = 4; ent = '1.5';  nuv = 'true';  fps = 260; vs = $true;  shader = 'complementary-unbound' }
    @{ n = '8 - FPS Maximo';        rd = 8;  sim = 6;  gm = 0; ao = $false; part = 1; somb = $false; bio = 0; mip = 2; ent = '0.75'; nuv = 'false'; fps = 260; vs = $false; shader = '' }
    @{ n = '9 - Bateria';           rd = 6;  sim = 5;  gm = 1; ao = $true;  part = 1; somb = $true;  bio = 1; mip = 2; ent = '0.75'; nuv = 'fast';  fps = 40;  vs = $true;  shader = '' }
    # Mac (Apple Silicon): VSync ligado (tela de 60/120 Hz, menos calor), simulacao menor que a distancia.
    @{ n = 'Mac 1 - Leve 8GB';         rd = 6;  sim = 5; gm = 0; ao = $true; part = 1; somb = $false; bio = 1; mip = 2; ent = '0.75'; nuv = 'fast'; fps = 60;  vs = $true; shader = '' }
    @{ n = 'Mac 2 - Equilibrado';      rd = 10; sim = 6; gm = 1; ao = $true; part = 1; somb = $true;  bio = 2; mip = 4; ent = '1.0';  nuv = 'fast'; fps = 120; vs = $true; shader = '' }
    @{ n = 'Mac 3 - Alto Pro Max';     rd = 14; sim = 8; gm = 1; ao = $true; part = 0; somb = $true;  bio = 3; mip = 4; ent = '1.0';  nuv = 'true'; fps = 120; vs = $true; shader = '' }
    @{ n = 'Mac 4 - Shader Leve';      rd = 8;  sim = 6; gm = 1; ao = $true; part = 1; somb = $true;  bio = 2; mip = 4; ent = '1.0';  nuv = 'fast'; fps = 60;  vs = $true; shader = 'makeup-ultra-fast-shaders' }
    @{ n = 'Mac 5 - Shader Bonito';    rd = 10; sim = 6; gm = 1; ao = $true; part = 0; somb = $true;  bio = 2; mip = 4; ent = '1.0';  nuv = 'true'; fps = 60;  vs = $true; shader = 'complementary-reimagined' }
    @{ n = 'Mac 6 - Shader Realista';  rd = 12; sim = 8; gm = 1; ao = $true; part = 0; somb = $true;  bio = 3; mip = 4; ent = '1.0';  nuv = 'true'; fps = 60;  vs = $true; shader = 'complementary-unbound' }
    @{ n = 'Mac 7 - Bateria';          rd = 6;  sim = 5; gm = 1; ao = $true; part = 1; somb = $true;  bio = 1; mip = 2; ent = '0.75'; nuv = 'fast'; fps = 30;  vs = $true; shader = '' }
    # Um perfil por shader que nao esta acima, para experimentar cada um com distancias medias.
    @{ n = 'Shader - BSL';                 rd = 10; sim = 6; gm = 1; ao = $true; part = 0; somb = $true; bio = 2; mip = 4; ent = '1.0'; nuv = 'true'; fps = 120; vs = $true; shader = 'bsl-shaders' }
    @{ n = 'Shader - Sildurs Vibrant';     rd = 10; sim = 6; gm = 1; ao = $true; part = 0; somb = $true; bio = 2; mip = 4; ent = '1.0'; nuv = 'true'; fps = 120; vs = $true; shader = 'sildurs-vibrant-shaders' }
    @{ n = 'Shader - Super Duper Vanilla'; rd = 10; sim = 6; gm = 1; ao = $true; part = 0; somb = $true; bio = 2; mip = 4; ent = '1.0'; nuv = 'true'; fps = 120; vs = $true; shader = 'super-duper-vanilla' }
    @{ n = 'Shader - Miniature';           rd = 10; sim = 6; gm = 1; ao = $true; part = 0; somb = $true; bio = 2; mip = 4; ent = '1.0'; nuv = 'true'; fps = 120; vs = $true; shader = 'miniature-shader' }
    # So PC (Windows/Linux com placa de video): nao rodam no Mac.
    @{ n = 'PC - Photon';            rd = 16; sim = 10; gm = 1; ao = $true; part = 0; somb = $true; bio = 5; mip = 4; ent = '1.25'; nuv = 'true'; fps = 260; vs = $true; shader = 'photon-shader' }
    @{ n = 'PC - Solas';             rd = 14; sim = 10; gm = 1; ao = $true; part = 0; somb = $true; bio = 3; mip = 4; ent = '1.0';  nuv = 'true'; fps = 260; vs = $true; shader = 'solas-shader' }
    @{ n = 'PC - Bliss';             rd = 16; sim = 10; gm = 1; ao = $true; part = 0; somb = $true; bio = 5; mip = 4; ent = '1.25'; nuv = 'true'; fps = 260; vs = $true; shader = 'bliss-shader' }
    @{ n = 'PC - Rethinking Voxels'; rd = 12; sim = 8;  gm = 1; ao = $true; part = 0; somb = $true; bio = 3; mip = 4; ent = '1.0';  nuv = 'true'; fps = 260; vs = $true; shader = 'rethinking-voxels' }
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
    # So options.txt e iris.properties (do Iris o mod aplica so shaderPack, debug e enableShaders). Sem
    # sodium-options.json, sodium-extra-options.json nem DistantHorizons.toml: o Options Profiles 1.4.2 chama
    # APIs que o Sodium 0.8, o Sodium Extra 0.9 e o DH 3 removeram, e o jogo fecha ao aplicar o perfil.
    $arq = if ($x.shader) { $sh[$x.shader] } else { '' }
    if ($x.shader -and -not $arq) { throw "Shader $($x.shader) nao esta no pack" }
    $iris = "allowUnknownShaders=false`ncolorSpace=SRGB`ndisableUpdateMessage=true`nenableDebugOptions=false`nenableShaders=$(if ($arq) { 'true' } else { 'false' })`nmaxShadowRenderDistance=32`nshaderPack=$arq`n"
    [IO.File]::WriteAllText((Join-Path $dir 'iris.properties'), $iris, $utf8)
    Write-Host ('{0,-24} rd={1,-2} fps={2,-3} shader={3}' -f $x.n, $x.rd, $x.fps, $(if ($arq) { $arq } else { '-' }))
}
