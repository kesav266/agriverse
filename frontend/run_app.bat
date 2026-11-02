@echo off
echo Starting AgriVerse AI Web Server...
if exist build rmdir /s /q build 2>nul
echo Launching Flutter Web Server at http://localhost:8080
flutter run -d web-server --web-port=8080
