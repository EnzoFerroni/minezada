# Testa o resetar.ps1 em um repo, servidor e pasta do Drive falsos: recusa com servidor ligado, guarda o mundo em
# arquivo/ antes de apagar e troca o mundo-id.txt. Igual ao resetar.sh.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/testes/resetar.ps1
$ErrorActionPreference = 'Stop'
$script = (Resolve-Path (Join-Path $PSScriptRoot '../resetar.ps1')).Path
$d = Join-Path ([IO.Path]::GetTempPath()) "resetar-teste-$PID"
$r = Join-Path $d 'repo'; $drive = Join-Path $d 'drive'
foreach ($p in 'scripts', 'modpack/arquivos', 'server/world/region') { New-Item -ItemType Directory -Force (Join-Path $r $p) | Out-Null }
New-Item -ItemType Directory -Force (Join-Path $drive 'backups') | Out-Null
Copy-Item $script (Join-Path $r 'scripts')
function Gravar($p, $t) { [IO.File]::WriteAllText($p, $t) }
Gravar (Join-Path $r 'config.env') "SYNC_DIR=`"$drive`"`n"
Gravar (Join-Path $r 'modpack/arquivos/mundo-id.txt') "mundo-1`n"
Gravar (Join-Path $drive 'mundo.tar.gz') 'mundo velho'
Gravar (Join-Path $drive 'backups/sessao-atual.tar.gz') 'sessao'
Gravar (Join-Path $r 'server/world/level.dat') 'x'
$sh = if (Get-Command powershell -ErrorAction SilentlyContinue) { 'powershell' } else { 'pwsh' }
$rs = Join-Path $r 'scripts/resetar.ps1'

$erros = 0
function Conferir($nome, $ok) { if ($ok) { Write-Host "ok: $nome" } else { Write-Host "FALHOU: $nome"; $script:erros++ } }
try {
    Gravar (Join-Path $drive 'host.lock') "PC`n"
    & $sh -NoProfile -ExecutionPolicy Bypass -File $rs -Sim | Out-Null
    Conferir 'servidor ligado: recusa' ($LASTEXITCODE -ne 0 -and (Test-Path (Join-Path $drive 'mundo.tar.gz')) -and (Test-Path (Join-Path $r 'server/world')))
    Gravar (Join-Path $drive 'host.lock') ''

    & $sh -NoProfile -ExecutionPolicy Bypass -File $rs -Sim | Out-Null
    Conferir 'termina sem erro' ($LASTEXITCODE -eq 0)
    $guardado = @(Get-ChildItem (Join-Path $drive 'arquivo') -Filter 'mundo-antes-do-reset-*.tar.gz')
    Conferir 'mundo guardado em arquivo/' ($guardado.Count -eq 1 -and [IO.File]::ReadAllText($guardado[0].FullName) -eq 'mundo velho')
    Conferir 'sessao guardada em arquivo/' (@(Get-ChildItem (Join-Path $drive 'arquivo') -Filter 'sessao-antes-do-reset-*.tar.gz').Count -eq 1)
    Conferir 'mundo, backups e world local apagados' (-not (Test-Path (Join-Path $drive 'mundo.tar.gz')) -and -not (Test-Path (Join-Path $drive 'backups')) -and -not (Test-Path (Join-Path $r 'server/world')))
    Conferir 'mundo-id trocado' ([IO.File]::ReadAllText((Join-Path $r 'modpack/arquivos/mundo-id.txt')).Trim() -match '^mundo-\d{8}-\d{4}$')

    # Sem mundo no Drive: guarda o world local.
    Remove-Item (Join-Path $drive 'arquivo') -Recurse -Force
    New-Item -ItemType Directory -Force (Join-Path $r 'server/world') | Out-Null
    Gravar (Join-Path $r 'server/world/level.dat') 'x'
    & $sh -NoProfile -ExecutionPolicy Bypass -File $rs -Sim | Out-Null
    $tgz = @(Get-ChildItem (Join-Path $drive 'arquivo') -Filter 'mundo-antes-do-reset-*.tar.gz')
    Conferir 'sem Drive: world local guardado' ($tgz.Count -eq 1 -and ((& tar -tzf $tgz[0].FullName) -match 'world/level.dat'))
}
finally {
    Remove-Item -Recurse -Force $d -ErrorAction SilentlyContinue
}
if ($erros) { exit 1 }
Write-Host 'resetar.ps1: ok'
