# Testa a comparacao de versoes e faixas do montar-pack.ps1 (conferencia das dependencias dos jars).
# Uso: powershell -ExecutionPolicy Bypass -File scripts/testes/versoes.ps1
$ErrorActionPreference = 'Stop'
$arq = Join-Path $PSScriptRoot '..\montar-pack.ps1'
$ast = [Management.Automation.Language.Parser]::ParseFile($arq, [ref]$null, [ref]$null)
$ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in 'Comparar-Versao', 'Na-Faixa' }, $true) |
    ForEach-Object { Invoke-Expression $_.Extent.Text }

$erros = 0
function Conferir($nome, $obtido, $esperado) {
    if ($obtido -ne $esperado) { Write-Host "FALHOU: $nome (deu $obtido, esperado $esperado)"; $script:erros++ }
}
Conferir '1.0.82+mc1.21.1 = 1.0.82' (Comparar-Versao '1.0.82+mc1.21.1' '1.0.82') 0
Conferir 'beta.48 < beta.53' (Comparar-Versao '1.1.0-beta.48' '1.1.0-beta.53') -1
Conferir '1.10 > 1.9' (Comparar-Versao '1.10' '1.9') 1
Conferir '1.0 = 1' (Comparar-Versao '1.0' '1') 0
Conferir '1.0-beta < 1.0' (Comparar-Versao '1.0-beta' '1.0') -1
Conferir '1.0.1 > 1.0-rc1' (Comparar-Versao '1.0.1' '1.0-rc1') 1
Conferir 'alpha < rc' (Comparar-Versao '2.0-alpha' '2.0-rc') -1
Conferir 'beta.53 em [1.1.0-beta.53,)' (Na-Faixa '1.1.0-beta.53' '[1.1.0-beta.53,)') $true
Conferir 'beta.48 fora de [1.1.0-beta.53,)' (Na-Faixa '1.1.0-beta.48' '[1.1.0-beta.53,)') $false
Conferir 'limite aberto' (Na-Faixa '2.0' '[1.0,2.0)') $false
Conferir 'limite fechado' (Na-Faixa '2.0' '[1.0,2.0]') $true
Conferir 'exata' (Na-Faixa '1.5' '[1.5]') $true
Conferir 'varias faixas' (Na-Faixa '3.1' '[1,2),[3,4)') $true
Conferir 'qualquer' (Na-Faixa '9' '*') $true
Conferir 'versao solta aceita tudo' (Na-Faixa '0.1' '1.0') $true
Conferir 'espaco na faixa' (Na-Faixa '21.1.215' '[21.1.0, 22)') $true
if ($erros) { exit 1 }
Write-Host 'versoes: ok'
