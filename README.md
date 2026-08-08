SA Summit 2026 — Exercise Setup

One command sets you up for the Machine Payments Protocol (MPP) exercises. It saves your Stripe sandbox credentials to a secured env file, sets the Stripe Directory API key, and registers the summit-booking-demo MCP server with Claude Code.

Prerequisite
Link CLI requires a passkey on your Link account. Add one at app.link.com/settings → Passkeys before summit day.

Setup

bash <(curl -fsSL https://raw.githubusercontent.com/dansmith-stripe/sa-summit-26-setup/main/setup.sh)

You'll be prompted for three values:

Prompt	Where to find it

Stripe LDAP handle	Your lowercase Stripe handle (e.g. jdoe)

Stripe Profile ID	Dashboard → Settings → Profile → Network ID. Starts with profile_

Stripe secret key	Dashboard → Developers → API keys, test mode. Starts with sk_test_

Copy
The script will:

Save credentials to ~/.machine-payments-summit.env (chmod 600)

Export all variables automatically — no manual source needed

Register summit-booking-demo as an MCP server with Claude Code

Launch Claude

Open a new terminal and run:


claude mcp list   # confirm summit-booking-demo shows ✔ Connected
claude
Scripts
setup.sh — interactive setup, run once before summit day
