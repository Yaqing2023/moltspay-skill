#!/bin/bash
# Ensure MoltsPay wallet exists, auto-init if not

set -euo pipefail

SKILL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MOLTSPAY="$SKILL_DIR/node_modules/.bin/moltspay"

# Use the skill's own pinned binary, never whatever `moltspay` is on PATH.
if [ ! -x "$MOLTSPAY" ]; then
    echo "❌ moltspay not installed. Run: $SKILL_DIR/scripts/setup.sh"
    exit 1
fi

MOLTSPAY_DIR="${HOME}/.moltspay"
WALLET_FILE="${MOLTSPAY_DIR}/wallet.json"

if [ ! -f "$WALLET_FILE" ]; then
    echo "🔐 Initializing MoltsPay wallet..."
    "$MOLTSPAY" init --max-per-tx 2 --max-per-day 10

    if [ -f "$WALLET_FILE" ]; then
        echo ""
        echo "✅ Wallet created!"
        "$MOLTSPAY" status
        echo ""
        echo "⚠️  Fund your wallet with USDC on your preferred chain to start using services."
    else
        echo "❌ Failed to initialize wallet"
        exit 1
    fi
else
    echo "✅ Wallet already exists"
    "$MOLTSPAY" status
fi
