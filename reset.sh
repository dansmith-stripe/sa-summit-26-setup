#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Machine Payments Summit — Reset (for testing only)
# Undoes everything setup.sh did so you can run it again from scratch.
# Usage: bash sa-summit-26-setup/reset.sh
# ─────────────────────────────────────────────────────────────────────────────

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo -e "${BOLD}Machine Payments Summit — Reset${RESET}"
echo "────────────────────────────────────────────"
echo ""

# ── 1. Remove env file ───────────────────────────────────────────────────────

ENV_FILE="$HOME/.machine-payments-summit.env"
if [[ -f "$ENV_FILE" ]]; then
  rm "$ENV_FILE"
  echo -e "${GREEN}✓ Removed $ENV_FILE${RESET}"
else
  echo -e "${YELLOW}  (no env file found)${RESET}"
fi

# ── 2. Remove auto-source lines from shell rc files ──────────────────────────

for RC_FILE in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [[ -f "$RC_FILE" ]] && grep -qF "machine-payments-summit" "$RC_FILE"; then
    sed -i '' '/machine-payments-summit/d' "$RC_FILE"
    echo -e "${GREEN}✓ Removed auto-source from $RC_FILE${RESET}"
  fi
done

# ── 3. Unset env vars in current shell ───────────────────────────────────────

unset LDAP_HANDLE MP_DEMO_TEAM_ID MP_DEMO_STRIPE_PROFILE_ID \
      MP_DEMO_STRIPE_SECRET_KEY STRIPE_DIRECTORY_API_KEY \
      CLAUDE_CODE_DANGEROUSLY_ALLOWED_MCP_SERVERS
echo -e "${GREEN}✓ Env vars unset in current shell${RESET}"

# ── 4. Remove summit-directory Stripe CLI profile ────────────────────────────

STRIPE_CONFIG="$HOME/.config/stripe/config.toml"
if [[ -f "$STRIPE_CONFIG" ]] && grep -q "\[summit-directory\]" "$STRIPE_CONFIG"; then
  python3 - "$STRIPE_CONFIG" <<'PYEOF'
import sys, re
p = sys.argv[1]
content = open(p).read()
content = re.sub(r"\[summit-directory\][^\[]*", "", content, flags=re.DOTALL).rstrip() + "\n"
open(p, "w").write(content)
PYEOF
  echo -e "${GREEN}✓ Removed Stripe CLI profile 'summit-directory'${RESET}"
else
  echo -e "${YELLOW}  (no summit-directory profile found)${RESET}"
fi

# ── 5. Remove MCP server ─────────────────────────────────────────────────────

if claude mcp remove summit-booking-demo >/dev/null 2>&1; then
  echo -e "${GREEN}✓ Removed MCP server 'summit-booking-demo'${RESET}"
else
  echo -e "${YELLOW}  (no summit-booking-demo MCP server found)${RESET}"
fi

# ── Remove cloned repo ───────────────────────────────────────────────────────

rm -rf "$SCRIPT_DIR"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Reset complete. Go back to step 1 to set up again.${RESET}"
echo ""
