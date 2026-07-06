---
name: moltspay-skill
description: |
  Pay for and use AI services via MoltsPay protocol.
  Trigger: User asks to generate video, use a paid service, etc.
  Auto-discovers services from /.well-known/agent-services.json
---

# MoltsPay Client Skill

Pay for AI services using USDC/USDT across 8 crypto chains (gasless), in CNY via the fiat rails — Alipay (支付宝, MoltsPay 2.0) and SDK-managed WeChat Pay sessions (微信支付, MoltsPay 2.1) — or password-free from a prepaid custodial balance (免密支付, MoltsPay 2.2).

## When to Use

- User asks to generate a video, image, or use any paid AI service
- User asks about wallet balance or payment history
- User wants to discover available services
- User mentions "pay", "buy", "purchase" + AI service
- User says they have paid ("已支付", "paid", "done") after a WeChat QR was shown
- User asks to top up, check, or spend a prepaid balance ("充值", "余额", "免密支付")

## Available Commands

| Command | Description |
|---------|-------------|
| `moltspay init` | Create wallet (works on all EVM chains + Solana) |
| `moltspay fund <amount>` | Fund wallet via QR code (debit card/Apple Pay) |
| `moltspay status` | Check balance on all chains |
| `moltspay config` | Modify spending limits |
| `moltspay services <url>` | List services from a provider or marketplace |
| `moltspay pay <url> <service> --chain <chain>` | Pay for a service |
| `moltspay wechat start <url> <service>` | Start a recoverable WeChat QR payment session |
| `moltspay wechat status <session-or-order>` | Query/recover a WeChat payment session |
| `moltspay wechat fulfill <session-or-order>` | Idempotently fulfill a paid WeChat session |
| `moltspay pay <url> <service> --rail balance` | Pay password-free from the prepaid balance |
| `moltspay balance query <url>` | Show custodial balance, limits, today's spend |
| `moltspay balance topup <url> <amount> --rail <rail>` | Credit the balance from a settled payment |
| `moltspay balance transactions <url>` | List balance ledger transactions |
| `moltspay balance set-buyer <id>` | Persist the buyer id used by `--rail balance` |

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

## Fiat & Balance Rails — Alipay, WeChat, Custodial Balance

In addition to the crypto chains above, MoltsPay adds **fiat rails** (pay in **CNY** via Alipay or WeChat Pay) and a **prepaid balance rail** (top up once, then password-free auto-deduct per purchase). No crypto balance or wallet is needed for any of them.

| Rail | `--rail` | Currency | Added | Notes |
|------|----------|----------|-------|-------|
| Alipay | `alipay` | CNY (yuan) | 2.0 | Autonomous: alipay-bot pays from the user's bound Alipay wallet |
| WeChat Pay | `wechat` | CNY (yuan) | 2.1 | **SDK-managed scan to pay**: a QR is shown, SDK session polls and fulfills after human scan |
| Balance | `balance` | provider currency | 2.2 | **Password-free (免密)**: prepaid custodial balance, auto-deducted per purchase — no signing, no QR |

- Select Alipay with `--rail alipay`. For WeChat in chat channels, prefer `moltspay wechat start/status/fulfill` over the blocking `moltspay pay --rail wechat` wrapper.
- A service exposes a CNY price only when its provider has that rail enabled; if a service is crypto-only, pay on a crypto chain instead.
- WeChat Pay requires a human scan, but payment lifecycle ownership belongs to the MoltsPay SDK client: it persists the session, polls, and fulfills the service.

### WeChat Pay flow (scan to pay)

For webchat, Discord, Feishu, or any channel where a tool call may time out, use the recoverable WeChat session flow:

```bash
moltspay wechat start <url> <service> --prompt "..."
moltspay wechat status <payment_session_id-or-out_trade_no>
moltspay wechat fulfill <payment_session_id-or-out_trade_no>
```

1. `wechat start` requests the service, receives the WeChat `code_url` from the server's 402, persists a `payment_session_id`, writes a PNG QR image, emits `MEDIA: <png-path>`, and exits immediately.
2. Send the `MEDIA` PNG to the user through the channel's media/image capability.
3. **The user opens WeChat and scans the QR to pay** — there is no autonomous WeChat wallet; a human must scan.
4. The SDK client polls by session id / `out_trade_no` until the order is paid, then fulfills the service idempotently.
5. If the process or channel times out, recover with `moltspay wechat status <payment_session_id-or-out_trade_no>` and `moltspay wechat fulfill <payment_session_id-or-out_trade_no>`.

`moltspay pay <url> <service> --rail wechat` still exists for local terminal use. It renders terminal ASCII QR, emits `MEDIA: <png-path>`, and blocks until paid or timed out. Do not use the blocking command as the primary path for chat integrations.

Present the QR to the user and tell them the amount in CNY and to scan with WeChat. If a caller bypasses the CLI and only has the WeChat Native `code_url`, generate a QR image from it before sending. Do not rely on terminal ASCII QR in chat UIs because line wrapping and font rendering can make it hard or impossible to scan. Do not treat the Native `code_url` as a normal HTTPS checkout link; use it as QR payload unless the provider explicitly returns a browser-safe payment URL.

### WeChat Pay session recovery rules

For chat integrations, treat WeChat Pay as a resumable state machine, not as a one-shot command.

**Always persist or recover these fields after `wechat start`:**

```json
{
  "channel": "discord|webchat|feishu",
  "userId": "<channel-user-id>",
  "serverUrl": "https://juai8.com/zen7",
  "serviceId": "ping",
  "rail": "wechat",
  "paymentSessionId": "<session-id>",
  "outTradeNo": "WX...",
  "qrPngPath": "/path/to/qr.png",
  "status": "pending",
  "createdAt": "ISO timestamp",
  "expiresAt": "ISO timestamp"
}
```

**When the user says "已支付", "paid", "done", or similar:**

1. Look up the current pending WeChat session for the same channel + user + conversation.
2. Run `moltspay wechat status <payment_session_id-or-out_trade_no>`.
3. If paid, run `moltspay wechat fulfill <payment_session_id-or-out_trade_no>` and return the service result.
4. If still pending, tell the user payment is not confirmed yet and keep polling or ask them to wait.
5. If expired/cancelled, start a new QR session only after telling the user the old QR can no longer be used.

Do **not** run `moltspay pay ... --rail wechat` or `moltspay wechat start ...` again merely because the user says "已支付". That creates a new WeChat order and loses the association with the QR the user already scanned.

If the bot process, exec tool, or channel session is killed after showing a QR, the next step is always `status`/`fulfill` on the saved session or `out_trade_no`, not a new `pay`.

### Balance rail (password-free / 免密支付, 2.2)

The balance rail is a **prepaid custodial balance held by the provider**: the user tops up once (settled via crypto, Alipay, or WeChat), then every purchase auto-deducts from that balance — no signing, no QR, no human interaction per transaction.

```bash
# One-time: persist the buyer id this client pays as
moltspay balance set-buyer <buyer-id>

# Check balance, per-tx/daily limits, and today's spend
moltspay balance query https://juai8.com/zen7

# Credit the balance from an externally settled payment
moltspay balance topup https://juai8.com/zen7 10 --rail alipay --trade-no <alipay-trade-no>
moltspay balance topup https://juai8.com/zen7 10 --rail wechat --out-trade-no <out-trade-no>
moltspay balance topup https://juai8.com/zen7 10 --rail crypto --tx-hash <hash> --chain base

# Pay password-free
moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --rail balance
```

Key behaviors to rely on:

- The deduction is **atomic and idempotent** on the client's `request_id` — a retried request never double-charges.
- If the service fails after deduction, the server **auto-refunds** the deduction; the response includes `refunded: true/false`.
- Deducts respect the account's per-transaction and daily limits; a limit or insufficient-balance failure comes back as a 402 with a reason code. On insufficient balance, offer the user a top-up (via Alipay/WeChat QR or crypto) rather than retrying.
- `balance query` shows whether an account exists; an account is created on first top-up.

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

Zen7 services are private provider services and may not appear in the public MoltsPay marketplace. If the user asks for "ping service" without a URL and the intent clearly refers to Zen7, use `https://juai8.com/zen7` as the provider URL or ask for the provider URL before searching the marketplace.

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

# Pay in CNY via WeChat in a chat/channel flow (fiat, scan the QR to pay)
moltspay wechat start https://juai8.com/zen7 text-to-video --prompt "a cat dancing"

# Local terminal-only blocking wrapper
moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --rail wechat

# Pay password-free from the prepaid custodial balance (免密支付)
moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --rail balance
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

If the user means the prepaid custodial balance (免密/余额), run `moltspay balance query <provider-url>` instead — crypto wallet balance and custodial balance are separate.

### "充值 / top up my balance"

1. Ask (or infer) how the top-up is settled: Alipay, WeChat, or crypto.
2. Collect the settlement reference: Alipay `trade_no`, WeChat `out_trade_no`, or the on-chain `tx-hash` + `--chain`.
3. Run `moltspay balance topup <provider-url> <amount> --rail <rail> ...` with the matching reference option.
4. Report the new balance. A replayed top-up (same reference) is safe — the server credits at most once.

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
| WeChat payment timed out | Check `moltspay wechat status <session-or-order>` first. If expired, start a fresh QR session (one code = one order) |
| User says paid but no result | Resume the saved WeChat session and run `status`, then `fulfill` if paid. Do not create a new order. |
| QR already shown but command died | Recover by session id or `out_trade_no`; never depend on the killed CLI process. |
| Balance rail not configured | Provider doesn't offer the balance rail. Pay via crypto or a fiat QR rail instead |
| Balance deduction failed (insufficient) | Show current balance (`moltspay balance query`) and offer a top-up |
| Balance deduction failed (limit) | Per-tx or daily limit hit on the custodial account; report the limit from `balance query` |
| Service failed after balance deduct | Check the response's `refunded` field; if `refunded: false`, tell the user manual reconciliation is needed |

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
