#!/usr/bin/env bash
#
# Stripe Tech Café — local attendee reset
#
# Recommended:
#   source ./reset.sh
#
# Running `bash ./reset.sh` removes local files and can remove the Claude MCP
# registration, but cannot unset variables already loaded into your current
# terminal. Sourcing this script clears those variables too.
#
# This script removes local setup only. It does not delete hosted catalog
# profiles, holds, payment records, or another person's data.

set -Eeuo pipefail

ENV_FILE="${HOME}/.machine-payments-summit.env"
MCP_NAME="summit-booking-demo"

is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "$0" ]]
}

finish() {
  local code="${1:-0}"

  if is_sourced; then
    return "$code"
  fi

  exit "$code"
}

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
  # Current individual-run variables.
  unset MP_DEMO_STRIPE_PROFILE_ID 2>/dev/null || true
  unset MP_DEMO_STRIPE_SECRET_KEY 2>/dev/null || true
  unset MP_DEMO_CATALOG_PROFILE_ID 2>/dev/null || true
  unset CLAUDE_CODE_DANGEROUSLY_ALLOWED_MCP_SERVERS 2>/dev/null || true

  # Legacy variables from older workshop setup versions.
  unset LDAP_HANDLE 2>/dev/null || true
  unset MP_DEMO_TEAM_ID 2>/dev/null || true
  unset STRIPE_DIRECTORY_API_KEY 2>/dev/null || true
}

printf '\nStripe Tech Café — local demo reset\n\n'

if is_sourced; then
  printf 'This script is sourced, so it can remove local setup and clear Machine Payments\n'
  printf 'variables from your current terminal.\n\n'
else
  printf 'This script was started with bash. It can remove local setup files, but it\n'
  printf 'cannot clear variables already loaded in your current terminal.\n'
  printf 'For a complete reset, run: source ./reset.sh\n\n'
fi

printf 'This reset can:\n'
printf '  - remove %s\n' "$ENV_FILE"
printf '  - clear current and legacy Machine Payments variables when sourced\n'
printf '  - optionally remove the Claude MCP registration: %s\n' "$MCP_NAME"
printf '\nIt does not delete hosted catalog profiles, holds, payment records, or another person'\''s data.\n\n'

if ! ask_yes_no "Continue"; then
  printf 'No changes made.\n'
  finish 0
fi

# Complete local cleanup before any Claude CLI invocation. This ensures an MFA
# prompt cannot prevent removal of the local environment file.
if [[ -f "$ENV_FILE" ]]; then
  rm -f "$ENV_FILE"
  printf '✓ Removed local environment file: %s\n' "$ENV_FILE"
else
  printf '• Local environment file was not present.\n'
fi

unset_demo_environment

if is_sourced; then
  printf '✓ Cleared Machine Payments variables from the current shell.\n'
else
  printf '• Cleared variables in the reset process only.\n'
fi

if command -v claude >/dev/null 2>&1; then
  printf '\nRemoving the Claude Code MCP registration may require Stripe authentication.\n'
  printf 'If your browser, macOS, terminal, or hardware security key prompts you,\n'
  printf 'touch your security key and wait for authentication to complete.\n'
  printf 'A short pause during this step is expected and is not a script hang.\n\n'

  if ask_yes_no "Remove the '${MCP_NAME}' MCP registration now?"; then
    # Do not suppress output: the Claude CLI may need to show an authentication
    # or hardware-security-key prompt.
    if claude mcp remove "$MCP_NAME"; then
      printf '✓ Removed Claude MCP server: %s\n' "$MCP_NAME"
    else
      printf '• Could not remove the Claude MCP server.\n'
      printf '  Local environment cleanup is complete. Retry later with:\n\n'
      printf '  claude mcp remove %s\n' "$MCP_NAME"
    fi
  else
    printf '• Left the Claude MCP registration in place.\n'
    printf '  Remove it later with:\n\n'
    printf '  claude mcp remove %s\n' "$MCP_NAME"
  fi
else
  printf '\n• Claude Code was not found; skipped MCP removal.\n'
fi

printf '\nReset complete.\n'

if ! is_sourced; then
  printf '\nYour current terminal may still retain old values because this script ran in a child process.\n'
  printf 'Run this command now, or close and reopen your terminal:\n\n'
  printf '  unset LDAP_HANDLE MP_DEMO_TEAM_ID MP_DEMO_STRIPE_PROFILE_ID \\\n'
  printf '    MP_DEMO_STRIPE_SECRET_KEY MP_DEMO_CATALOG_PROFILE_ID \\\n'
  printf '    STRIPE_DIRECTORY_API_KEY CLAUDE_CODE_DANGEROUSLY_ALLOWED_MCP_SERVERS\n'
fi

printf '\nTo configure the default Stripe Tech Café demo again:\n\n'
printf '  bash ./setup.sh\n\n'
printf 'To configure a custom fictional catalog:\n\n'
printf '  bash ./setup.sh --catalog ./examples/my-fictional-catalog.json\n'

finish 0
