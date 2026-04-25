#!/usr/bin/env pwsh
# Start the Screeps server and initialise the world if needed.

Write-Host "[start] Starting Docker containers..." -ForegroundColor Cyan
docker compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Error "[start] Failed to start Docker containers!"
    exit 1
}

Write-Host "[start] Initialising world (waits for backend to be ready)..." -ForegroundColor Cyan
node init-world.js

if ($LASTEXITCODE -ne 0) {
    Write-Error "[start] World initialization failed!"
    Write-Host "[start] Check logs: docker compose logs screeps" -ForegroundColor Yellow
    exit 1
}

# The backend may have been crash-looping on an empty world before init-world
# seeded data. Restart it so the launcher picks up a clean run with the now-
# populated database.
Write-Host "[start] Restarting backend so it sees the seeded world..." -ForegroundColor Cyan
docker compose restart screeps | Out-Null

Write-Host ""
Write-Host "[start] Server is running!" -ForegroundColor Green
Write-Host "  Connect to: localhost:21025" -ForegroundColor Green
Write-Host "  CLI admin:  docker compose exec screeps screeps-launcher cli" -ForegroundColor Gray
