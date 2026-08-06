#!/bin/bash
# MoltsPay Skill Setup - runs on first use
#
# Installs MoltsPay LOCALLY at a pinned version, verified against the committed
# package-lock.json, with dependency lifecycle scripts disabled. Never installs
# globally: this skill holds wallet and balance-signing keys, so install-time
# code execution is part of its threat model.
# See docs/SECURITY.md (issue 8) in the MoltsPay SDK repo.

set -euo pipefail

SKILL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MOLTSPAY="$SKILL_DIR/node_modules/.bin/moltspay"

echo "🔧 Setting up MoltsPay skill..."

# --ignore-scripts blocks preinstall/install/postinstall across the whole
# dependency tree. It also skips MoltsPay's own postinstall, which would
# otherwise fetch the alipay-bot CLI from Alipay's CDN - that is provisioned
# explicitly below instead.
echo "📦 Installing pinned dependencies..."
npm ci \
    --prefix "$SKILL_DIR" \
    --ignore-scripts \
    --no-audit \
    --no-fund

if [ ! -x "$MOLTSPAY" ]; then
    echo "❌ moltspay binary not found at: $MOLTSPAY"
    echo "   Install did not complete. Aborting before touching wallet state."
    exit 1
fi

echo "✅ moltspay installed locally ($("$MOLTSPAY" --version 2>/dev/null || echo 'version unknown'))"

# Initialize wallet if not exists
WALLET_FILE="${HOME}/.moltspay/wallet.json"
if [ ! -f "$WALLET_FILE" ]; then
    echo "🔐 Initializing wallet..."
    "$MOLTSPAY" init --chain base --max-per-tx 2 --max-per-day 10

    if [ -f "$WALLET_FILE" ]; then
        # node is already a hard requirement (npm above), so parse with it
        # rather than adding a jq dependency.
        ADDRESS=$(node -e "process.stdout.write(require('$WALLET_FILE').address || '')" 2>/dev/null || echo "")
        echo ""
        echo "✅ Setup complete!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📍 Wallet: ${ADDRESS:-<unreadable>}"
        echo "⛓️  Chain: Base (mainnet)"
        echo "💰 Limits: \$2/tx, \$10/day"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "⚠️  Fund wallet with USDC on Base to use services."
    fi
else
    echo "✅ Wallet already exists"
    "$MOLTSPAY" status 2>/dev/null || true
fi

echo ""
echo "ℹ️  Alipay rail only: run once before first use -"
echo "     npx -y @alipay/agent-payment install-cli"
echo "   Crypto, WeChat Pay, and balance rails need no extra step."
echo ""
echo "🎉 MoltsPay skill ready!"
echo "   Run it via: $MOLTSPAY"
