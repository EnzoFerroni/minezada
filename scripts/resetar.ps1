# Recomeca o servidor do zero (mundo novo, inventarios, missoes e conquistas zerados), por exemplo na abertura
# para todos. Antes de apagar, guarda o mundo atual em arquivo/ na pasta do Drive. Depois troca o
# modpack/arquivos/mundo-id.txt: na proxima abertura, o jogo de cada um apaga os mapas do Xaero e o cache do DH
# do mundo velho. Igual ao resetar.sh. Uso: powershell -ExecutionPolicy Bypass -File scripts\resetar.ps1 [-Sim]
# (-Sim responde a confirmacao, so para os testes).
param([switch]$Sim)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Morrer($msg) { Write-Host "ERRO: $msg" -ForegroundColor Red; exit 1 }

$sync = ''
$cfg = Join-Path $root 'config.env'
if (Test-Path $cfg) {
    $m = Select-String $cfg -Pattern '^SYNC_DIR="?(.*?)"?\s*$' | Select-Object -First 1
    if ($m) { $sync = $m.Matches[0].Groups[1].Value }
}
if (-not $sync -or -not (Test-Path $sync)) { Morrer 'Pasta do Drive nao encontrada (SYNC_DIR no config.env). Rode o iniciar uma vez antes.' }
$server = Join-Path $root 'server'

# Servidor ligado (aqui ou em outro host) = mundo em uso: nao mexe.
$lock = Join-Path $sync 'host.lock'
if ((Test-Path $lock) -and ((Get-Content $lock -Raw) -match '\S')) { Morrer "Servidor ligado em '$((Get-Content $lock -Raw).Trim())'. Desligue com stop e rode de novo." }
$rodando = @(try { Get-CimInstance Win32_Process -Filter "Name like 'java%'" | Where-Object { $_.CommandLine -and $_.CommandLine.Contains($server) } } catch { })
if ($rodando.Count) { Morrer 'Tem um servidor rodando nesta maquina. Desligue com stop e rode de novo.' }

Write-Host 'Isto apaga o mundo do servidor e todo o progresso (inventarios, missoes, conquistas, waystones).'
Write-Host "O mundo atual fica guardado em: $sync\arquivo\"
if (-not $Sim) {
    if ((Read-Host 'Digite RESETAR para continuar') -cne 'RESETAR') { Morrer 'Cancelado.' }
}

$data = Get-Date -Format 'yyyyMMdd-HHmm'
$arquivo = Join-Path $sync 'arquivo'
New-Item -ItemType Directory -Force $arquivo | Out-Null
function Guardar($origem, $nome) {
    $destino = Join-Path $arquivo $nome
    try { Copy-Item -LiteralPath $origem "$destino.tmp" -Force } catch { Remove-Item "$destino.tmp" -ErrorAction SilentlyContinue; Morrer "Nao consegui copiar $origem (Drive aberto?). Nada foi apagado." }
    if ((Get-Item "$destino.tmp").Length -eq 0) { Remove-Item "$destino.tmp"; Morrer "Copia vazia de $origem. Nada foi apagado." }
    Move-Item "$destino.tmp" $destino -Force
    Write-Host "Guardado: arquivo\$nome"
}
$guardou = $false
$mundo = Join-Path $sync 'mundo.tar.gz'
$sessao = Join-Path $sync 'backups\sessao-atual.tar.gz'
if (Test-Path $mundo) { Guardar $mundo "mundo-antes-do-reset-$data.tar.gz"; $guardou = $true }
if (Test-Path $sessao) { Guardar $sessao "sessao-antes-do-reset-$data.tar.gz"; $guardou = $true }
# Sem mundo no Drive (host sem Drive ate agora): guarda o mundo local.
if (-not $guardou -and (Test-Path (Join-Path $server 'world'))) {
    & tar -czf (Join-Path $arquivo "mundo-antes-do-reset-$data.tar.gz") --exclude session.lock -C $server world
    if ($LASTEXITCODE) { Morrer 'Nao consegui guardar o mundo local. Nada foi apagado.' }
    Write-Host "Guardado: arquivo\mundo-antes-do-reset-$data.tar.gz (mundo local)"
}

Remove-Item $mundo -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $sync 'backups') -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $server 'world') -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Apagados: mundo.tar.gz e backups\ do Drive, server\world desta maquina.'

[IO.File]::WriteAllText((Join-Path $root 'modpack\arquivos\mundo-id.txt'), "mundo-$data`n")
Write-Host @'

Pronto. Proximos passos:
1. Publicar o mundo-id novo: rode scripts\montar-pack.ps1, faca commit e push (os mapas velhos saem do jogo de cada um).
2. Ligue o servidor pelo iniciar: ele cria o mundo novo.
3. Pre-gere no console: chunky radius 1500 e chunky start (leva horas; deixe ligado ate "Task finished").
4. Desligue com stop: o mundo pre-gerado vai para o Drive.
'@
exit 0
