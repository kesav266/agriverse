# AgriVerse AI Web Launcher Script
# Unlocks build directory and launches Flutter on Chrome safely

Write-Host "Unlocking build directory and stopping lingering Chrome/Dart processes..." -ForegroundColor Green
Get-Process dart -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

if (Test-Path "windows\flutter\ephemeral") {
    cmd /c "attrib -r -s windows\flutter\ephemeral\*.* /s /d" 2>$null
    cmd /c "rmdir /s /q windows\flutter\ephemeral" 2>$null
}

if (Test-Path "build") {
    cmd /c "attrib -r -s build\*.* /s /d" 2>$null
    cmd /c "rmdir /s /q build" 2>$null
}

Write-Host "Launching AgriVerse AI on Chrome..." -ForegroundColor Cyan
flutter run -d chrome
