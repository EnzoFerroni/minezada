# Escolhe a foto de cada mod para a vitrine (docs/mods.md) e grava modpack/fotos.txt ("slug | link").
# Candidatas, nesta ordem: galeria do Modrinth (destacada primeiro) e imagens da pagina do mod. Fica a primeira
# com cara de captura de tela: sem banner/logo no titulo ou no link, largura >= 400 px e proporcao entre 1,2 e 2,3.
# Sem nenhuma: o mod aparece so com o icone. Linhas ja em fotos.txt sao mantidas (corrija a mao se quiser);
# -Tudo escolhe de novo para todos. Uso: powershell -ExecutionPolicy Bypass -File scripts/fotos.ps1 [-Tudo]
param([switch]$Tudo)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$arq = Join-Path $root 'modpack/fotos.txt'
$h = @{ 'User-Agent' = 'minezada-modpack-builder/1.0' }
$ruim = 'banner|logo|header|title|thumbnail|cover|transparent|icon|divider|discord|patreon|ko-?fi|donat|sponsor|badge|shield|curseforge|bisect|kinetic|wiki'

$fotos = [ordered]@{}
if ((Test-Path $arq) -and -not $Tudo) {
    foreach ($l in Get-Content $arq -Encoding UTF8) { if ($l -match '^\s*([a-z0-9_-]+)\s*\|\s*(.*?)\s*$') { $fotos[$matches[1]] = $matches[2] } }
}

# Baixa a imagem num arquivo temporario e diz se tem formato de captura de tela.
$tmp = Join-Path ([IO.Path]::GetTempPath()) "minezada-foto-$PID"
function Boa($url) {
    try {
        Invoke-WebRequest $url -OutFile $tmp -UseBasicParsing -TimeoutSec 20 -Headers $h
        $i = [Drawing.Image]::FromFile($tmp)
        $ok = $i.Width -ge 400 -and ($i.Width / $i.Height) -ge 1.2 -and ($i.Width / $i.Height) -le 2.3
        $i.Dispose(); $ok
    }
    catch { $false }  # formato que o .NET nao abre (webp) ou link quebrado: nao arrisca
}

$slugs = Get-Content (Join-Path $root 'modpack/mods.txt') -Encoding UTF8 | ForEach-Object { if ($_ -match '^\s*([a-z0-9_-]+)\s*\|') { $matches[1] } }
foreach ($s in $slugs) {
    if ($fotos.Contains($s)) { continue }
    $p = [Text.Encoding]::UTF8.GetString((Invoke-WebRequest "https://api.modrinth.com/v2/project/$s" -Headers $h -UseBasicParsing).RawContentStream.ToArray()) | ConvertFrom-Json
    # Galeria: mede pelo original (raw_url, PNG/JPG) e mostra a versao webp leve do Modrinth (url).
    $cand = @($p.gallery | Where-Object { "$($_.title) $($_.description) $($_.url)" -notmatch $ruim } | Sort-Object { -not $_.featured }, ordering |
        ForEach-Object { [pscustomobject]@{ ver = $_.url; medir = $(if ($_.raw_url) { $_.raw_url } else { $_.url }) } })
    $cand += [regex]::Matches("$($p.body)", '!\[[^\]]*\]\(([^)\s]+)|<img[^>]+src="([^"]+)"') |
        ForEach-Object { if ($_.Groups[1].Value) { $_.Groups[1].Value } else { $_.Groups[2].Value } } |
        Where-Object { $_ -match '^https://' -and $_ -notmatch $ruim -and $_ -notmatch '\.svg(\?|$)' } |
        ForEach-Object { [pscustomobject]@{ ver = $_; medir = $_ } }
    $fotos[$s] = ($cand | Where-Object { Boa $_.medir } | Select-Object -First 1).ver
    Write-Host ('{0,-26} {1}' -f $s, $(if ($fotos[$s]) { $fotos[$s] } else { '(so icone)' }))
}
Remove-Item $tmp -ErrorAction SilentlyContinue
$linhas = @('# Foto de cada mod em docs/mods.md (gerado por scripts/fotos.ps1; pode corrigir a mao). Vazio = so o icone.') +
    @($slugs | ForEach-Object { "$_ | $($fotos[$_])" })
[IO.File]::WriteAllLines($arq, [string[]]$linhas, (New-Object Text.UTF8Encoding $false))
Write-Host "`n$(@($slugs | Where-Object { $fotos[$_] }).Count) de $($slugs.Count) mods com foto -> $arq"
