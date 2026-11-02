@echo off
echo Starting AgriVerse AI Web Server...
if exist windows\flutter\ephemeral (
    attrib -r -s windows\flutter\ephemeral\*.* /s /d 2>nul
    rmdir /s /q windows\flutter\ephemeral 2>nul
)
if exist build (
    attrib -r -s build\*.* /s /d 2>nul
    rmdir /s /q build 2>nul
)
echo Launching Flutter Web Server at http://localhost:8080
flutter run -d web-server --web-port=8080
