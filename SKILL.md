---
name: moltspay-skill
description: |
  Pay for and use AI services via MoltsPay protocol.
  Trigger: User asks to generate video, use a paid service, etc.
  Auto-discovers services from /.well-known/agent-services.json
---

# MoltsPay Client Skill

Pay for AI services using USDC/USDT across 8 crypto chains (gasless), or in CNY via the fiat rails — Alipay (支付宝, MoltsPay 2.0) and WeChat Pay (微信支付, MoltsPay 2.1).

## When to Use

- User asks to generate a video, image, or use any paid AI service
- User asks about wallet balance or payment history
- User wants to discover available services
- User mentions "pay", "buy", "purchase" + AI service

## Available Commands

| Command | Description |
|---------|-------------|
| `moltspay init` | Create wallet (works on all EVM chains + Solana) |
| `moltspay fund <amount>` | Fund wallet via QR code (debit card/Apple Pay) |
| `moltspay status` | Check balance on all chains |
| `moltspay config` | Modify spending limits |
| `moltspay services <url>` | List services from a provider or marketplace |
| `moltspay pay <url> <service> --chain <chain>` | Pay for a service |

## Supported Chains

| Chain | ID | Tokens | Notes |
|-------|-----|--------|-------|
| Base | `base` | USDC, USDT | Recommended, lowest fees |
| Polygon | `polygon` | USDC | Alternative EVM |
| BNB Chain | `bnb` | USDC, USDT | High liquidity |
| opBNB | `opbnb` | USDC | BNB L2, very low fees |
| Solana | `solana` | USDC | Fast, separate wallet |
| Tempo | `tempo_moderato` | pathUSD | Testnet only |
| Base Sepolia | `base_sepolia` | USDC | Testnet |
| BNB Testnet | `bnb_testnet` | USDC | Testnet |
| Solana Devnet | `solana_devnet` | USDC | Testnet |

## Fiat Rails — Alipay & WeChat (CNY)

In addition to the crypto chains above, MoltsPay adds **fiat rails**: pay in **CNY** via Alipay or WeChat Pay. No crypto balance or wallet is needed for either.

| Rail | `--rail` | Currency | Added | Notes |
|------|----------|----------|-------|-------|
| Alipay | `alipay` | CNY (yuan) | 2.0 | Autonomous: alipay-bot pays from the user's bound Alipay wallet |
| WeChat Pay | `wechat` | CNY (yuan) | 2.1 | **Scan to pay**: a QR is shown, a human scans it with the WeChat app |

- Select a fiat rail with `--rail`: `moltspay pay <url> <service> --rail alipay` or `--rail wechat`.
- A service exposes a CNY price only when its provider has that rail enabled; if a service is crypto-only, pay on a crypto chain instead.
- **Both rails finish with a scan + confirm**, then the client polls until the order is paid and the resource is delivered — paying via a fiat rail looks the same as awaiting a crypto settle.

### WeChat Pay flow (scan to pay)

When you run `moltspay pay <url> <service> --rail wechat`:

1. The client requests the service and receives the WeChat `code_url` from the server's 402.
2. It renders the `code_url` as a **QR code** in the terminal and emits `MEDIA: <png-path>` for chat surfaces.
3. **The user opens WeChat and scans the QR to pay** — there is no autonomous WeChat wallet; a human must scan.
4. The client polls every ~3s until the order is confirmed `SUCCESS`, then returns the service result.

Present the QR to the user and tell them the amount in CNY and to scan with WeChat. In CLI, terminal ASCII QR is acceptable. In webchat, Discord, Feishu, or any chat UI, capture the MoltsPay CLI `MEDIA: <png-path>` line and send that PNG through the channel's media/image capability. If a caller bypasses the CLI and only has the WeChat Native `code_url`, generate a QR image from it before sending. Do not rely on terminal ASCII QR in chat UIs because line wrapping and font rendering can make it hard or impossible to scan. Do not treat the Native `code_url` as a normal HTTPS checkout link; use it as QR payload unless the provider explicitly returns a browser-safe payment URL.

## Wallet Setup

`moltspay init` creates wallets for all chains:

**EVM Chains** (Base, Polygon, BNB, opBNB, Tempo):
- Single address works on all EVM chains
- Same private key, different networks

**Solana**:
- Separate Ed25519 keypair
- Different address from EVM

After setup, tell user their wallet addresses and that they need to fund with USDC on their preferred chain.

## Discover Services

### Marketplace Discovery

List all services on MoltsPay marketplace:
```
moltspay services https://moltspay.com
```

### Single Provider Discovery

List services from a specific provider:
```
moltspay services https://juai8.com/zen7
```

Shows provider name, wallet, supported chains, and all services with prices.

**Present results as a table to users:**

| Service | Price | Chains |
|---------|-------|--------|
| text-to-video | $0.99 USDC | Base, Polygon, BNB |
| image-to-video | $1.49 USDC | Base, Polygon, BNB |

Never show raw JSON to users - always format nicely.

## Chain Selection (Pay Only)

When paying:
- If server accepts only one chain → auto-selected
- If server accepts multiple chains → specify with `--chain`

Examples:
```bash
# Pay on Base (recommended)
moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --chain base

# Pay on Polygon
moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --chain polygon

# Pay on BNB
moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --chain bnb

# Pay on Solana
moltspay pay https://example.com/service image-gen --prompt "sunset" --chain solana

# Pay in CNY via Alipay (fiat, no crypto balance needed)
moltspay pay https://example.com/service text-to-video --prompt "a cat dancing" --rail alipay

# Pay in CNY via WeChat (fiat, scan the QR to pay)
moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --rail wechat
```

## Paying for Services

Use the `moltspay pay` command with the provider URL and service ID.

**Parameters vary by service:**
- `--prompt` for text-based services
- `--image` for image-based services
- `--chain` to specify which chain to pay on
- `--token` to specify token (USDC or USDT, default USDC)

Example: Zen7 video generation
```
moltspay pay https://juai8.com/zen7 text-to-video --prompt "sunset over ocean" --chain base
```

## Spending Limits

Users can configure:
- **max-per-tx**: Maximum per transaction (default $2)
- **max-per-day**: Daily spending limit (default $10)

Use `moltspay config` to modify limits.

## Funding Your Wallet

### Option 1: QR Code (Easiest - No crypto needed!)

```bash
# Fund $10 on Base (recommended)
moltspay fund 10

# Fund $20 on Polygon  
moltspay fund 20 --chain polygon

# Fund $10 on Solana
moltspay fund 10 --chain solana
```

Scan QR code → pay with US debit card or Apple Pay → tokens arrive in ~2 minutes.

**No CDP credentials or crypto knowledge needed.** Server handles everything.

### Option 2: Direct Transfer

**EVM Chains** - Same address works on Base, Polygon, BNB, opBNB:
- Send USDC from Coinbase, MetaMask, etc.
- Make sure you're on the correct network!

**Solana** - Different address:
- Send USDC to your Solana wallet address
- Check with `moltspay status`

⚠️ **Important:**
- Balance on Base ≠ Balance on Polygon ≠ Balance on Solana (separate!)
- Check balance per chain with `moltspay status`
- No ETH/MATIC/SOL needed for gas (gasless transactions via x402)
- Exception: BNB needs tiny amount of BNB for first approval (~$0.0001)

## Common User Requests

### "Generate a video of X"

1. Check wallet status (`moltspay status`)
2. If not initialized → run `moltspay init`
3. If balance is 0 → tell user to fund wallet
4. If funded → pay for text-to-video service with appropriate chain
5. Return video URL to user

### "What's my balance?"

Run `moltspay status` and report:
- Wallet addresses (EVM + Solana)
- Balance on each chain
- Spending limits
- Today's usage

### "What services are available?"

Run `moltspay services https://moltspay.com` to list marketplace.
Format results as a clean table with service names, prices, and providers.

## Error Handling

| Error | Solution |
|-------|----------|
| Insufficient balance | Fund wallet with USDC on the chain you want to use |
| Exceeds daily limit | Wait until tomorrow, or increase limit with `moltspay config` |
| Exceeds per-tx limit | Increase limit with `moltspay config` |
| Service not found | Verify service URL and ID |
| Chain mismatch | Server doesn't accept specified chain. Check supported chains. |
| Multi-chain required | Server accepts multiple chains. Specify `--chain` |
| BNB approval needed | First BNB payment needs tiny gas (~$0.0001 BNB) |
| Alipay not accepted | Service is crypto-only. Pay on a crypto chain instead |
| WeChat not accepted | Service doesn't offer the WeChat rail. Use `--rail alipay` or a crypto chain |
| WeChat payment timed out | User didn't scan/pay in time. Re-run to get a fresh QR (one code = one order) |

## Testnet Faucets

For testing without real money:

```bash
# Get 1 USDC on Base Sepolia
moltspay faucet --chain base_sepolia

# Get 1 USDC on BNB Testnet (+ 0.001 tBNB for gas)
moltspay faucet --chain bnb_testnet

# Get 1 USDC on Solana Devnet
moltspay faucet --chain solana_devnet
```

Limit: 1 USDC per address per 24 hours.

## Links

- Docs: https://moltspay.com/docs
- Marketplace: https://moltspay.com/services
- GitHub: https://github.com/Yaqing2023/moltspay-skill
