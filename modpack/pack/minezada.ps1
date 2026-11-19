# Roda antes de cada abertura do jogo (PreLaunchCommand da instancia, na pasta .minecraft).
# Vem pelo pack: uma mudanca aqui chega em todos sem rodar o comando de jogar de novo (vale a partir da
# abertura seguinte, porque o packwiz troca este arquivo enquanto ele roda).
$ErrorActionPreference = 'Stop'
$java = if ($env:INST_JAVA) { $env:INST_JAVA } else { 'javaw' }
# Start-Process -Wait: o javaw e programa de janela, e sem isso o PowerShell nao espera o packwiz terminar.
# -t 0: sem a espera de 10 s do "Reconfigure optional mods?". Opcional novo continua abrindo a lista.
$p = Start-Process $java -Wait -PassThru -NoNewWindow -ArgumentList '-jar', 'packwiz-installer-bootstrap.jar',
    '--bootstrap-no-update', '--bootstrap-main-jar', 'packwiz-installer.jar', '-t', '0',
    'https://raw.githubusercontent.com/EnzoFerroni/minezada/main/modpack/pack/pack.toml'
exit $p.ExitCode
