# AgriVerse AI Web Launcher Script
# Unlocks build directory and launches Flutter on Chrome safely

Write-Host "Unlocking build directory and stopping lingering Chrome/Dart processes..." -ForegroundColor Green
Get-Process chrome, dart -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

if (Test-Path "build") {
    Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
}

Write-Host "Launching AgriVerse AI on Chrome..." -ForegroundColor Cyan
flutter run -d chrome
