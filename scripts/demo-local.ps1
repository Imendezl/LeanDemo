# Ejecuta el ciclo completo de la demo en local desde PowerShell.
# Delegua en Git Bash, que es quien puede ejecutar el script demo-local.sh.
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "demo-local.sh"
if (-not (Test-Path $scriptPath)) { throw "No se encontró $scriptPath" }

# Localiza la instalación de Git (preferimos bin\bash.exe, que configura el PATH completo
# de Git Bash; usr\bin\bash.exe arranca sin las herramientas estándar en el PATH).
$candidates = @()
$found = (Get-Command bash -ErrorAction SilentlyContinue).Source
if ($found) {
    if ($found -match '(?i)^(.*)\\usr\\bin\\bash\.exe$') { $candidates += $Matches[1] }
    elseif ($found -match '(?i)^(.*)\\bin\\bash\.exe$')  { $candidates += $Matches[1] }
}
$candidates += @("C:\Program Files\Git", "E:\Git", "$env:LOCALAPPDATA\Programs\Git")

$bash = $null
foreach ($base in $candidates) {
    $p = Join-Path $base "bin\bash.exe"
    if (Test-Path $p) { $bash = $p; break }
}
if (-not $bash -and $found) { $bash = $found }
if (-not $bash) { throw "No se encontró Git Bash. Instala Git for Windows y vuelve a intentarlo." }

Write-Host "Ejecutando demo-local.sh con $bash ..." -ForegroundColor Cyan
& $bash $scriptPath @args
exit $LASTEXITCODE
