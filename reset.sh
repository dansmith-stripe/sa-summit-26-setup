#!/usr/bin/env bash
#
# Stripe Tech Café — local attendee reset
#
# Removes only local Machine Payments demo setup created by setup.sh:
# - ~/.machine-payments-summit.env
# - the summit-booking-demo Claude MCP registration
#
# It does not delete hosted catalog profiles, holds, PaymentIntents, or another
# person's state. A new setup run starts with the default catalog unless you
# register a custom catalog again with:
#
#   bash ./setup.sh --catalog ./examples/my-fictional-catalog.json

set -Eeuo pipefail

ENV_FILE="${HOME}/.machine-payments-summit.env"
MCP_NAME="summit-booking-demo"

ask_yes_no() {
  local prompt="$1"
  local answer=""

  while true; do
    read -r -p "${prompt} [y/N] " answer
    answer="${answer:-n}"

    case "$answer" in
      y|Y|yes|YES|Yes) return 0 ;;
      n|N|no|NO|No) return 1 ;;
      *) printf 'Please answer yes or no.\n' ;;
    esac
  done
}

printf '\nStripe Tech Café — local demo reset\n\n'
printf 'This removes only your local Claude MCP registration and local environment file.\n'
printf 'It does not delete hosted payment records or custom catalog profiles.\n\n'

if ! ask_yes_no "Continue"; then
  printf 'No changes made.\n'
  exit 0
fi

if command -v claude >/dev/null 2>&1; then
  if claude mcp remove "$MCP_NAME" >/dev/null 2>&1; then
    printf '✓ Removed Claude MCP server: %s\n' "$MCP_NAME"
  else
    printf '• Claude MCP server was not registered locally.\n'
  fi
else
  printf '• Claude Code was not found; skipped MCP removal.\n'
fi

if [[ -f "$ENV_FILE" ]]; then
  rm -f "$ENV_FILE"
  printf '✓ Removed local environment file: %s\n' "$ENV_FILE"
else
  printf '• Local environment file was not present.\n'
fi

printf '\nReset complete.\n'
printf 'To configure the demo again, run:\n\n'
printf '  bash ./setup.sh\n\n'
printf 'To configure a fictional custom catalog, run:\n\n'
printf '  bash ./setup.sh --catalog ./examples/my-fictional-catalog.json\n'
