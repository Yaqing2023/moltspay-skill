# MoltsPay Client Skill

Let your OpenClaw agent pay for AI services using USDC on Base chain.

## Features

- 🔐 **Auto-init wallet** on first use
- 💸 **Pay for services** with USDC (gasless)
- 🔍 **Discover services** via x402 protocol
- 🛡️ **Spending limits** built-in ($2/tx, $10/day default)

## Quick Start

After installing, your agent can:

1. **Generate videos:**
   > "Generate a video of a cat dancing"
   
2. **Check balance:**
   > "What's my wallet balance?"

3. **Discover services:**
   > "What services can I pay for?"

## Example Services

| Service | Price | Command |
|---------|-------|---------|
| Zen7 Text-to-Video | $0.99 | `npx moltspay pay https://juai8.com/zen7 text-to-video --prompt "..."` |
| Zen7 Image-to-Video | $1.49 | `npx moltspay pay https://juai8.com/zen7 image-to-video --image /path/to/img` |

## Funding Your Wallet

1. Get your address: `npx moltspay status`
2. Send USDC on **Base chain** to that address
3. No ETH needed (gasless transactions)

## Find Services

Just ask your agent:
> "What AI services can I pay for?"
> "Find video generation services"

The agent will search moltspay.com automatically and show you results.

## Links

- [MoltsPay Docs](https://moltspay.com/docs)
- [Browse Services](https://moltspay.com/services)
- [Discord Support](https://discord.gg/QwCJgVBxVK)

## License

MIT
