#!/usr/bin/env pwsh
# Quick pause/resume/toggle for the Screeps simulation.
#   ./toggle-sim.ps1            -> toggles based on current state
#   ./toggle-sim.ps1 pause      -> pause
#   ./toggle-sim.ps1 resume     -> resume
#   ./toggle-sim.ps1 status     -> show current state

param(
    [ValidateSet('toggle', 'pause', 'resume', 'status')]
    [string]$Action = 'toggle'
)

$cli = 'http://127.0.0.1:21026/cli'

function Invoke-Cli([string]$expr) {
    try {
        $resp = Invoke-WebRequest -Uri $cli -Method POST -Body $expr `
            -ContentType 'text/plain' -ErrorAction Stop
        $body = $resp.Content
        # PowerShell may return Content as byte[]; normalise to string.
        if ($body -is [byte[]]) { $body = [System.Text.Encoding]::UTF8.GetString($body) }
        return $body.Trim()
    } catch {
        Write-Error "[sim] CLI request failed: $($_.Exception.Message)"
        Write-Host "[sim] Is the server running?  docker compose ps" -ForegroundColor Yellow
        exit 1
    }
}

# Use mainLoopPaused in redis as the source of truth (set by pause/resumeSimulation).
# Value is the string '1' (paused) or '0'/null (running).
$paused = (Invoke-Cli "storage.env.get('mainLoopPaused')") -eq '1'

switch ($Action) {
    'status' {
        if ($paused) { Write-Host '[sim] PAUSED'  -ForegroundColor Yellow }
        else         { Write-Host '[sim] RUNNING' -ForegroundColor Green  }
        return
    }
    'pause'  { $doPause = $true }
    'resume' { $doPause = $false }
    'toggle' { $doPause = -not $paused }
}

if ($doPause -eq $paused) {
    if ($paused) { Write-Host '[sim] Already PAUSED'  -ForegroundColor Yellow }
    else         { Write-Host '[sim] Already RUNNING' -ForegroundColor Green  }
    return
}

if ($doPause) {
    Invoke-Cli 'system.pauseSimulation()' | Out-Null
    Write-Host '[sim] -> PAUSED'  -ForegroundColor Yellow
} else {
    Invoke-Cli 'system.resumeSimulation()' | Out-Null
    Write-Host '[sim] -> RUNNING' -ForegroundColor Green
}
