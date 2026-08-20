#!/usr/bin/env bash
#
# Stripe Tech Café — local attendee reset
#
# Removes only local Machine Payments demo setup created by setup.sh:
# - ~/.machine-payments-summit.env
# - the summit-booking-demo Claude MCP registration
#
# It does not delete hosted catalog profiles, holds, PaymentIntents, or another
# person's state.
#
# Run normally:
#   bash ./reset.sh
#
# To also clear the variables from the CURRENT shell:
#   source ./reset.sh
#
# Note: source this script only from a shell that supports Bash syntax.

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

unset_demo_environment() {
  unset LDAP_HANDLE 2>/dev/null || true
  unset MP_DEMO_TEAM_ID 2>/dev/null || true
  unset MP_DEMO_STRIPE_PROFILE_ID 2>/dev/null || true
  unset MP_DEMO_STRIPE_SECRET_KEY 2>/dev/null || true
  unset MP_DEMO_CATALOG_PROFILE_ID 2>/dev/null || true
  unset CLAUDE_CODE_DANGEROUSLY_ALLOWED_MCP_SERVERS 2>/dev/null || true
}

printf '\nStripe Tech Café — local demo reset\n\n'
printf 'This removes only your local Claude MCP registration and local environment file.\n'
printf 'It does not delete hosted payment records or custom catalog profiles.\n\n'

if ! ask_yes_no "Continue"; then
  printf 'No changes made.\n'
  return 0 2>/dev/null || exit 0
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

unset_demo_environment

printf '\nReset complete.\n'

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf '\nBecause this script was run with bash, your current terminal may still have old\n'
  printf 'demo variables loaded. Clear them by running:\n\n'
  printf '  unset LDAP_HANDLE MP_DEMO_TEAM_ID MP_DEMO_STRIPE_PROFILE_ID \\\n'
  printf '    MP_DEMO_STRIPE_SECRET_KEY MP_DEMO_CATALOG_PROFILE_ID \\\n'
  printf '    CLAUDE_CODE_DANGEROUSLY_ALLOWED_MCP_SERVERS\n\n'
  printf 'Or close this terminal and open a fresh one.\n'
else
  printf '\n✓ Cleared Machine Payments demo variables from the current shell.\n'
fi

printf '\nTo configure the demo again, run:\n\n'
printf '  bash ./setup.sh\n\n'
printf 'To configure a fictional custom catalog, run:\n\n'
printf '  bash ./setup.sh --catalog ./examples/my-fictional-catalog.json\n'
