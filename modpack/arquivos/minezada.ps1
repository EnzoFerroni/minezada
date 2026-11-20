# Roda antes de cada abertura do jogo (PreLaunchCommand da instancia, na pasta .minecraft).
# Vem pelo pack: uma mudanca aqui chega em todos sem rodar o comando de jogar de novo (vale a partir da
# abertura seguinte, porque o packwiz troca este arquivo enquanto ele roda).
# java.exe no lugar do javaw.exe: o PowerShell so espera programa de console terminar. (Start-Process -Wait
# da "Acesso negado" quando o Prism roda este script.)
# Perfis de shaders que sairam do pack (o packwiz nao apaga arquivo com preserve).
foreach ($p in 'Shader - Sildurs Vibrant', 'Shader - Super Duper Vanilla', 'Shader - Miniature', 'PC - Solas', 'PC - Rethinking Voxels') {
    Remove-Item -LiteralPath "options-profiles/$p" -Recurse -Force -ErrorAction SilentlyContinue
}
# Teclas do pack, trocadas so em quem ainda esta sem a tecla salva ou no padrao do mod (tecla, padroes, nova):
# Ping Wheel no botao do meio (o padrao e o lateral, que o trackpad nao tem) e o pegar bloco no lateral;
# VeinMiner na tecla ao lado do 1 (o padrao Z bate com o Xaero).
# shortcut: quem escolher de volta um padrao do mod perde a escolha na abertura seguinte; marcar a troca se alguem reclamar.
$teclas = @(
    @('key_key.pingwheel.ping_location', 'key.mouse.5', 'key.mouse.middle'),
    @('key_key.pickItem', 'key.mouse.middle', 'key.mouse.5'),
    @('key_key.veinminer_client.hold', 'key.keyboard.z', 'key.keyboard.grave.accent')
)
if (Test-Path options.txt) {
    $o = [Collections.Generic.List[string]](Get-Content options.txt -Encoding UTF8)
    foreach ($t in $teclas) {
        $n = $o.FindIndex({ param($l) $l -like "$($t[0]):*" })
        if ($n -lt 0) { $o.Add("$($t[0]):$($t[2])") } elseif ($o[$n] -eq "$($t[0]):$($t[1])") { $o[$n] = "$($t[0]):$($t[2])" }
    }
    [IO.File]::WriteAllLines("$PWD\options.txt", $o)
}
# Na primeira abertura (instancia sem Java escolhido) o Prism passa a pasta de dados dele em INST_JAVA: usa o Java
# que ele baixou la dentro.
$java = $env:INST_JAVA
if (-not ($java -and (Test-Path -LiteralPath $java -PathType Leaf))) { $java = Get-ChildItem "$env:INST_JAVA\java\*\bin\javaw.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
$java = if ($java) { $java -replace 'javaw\.exe$', 'java.exe' } else { 'java' }
# Pack pelo link do commit mais novo: o link do main fica ate 5 min velho no cache do GitHub depois de um push.
$ref = try { "$(Invoke-RestMethod 'https://api.github.com/repos/EnzoFerroni/minezada/commits/main' -Headers @{ Accept = 'application/vnd.github.sha' } -TimeoutSec 10)".Trim() } catch { '' }
if ($ref -notmatch '^[0-9a-f]{40}$') { $ref = 'main' }
$pack = "https://raw.githubusercontent.com/EnzoFerroni/minezada/$ref/modpack/pack/pack.toml"
# -t 0: sem a espera de 10 s do "Reconfigure optional mods?". Opcional novo continua abrindo a lista.
& $java -jar packwiz-installer-bootstrap.jar --bootstrap-no-update --bootstrap-main-jar packwiz-installer.jar -t 0 $pack
exit $LASTEXITCODE
