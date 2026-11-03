[CmdletBinding()]
param(
    [ValidateSet("web", "android")]
    [string]$Platform = "web",
    [string]$Device
)

$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$backendDirectory = Join-Path $projectRoot "backend"
$frontendDirectory = Join-Path $projectRoot "frontend"
$backendPython = Join-Path $backendDirectory ".venv\\Scripts\\python.exe"
$backendEnvironment = Join-Path $backendDirectory ".env"

if (-not (Test-Path $backendPython)) {
    throw "Backend virtual environment not found. Run the backend installation steps in README.md first."
}

if (-not (Test-Path $backendEnvironment)) {
    throw "Backend configuration not found. Copy backend/.env.example to backend/.env and configure DATABASE_URL."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter is not available on PATH. Install Flutter or add its bin directory to PATH."
}

$existingBackend = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
if ($existingBackend) {
    throw "Port 8000 is already in use. Stop the existing backend before using this launcher."
}

if ($Platform -eq "android") {
    $apiBaseUrl = "http://10.0.2.2:8000/api/v1"
} else {
    $apiBaseUrl = "http://localhost:8000/api/v1"
    if (-not $Device) {
        $Device = "chrome"
    }
}

$backendJob = Start-Job -Name "AgriVerse Backend" -ScriptBlock {
    param($pythonPath, $workingDirectory)

    Set-Location $workingDirectory
    & $pythonPath -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
} -ArgumentList $backendPython, $backendDirectory

$backendReady = $false
try {
    Write-Host "Starting backend and connecting to the configured database..." -ForegroundColor Cyan

    for ($attempt = 1; $attempt -le 20; $attempt++) {
        Start-Sleep -Seconds 1

        try {
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:8000/health/ready" -TimeoutSec 2
            if ($health.database.status -eq "connected") {
                $backendReady = $true
                break
            }
        } catch {
            if ($backendJob.State -in @("Failed", "Completed", "Stopped")) {
                Receive-Job $backendJob -Keep | Write-Host
                throw "The backend stopped before it could connect to the database."
            }
        }
    }

    if (-not $backendReady) {
        Receive-Job $backendJob -Keep | Write-Host
        throw "Backend did not become ready within 20 seconds. Check backend/.env and database connectivity."
    }

    Write-Host "Backend and database are ready. Launching Flutter..." -ForegroundColor Green
    Push-Location $frontendDirectory
    try {
        $flutterArguments = @("run", "--dart-define=API_BASE_URL=$apiBaseUrl")
        if ($Device) {
            $flutterArguments += @("-d", $Device)
        }

        & flutter @flutterArguments
        $flutterExitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
} finally {
    if ($backendJob) {
        Stop-Job $backendJob -ErrorAction SilentlyContinue
        Remove-Job $backendJob -Force -ErrorAction SilentlyContinue
    }
}

exit $flutterExitCode
