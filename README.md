# SA Summit 2026 — Exercise Setup

Three commands set you up for the Machine Payments Protocol (MPP) exercises. They save your Stripe sandbox credentials to a secured env file, configure the Stripe Directory CLI profile, and register the `summit-booking-demo` MCP server with Claude Code.

## Prerequisite

Link CLI requires a passkey on your Link account. Add one at [app.link.com/settings](https://app.link.com/settings) → **Passkeys** before summit day.

## Setup

Run these three commands in order:

```bash
# 1. Get the setup script
git clone https://github.com/dansmith-stripe/sa-summit-26-setup.git
```

```bash
# 2. Run setup (you'll be prompted for 3 values)
bash sa-summit-26-setup/setup.sh
```

```bash
# 3. Activate credentials in this terminal
source ~/.machine-payments-summit.env
```

You'll be prompted for three values:

| Prompt | Where to find it |
|--------|-----------------|
| **Stripe LDAP handle** | Your lowercase Stripe handle (e.g. `jdoe`) |
| **Stripe Profile ID** | Dashboard → Settings → Profile → Network ID. Starts with `profile_` |
| **Stripe secret key** | Dashboard → Developers → API keys, test mode. Starts with `sk_test_` |

The script will:
- Save credentials to `~/.machine-payments-summit.env` (chmod 600)
- Add a `summit-directory` Stripe CLI profile for live-mode Directory lookups
- Register `summit-booking-demo` as an MCP server with Claude Code
- Add auto-source to `~/.zshrc` so credentials load in all future terminals

## Launch Claude

After step 3, verify and launch in the same terminal:

```bash
claude mcp list   # confirm summit-booking-demo shows ✔ Connected
claude
```

## Scripts

- `setup.sh` — interactive setup, run once before summit day
- `reset.sh` — removes everything setup.sh created (for re-testing)
