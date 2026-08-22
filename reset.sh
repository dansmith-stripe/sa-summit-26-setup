#!/usr/bin/env bash
#
# Stripe Tech Café — Machine Payments demo reset
#
# Recommended:
#   source ./reset.sh
#
# Running "bash ./reset.sh" removes the local file and MCP configuration, but it
# cannot unset variables already loaded into the current parent shell.

ENV_FILE="${HOME}/.mpp-demo.env"
MCP_NAME="mpp-demo"

is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "$0" ]]
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local answer=""

  while true; do
    if [[ "$default" == "y" ]]; then
      read -r -p "${prompt} [Y/n] " answer
      answer="${answer:-y}"
    else
      read -r -p "${prompt} [y/N] " answer
      answer="${answer:-n}"
    fi

    case "$answer" in
      y|Y|yes|YES|Yes) return 0 ;;
      n|N|no|NO|No) return 1 ;;
      *) printf 'Please answer yes or no.\n' ;;
    esac
  done
}

printf '\nStripe Tech Café — Machine Payments demo reset\n\n'

if [[ -f "$ENV_FILE" ]]; then
  rm -f "$ENV_FILE"
  printf '✓ Removed %s\n' "$ENV_FILE"
else
  printf '• No local environment file found at %s\n' "$ENV_FILE"
fi

if is_sourced; then
  unset MP_DEMO_STRIPE_PROFILE_ID
  unset MP_DEMO_STRIPE_SECRET_KEY
  unset MP_DEMO_CATALOG_PROFILE_ID
  unset CLAUDE_CODE_DANGEROUSLY_ALLOWED_MCP_SERVERS

  printf '✓ Cleared Machine Payments variables from this shell.\n'
else
  printf '\nNote: this script was run in a child shell, so it cannot clear variables\n'
  printf 'already loaded into your current terminal. For a full reset, run:\n\n'
  printf '  source ./reset.sh\n\n'
fi

printf '\nThe reset does not delete hosted catalog profiles, test PaymentIntents, orders,\n'
printf 'or any other attendee’s state.\n\n'

if command -v claude >/dev/null 2>&1; then
  if ask_yes_no "Remove '${MCP_NAME}' from Claude Code?"; then
    printf '\nClaude Code may request Stripe authentication or a hardware security key.\n'
    printf 'If prompted, complete the request and wait. A short pause is expected.\n\n'

    # Do not suppress output. Authentication and hardware-key prompts must remain visible.
    if claude mcp remove "$MCP_NAME"; then
      printf '✓ Removed Claude MCP server: %s\n' "$MCP_NAME"
    else
      printf '• Claude MCP server was not removed, was already absent, or authentication was cancelled.\n'
    fi
  else
    printf '• Left the Claude MCP server registration unchanged.\n'
  fi
else
  printf '• Claude Code is not available on PATH; no MCP registration was removed.\n'
fi

printf '\nReset complete.\n'

if ! is_sourced; then
  exit 0
fi

return 0
