---
name: moltspay_skill
description: |
  Pay for and use AI services via MoltsPay protocol.
  Trigger: User asks to generate video, use a paid service, etc.
  Auto-discovers services from /.well-known/agent-services.json
---

# MoltsPay Client Skill

Pay for AI services using USDC on Base chain. No gas needed.

## When to Use

- User asks to generate a video, image, or use any paid AI service
- User asks about wallet balance or payment history
- User wants to discover available services
- User mentions "pay", "buy", "purchase" + AI service

## Available Commands

The `moltspay` CLI provides these commands:

| Command | Description |
|---------|-------------|
| `moltspay init --chain base` | Create wallet (first time only) |
| `moltspay status` | Check balance and limits |
| `moltspay config` | Modify spending limits |
| `moltspay pay <url> <service>` | Pay for a service |

## Wallet Setup

On first use, initialize the wallet with sensible defaults:
- Chain: Base (mainnet)
- Max per transaction: $2 USDC
- Daily limit: $10 USDC

After setup, tell user their wallet address and that they need to fund it with USDC on Base.

## Discover Services

### MoltsPay API

Query available services:
- Search: `GET https://moltspay.com/api/search?q=<keyword>`
- List all: `GET https://moltspay.com/api/services`

### Provider Discovery

Providers publish services at `/.well-known/agent-services.json`

Example: `https://juai8.com/.well-known/agent-services.json`

**Present results as a table to users:**

| Service | Price | Description |
|---------|-------|-------------|
| text-to-video | $0.99 | Generate video from text prompt |
| image-to-video | $1.49 | Animate an image |

Never show raw JSON to users - always format nicely.

## Paying for Services

Use the `moltspay pay` command with the provider URL and service ID.

**Parameters vary by service:**
- `--prompt` for text-based services
- `--image` for image-based services
- `--duration` for video length

Example: Zen7 video generation at `https://juai8.com/zen7`

## Spending Limits

Users can configure:
- **max-per-tx**: Maximum per transaction (default $2)
- **max-per-day**: Daily spending limit (default $10)

Use `moltspay config` to modify limits.

## Common User Requests

### "Generate a video of X"

1. Check wallet status
2. If not initialized → init first
3. If balance is 0 → tell user to fund wallet
4. If funded → pay for text-to-video service
5. Return video URL to user

### "What's my balance?"

Run status check and report balance, limits, and today's usage.

### "What services are available?"

Query the MoltsPay API, format results as a clean list with prices.

## Error Handling

| Error | Solution |
|-------|----------|
| Insufficient balance | Tell user to fund wallet with USDC on Base |
| Exceeds daily limit | Wait until tomorrow, or increase limit |
| Exceeds per-tx limit | Increase limit with config command |
| Service not found | Verify service URL and ID |

## Funding Instructions

Tell users:
1. Get wallet address from status command
2. Send USDC on **Base chain** to that address
3. Use Coinbase, MetaMask, or any Base-compatible wallet
4. No ETH needed (gasless transactions)

## Links

- Docs: https://moltspay.com/docs
- Services: https://moltspay.com/services
- GitHub: https://github.com/Yaqing2023/moltspay
