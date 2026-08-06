#!/usr/bin/env node
/**
 * MoltsPay Skill Setup - Cross-platform (Windows/Mac/Linux)
 *
 * Installs MoltsPay LOCALLY at a pinned version, verified against the committed
 * package-lock.json, with dependency lifecycle scripts disabled. Never installs
 * globally: this skill holds wallet and balance-signing keys, so install-time
 * code execution is part of its threat model.
 * See docs/SECURITY.md (issue 8) in the MoltsPay SDK repo.
 */

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const SKILL_DIR = path.join(__dirname, '..');
const IS_WIN = process.platform === 'win32';
const MOLTSPAY = path.join(
  SKILL_DIR,
  'node_modules',
  '.bin',
  IS_WIN ? 'moltspay.cmd' : 'moltspay',
);
const WALLET_PATH = path.join(os.homedir(), '.moltspay', 'wallet.json');

/** Run a command. Returns the exit status; never throws. */
function run(cmd, cmdArgs, opts = {}) {
  const result = spawnSync(cmd, cmdArgs, {
    stdio: opts.silent ? 'pipe' : 'inherit',
    encoding: 'utf8',
    shell: IS_WIN, // .cmd shims on Windows need a shell
    ...opts,
  });
  return result;
}

console.log('🔧 Setting up MoltsPay skill...\n');

// 1. Install pinned dependencies locally.
//    --ignore-scripts blocks preinstall/install/postinstall across the whole
//    dependency tree. It also skips MoltsPay's own postinstall, which would
//    otherwise fetch the alipay-bot CLI from Alipay's CDN - provisioned
//    explicitly at the end instead.
console.log('📦 Installing pinned dependencies...');
const install = run(IS_WIN ? 'npm.cmd' : 'npm', [
  'ci',
  '--prefix',
  SKILL_DIR,
  '--ignore-scripts',
  '--no-audit',
  '--no-fund',
]);

// Unlike the previous version, an install failure is fatal. Continuing here
// would run wallet initialization against a half-installed tree.
if (install.error || install.status !== 0) {
  console.error('\n❌ Dependency install failed.');
  if (install.error) console.error(`   ${install.error.message}`);
  process.exit(1);
}

if (!fs.existsSync(MOLTSPAY)) {
  console.error(`\n❌ moltspay binary not found at: ${MOLTSPAY}`);
  console.error('   Aborting before touching wallet state.');
  process.exit(1);
}
console.log('✅ moltspay installed locally\n');

// 2. Initialize wallet if not exists
if (!fs.existsSync(WALLET_PATH)) {
  console.log('🔐 Initializing wallet...');
  run(MOLTSPAY, ['init', '--chain', 'base', '--max-per-tx', '2', '--max-per-day', '10']);

  if (fs.existsSync(WALLET_PATH)) {
    try {
      const wallet = JSON.parse(fs.readFileSync(WALLET_PATH, 'utf8'));
      console.log('\n✅ Setup complete!');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log(`📍 Wallet: ${wallet.address}`);
      console.log('⛓️  Chain: Base (mainnet)');
      console.log('💰 Limits: $2/tx, $10/day');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      console.log('⚠️  Fund wallet with USDC on Base to use services.');
    } catch (e) {
      console.log('✅ Wallet created');
    }
  }
} else {
  console.log('✅ Wallet already exists');
  run(MOLTSPAY, ['status']);
}

console.log('\nℹ️  Alipay rail only: run once before first use -');
console.log('     npx -y @alipay/agent-payment install-cli');
console.log('   Crypto, WeChat Pay, and balance rails need no extra step.');
console.log('\n🎉 MoltsPay skill ready!');
console.log(`   Run it via: ${MOLTSPAY}`);
