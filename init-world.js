/**
 * Screeps World Initializer
 *
 * Seeds the default Screeps world (the same shape as the official MMO sector)
 * by calling `system.resetAllData()` via the backend's CLI HTTP endpoint.
 *
 * Usage:  node init-world.js
 *
 * Idempotent — checks the existing room count first and skips if a world
 * is already present.
 */

const http = require('http');

const CLI_HOST = process.env.SCREEPS_CLI_HOST || '127.0.0.1';
const CLI_PORT = parseInt(process.env.SCREEPS_CLI_PORT || '21026', 10);

// ── CLI HTTP client ─────────────────────────────────────────────────

/**
 * POST a JS expression to the backend CLI endpoint.
 * Returns { status, body }.
 */
function cliRequest(command) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: CLI_HOST,
        port: CLI_PORT,
        method: 'POST',
        path: '/cli',
        headers: {
          'Content-Type': 'text/plain',
          'Content-Length': Buffer.byteLength(command)
        }
      },
      (res) => {
        let body = '';
        res.on('data', (c) => (body += c));
        res.on('end', () => resolve({ status: res.statusCode, body }));
      }
    );
    req.on('error', reject);
    req.write(command);
    req.end();
  });
}

/**
 * Wait until the CLI endpoint is reachable AND the backend isn't crash-looping.
 * Requires several consecutive successes to confirm stability.
 */
async function waitForCli({
  maxAttempts = 60,
  intervalMs = 2000,
  requiredStreak = 3
} = {}) {
  console.log(`[init-world] Waiting for CLI at ${CLI_HOST}:${CLI_PORT}...`);
  let streak = 0;
  for (let i = 1; i <= maxAttempts; i++) {
    try {
      const r = await cliRequest('1');
      if (r.status === 200) {
        streak++;
        if (streak >= requiredStreak) {
          console.log('[init-world] CLI is responsive.');
          return;
        }
      } else {
        streak = 0;
      }
    } catch {
      streak = 0;
    }
    await sleep(intervalMs);
  }
  throw new Error('CLI did not become reachable within timeout');
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

/**
 * Run a command and return the stringified result body.
 */
async function run(command) {
  const r = await cliRequest(command);
  if (r.status !== 200) {
    throw new Error(`CLI ${command} -> HTTP ${r.status}: ${r.body}`);
  }
  return r.body;
}

// ── Main ────────────────────────────────────────────────────────────

async function main() {
  await waitForCli();

  // Check existing world
  console.log('[init-world] Checking existing world...');
  const countBody = await run('storage.db.rooms.count()');
  const existing = parseInt(countBody.trim(), 10) || 0;

  if (existing > 0) {
    console.log(
      `[init-world] World already has ${existing} rooms. Skipping reset.`
    );
    return;
  }

  // Seed the default world
  console.log(
    '[init-world] Seeding default world via system.resetAllData()...'
  );
  await run('system.resetAllData()');

  // Verify
  await sleep(2000);
  const finalBody = await run('storage.db.rooms.count()');
  const total = parseInt(finalBody.trim(), 10) || 0;

  console.log('========================================');
  console.log('[init-world] World generation complete!');
  console.log(`  Total rooms: ${total}`);
  console.log('========================================');
  console.log('Connect to: localhost:21025');
}

main().catch((err) => {
  console.error('\n[init-world] ERROR:', err.message);
  process.exit(1);
});
