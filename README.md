# Screeps Private Server — Official MMO Parity

A Docker-based Screeps private server configured to match the **official Screeps MMO** as closely as possible, so code tested here can be deployed to the live server with confidence.

## Official MMO Parity

This server is configured to replicate the official Screeps MMO environment:

| Feature              | Status | Notes                                                 |
| -------------------- | ------ | ----------------------------------------------------- |
| Game Constants       | ✅     | Engine defaults match official values                 |
| Source Keepers       | ✅     | Present in SK rooms (within 4 tiles of sector center) |
| NPC Invaders         | ✅     | Spawn based on energy harvested                       |
| Power Creeps         | ✅     | Enabled via `screepsmod-features`                     |
| Factories            | ✅     | Enabled via `screepsmod-features`                     |
| Commodities/Deposits | ✅     | Enabled via `screepsmod-features`                     |
| Strongholds          | ✅     | Enabled via `screepsmod-features`                     |
| Market/Terminal      | ✅     | Built-in engine feature                               |
| Power Banks          | ✅     | Spawn in highway rooms                                |
| MongoDB Backend      | ✅     | Via `screepsmod-mongo`                                |
| Multi-Shard          | ❌     | Single shard only (sufficient for most testing)       |

### Known Differences from Official

- **Tick rate**: Set to 1 second (official is ~3-4.5s) for faster testing
- **Single shard**: No inter-shard portals or shard-based features
- **No Steam auth**: Uses password auth instead (via `screepsmod-auth`)
- **Player count**: No other real players — use bots for PvP testing
- **Market**: No real player orders — use CLI to seed NPC market orders

### Deploying to Official — Things to Keep in Mind

Your code will behave the same on official, but watch out for these edge cases:

1. **`Game.shard`** — This server is single-shard. On official, `Game.shard.name` exists and matters for inter-shard logic. Avoid hardcoding shard names.
2. **CPU Bucket** — Official has the 10,000 tick bucket with `Game.cpu.generatePixel()`. It works the same here, but the faster tick rate (1s vs ~3-4.5s) means your bucket fills at a different real-time rate.
3. **Market Liquidity** — Your test market is empty unless you seed it via CLI. Don't rely on specific market prices or order availability in your code.
4. **`Game.cpu.limit`** — Make sure your test user's CPU is set to match your official GCL allocation (use the CLI commands below). Official formula: `20 + GCL_level * 10`, capped at 300.

> **Rule of thumb:** If your code runs clean here without touching any of the above, it will run identically on the official server.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- Git (optional, for version control)

## Quick Start

### 1. Start the Server

```bash
docker-compose up -d
```

This launches all three containers (Screeps, MongoDB, Redis) in the background.

### 2. Connect to Your Server

In the Screeps game client:

1. Click "Private Server" on the main menu
2. Enter host: `localhost` and port: `21025`
3. Create an account (since `screepsmod-auth` is enabled)

## Management Commands

| Action       | Command                          | Description                           |
| ------------ | -------------------------------- | ------------------------------------- |
| Start Server | `docker-compose up -d`           | Launches all containers in background |
| Stop Server  | `docker-compose down`            | Safely shuts down (data preserved)    |
| View Logs    | `docker-compose logs -f screeps` | Follow server logs                    |
| Restart      | `docker-compose restart`         | Apply config changes                  |
| Rebuild      | `docker-compose up -d --build`   | Rebuild containers                    |

## CLI Administration

Access the Screeps CLI for admin commands:

```bash
docker-compose exec screeps screeps-launcher cli
```

### Common CLI Commands

```javascript
// Reset the entire game world (wipes all rooms, keeps config)
system.resetAllData();

// Pause / Resume the server
system.pauseSimulation();
system.resumeSimulation();

// --- OFFICIAL PARITY: Set CPU to match MMO (20 base + GCL*10, max 300) ---
storage.db.users.update({ username: 'YourUsername' }, { $set: { cpu: 300 } });

// Set GCL (official formula: GCL_MULTIPLY * (level ^ GCL_POW))
// GCL 10 = 1000000 * (10 ^ 2.4) ≈ 251,188,643
storage.db.users.update(
  { username: 'YourUsername' },
  { $set: { gcl: 251188643 } }
);

// Set GPL (for Power Creep testing)
// GPL 10 = 1000 * (10 ^ 2) = 100,000
storage.db.users.update(
  { username: 'YourUsername' },
  { $set: { power: 100000 } }
);

// Add credits for Market testing
storage.db.users.update(
  { username: 'YourUsername' },
  { $set: { money: 10000000 } }
);

// Spawn NPC market orders (useful since no real players exist)
Game.market.createOrder({
  type: ORDER_SELL,
  resourceType: RESOURCE_ENERGY,
  price: 0.01,
  totalAmount: 1000000,
  roomName: 'E5N5'
});
```

Type `.exit` to leave the CLI.

## Configuration Files

### config.yml

Main server configuration — tuned for official MMO parity:

- `tickRate`: Game speed in milliseconds (1000 = 1 tick/second, official ~3000-4500)
- `runners.processors`: Number of processor workers
- `mods`: List of server mods to enable
- `serverConfig`: Game constants and server behavior (defaults match official)
- `adminPassword`: Password for admin CLI access

### mods.json

Defines which mods to install:

| Mod                      | Purpose                                        |
| ------------------------ | ---------------------------------------------- |
| `screepsmod-auth`        | Password authentication (replaces Steam auth)  |
| `screepsmod-admin-utils` | Admin CLI commands and utilities               |
| `screepsmod-mongo`       | MongoDB storage backend                        |
| `screepsmod-features`    | Power Creeps, Factories, Deposits, Strongholds |

### Installed Mods

All mods listed in both `config.yml` and `mods.json` — they must stay in sync.

| Mod                      | Description                                    |
| ------------------------ | ---------------------------------------------- |
| `screepsmod-auth`        | Password authentication                        |
| `screepsmod-admin-utils` | Admin commands                                 |
| `screepsmod-mongo`       | MongoDB storage backend                        |
| `screepsmod-features`    | Power Creeps, Factories, Deposits, Strongholds |

To add a mod, add it to both `config.yml` and `mods.json`, then restart:

```bash
docker-compose restart
```

## Data Persistence

All data is stored in Docker volumes:

- `screeps-data`: Server files and mods
- `mongo-data`: Game world database
- `redis-data`: Runtime data

To completely reset (delete all data):

```bash
docker-compose down -v
```

## Troubleshooting

### Server won't start

```bash
docker-compose logs screeps
```

### Port already in use

Change the port in `docker-compose.yml`:

```yaml
ports:
  - '21026:21025' # Use external port 21026
```

### Reset world without losing config

Use the CLI:

```bash
docker-compose exec screeps screeps-launcher cli
> system.resetAllData()
```

## Folder Structure

```
Screeps/
├── docker-compose.yml   # Container orchestration
├── config.yml           # Server configuration
├── mods.json            # Mod list
└── README.md            # This file
```
