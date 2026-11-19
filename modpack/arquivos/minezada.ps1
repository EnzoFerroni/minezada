# Roda antes de cada abertura do jogo (PreLaunchCommand da instancia, na pasta .minecraft).
# Vem pelo pack: uma mudanca aqui chega em todos sem rodar o comando de jogar de novo (vale a partir da
# abertura seguinte, porque o packwiz troca este arquivo enquanto ele roda).
# java.exe no lugar do javaw.exe: o PowerShell so espera programa de console terminar. (Start-Process -Wait
# da "Acesso negado" quando o Prism roda este script.)
$java = if ($env:INST_JAVA) { $env:INST_JAVA -replace 'javaw\.exe$', 'java.exe' } else { 'java' }
# -t 0: sem a espera de 10 s do "Reconfigure optional mods?". Opcional novo continua abrindo a lista.
& $java -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -t 0 https://raw.githubusercontent.com/EnzoFerroni/minezada/main/modpack/pack/pack.toml
exit $LASTEXITCODE
