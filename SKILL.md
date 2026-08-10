---
name: moltspay-skill
description: Pay for AI services via the MoltsPay protocol — USDC/USDT on 5 crypto chains (gasless x402), CNY via Alipay and WeChat Pay, or password-free from a prepaid custodial balance. Use when the user asks to generate a video or image, buy or pay for any AI service, check a wallet or prepaid balance, or top up. Auto-discovers services from /.well-known/agent-services.json.
version: 2.4.1
metadata:
  openclaw:
    emoji: 💸
    homepage: https://moltspay.com/docs
    requires:
      bins: [node, npm]
    install:
      - kind: node
        package: moltspay@2.4.1
        bins: [moltspay]
---

# MoltsPay Client Skill

Pay for AI services using USDC/USDT across 5 crypto mainnets and 4 testnets (gasless), in CNY via the fiat rails — Alipay (支付宝, MoltsPay 2.0) and SDK-managed WeChat Pay sessions (微信支付, MoltsPay 2.1) — or password-free from a prepaid custodial balance (免密支付, MoltsPay 2.2). Since 2.3 the balance rail can be **funded by WeChat**: `pay --rail balance` scans one top-up pack when the balance is short, then every later purchase is password-free. Since 2.4 the balance rail is **authenticated**: the client signs every deduction with a local key, and the account is anchored to the WeChat payer who funded it — see "Balance identity & authentication".

## ⚠️ Setup — run this ONCE before any command below

Every command in this document is `./node_modules/.bin/moltspay`, executed **with
this skill's directory as the working directory**. Install first:

```bash
cd <the directory containing this SKILL.md>
npm ci --ignore-scripts --no-audit --no-fund
./node_modules/.bin/moltspay --version     # must print 2.4.1
```

**Never run a bare `moltspay`, and never `npx moltspay`.** Both resolve an
arbitrary version from `PATH` or the registry and bypass the version pinning this
skill depends on — a stale global install will silently answer with a client that
has none of the balance/2.4 commands. This skill holds wallet keys and the
balance-signing key, so which binary runs is part of its threat model.

If you cannot `cd`, use the absolute path `"$SKILL_DIR/node_modules/.bin/moltspay"`
instead. If a command fails with `./node_modules/.bin/moltspay: No such file or
directory`, you are in the wrong directory or the install above has not been run —
fix that; do not fall back to a bare `moltspay`.

`npm run setup` (`scripts/setup.js`) does the same install and additionally
initializes a wallet with the default $2/tx, $10/day limits.

**Alipay rail only:** `--ignore-scripts` skips the postinstall that fetches the
`alipay-bot` CLI from Alipay's CDN. Before first use of `--rail alipay`, run once:
`npx -y @alipay/agent-payment install-cli`. Crypto, WeChat Pay, and balance rails
need no extra step.

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
| `./node_modules/.bin/moltspay init` | Create wallet (works on all EVM chains + Solana) |
| `./node_modules/.bin/moltspay fund <amount>` | Fund wallet via QR code (debit card/Apple Pay) |
| `./node_modules/.bin/moltspay status` | Check balance on all chains |
| `./node_modules/.bin/moltspay transfer <to> <amount>` | Transfer USDC/USDT out to any address, e.g. an exchange (2.4) |
| `./node_modules/.bin/moltspay config` | Modify spending limits |
| `./node_modules/.bin/moltspay services <url>` | List services from a provider or marketplace |
| `./node_modules/.bin/moltspay pay <url> <service> --chain <chain>` | Pay for a service |
| `./node_modules/.bin/moltspay wechat start <url> <service>` | Start a recoverable WeChat QR payment session |
| `./node_modules/.bin/moltspay wechat status <session-or-order>` | Query/recover a WeChat payment session |
| `./node_modules/.bin/moltspay wechat fulfill <session-or-order>` | Idempotently fulfill a paid WeChat session |
| `./node_modules/.bin/moltspay pay <url> <service> --rail balance` | Pay password-free; auto-prompts a WeChat top-up pack QR if the balance is short (2.3) |
| `./node_modules/.bin/moltspay balance query <url>` | Show custodial balance, limits, today's spend |
| `./node_modules/.bin/moltspay balance topup-pack <url> --pack <amount>` | Fund the balance by scanning a WeChat top-up pack; blocks until paid (2.3) |
| `./node_modules/.bin/moltspay balance topup-order <url> [--pack]` | Create a top-up order, show the QR, and exit (non-blocking); confirm later (2.4) |
| `./node_modules/.bin/moltspay balance topup-confirm <out_trade_no>` | Confirm a top-up order once and credit if paid (2.4) |
| `./node_modules/.bin/moltspay balance topup <url> <amount> --rail <rail>` | Credit the balance from an already-settled payment (operator/recovery) |
| `./node_modules/.bin/moltspay balance transactions <url>` | List balance ledger transactions |
| `./node_modules/.bin/moltspay balance set-buyer <id>` | Persist the buyer id used by `--rail balance` |
| `./node_modules/.bin/moltspay balance whoami [url]` | Show this client's signer address, and its binding to the account (2.4) |
| `./node_modules/.bin/moltspay balance bind <url>` | Bind this client to the account via one WeChat top-up; **blocks until scanned** (2.4) |

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

### ⛔ Rail selection — READ THIS FIRST

**If the service offers the `balance` rail, you MUST pay with `--rail balance`. Nothing else.**

**WeChat is a way to LOAD the balance, not a way to buy things.** When the user says「微信支付」/ "pay with WeChat", they are telling you *how they want to put money in* — they are **not** asking you to mint a one-off QR for the item's price.

```
用户「买视频」/「微信支付」/「付款」
  → ./node_modules/.bin/moltspay pay <url> <service> --rail balance          （余额够 → 直接免密扣款，交付，结束）
  → 余额不足?
      → ./node_modules/.bin/moltspay balance topup-order <url>               （出【微信充值码】，退出本回合）
      → 用户扫码充值 → 说「已支付」
      → ./node_modules/.bin/moltspay balance topup-confirm <out_trade_no>    （到账）
      → ./node_modules/.bin/moltspay pay <url> <service> --rail balance      （免密扣款，交付）
  → 之后每一次购买：直接扣款，不再出任何码 ✅
```

**Never** reach for `--rail wechat` / `wechat start` / `--rail alipay` / `--rail crypto` when `balance` is on offer — that bypasses the whole password-free model and charges the user per item. Check what the service offers with `./node_modules/.bin/moltspay services <url>` (or the 402 `accepts[]`) if unsure.

The per-transaction rails below are **fallbacks only** — use them when the provider does **not** offer `balance` at all, or when the user explicitly refuses to top up.

| Rail | `--rail` | Currency | Notes |
|------|----------|----------|-------|
| **Balance** | `balance` | provider currency (CNY) | ✅ **DEFAULT — always prefer this.** Password-free (免密): prepaid custodial balance, auto-deducted per purchase. Funded by WeChat (scan once). Every deduction is signed by this client's key (2.4); the account is anchored to the WeChat payer's openid |
| WeChat Pay | `wechat` | CNY (yuan) | ⚠️ **Fallback only** — per-item scan-to-pay. Do NOT use when `balance` is available; the user ends up scanning for every single purchase |
| Alipay | `alipay` | CNY (yuan) | ⚠️ Fallback only — autonomous: alipay-bot pays from the user's bound Alipay wallet |
| Crypto | `crypto` | USDC/USDT | ⚠️ Fallback only — needs a funded crypto wallet |

- A service exposes a rail only when its provider has it enabled; if `balance` is absent from the 402, fall back per the table above.
- WeChat Pay requires a human scan, but payment lifecycle ownership belongs to the MoltsPay SDK client: it persists the session, polls, and fulfills the service.

### WeChat Pay flow (scan to pay) — ⚠️ FALLBACK RAIL, NOT THE DEFAULT

> **Do not use this section when the provider offers the `balance` rail.** This is the per-item flow: one QR, one purchase, every time. If `balance` is on offer, the user should scan **once to top up** and then buy password-free — see "Rail selection" above. A user saying「微信支付」is asking for that, not for this.
>
> Use this only when the provider has **no** balance rail, or the user explicitly refuses to top up.

For webchat, Discord, Feishu, or any channel where a tool call may time out, use the recoverable WeChat session flow:

```bash
./node_modules/.bin/moltspay wechat start <url> <service> --prompt "..."
./node_modules/.bin/moltspay wechat status <payment_session_id-or-out_trade_no>
./node_modules/.bin/moltspay wechat fulfill <payment_session_id-or-out_trade_no>
```

1. `wechat start` requests the service, receives the WeChat `code_url` from the server's 402, persists a `payment_session_id`, writes a PNG QR image, emits `MEDIA: <png-path>`, and exits immediately.
2. Send the `MEDIA` PNG to the user through the channel's media/image capability.
3. **The user opens WeChat and scans the QR to pay** — there is no autonomous WeChat wallet; a human must scan.
4. The SDK client polls by session id / `out_trade_no` until the order is paid, then fulfills the service idempotently.
5. If the process or channel times out, recover with `./node_modules/.bin/moltspay wechat status <payment_session_id-or-out_trade_no>` and `./node_modules/.bin/moltspay wechat fulfill <payment_session_id-or-out_trade_no>`.

`./node_modules/.bin/moltspay pay <url> <service> --rail wechat` still exists for local terminal use. It renders terminal ASCII QR, emits `MEDIA: <png-path>`, and blocks until paid or timed out. Do not use the blocking command as the primary path for chat integrations.

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
2. Run `./node_modules/.bin/moltspay wechat status <payment_session_id-or-out_trade_no>`.
3. If paid, run `./node_modules/.bin/moltspay wechat fulfill <payment_session_id-or-out_trade_no>` and return the service result.
4. If still pending, tell the user payment is not confirmed yet and keep polling or ask them to wait.
5. If expired/cancelled, start a new QR session only after telling the user the old QR can no longer be used.

Do **not** run `./node_modules/.bin/moltspay pay ... --rail wechat` or `./node_modules/.bin/moltspay wechat start ...` again merely because the user says "已支付". That creates a new WeChat order and loses the association with the QR the user already scanned.

If the bot process, exec tool, or channel session is killed after showing a QR, the next step is always `status`/`fulfill` on the saved session or `out_trade_no`, not a new `pay`.

### Balance rail (password-free / 免密支付, 2.2 + 2.3)

The balance rail is a **prepaid custodial balance held by the provider**. Once funded, every purchase auto-deducts from it — no signing, no QR, no human interaction per transaction. **The model is "scan once to fund, then password-free"**: WeChat only tops up the balance; the balance does the spending.

```bash
# One-time: persist the buyer id this client pays as
./node_modules/.bin/moltspay balance set-buyer <buyer-id>

# Check balance, per-tx/daily limits, and today's spend
./node_modules/.bin/moltspay balance query https://juai8.com/zen7

# Pay password-free. If the balance is short, this auto-prompts a WeChat
# top-up pack QR (emits MEDIA: <png>), waits for the scan, credits, and
# completes the purchase automatically. --pack picks the pack; --no-auto-topup
# fails instead of prompting.
./node_modules/.bin/moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --rail balance
./node_modules/.bin/moltspay pay https://juai8.com/zen7 text-to-video --prompt "..." --rail balance --pack 20

# Fund the balance up front by scanning a WeChat top-up pack (create + confirm).
./node_modules/.bin/moltspay balance topup-pack https://juai8.com/zen7 --pack 20
```

**2.3 auto top-up (the primary funding path):** when a `pay --rail balance` finds an insufficient balance, the SDK creates a buyer-bound WeChat pack order, shows the QR, and credits the **gateway-verified amount** after the user scans — the client never declares the amount. The ledger is 1:1 with WeChat (fen), so a `20.00` pack credits `20.00 CNY`.

Operator/recovery funding (an already-settled payment; not the primary path):

```bash
./node_modules/.bin/moltspay balance topup https://juai8.com/zen7 20 --rail wechat --out-trade-no <out-trade-no>
./node_modules/.bin/moltspay balance topup https://juai8.com/zen7 10 --rail crypto --tx-hash <hash> --chain base
```

Key behaviors to rely on:

- The deduction is **atomic and idempotent** on the client's `request_id` — a retried request never double-charges.
- If the service fails after deduction, the server **auto-refunds** the deduction; the response includes `refunded: true/false`.
- Deducts respect per-transaction and daily limits. An **insufficient balance or brand-new account** triggers the 2.3 auto top-up (unless `--no-auto-topup`); a **limit** failure does not (topping up would not help) — report the limit instead.
- Top-up credits the WeChat-verified `payer_total`, idempotent on `out_trade_no`; a replayed confirm credits at most once.
- `balance query` shows whether an account exists; an account is created on first top-up.

> **Chat channels (webchat/Discord/Feishu):** the blocking auto top-up (`pay --rail balance` default, and `topup-pack`, and `balance bind`) waits up to ~5 min for the human scan, so a turn-based agent should NOT use it — the tool call times out. Use the **recoverable flow** below instead.

### Balance identity & authentication (2.4)

Before 2.4 the `buyer_id` was a bare string: anyone who knew it could spend that balance, and one user writing it two ways became two accounts. 2.4 fixes both. **You mostly do not have to do anything — it is automatic** — but you must understand it to read errors correctly.

**Two halves:**

- **Who the account belongs to = the WeChat payer.** When a top-up is paid, the server reads the payer's `openid` from WeChat and anchors the account to that person. Identity comes from who actually paid, not from the string you passed.
- **Who may spend it = whoever holds this client's signing key.** The SDK signs every deduction with a key stored at `<configDir>/balance-identity.key` (auto-created, `0600`). The server binds that signer to the account on first use (trust-on-first-use) and checks it on every later deduction. **Signing is automatic — `pay --rail balance` already does it.**

```bash
# Who am I, and am I bound to this account?
./node_modules/.bin/moltspay balance whoami https://provider.com
#   -> signer address, the account's bound signer, its WeChat openid

# Bind explicitly by funding once (BLOCKS on the scan — terminal only, never in a chat turn).
# In a chat channel, just use the recoverable topup-order/topup-confirm flow below:
# it binds on the same top-up, without blocking.
./node_modules/.bin/moltspay balance bind https://provider.com --pack 20
```

**Rules:**

- **The key is the money.** Anyone holding `<configDir>/balance-identity.key` can spend every account this client is bound to. Never print it, copy it into a channel, or commit it. Losing it means losing access to the balance (the account is still the user's — re-binding requires the server operator or a fresh account).
- **One agent, one key, many users.** A shared agent uses a *single* key for all the users it tops up. Accounts stay separate (by openid), but the agent's key can spend all of them — this is the deliberate trade-off of an agent paying on users' behalf, not a bug.
- Do **not** try to "fix" an auth failure by switching `--buyer` to another id or running `set-buyer`. That does not authenticate you; it just points at a different account (and re-creates the account-splitting problem 2.4 exists to solve). See the error table.
- A server may run auth in `off` / `shadow` / `enforce` mode. Under `enforce`, an unsigned or wrongly-signed deduction is rejected with **401** — an old, un-upgraded client will fail here and must be upgraded, not worked around.

### Balance top-up in a chat channel (recoverable, 2.4)

Mirror the WeChat `start/status/fulfill` pattern. Never block a turn waiting for a scan, and never re-issue a fresh order just because the user says they paid.

```bash
# 1. Create the order, show the QR, and EXIT immediately (non-blocking).
#    Or: ./node_modules/.bin/moltspay pay <url> <svc> --rail balance --topup-mode manual  (same result)
./node_modules/.bin/moltspay balance topup-order https://provider.com --buyer <id>
#    -> emits MEDIA: <png> and an out_trade_no; persists a recoverable session.

# 2. [end the turn] Send the QR to the user as an image (Discord attachment /
#    channel media). Tell them to scan with WeChat, then say "已支付" / "paid".

# 3. When the user says paid, confirm ONCE by out_trade_no (server_url is
#    recovered from the session):
./node_modules/.bin/moltspay balance topup-confirm <out_trade_no>
#    credited -> continue;  pending -> tell the user it is not confirmed yet, wait.

# 4. Once credited, complete the purchase password-free (no new QR):
./node_modules/.bin/moltspay pay https://provider.com <service> --rail balance --buyer <id>
```

Rules:
- On the "已支付"/"paid" signal, run `topup-confirm <out_trade_no>` (recover the order id from your memory or `balance topup-list`). **Do NOT run `topup-order` / `pay` again** — that mints a new QR and loses the association, exactly like the WeChat rail.
- Render the QR as an **image attachment** (Discord supports this natively); send the `MEDIA:` PNG, do not treat `code_url` as a browser link, do not rely on terminal ASCII QR.
- `topup-confirm` is idempotent; a replay after crediting is safe.
- `--topup-mode manual` on `pay` returns `{ status: "topup_required", out_trade_no, code_url, ... }` instead of blocking, so a single `pay` call gives you the QR + order id to confirm later.

For a plain terminal (not an agent), the blocking `pay --rail balance` / `topup-pack` are fine.

## Wallet Setup

`./node_modules/.bin/moltspay init` creates wallets for all chains:

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
./node_modules/.bin/moltspay services https://moltspay.com
```

### Single Provider Discovery

List services from a specific provider:
```
./node_modules/.bin/moltspay services https://juai8.com/zen7
```

Shows provider name, wallet, supported chains, and all services with prices.

Zen7 services are private provider services and may not appear in the public MoltsPay marketplace. If the user asks for "ping service" without a URL and the intent clearly refers to Zen7, use `https://juai8.com/zen7` as the provider URL or ask for the provider URL before searching the marketplace.

**Present results as a table to users:**

| Service | Price | Chains |
|---------|-------|--------|
| text-to-video | $0.99 USDC | Base, Polygon, BNB |
| image-to-video | $1.49 USDC | Base, Polygon, BNB |

Never show raw JSON to users - always format nicely.

## Rail & Chain Selection (Pay Only)

**First: if the service offers `balance`, use `--rail balance`.** See "Rail selection — READ THIS FIRST" above. The examples below cover the fallback rails (provider does not offer `balance`, or the user refuses to top up).

When paying on a crypto chain:
- If server accepts only one chain → auto-selected
- If server accepts multiple chains → specify with `--chain`

```bash
# ✅ DEFAULT — password-free from the prepaid balance. Auto-prompts a WeChat
#    top-up pack QR if the balance is short (in a chat channel use the
#    non-blocking topup-order/topup-confirm flow instead).
./node_modules/.bin/moltspay pay https://juai8.com/zen7 buy-video --rail balance

# --- Fallbacks: only when the provider does NOT offer the balance rail ---

# Pay on Base (recommended crypto chain)
./node_modules/.bin/moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --chain base

# Pay on Polygon / BNB / Solana
./node_modules/.bin/moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --chain polygon
./node_modules/.bin/moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --chain bnb
./node_modules/.bin/moltspay pay https://example.com/service image-gen --prompt "sunset" --chain solana

# Pay in CNY via Alipay (autonomous, no scan)
./node_modules/.bin/moltspay pay https://example.com/service text-to-video --prompt "a cat dancing" --rail alipay

# Per-item WeChat scan-to-pay. ⚠️ NOT for a provider that offers `balance` --
# it charges the user a fresh QR for every single purchase.
./node_modules/.bin/moltspay wechat start https://juai8.com/zen7 text-to-video --prompt "a cat dancing"

# Pay password-free from the prepaid custodial balance (免密支付).
# Auto-prompts a WeChat top-up pack QR if the balance is short (2.3).
./node_modules/.bin/moltspay pay https://juai8.com/zen7 text-to-video --prompt "a cat dancing" --rail balance

# Fund the balance up front by scanning a WeChat pack (2.3)
./node_modules/.bin/moltspay balance topup-pack https://juai8.com/zen7 --pack 20
```

## Paying for Services

Use the `./node_modules/.bin/moltspay pay` command with the provider URL and service ID.

**Parameters vary by service:**
- `--prompt` for text-based services
- `--image` for image-based services
- `--chain` to specify which chain to pay on
- `--token` to specify token (USDC or USDT, default USDC)

Example: Zen7 video generation
```
./node_modules/.bin/moltspay pay https://juai8.com/zen7 text-to-video --prompt "sunset over ocean" --chain base
```

## Spending Limits

Users can configure:
- **max-per-tx**: Maximum per transaction (default $2)
- **max-per-day**: Daily spending limit (default $10)

Use `./node_modules/.bin/moltspay config` to modify limits.

## Funding Your Wallet

### Option 1: QR Code (Easiest - No crypto needed!)

```bash
# Fund $10 on Base (recommended)
./node_modules/.bin/moltspay fund 10

# Fund $20 on Polygon  
./node_modules/.bin/moltspay fund 20 --chain polygon

# Fund $10 on Solana
./node_modules/.bin/moltspay fund 10 --chain solana
```

Scan QR code → pay with US debit card or Apple Pay → tokens arrive in ~2 minutes.

**No CDP credentials or crypto knowledge needed.** Server handles everything.

### Option 2: Direct Transfer

**EVM Chains** - Same address works on Base, Polygon, BNB, opBNB:
- Send USDC from Coinbase, MetaMask, etc.
- Make sure you're on the correct network!

**Solana** - Different address:
- Send USDC to your Solana wallet address
- Check with `./node_modules/.bin/moltspay status`

⚠️ **Important:**
- Balance on Base ≠ Balance on Polygon ≠ Balance on Solana (separate!)
- Check balance per chain with `./node_modules/.bin/moltspay status`
- No ETH/MATIC/SOL needed for gas (gasless transactions via x402)
- Exception: BNB needs tiny amount of BNB for first approval (~$0.0001)

## Common User Requests

### "Buy a video" / "Generate a video of X" / "微信支付"

**All of these mean the same thing: pay from the balance.** The user naming WeChat is telling you how they want to *fund* it, not asking for a per-item QR.

1. `./node_modules/.bin/moltspay pay <url> <service> --rail balance` (add `--prompt` for generation services)
2. **Funded** → it deducts password-free and returns the result. Deliver it. Done.
3. **Short on balance** (in a chat channel — never block a turn):
   - `./node_modules/.bin/moltspay balance topup-order <url>` → send the `MEDIA:` QR as an image, end the turn, tell the user to scan it with WeChat and say「已支付」
   - On「已支付」→ `./node_modules/.bin/moltspay balance topup-confirm <out_trade_no>` (the SAME order — never mint a new QR)
   - Credited → rerun step 1. It now completes with no QR.
4. Return the video URL to the user.

Only if the provider does **not** offer the balance rail: fall back per "Rail selection" above (crypto chain / Alipay / per-item WeChat).

### "What's my balance?"

Run `./node_modules/.bin/moltspay status` and report:
- Wallet addresses (EVM + Solana)
- Balance on each chain
- Spending limits
- Today's usage

If the user means the prepaid custodial balance (免密/余额), run `./node_modules/.bin/moltspay balance query <provider-url>` instead — crypto wallet balance and custodial balance are separate.

### "充值 / top up my balance"

**In a chat channel (you are an agent): use the recoverable flow** — `balance topup-order` to show the QR and exit, then `balance topup-confirm <out_trade_no>` when the user says paid. See "Balance top-up in a chat channel (recoverable, 2.4)" above. Do NOT use the blocking `topup-pack` or `balance bind` in a chat turn.

At a plain terminal (2.3): scan a WeChat top-up pack.

1. Run `./node_modules/.bin/moltspay balance topup-pack <provider-url> --pack <amount>`.
2. Send the emitted `MEDIA:` QR PNG to the user and ask them to scan it with WeChat.
3. The command creates the order, waits for the scan, credits the WeChat-verified amount, and reports the new balance.
4. Or just run `./node_modules/.bin/moltspay pay <url> <service> --rail balance` directly — it auto-prompts the same pack QR when the balance is short.

Operator/recovery (an already-settled payment):

- Collect the settlement reference (WeChat `out_trade_no`, Alipay `trade_no`, or on-chain `tx-hash` + `--chain`) and run `./node_modules/.bin/moltspay balance topup <provider-url> <amount> --rail <rail> ...`. A replayed top-up (same reference) is safe — the server credits at most once.

### "提现 / transfer / withdraw USDC to Binance (or any exchange/address)" (2.4)

Use `./node_modules/.bin/moltspay transfer` — it moves USDC/USDT out of the wallet to any address.

1. Get the user's **deposit address** from the exchange, and **which network** the exchange expects for USDC/USDT (Base, Polygon, BNB, …).
2. Run `./node_modules/.bin/moltspay transfer <deposit-address> <amount> --token USDC --chain <matching-network>` (add `--yes` to skip the prompt for automated flows).
3. Report the returned tx hash + explorer URL.

Critical rules to tell the user:
- **Network must match.** The `--chain` you send on must equal the network the exchange shows for that deposit address — sending USDC on Base to a BSC/BEP20 address loses the funds.
- **Gas is required.** Unlike paying for services (gasless x402), `transfer` is a normal on-chain transfer, so the wallet needs a little native gas: ETH on Base, BNB on BNB Chain, POL on Polygon. If there's no gas, it fails.
- **EVM only.** Solana `transfer` isn't supported yet; for Solana funds use a Solana wallet.
- Suggest a **small test amount first**, confirm it lands, then send the rest.

### "What services are available?"

Run `./node_modules/.bin/moltspay services https://moltspay.com` to list marketplace.
Format results as a clean table with service names, prices, and providers.

## Error Handling

| Error | Solution |
|-------|----------|
| Insufficient balance | Fund wallet with USDC on the chain you want to use |
| Exceeds daily limit | Wait until tomorrow, or increase limit with `./node_modules/.bin/moltspay config` |
| Exceeds per-tx limit | Increase limit with `./node_modules/.bin/moltspay config` |
| Service not found | Verify service URL and ID |
| Chain mismatch | Server doesn't accept specified chain. Check supported chains. |
| Multi-chain required | Server accepts multiple chains. Specify `--chain` |
| BNB approval needed | First BNB payment needs tiny gas (~$0.0001 BNB) |
| Alipay not accepted | Service is crypto-only. Pay on a crypto chain instead |
| WeChat not accepted | Service doesn't offer the WeChat rail. Use `--rail alipay` or a crypto chain |
| WeChat payment timed out | Check `./node_modules/.bin/moltspay wechat status <session-or-order>` first. If expired, start a fresh QR session (one code = one order) |
| User says paid but no result | Resume the saved WeChat session and run `status`, then `fulfill` if paid. Do not create a new order. |
| QR already shown but command died | Recover by session id or `out_trade_no`; never depend on the killed CLI process. |
| Balance rail not configured | Provider doesn't offer the balance rail. Pay via crypto or a fiat QR rail instead |
| Balance deduction failed (insufficient) | 2.3: `pay --rail balance` auto-prompts a WeChat top-up pack QR — show the `MEDIA:` PNG and let it complete. Or pre-fund with `balance topup-pack` |
| Balance deduction failed (limit) | Per-tx or daily limit hit on the custodial account; report the limit from `balance query` |
| Service failed after balance deduct | Check the response's `refunded` field; if `refunded: false`, tell the user manual reconciliation is needed |
| Balance deduct rejected **401 / unauthorized** (2.4) | This client is not the account's bound signer. Run `balance whoami <url>`: if it says **bound to a DIFFERENT signer**, you are trying to spend someone else's account — stop, do not switch `--buyer` to dodge it. If the client is old/unsigned, it must be upgraded to 2.4. Never "solve" this by picking another buyer id |
| `whoami` shows no bound signer | The account has never been spent from by a signed client. It binds automatically on the next top-up or first signed deduction — just proceed |

## Testnet Faucets

For testing without real money:

```bash
# Get 1 USDC on Base Sepolia
./node_modules/.bin/moltspay faucet --chain base_sepolia

# Get 1 USDC on BNB Testnet (+ 0.001 tBNB for gas)
./node_modules/.bin/moltspay faucet --chain bnb_testnet

# Get 1 USDC on Solana Devnet
./node_modules/.bin/moltspay faucet --chain solana_devnet
```

Limit: 1 USDC per address per 24 hours.

## Links

- Docs: https://moltspay.com/docs
- Marketplace: https://moltspay.com/services
- GitHub: https://github.com/Yaqing2023/moltspay-skill
