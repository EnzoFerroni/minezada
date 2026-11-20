# Testa o desinstalar.ps1 em uma arvore falsa (APPDATA, LOCALAPPDATA, Area de Trabalho). Nada fora dela e tocado.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/testes/desinstalar.ps1
$ErrorActionPreference = 'Stop'
$script = (Resolve-Path (Join-Path $PSScriptRoot '..\..\desinstalar.ps1')).Path
$tmp = Join-Path $env:TEMP "desinstalar-teste-$PID"
$raiz = Join-Path $tmp 'arvore'
New-Item -ItemType Directory -Force $tmp | Out-Null
$falhas = 0

# uninstall.exe falso: so grava os argumentos em $env:MARCA.
$fakeExe = Join-Path $tmp 'fake-uninstall.exe'
if (-not (Test-Path $fakeExe)) {
    Add-Type -OutputType ConsoleApplication -OutputAssembly $fakeExe -TypeDefinition 'public static class P { public static void Main(string[] a) { System.IO.File.WriteAllText(System.Environment.GetEnvironmentVariable("MARCA"), string.Join(" ", a)); } }'
}

function New-Arvore($nome, [switch]$Outra, [switch]$Fork, [switch]$Prism, [switch]$Servidor) {
    $r = Join-Path $raiz $nome
    if (Test-Path $r) { Remove-Item $r -Recurse -Force }
    $d = "$r\Roaming\PrismLauncher"
    New-Item -ItemType Directory -Force "$d\instances\Minezada\.minecraft\saves", "$d\instances\.LAUNCHER_TEMP", "$r\Desktop", "$r\Local", "$r\PF" | Out-Null
    Set-Content "$d\prismlauncher.cfg" "[General]`nLanguage=pt_BR"
    Set-Content "$d\accounts.json" '{}'
    Set-Content "$d\instances\instgroups.json" '{}'
    Set-Content "$d\instances\Minezada\minezada-zip.txt" 'x'
    Set-Content "$r\Desktop\Minezada.lnk" 'x'
    Set-Content "$r\Desktop\Outro.lnk" 'x'
    if ($Outra) { New-Item -ItemType Directory -Force "$d\instances\Outra" | Out-Null }
    if ($Fork) {
        New-Item -ItemType Directory -Force "$r\Local\Programs\Minezada Launcher" | Out-Null
        Set-Content "$r\Local\Programs\Minezada Launcher\prismlauncher.exe" 'x'
        Set-Content "$r\Local\Programs\Minezada Launcher\minezada-versao.txt" 'x'
    }
    if ($Prism) {
        New-Item -ItemType Directory -Force "$r\Local\Programs\PrismLauncher" | Out-Null
        Set-Content "$r\Local\Programs\PrismLauncher\prismlauncher.exe" 'x'
        Copy-Item $fakeExe "$r\Local\Programs\PrismLauncher\uninstall.exe"
    }
    if ($Servidor) { New-Item -ItemType Directory -Force "$r\Minezada-servidor" | Out-Null }
    $r
}

function Invoke-Caso($r, $entrada) {
    $env:APPDATA = "$r\Roaming"; $env:LOCALAPPDATA = "$r\Local"; $env:ProgramFiles = "$r\PF"
    $env:USERPROFILE = $r; $env:MINEZADA_DESKTOP = "$r\Desktop"; $env:MARCA = "$r\uninstall-rodou.txt"
    # Igual ao uso real: irm | iex.
    if ($entrada) { $env:MINEZADA_SIM = ''; $saida = $entrada | powershell -NoProfile -Command "iex (Get-Content '$script' -Raw)" 2>&1 }
    else { $env:MINEZADA_SIM = '1'; $saida = powershell -NoProfile -Command "iex (Get-Content '$script' -Raw)" 2>&1 }
    "  exit=$LASTEXITCODE"
    $saida | ForEach-Object { "  | $_" }
}

function Confere($desc, $ok) {
    if ($ok) { "  ok    $desc" } else { "  FALHA $desc"; $script:falhas++ }
}

# Salva o ambiente real para restaurar no fim.
$salvo = @{}; foreach ($v in 'APPDATA', 'LOCALAPPDATA', 'ProgramFiles', 'USERPROFILE', 'MINEZADA_DESKTOP', 'MARCA', 'MINEZADA_SIM') { $salvo[$v] = [Environment]::GetEnvironmentVariable($v) }
try {
    '(a) so a Minezada, Prism oficial instalado, pasta do servidor'
    $r = New-Arvore 'a' -Prism -Servidor
    Invoke-Caso $r
    Confere 'instancia removida' (-not (Test-Path "$r\Roaming\PrismLauncher\instances\Minezada"))
    Confere 'pasta de dados removida' (-not (Test-Path "$r\Roaming\PrismLauncher"))
    Confere 'atalho removido' (-not (Test-Path "$r\Desktop\Minezada.lnk"))
    Confere 'outro atalho intacto' (Test-Path "$r\Desktop\Outro.lnk")
    Confere 'uninstall.exe rodou com /S' ((Get-Content "$r\uninstall-rodou.txt" -ErrorAction SilentlyContinue) -like '/S _?=*')
    Confere 'pasta do Prism removida' (-not (Test-Path "$r\Local\Programs\PrismLauncher"))
    Confere 'servidor intacto' (Test-Path "$r\Minezada-servidor")

    '(b) outra instancia junto'
    $r = New-Arvore 'b' -Prism -Outra
    Invoke-Caso $r
    Confere 'instancia Minezada removida' (-not (Test-Path "$r\Roaming\PrismLauncher\instances\Minezada"))
    Confere 'outra instancia intacta' (Test-Path "$r\Roaming\PrismLauncher\instances\Outra")
    Confere 'contas intactas' (Test-Path "$r\Roaming\PrismLauncher\accounts.json")
    Confere 'Prism intacto' (Test-Path "$r\Local\Programs\PrismLauncher\prismlauncher.exe")
    Confere 'uninstall.exe nao rodou' (-not (Test-Path "$r\uninstall-rodou.txt"))
    Confere 'atalho removido' (-not (Test-Path "$r\Desktop\Minezada.lnk"))

    '(c) fork instalado, sem Prism oficial'
    $r = New-Arvore 'c' -Fork
    Invoke-Caso $r
    Confere 'fork removido' (-not (Test-Path "$r\Local\Programs\Minezada Launcher"))
    Confere 'pasta de dados removida' (-not (Test-Path "$r\Roaming\PrismLauncher"))
    Confere 'uninstall.exe nao rodou' (-not (Test-Path "$r\uninstall-rodou.txt"))
    Confere 'pasta Local intacta' (Test-Path "$r\Local\Programs")

    '(d) fork com outra instancia'
    $r = New-Arvore 'd' -Fork -Outra
    Invoke-Caso $r
    Confere 'fork removido' (-not (Test-Path "$r\Local\Programs\Minezada Launcher"))
    Confere 'outra instancia intacta' (Test-Path "$r\Roaming\PrismLauncher\instances\Outra")

    '(e) responde n na confirmacao'
    $r = New-Arvore 'e' -Prism
    Invoke-Caso $r 'n'
    Confere 'instancia intacta' (Test-Path "$r\Roaming\PrismLauncher\instances\Minezada")
    Confere 'atalho intacto' (Test-Path "$r\Desktop\Minezada.lnk")
    Confere 'uninstall.exe nao rodou' (-not (Test-Path "$r\uninstall-rodou.txt"))

    '(f) nada instalado'
    $r = Join-Path $raiz 'f'; if (Test-Path $r) { Remove-Item $r -Recurse -Force }
    New-Item -ItemType Directory -Force "$r\Roaming", "$r\Local", "$r\PF", "$r\Desktop" | Out-Null
    Invoke-Caso $r
    Confere 'sem erro' ($LASTEXITCODE -eq 0)

    '(g) InstanceDir personalizado no cfg'
    $r = New-Arvore 'g'
    Move-Item "$r\Roaming\PrismLauncher\instances" "$r\inst"
    Set-Content "$r\Roaming\PrismLauncher\prismlauncher.cfg" "[General]`nInstanceDir=$r\inst"
    Invoke-Caso $r
    Confere 'instancia removida' (-not (Test-Path "$r\inst\Minezada"))
    Confere 'pasta de dados removida' (-not (Test-Path "$r\Roaming\PrismLauncher"))

    '(h) fecha so o jogo e o launcher da arvore falsa'
    $sleeper = Join-Path $tmp 'fake-sleep.exe'
    if (-not (Test-Path $sleeper)) {
        Add-Type -OutputType ConsoleApplication -OutputAssembly $sleeper -TypeDefinition 'public static class S { public static void Main(string[] a) { System.Threading.Thread.Sleep(60000); } }'
    }
    $r = New-Arvore 'h' -Prism
    $outro = Join-Path $raiz 'h-outro'; New-Item -ItemType Directory -Force $outro | Out-Null
    Copy-Item $sleeper "$outro\java.exe"; Copy-Item $sleeper "$outro\prismlauncher.exe"
    Copy-Item $sleeper "$r\Local\Programs\PrismLauncher\prismlauncher.exe" -Force
    $jogo = Start-Process "$outro\java.exe" "-Djava.library.path=$r\Roaming\PrismLauncher\instances\Minezada\natives" -PassThru -WindowStyle Hidden
    $alheio = Start-Process "$outro\java.exe" '-Djava.library.path=C:\x\PrismLauncher\instances\Minezada\natives' -PassThru -WindowStyle Hidden
    $prismFalso = Start-Process "$r\Local\Programs\PrismLauncher\prismlauncher.exe" -PassThru -WindowStyle Hidden
    $prismOutro = Start-Process "$outro\prismlauncher.exe" -PassThru -WindowStyle Hidden
    Start-Sleep 1
    Invoke-Caso $r
    Start-Sleep 1
    Confere 'jogo da instancia fechado' ($jogo.HasExited)
    Confere 'java de outra pasta Minezada continua' (-not $alheio.HasExited)
    Confere 'Prism falso fechado' ($prismFalso.HasExited)
    Confere 'prismlauncher de outro caminho continua' (-not $prismOutro.HasExited)
    $alheio, $prismOutro | Stop-Process -Force -ErrorAction SilentlyContinue
}
finally {
    foreach ($v in $salvo.Keys) { [Environment]::SetEnvironmentVariable($v, $salvo[$v]) }
}
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
if ($falhas) { "falhas: $falhas"; exit 1 }
"ok    desinstalar"
