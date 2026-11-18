# Testa o Sincronizar-Whitelist do iniciar.ps1 (Windows) com o caso de scripts/testes/whitelist/, o mesmo do
# whitelist.sh (Mac): as duas versoes tem que dar o mesmo resultado. Carrega so a funcao, sem rodar o iniciar.
# Uso: powershell -ExecutionPolicy Bypass -File scripts\testes\whitelist.ps1
$ErrorActionPreference = 'Stop'
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '..\iniciar.ps1'), [ref]$null, [ref]$null)
$funcao = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Sincronizar-Whitelist' }, $true)
. ([scriptblock]::Create($funcao.Extent.Text))

$t = Join-Path ([IO.Path]::GetTempPath()) "minezada-teste-$([guid]::NewGuid())"
Copy-Item -Recurse (Join-Path $PSScriptRoot 'whitelist') $t
try {
    Sincronizar-Whitelist (Join-Path $t 'jogadores.txt') $t
    $esperado = Get-Content (Join-Path $t 'esperado.json') -Raw | ConvertFrom-Json
    # Cada entrada vira "uuid|nome[|nivel]", em ordem, para comparar sem depender da ordem do arquivo.
    $chaves = { param($lista, $campos) @($lista | ForEach-Object { $e = $_; @($campos | ForEach-Object { $e.$_ }) -join '|' }) | Sort-Object }
    $erros = @()
    foreach ($nome in 'whitelist', 'ops') {
        $campos = if ($nome -eq 'ops') { 'uuid', 'name', 'level' } else { 'uuid', 'name' }
        # (o ForEach achata: no PS 5.1 o ConvertFrom-Json devolve a lista inteira como um item so)
        $obtido = (& $chaves (Get-Content (Join-Path $t "$nome.json") -Raw | ConvertFrom-Json | ForEach-Object { $_ }) $campos) -join ', '
        $quer = (& $chaves ($esperado.$nome | ForEach-Object { $_ }) $campos) -join ', '
        if ($obtido -cne $quer) { $erros += "$nome.json: esperado [$quer], veio [$obtido]" }
    }
    foreach ($a in $esperado.copiados) { if (-not (Test-Path (Join-Path $t $a))) { $erros += "progresso nao copiado: $a" } }
    if ($erros) { Write-Host "FALHA whitelist:`n  $($erros -join "`n  ")"; exit 1 }
    Write-Host 'ok    whitelist'
}
finally { Remove-Item -Recurse -Force $t }
