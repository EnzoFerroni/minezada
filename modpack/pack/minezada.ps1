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
# Pack pelo link do commit mais novo: o link do main fica ate 5 min velho no cache do GitHub depois de um push.
$ref = try { "$(Invoke-RestMethod 'https://api.github.com/repos/EnzoFerroni/minezada/commits/main' -Headers @{ Accept = 'application/vnd.github.sha' } -TimeoutSec 10)".Trim() } catch { '' }
if ($ref -notmatch '^[0-9a-f]{40}$') { $ref = 'main' }
$pack = "https://raw.githubusercontent.com/EnzoFerroni/minezada/$ref/modpack/pack/pack.toml"
# -t 0: sem a espera de 10 s do "Reconfigure optional mods?". Opcional novo continua abrindo a lista.
& $java -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -t 0 $pack
exit $LASTEXITCODE
