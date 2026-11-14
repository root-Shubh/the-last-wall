# Exports the Windows Desktop release build to build/ (SVTLW-94).
# Usage: powershell -ExecutionPolicy Bypass -File tools/build_windows.ps1 [-Godot <path to Godot console exe>]
# build/ is git-ignored. Nothing is copied beside the executable.
param(
	[string]$Godot = $env:GODOT
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$game = Join-Path $root "game"
$build = Join-Path $root "build"

if (-not $Godot) {
	$Godot = "godot"
}

New-Item -ItemType Directory -Force -Path $build | Out-Null

& $Godot --headless --path $game --import | Out-Null

& $Godot --headless --path $game --export-release "Windows Desktop" "../build/TheLastWall.exe"
if ($LASTEXITCODE -ne 0) {
	Write-Error "Export failed with exit code $LASTEXITCODE. Check that the Windows export templates for Godot 4.7.2 are installed."
	exit $LASTEXITCODE
}

Write-Host "Exported build/TheLastWall.exe"
