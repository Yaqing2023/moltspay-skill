# MoltsPay Client Skill

Let your AI agent pay for AI services — in **crypto across 8 chains**, in **CNY via Alipay and WeChat Pay**, or **password-free from a prepaid custodial balance**. Gasless on crypto, no crypto balance needed for fiat rails.

## Features

- 🔐 **One wallet, all chains** — same EVM address across Base, Polygon, BNB, opBNB, Tempo; separate Solana keypair
- 💸 **Pay in crypto** with USDC/USDT (gasless via x402)
- 🇨🇳 **Pay in fiat** — CNY via Alipay (支付宝) or SDK-managed WeChat Pay sessions (微信支付)
- ⚡ **Pay password-free** (免密支付) — top up a custodial balance once, purchases auto-deduct with no signing or QR
- 🔍 **Discover services** from marketplace or individual providers
- 🛡️ **Spending limits** built-in ($2/tx, $10/day default)

## Installation

Install MoltsPay **inside the skill directory**, pinned to an exact version, and
invoke its local binary. Do not install it globally — this skill handles wallet
keys and balance-signing keys, so the install step is part of its threat model.

```bash
npm ci --prefix "$SKILL_DIR" --ignore-scripts --no-audit --no-fund
"$SKILL_DIR/node_modules/.bin/moltspay" status
```

This relies on `package.json` pinning `"moltspay": "2.4.1"` (exact — not
`^2.4.1`, not `latest`) and on `package-lock.json` being committed, which is
what lets `npm ci` verify package integrity.

Why each part matters:

| Control | Purpose |
|---------|---------|
| Exact version + committed lockfile | You are never auto-upgraded into a compromised release |
| `npm ci` | Verifies integrity hashes against the lockfile |
| `--ignore-scripts` | Blocks install-time code execution across the whole dependency tree |
| Local install, explicit path | Contains blast radius; avoids trusting whatever `moltspay` happens to be on `PATH` |

### Alipay rail: one-time manual step

`--ignore-scripts` also skips MoltsPay's own postinstall, which normally
downloads the `alipay-bot` CLI from Alipay's CDN. Crypto, WeChat Pay, and
balance rails are unaffected. Before using the **Alipay** rail, run once:

```bash
npx -y @alipay/agent-payment install-cli
```

This is deliberate: `alipay-bot` is distributed outside npm, so no lockfile
hash covers it. Making the download an explicit step keeps it visible rather
than hidden inside `npm install`. If you skip it, nothing fails silently — the
runtime `ensureCli` gate stops the Alipay rail at first use and repeats this
command.

For the full threat model, see
[`docs/SECURITY.md`](https://github.com/Yaqing2023/moltspay/blob/v2.4.1/docs/SECURITY.md)
in the MoltsPay SDK repo (issue 8).

> Examples below assume the skill directory is your working directory. From
> anywhere else, use the absolute path `"$SKILL_DIR/node_modules/.bin/moltspay"`.
> Do not substitute `npx moltspay` — that resolves an unpinned version from the
> registry and bypasses every control in this section.

## Quick Start

After installing, your agent can:

1. **Generate videos:**
   > "Generate a video of a cat dancing"
   
2. **Check balance:**
   > "What's my wallet balance?"

3. **Discover services:**
   > "What services can I pay for?"

## Supported Rails

**Crypto (USDC/USDT, gasless):**

| Chain | ID | Tokens | Notes |
|-------|-----|--------|-------|
| Base | `base` | USDC, USDT | Recommended, lowest fees |
| Polygon | `polygon` | USDC | Alternative EVM |
| BNB Chain | `bnb` | USDC, USDT | High liquidity |
| opBNB | `opbnb` | USDC | BNB L2, very low fees |
| Solana | `solana` | USDC | Fast, separate wallet |
| Tempo | `tempo_moderato` | pathUSD | Testnet |

Plus testnets: `base_sepolia`, `bnb_testnet`, `solana_devnet`.

**Fiat (CNY):**

| Rail | ID | Currency | Notes |
|------|-----|----------|-------|
| Alipay (支付宝) | `alipay` | CNY | Pay services priced in CNY; settled via the Alipay rail |
| WeChat Pay (微信支付) | `wechat` | CNY | SDK-managed scan-to-pay QR session; user scans with WeChat |

**Prepaid balance (password-free / 免密):**

| Rail | ID | Notes |
|------|-----|-------|
| Custodial balance | `balance` | Scan once to fund, then purchases auto-deduct — no signing or QR per transaction. 2.3: `pay --rail balance` auto-funds via a WeChat top-up pack when short. 2.4: the account is anchored to the WeChat payer's openid and every deduction is signed by this client's key. Idempotent deducts, auto-refund on service failure. |

```bash
./node_modules/.bin/moltspay balance query https://juai8.com/zen7                      # balance, limits, today's spend
./node_modules/.bin/moltspay balance topup-pack https://juai8.com/zen7 --pack 20       # fund by scanning a WeChat pack (2.3)
./node_modules/.bin/moltspay pay https://juai8.com/zen7 text-to-video --prompt "..." --rail balance   # auto-tops-up if short
./node_modules/.bin/moltspay balance whoami https://juai8.com/zen7                     # signer identity + account binding (2.4)
```

> **The balance key is the money (2.4).** The client signs each deduction with a key at `<configDir>/balance-identity.key` (auto-created, `0600`). Whoever holds it can spend every account this client is bound to — protect it like a private key. Under a server running `auth_mode: enforce`, an unsigned or wrongly-signed deduction is rejected with 401.

## Example Services

| Service | Price | Command |
|---------|-------|---------|
| Zen7 Text-to-Video | $0.99 | `./node_modules/.bin/moltspay pay https://juai8.com/zen7 text-to-video --prompt "..." --chain base` |
| Zen7 Image-to-Video | $1.49 | `./node_modules/.bin/moltspay pay https://juai8.com/zen7 image-to-video --image /path/to/img --chain base` |
| Zen7 Text-to-Video via WeChat | ¥7.00 | `./node_modules/.bin/moltspay wechat start https://juai8.com/zen7 text-to-video --prompt "..."` |

## Discover Services

List all services on marketplace:
```bash
./node_modules/.bin/moltspay services https://moltspay.com
```

List services from a specific provider:
```bash
./node_modules/.bin/moltspay services https://juai8.com/zen7
```

## Funding Your Wallet

1. Get your address: `./node_modules/.bin/moltspay status`
2. Send USDC on the chain you want to use (Base, Polygon, BNB, opBNB, Solana) to that address
3. No native gas token needed (gasless transactions via x402)

⚠️ Balance on each chain is separate — fund the chain you want to use!

Paying in CNY via Alipay or WeChat Pay needs no crypto balance. For WeChat Pay, MoltsPay creates a recoverable payment session, returns a QR image, polls payment status from the SDK client, and fulfills the service after the user scans and pays in WeChat. The custodial balance rail needs no interaction at all once topped up — purchases auto-deduct.

### WeChat Pay in Chat UIs

The WeChat Pay rail uses a Native `code_url` QR payload. For chat UIs, prefer the recoverable session commands:

```bash
./node_modules/.bin/moltspay wechat start https://juai8.com/zen7 text-to-video --prompt "..."
./node_modules/.bin/moltspay wechat status <payment_session_id-or-out_trade_no>
./node_modules/.bin/moltspay wechat fulfill <payment_session_id-or-out_trade_no>
```

`moltspay wechat start` creates and persists a SDK-managed payment session under the MoltsPay config directory, writes a PNG QR image, emits `MEDIA: <png-path>`, and exits immediately. The channel should send that PNG to the user. The SDK/client can then poll and fulfill by `payment_session_id` or `out_trade_no`, so the flow can recover after exec timeout, channel restart, or process restart.

`moltspay pay ... --rail wechat` still exists for local terminal use. It renders ASCII QR, emits `MEDIA: <png-path>`, and blocks until paid or timed out. Do not use that blocking command as the primary integration path for Discord, webchat, Feishu, or other chat channels.

If you are not using the CLI and only have the WeChat Native `code_url`, generate a QR image from it before sending. Do not rely on terminal ASCII QR in chat messages because wrapping and font rendering can make it hard or impossible to scan. Do not treat the Native `code_url` as a normal HTTPS checkout link unless the provider explicitly returns a browser-safe payment URL.

## Links

- [MoltsPay Docs](https://moltspay.com/docs)
- [Browse Services](https://moltspay.com/services)
- [Discord Support](https://discord.gg/QwCJgVBxVK)

## License

MIT
