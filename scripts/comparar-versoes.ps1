# Em quais versoes do Minecraft os mods do pack (e os pedidos) tem versao para NeoForge no Modrinth.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/comparar-versoes.ps1 [slug-pedido ...]
# Mostra, para cada versao do jogo, quantos mods tem e quais faltam. So os mods do mods.txt contam (dependencias nao).
param([string[]]$Pedidos = @())
$ErrorActionPreference = 'Stop'
$api = 'https://api.modrinth.com/v2'
$h = @{ 'User-Agent' = 'minezada-comparar-versoes' }
function Get-Api($path) {
    $r = Invoke-WebRequest "$api/$path" -Headers $h -UseBasicParsing
    @([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ }
}
$root = Split-Path $PSScriptRoot
$slugs = foreach ($l in Get-Content (Join-Path $root 'modpack/mods.txt') -Encoding UTF8) { if ($l -match '^\s*([a-z0-9_-]+)\s*\|') { $matches[1] } }
$slugs = @($slugs) + $Pedidos | Select-Object -Unique

# Versoes do jogo que valem a comparacao: lancamentos de 1.20.1 em diante.
function Num($v) { $a = "$v.0.0".Split('.'); [version]"$($a[0]).$($a[1]).$($a[2])" }
$jogo = @(Get-Api 'tag/game_version' | Where-Object { $_.version_type -eq 'release' -and $_.version -match '^\d+\.\d+(\.\d+)?$' } |
    ForEach-Object version | Where-Object { (Num $_) -ge [version]'1.20.1' })
$tem = @{}; $fora = @()
foreach ($s in $slugs) {
    try {
        $p = Get-Api "project/$s"
        # Mod precisa de NeoForge; pacote de recursos, shader e datapack servem em qualquer loader.
        $vs = Get-Api "project/$s/version"
        if ($p.project_type -eq 'mod') { $vs = $vs | Where-Object { $_.loaders -contains 'neoforge' -or $_.loaders -contains 'datapack' } }
        $tem[$s] = @($vs | ForEach-Object game_versions | Select-Object -Unique)
    }
    catch { $fora += $s; Write-Host "${s}: nao esta no Modrinth" }
}
$lista = foreach ($v in $jogo) {
    $faltam = @($slugs | Where-Object { $_ -notin $fora -and $v -notin $tem[$_] })
    [pscustomobject]@{ Versao = $v; Tem = ($slugs.Count - $faltam.Count - $fora.Count); Faltam = $faltam.Count
        Pedidos = (@($Pedidos | Where-Object { $v -in $tem[$_] }).Count); Quais = ($faltam -join ', ') }
}
$ok = $slugs.Count - $fora.Count
Write-Host "`n$ok mods no Modrinth$(if ($Pedidos) { " (pedidos: $($Pedidos -join ', '))" })"
$lista | Sort-Object { Num $_.Versao } -Descending |
    Format-Table Versao, Tem, Faltam, @{ n = 'Pedidos ok'; e = { $_.Pedidos } }, @{ n = 'Faltam (ate 8)'; e = { (($_.Quais -split ', ') | Select-Object -First 8) -join ', ' } } -AutoSize -Wrap
