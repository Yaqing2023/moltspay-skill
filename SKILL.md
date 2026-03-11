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

## First-Time Setup (Automatic)

**On first use, run the setup script:**

```bash
node scripts/setup.js
```

Or if skill was npm installed, it runs automatically.

This will:
1. Install `moltspay` globally via npm
2. Initialize wallet with default limits
3. Show wallet address for funding

After setup, use `moltspay` directly (no npx needed).

On first use, automatically initialize the wallet:

```bash
moltspay init --chain base --max-per-tx 2 --max-per-day 10
```

This creates a wallet with:
- **Chain:** Base (mainnet)
- **Max per transaction:** $2 USDC
- **Daily limit:** $10 USDC

Tell user their wallet address and that they need to fund it with USDC on Base.

## Check Wallet Status

```bash
moltspay status
```

Shows: wallet address, USDC balance, spending limits, today's usage.

## Discover Services

When user asks about available services, **run these commands yourself** and present the results nicely:

### Search on MoltsPay.com

```bash
# Search for services by keyword (run this, don't ask user to)
curl -s "https://moltspay.com/api/search?q=video" | jq '.services'

# List all available services
curl -s "https://moltspay.com/api/services" | jq '.services'
```

### From a Specific Provider

```bash
curl -s https://juai8.com/zen7/services | jq '.services'
```

**Present results as a table:**

| Service | Price | Description |
|---------|-------|-------------|
| text-to-video | $0.99 | Generate video from text prompt |
| image-to-video | $1.49 | Animate an image |

Don't show raw JSON to users - format it nicely!

## Pay for Services

### Zen7 Video Generation (Example)

**Text to Video ($0.99):**
```bash
moltspay pay https://juai8.com/zen7 text-to-video \
  --prompt "A cat dancing in the rain" \
  --duration 5
```

**Image to Video ($1.49):**
```bash
moltspay pay https://juai8.com/zen7 image-to-video \
  --image /path/to/image.jpg \
  --prompt "Make it come alive"
```

### Generic Service Payment

```bash
moltspay pay <service-url> <service-id> [--param value ...]
```

## Modify Spending Limits

```bash
# Interactive
moltspay config

# Direct
moltspay config --max-per-tx 5 --max-per-day 20
```

## Common Scenarios

### User: "Generate a video of a sunset over mountains"

1. Check if wallet exists: `moltspay status`
2. If not initialized, run init first
3. If balance is 0, tell user to fund wallet
4. If funded, run:
   ```bash
   moltspay pay https://juai8.com/zen7 text-to-video --prompt "A beautiful sunset over mountains"
   ```
5. Return the video URL to user

### User: "What's my wallet balance?"

```bash
moltspay status
```

### User: "What services can I buy?"

1. Run the search yourself:
   ```bash
   curl -s "https://moltspay.com/api/services" | jq '.services'
   ```

2. Present as a nice list:
   > Here are some AI services you can pay for:
   > 
   > **Zen7 Video Generation**
   > - Text to Video: $0.99 - describe a scene, get a video
   > - Image to Video: $1.49 - animate any image
   > 
   > Want me to search for something specific? Or browse all at moltspay.com/services

## Error Handling

| Error | Solution |
|-------|----------|
| "Insufficient balance" | Tell user to fund wallet with USDC on Base |
| "Exceeds daily limit" | Wait until tomorrow, or increase limit |
| "Exceeds per-tx limit" | Increase limit with `moltspay config` |
| "Service not found" | Check service URL and ID |

## Funding the Wallet

Tell user:
1. Copy wallet address from `moltspay status`
2. Send USDC on **Base chain** to that address
3. Can use Coinbase, MetaMask, or any Base-compatible wallet
4. No ETH needed for gas (gasless transactions)

## Links

- **Docs:** https://moltspay.com/docs
- **Services:** https://moltspay.com/services
- **Discord:** https://discord.gg/QwCJgVBxVK
- **Zen7 Demo:** https://moltspay.com/demo/livedemo.mp4
