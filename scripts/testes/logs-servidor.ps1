# Testa o trecho do iniciar.ps1 que guarda os logs da sessao no Drive, com pastas falsas:
# latest.log, erros.txt so com WARN/ERROR, crash novo sim e velho nao, e no maximo 20 pastas.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/testes/logs-servidor.ps1
$ErrorActionPreference = 'Stop'
$t = Join-Path ([IO.Path]::GetTempPath()) "minezada-logs-$PID"
$sync = "$t\drive"; $server = "$t\server"
New-Item -ItemType Directory -Force "$server\logs", "$server\crash-reports", "$sync\logs" | Out-Null
1..22 | ForEach-Object { New-Item -ItemType Directory -Force ("$sync\logs\20200101-{0:D4}" -f $_) | Out-Null }
Set-Content "$server\logs\latest.log" "[x] [main/INFO] [a]: ok`n[x] [main/WARN] [b]: aviso`n[x] [Server thread/ERROR] [c]: erro"
Set-Content "$server\crash-reports\crash-velho.txt" 'v'
(Get-Item "$server\crash-reports\crash-velho.txt").LastWriteTime = (Get-Date).AddDays(-2)
$inicio = (Get-Date).AddMinutes(-1)
Set-Content "$server\crash-reports\crash-novo.txt" 'n'
Set-Content "$server\hs_err_pid1.log" 'h'

$src = Get-Content (Join-Path $PSScriptRoot '..\iniciar.ps1') -Raw
$bloco = [regex]::Match($src, '(?s)    # Logs da sessao no Drive.*?catch \{ Write-Warning "Nao guardei os logs[^\n]*\n    \}').Value
if (-not $bloco) { throw 'trecho dos logs nao encontrado no iniciar.ps1' }
Invoke-Expression $bloco

$d = (Get-ChildItem "$sync\logs" -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
$nomes = (Get-ChildItem $d | Sort-Object Name).Name -join ' '
$erros = @(Get-Content "$d\erros.txt")
$pastas = @(Get-ChildItem "$sync\logs" -Directory).Count
Remove-Item -Recurse -Force $t
if ($nomes -ne 'crash-novo.txt erros.txt hs_err_pid1.log latest.log') { throw "arquivos errados: $nomes" }
if ($erros.Count -ne 2) { throw "erros.txt com $($erros.Count) linhas" }
if ($pastas -ne 20) { throw "$pastas pastas de logs" }
Write-Host 'logs-servidor.ps1: ok'
