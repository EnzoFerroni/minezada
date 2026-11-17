# Baixa/atualiza o servidor do Minezada, cria o atalho "Hospedar Minezada" na Area de Trabalho e sobe
# o servidor. Rode no PowerShell (serve para instalar, atualizar e hospedar):
#   irm https://raw.githubusercontent.com/EnzoFerroni/minezada/main/hospedar.ps1 | iex
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$dir = Join-Path $env:USERPROFILE 'Minezada-servidor'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'Instalando o Git...'
    winget install -e --id Git.Git --silent --accept-source-agreements --accept-package-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git nao instalado. Instale em https://git-scm.com e rode de novo.' }
}

if (Test-Path (Join-Path $dir '.git')) {
    git -C $dir pull --ff-only
    if ($LASTEXITCODE) { Write-Warning 'git pull falhou; seguindo com a versao local.' }
}
else {
    git clone --depth 1 https://github.com/EnzoFerroni/minezada $dir
    if ($LASTEXITCODE) { throw 'Falha ao baixar o servidor (git clone).' }
}

# Atalho na Area de Trabalho que sobe o servidor.
$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("$([Environment]::GetFolderPath('Desktop'))\Hospedar Minezada.lnk")
$lnk.TargetPath = Join-Path $dir 'iniciar.bat'; $lnk.WorkingDirectory = $dir; $lnk.Save()

# iniciar.bat abre a propria janela: o servidor precisa do teclado para perguntas e para o "stop".
Start-Process (Join-Path $dir 'iniciar.bat') -WorkingDirectory $dir
Write-Host "`nServidor abrindo em outra janela. Das proximas vezes, clique em 'Hospedar Minezada' na Area de Trabalho."
