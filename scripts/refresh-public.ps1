# Export the Ringbots web build and ship this project's files to the zimaboard.
# Installs caddy/ringbots.caddy only. Does not edit the board Caddyfile,
# cloudflared, or any other app.
# Usage (repo root):
#   powershell -File scripts/refresh-public.ps1 [-SshHost zimaboard] [-RemoteDir /srv/ringbots]

param(
	[string]$SshHost = "zimaboard",
	[string]$RemoteDir = "/srv/ringbots"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$godot = (
	Get-ChildItem 'D:\Projects\Godot\Godot_v*_win64_console.exe' -ErrorAction SilentlyContinue |
	Select-Object -First 1
).FullName
if (-not $godot) {
	$godot = (
		Get-ChildItem 'D:\Projects\Godot\Godot_v*_win64.exe' -ErrorAction SilentlyContinue |
		Select-Object -First 1
	).FullName
}
if (-not $godot) {
	Write-Error "No Godot binary matched D:\Projects\Godot\Godot_v*_win64(_console).exe"
	exit 1
}

Write-Host "Godot: $godot"
New-Item -ItemType Directory -Force -Path build\web | Out-Null
$indexPath = Join-Path $PWD "build\web\index.html"
$beforeUtc = if (Test-Path $indexPath) {
	(Get-Item $indexPath).LastWriteTimeUtc
} else {
	[datetime]::MinValue
}

$export = Start-Process -FilePath $godot -ArgumentList @(
	"--headless",
	"--path", "godot",
	"--export-release", "Web",
	$indexPath
) -Wait -PassThru -NoNewWindow

if (-not (Test-Path $indexPath)) {
	Write-Error "Web export produced no build\web\index.html (exit $($export.ExitCode))"
	exit 1
}
$afterUtc = (Get-Item $indexPath).LastWriteTimeUtc
if ($afterUtc -le $beforeUtc) {
	Write-Error "Web export did not update build\web\index.html (exit $($export.ExitCode))"
	exit 1
}
Write-Host "Exported: $((Get-Item $indexPath).LastWriteTime) (exit $($export.ExitCode))"

$stage = Join-Path $env:TEMP "ringbots-deploy"
$tarPath = Join-Path $env:TEMP "ringbots-deploy.tar"
if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $stage "caddy") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stage "build\web") | Out-Null
Copy-Item -LiteralPath (Join-Path $PWD "caddy\ringbots.caddy") -Destination (Join-Path $stage "caddy\ringbots.caddy")
Copy-Item -Path (Join-Path $PWD "build\web\*") -Destination (Join-Path $stage "build\web") -Force

if (Test-Path $tarPath) { Remove-Item -LiteralPath $tarPath -Force }
Push-Location $stage
& tar.exe -cf $tarPath .
if ($LASTEXITCODE -ne 0) {
	Pop-Location
	Write-Error "tar failed"
	exit $LASTEXITCODE
}
Pop-Location
Write-Host "Payload: $tarPath -> ${SshHost}:$RemoteDir"

& scp.exe -o BatchMode=yes -o ConnectTimeout=15 $tarPath "${SshHost}:/tmp/ringbots-deploy.tar"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$remote = @"
set -euo pipefail
sudo mkdir -p '$RemoteDir'
sudo chown "`$(id -un):`$(id -gn)" '$RemoteDir'
tar -xf /tmp/ringbots-deploy.tar -C '$RemoteDir'
rm -f /tmp/ringbots-deploy.tar
sed -i 's/\r`$//' '$RemoteDir/caddy/ringbots.caddy'
cp '$RemoteDir/caddy/ringbots.caddy' /srv/caddy/apps/ringbots.caddy
mkdir -p /srv/caddy/apps/ringbots-web
cp -a '$RemoteDir/build/web/.' /srv/caddy/apps/ringbots-web/
sudo docker compose -f /srv/bingus/zimaboard/caddy/docker-compose.yml exec caddy caddy reload --config /etc/caddy/Caddyfile
echo Health:
curl -sS -o /dev/null -w '  board frontdoor: %{http_code}\n' -H 'Host: ringbots.bingus.gg' http://127.0.0.1/
"@
$remote = $remote -replace "`r", ""
$remotePath = Join-Path $env:TEMP "ringbots-board-refresh.sh"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($remotePath, $remote, $utf8NoBom)
& scp.exe -o BatchMode=yes $remotePath "${SshHost}:/tmp/ringbots-board-refresh.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& ssh.exe -o BatchMode=yes $SshHost "sed -i 's/\r`$//' /tmp/ringbots-board-refresh.sh; bash /tmp/ringbots-board-refresh.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Health:"
curl.exe -sS -o NUL -w "  public: %{http_code}`n" https://ringbots.bingus.gg/
