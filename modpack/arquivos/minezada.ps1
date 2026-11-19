# Roda antes de cada abertura do jogo (PreLaunchCommand da instancia, na pasta .minecraft).
# Vem pelo pack: uma mudanca aqui chega em todos sem rodar o comando de jogar de novo (vale a partir da
# abertura seguinte, porque o packwiz troca este arquivo enquanto ele roda).
# java.exe no lugar do javaw.exe: o PowerShell so espera programa de console terminar. (Start-Process -Wait
# da "Acesso negado" quando o Prism roda este script.)
# Perfis de shaders que sairam do pack (o packwiz nao apaga arquivo com preserve).
foreach ($p in 'Shader - Sildurs Vibrant', 'Shader - Super Duper Vanilla', 'Shader - Miniature', 'PC - Solas', 'PC - Rethinking Voxels') {
    Remove-Item -LiteralPath "options-profiles/$p" -Recurse -Force -ErrorAction SilentlyContinue
}
$java = if ($env:INST_JAVA) { $env:INST_JAVA -replace 'javaw\.exe$', 'java.exe' } else { 'java' }
# -t 0: sem a espera de 10 s do "Reconfigure optional mods?". Opcional novo continua abrindo a lista.
$pack = 'https://raw.githubusercontent.com/EnzoFerroni/minezada/main/modpack/pack/pack.toml'
& $java -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -t 0 $pack
if ($LASTEXITCODE) { exit $LASTEXITCODE }
# NeoForge da instancia igual ao do pack. O Prism ja carregou a versao desta abertura, entao troca o
# mmc-pack.json e pede para abrir de novo (com a versao antiga o servidor recusa a entrada).
try { $t = Invoke-RestMethod $pack -TimeoutSec 10 } catch { exit 0 }
$mc = [regex]::Match($t, 'minecraft = "(.+?)"').Groups[1].Value; $neo = [regex]::Match($t, 'neoforge = "(.+?)"').Groups[1].Value
if ($neo -and -not (Select-String -Quiet -SimpleMatch "`"$neo`"" ..\mmc-pack.json)) {
    Set-Content ..\mmc-pack.json -Encoding ascii "{`"formatVersion`":1,`"components`":[{`"uid`":`"net.minecraft`",`"version`":`"$mc`",`"important`":true},{`"uid`":`"net.neoforged`",`"version`":`"$neo`"}]}"
    Write-Host "Minezada atualizou o NeoForge para $neo. Feche este aviso e abra o jogo de novo."
    exit 1
}
exit 0
