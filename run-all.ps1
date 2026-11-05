[CmdletBinding()]
param(
    [ValidateSet("web", "android")]
    [string]$Platform = "web",
    [string]$Device,
    [ValidateRange(1, 65535)]
    [int]$Port = 8000,
    [ValidateRange(1, 300)]
    [int]$StartupTimeoutSeconds = 20,
    [ValidateRange(1, 60)]
    [int]$ShutdownTimeoutSeconds = 10
)

$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$backendDirectory = Join-Path $projectRoot "backend"
$frontendDirectory = Join-Path $projectRoot "frontend"
$backendPython = Join-Path $backendDirectory ".venv\Scripts\python.exe"
$backendEnvironment = Join-Path $backendDirectory ".env"
$expectedAppName = "AgriVerse AI Backend"
$backendProcess = $null
$backendStartedByLauncher = $false
$flutterExitCode = 1

function Test-BackendReady {
    param([string]$Uri)

    try {
        $health = Invoke-RestMethod -Uri $Uri -TimeoutSec 2 -ErrorAction Stop
        return ($health.app_name -eq $expectedAppName -and $health.database.status -eq "connected")
    } catch {
        return $false
    }
}

function Stop-BackendProcess {
    param([System.Diagnostics.Process]$Process)

    if (-not $Process) {
        return
    }
    $Process.Refresh()
    if ($Process.HasExited) {
        return
    }

    $stopError = $null
    try {
        # Kill through the tracked process handle rather than looking up a PID.
        $Process.Kill()
    } catch {
        if (-not $Process.HasExited) {
            $stopError = $_.Exception.Message
        }
    }

    $exited = $false
    if (-not $stopError) {
        try {
            $exited = $Process.WaitForExit($ShutdownTimeoutSeconds * 1000)
        } catch {
            $stopError = $_.Exception.Message
        }
    }
    $Process.Refresh()
    if (-not $Process.HasExited) {
        if ($stopError) {
            throw "Could not terminate launcher-owned backend PID $($Process.Id): $stopError"
        }
        if (-not $exited) {
            throw "Could not terminate launcher-owned backend PID $($Process.Id) within $ShutdownTimeoutSeconds seconds; it is still running."
        }
        throw "Launcher-owned backend PID $($Process.Id) did not exit after the shutdown wait."
    }
}

if (-not (Test-Path -LiteralPath $backendPython -PathType Leaf)) {
    throw "Backend virtual environment not found at '$backendPython'. Run the backend installation steps in README.md first."
}
if (-not (Test-Path -LiteralPath $backendEnvironment -PathType Leaf)) {
    throw "Backend configuration not found at '$backendEnvironment'. Copy backend/.env.example to backend/.env and configure it."
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter is not available on PATH. Install Flutter or add its bin directory to PATH."
}

try {
    $healthUri = "http://127.0.0.1:$Port/health/ready"
    $existingListener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existingListener) {
        if (Test-BackendReady -Uri $healthUri) {
            Write-Host "AgriVerse backend is already healthy on port $Port; reusing it without taking ownership." -ForegroundColor Green
        } else {
            throw "Port $Port is already in use by another application or an unhealthy backend. No process was stopped."
        }
    } else {
        Write-Host "Starting backend on port $Port..." -ForegroundColor Cyan
        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $backendPython
        $startInfo.WorkingDirectory = $backendDirectory
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        # Inherit the launcher's console streams. No redirected pipes means no
        # asynchronous reader lifecycle or pipe-buffer deadlocks.
        $startInfo.Arguments = "-m uvicorn app.main:app --host 127.0.0.1 --port $Port"
        $backendProcess = [System.Diagnostics.Process]::new()
        $backendProcess.StartInfo = $startInfo
        if (-not $backendProcess.Start()) {
            throw "Python could not start the backend process."
        }
        $backendStartedByLauncher = $true

        $ready = $false
        $deadline = [DateTime]::UtcNow.AddSeconds($StartupTimeoutSeconds)
        while ([DateTime]::UtcNow -lt $deadline) {
            $backendProcess.Refresh()
            if ($backendProcess.HasExited) {
                throw "Backend process exited during startup (code $($backendProcess.ExitCode)). Check the backend startup output, backend/.env, and database connectivity."
            }
            if (Test-BackendReady -Uri $healthUri) {
                $ready = $true
                break
            }
            Start-Sleep -Milliseconds 500
        }
        if (-not $ready) {
            throw "Backend did not report the expected application identity and connected database within $StartupTimeoutSeconds seconds. Check the backend startup output and database connectivity."
        }
    }

    if ($Platform -eq "android") {
        $apiBaseUrl = "http://10.0.2.2:$Port/api/v1"
    } else {
        $apiBaseUrl = "http://localhost:$Port/api/v1"
        if (-not $Device) {
            $Device = "chrome"
        }
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
    if ($backendStartedByLauncher -and $backendProcess) {
        try {
            Stop-BackendProcess -Process $backendProcess
        } finally {
            $backendProcess.Dispose()
        }
    }
}

exit $flutterExitCode
