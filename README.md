# MoltsPay Client Skill

Let your AI agent pay for AI services — in **crypto across 8 chains** or in **CNY via Alipay and WeChat Pay**. Gasless on crypto, no crypto balance needed for fiat rails.

## Features

- 🔐 **One wallet, all chains** — same EVM address across Base, Polygon, BNB, opBNB, Tempo; separate Solana keypair
- 💸 **Pay in crypto** with USDC/USDT (gasless via x402)
- 🇨🇳 **Pay in fiat** — CNY via Alipay (支付宝) or WeChat Pay (微信支付)
- 🔍 **Discover services** from marketplace or individual providers
- 🛡️ **Spending limits** built-in ($2/tx, $10/day default)

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
| WeChat Pay (微信支付) | `wechat` | CNY | Scan-to-pay QR flow; user scans with WeChat |

## Example Services

| Service | Price | Command |
|---------|-------|---------|
| Zen7 Text-to-Video | $0.99 | `npx moltspay pay https://juai8.com/zen7 text-to-video --prompt "..." --chain base` |
| Zen7 Image-to-Video | $1.49 | `npx moltspay pay https://juai8.com/zen7 image-to-video --image /path/to/img --chain base` |
| Zen7 Text-to-Video via WeChat | ¥7.00 | `npx moltspay pay https://juai8.com/zen7 text-to-video --prompt "..." --rail wechat` |

## Discover Services

List all services on marketplace:
```bash
npx moltspay services https://moltspay.com
```

List services from a specific provider:
```bash
npx moltspay services https://juai8.com/zen7
```

## Funding Your Wallet

1. Get your address: `npx moltspay status`
2. Send USDC on the chain you want to use (Base, Polygon, BNB, opBNB, Solana) to that address
3. No native gas token needed (gasless transactions via x402)

⚠️ Balance on each chain is separate — fund the chain you want to use!

Paying in CNY via Alipay or WeChat Pay needs no crypto balance. For WeChat Pay, MoltsPay shows a QR code and waits for the user to scan and pay in WeChat.

### WeChat Pay in Chat UIs

The WeChat Pay rail uses a Native `code_url` QR payload. In a CLI terminal, MoltsPay renders this as an ASCII QR code and also emits a generated PNG image path as `MEDIA: <png-path>`.

For webchat, Discord, Feishu, or other chat UIs, capture the `MEDIA: <png-path>` line and send that PNG through the channel's media/image capability. If you are not using the CLI and only have the `code_url`, generate a QR image from it before sending. Do not rely on terminal ASCII QR in chat messages because wrapping and font rendering can make it hard or impossible to scan. Do not treat the Native `code_url` as a normal HTTPS checkout link unless the provider explicitly returns a browser-safe payment URL.

## Links

- [MoltsPay Docs](https://moltspay.com/docs)
- [Browse Services](https://moltspay.com/services)
- [Discord Support](https://discord.gg/QwCJgVBxVK)

## License

MIT
