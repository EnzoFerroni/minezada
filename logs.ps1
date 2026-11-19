# Manda os logs do Minezada para o mclo.gs e copia os links. Rode no PowerShell quando o jogo fechar ou nao conectar:
#   irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/logs.ps1 | iex
$ErrorActionPreference = 'Stop'
$dados = "$env:APPDATA\PrismLauncher"
$mc = "$dados\instances\Minezada\.minecraft"
$arquivos = @(
    Get-Item "$mc\logs\latest.log" -ErrorAction SilentlyContinue
    # Crash report so se for recente, para nao mandar um problema antigo.
    Get-ChildItem "$mc\crash-reports\*.txt" -ErrorAction SilentlyContinue | Where-Object LastWriteTime -gt (Get-Date).AddDays(-2) |
        Sort-Object LastWriteTime | Select-Object -Last 1
    Get-Item "$dados\logs\PrismLauncher-0.log" -ErrorAction SilentlyContinue
) | Where-Object { $_ }
if (-not $arquivos) { Write-Host 'Nenhum log do Minezada neste computador. Rode o comando de jogar antes.'; return }
$links = foreach ($a in $arquivos) {
    # Troca a pasta do usuario por ~ para nao mandar o nome do Windows. mclo.gs aceita ate 25 mil linhas.
    $texto = (Get-Content $a.FullName -Tail 25000 -Encoding UTF8) -join "`n"
    $texto = $texto.Replace($env:USERPROFILE, '~').Replace($env:USERPROFILE.Replace('\', '/'), '~')
    try {
        $r = Invoke-RestMethod -Method Post -Uri https://api.mclo.gs/1/log -Body @{ content = $texto }
        "$($a.Name): $($r.url)"
    } catch { Write-Host "Nao consegui mandar $($a.Name): $($_.Exception.Message)" }
}
if (-not $links) { return }
$links | Set-Clipboard
Write-Host "`nLinks copiados. Cole na conversa com o Enzo:`n"
$links | ForEach-Object { Write-Host $_ }
