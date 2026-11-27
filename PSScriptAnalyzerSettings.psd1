# Regras do PSScriptAnalyzer no CI (lint.yml). Cada regra fora tem o motivo.
@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # Os scripts falam com o jogador pela janela.
        'PSAvoidUsingWriteHost',
        # Nomes em portugues (Baixar-Jar, Tentar).
        'PSUseApprovedVerbs',
        # catch vazio so onde a falha nao importa (save-on com o servidor ja fechado).
        'PSAvoidUsingEmptyCatchBlock',
        # Os testes carregam trechos dos scripts com Invoke-Expression.
        'PSAvoidUsingInvokeExpression',
        'PSUseDeclaredVarsMoreThanAssignments',
        # O packwiz exige SHA1 no .pw.toml.
        'PSAvoidUsingBrokenHashAlgorithms',
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
