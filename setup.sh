#!/usr/bin/env bash
#
# Stripe Tech Café — Machine Payments demo setup
#
# Standard setup:
#   bash ./setup.sh
#
# Custom fictional catalog:
#   bash ./setup.sh --catalog ./examples/my-fictional-catalog.json
#
# This script stores your test-mode Stripe credentials only in:
#   ~/.machine-payments-summit.env
#
# It registers the hosted MCP server with Claude Code. It does not start a
# local application, require npm, or change the static Stripe Tech Café page.

set -Eeuo pipefail

ENV_FILE="${HOME}/.machine-payments-summit.env"
MCP_NAME="summit-booking-demo"
MCP_URL="https://machine-payments.stripedemos.com/mcp"
CATALOG_REGISTRATION_URL="https://machine-payments.stripedemos.com/api/catalog-profiles"

CATALOG_FILE=""
TMP_ENV_FILE=""
TMP_RESPONSE_FILE=""

OLD_PROFILE_ID=""
OLD_SECRET_KEY=""
OLD_CATALOG_PROFILE_ID=""

cleanup() {
  [[ -n "${TMP_ENV_FILE:-}" && -f "${TMP_ENV_FILE:-}" ]] && rm -f "$TMP_ENV_FILE"
  [[ -n "${TMP_RESPONSE_FILE:-}" && -f "${TMP_RESPONSE_FILE:-}" ]] && rm -f "$TMP_RESPONSE_FILE"
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Stripe Tech Café — Machine Payments demo setup

Usage:
  bash ./setup.sh
  bash ./setup.sh --catalog ./examples/my-fictional-catalog.json

Options:
  --catalog PATH   Register a fictional JSON catalog for this Claude Code demo.
                   The custom catalog appears through MCP/Claude Code only.
                   It does not change the public Stripe Tech Café website.
  -h, --help       Show this help text.

Examples:
  # Standard Stripe Tech Café catalog
  bash ./setup.sh

  # Create and use a custom fictional catalog
  cp examples/custom-catalog.example.json examples/my-fictional-catalog.json
  # Edit examples/my-fictional-catalog.json
  bash ./setup.sh --catalog ./examples/my-fictional-catalog.json
EOF
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Error: required command not found: %s\n' "$1" >&2
    exit 1
  }
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

prompt_value() {
  local label="$1"
  local default="${2:-}"
  local value=""

  if [[ -n "$default" ]]; then
    read -r -p "${label} [${default}]: " value
    value="${value:-$default}"
  else
    read -r -p "${label}: " value
  fi

  printf '%s' "$value"
}

prompt_secret() {
  local value=""
  read -r -s -p "Stripe test secret key (must begin with sk_test_): " value
  printf '\n'
  printf '%s' "$value"
}

validate_profile_id() {
  [[ "$1" =~ ^profile_test_[A-Za-z0-9_]+$ ]]
}

validate_test_key() {
  local key="$1"

  [[ -n "$key" ]] &&
    [[ "$key" == "${key#"${key%%[![:space:]]*}"}" ]] &&
    [[ "$key" == "${key%"${key##*[![:space:]]}"}" ]] &&
    [[ "$key" == sk_test_* ]] &&
    [[ "${#key}" -gt 16 ]]
}

validate_catalog_file() {
  local path="$1"

  [[ -f "$path" ]] || {
    printf 'Error: catalog file does not exist: %s\n' "$path" >&2
    exit 1
  }

  [[ -r "$path" ]] || {
    printf 'Error: catalog file is not readable: %s\n' "$path" >&2
    exit 1
  }

  python3 -m json.tool "$path" >/dev/null 2>&1 || {
    printf 'Error: catalog file is not valid JSON: %s\n' "$path" >&2
    exit 1
  }
}

extract_catalog_profile_id() {
  local response_file="$1"

  python3 - "$response_file" <<'PYTHON'
import json
import re
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)

candidates = [
    payload.get("catalog_profile_id"),
    payload.get("profile_id"),
    payload.get("id"),
]

data = payload.get("data")
if isinstance(data, dict):
    candidates.extend([
        data.get("catalog_profile_id"),
        data.get("profile_id"),
        data.get("id"),
    ])

for candidate in candidates:
    if isinstance(candidate, str) and re.fullmatch(r"demo_catalog_profile_[A-Za-z0-9_-]+", candidate):
        print(candidate)
        sys.exit(0)

sys.exit(1)
PYTHON
}

register_catalog() {
  local catalog_path="$1"
  local http_status=""
  local profile_id=""

  TMP_RESPONSE_FILE="$(mktemp "${TMPDIR:-/tmp}/stripe-tech-cafe-catalog-response.XXXXXX")"

  printf '\nRegistering fictional custom catalog with the hosted Machine Payments demo...\n'

  if ! http_status="$(
    curl \
      --silent \
      --show-error \
      --output "$TMP_RESPONSE_FILE" \
      --write-out '%{http_code}' \
      --request POST \
      --header 'Content-Type: application/json' \
      --header "X-Demo-Stripe-Secret-Key: ${SECRET_KEY}" \
      --header "X-Demo-Stripe-Profile-Id: ${PROFILE_ID}" \
      --data-binary "@${catalog_path}" \
      "$CATALOG_REGISTRATION_URL"
  )"; then
    printf 'Error: could not reach the hosted catalog-registration endpoint.\n' >&2
    printf 'Check your network connection and confirm the hosted custom-catalog release is deployed.\n' >&2
    exit 1
  fi

  if [[ "$http_status" != "200" && "$http_status" != "201" ]]; then
    printf 'Error: catalog registration was rejected by the hosted service (HTTP %s).\n' "$http_status" >&2
    printf 'Check that the catalog follows the documented fictional/test-mode schema.\n' >&2
    exit 1
  fi

  if ! profile_id="$(extract_catalog_profile_id "$TMP_RESPONSE_FILE")"; then
    printf 'Error: catalog registration succeeded but returned an unexpected response format.\n' >&2
    printf 'Do not continue. Confirm the deployed API returns a demo_catalog_profile_... ID.\n' >&2
    exit 1
  fi

  CATALOG_PROFILE_ID="$profile_id"
  rm -f "$TMP_RESPONSE_FILE"
  TMP_RESPONSE_FILE=""

  printf '✓ Registered a custom fictional catalog for this local demo.\n'
}

write_env_file() {
  TMP_ENV_FILE="${ENV_FILE}.tmp.$$"

  umask 077
  {
    printf 'export MP_DEMO_STRIPE_PROFILE_ID=%q\n' "$PROFILE_ID"
    printf 'export MP_DEMO_STRIPE_SECRET_KEY=%q\n' "$SECRET_KEY"

    if [[ -n "${CATALOG_PROFILE_ID:-}" ]]; then
      printf 'export MP_DEMO_CATALOG_PROFILE_ID=%q\n' "$CATALOG_PROFILE_ID"
    fi

    printf 'export CLAUDE_CODE_DANGEROUSLY_ALLOWED_MCP_SERVERS=%q\n' "$MCP_NAME"
  } >"$TMP_ENV_FILE"

  chmod 600 "$TMP_ENV_FILE"
  mv -f "$TMP_ENV_FILE" "$ENV_FILE"
  TMP_ENV_FILE=""

  printf '✓ Wrote %s with mode 600.\n' "$ENV_FILE"
}

register_mcp() {
  claude mcp remove "$MCP_NAME" >/dev/null 2>&1 || true

  if [[ -n "${CATALOG_PROFILE_ID:-}" ]]; then
    claude mcp add \
      --transport http \
      --scope user \
      "$MCP_NAME" \
      "$MCP_URL" \
      --header 'X-Demo-Stripe-Secret-Key: ${MP_DEMO_STRIPE_SECRET_KEY}' \
      --header 'X-Demo-Stripe-Profile-Id: ${MP_DEMO_STRIPE_PROFILE_ID}' \
      --header 'X-Demo-Catalog-Profile-Id: ${MP_DEMO_CATALOG_PROFILE_ID}'
  else
    claude mcp add \
      --transport http \
      --scope user \
      "$MCP_NAME" \
      "$MCP_URL" \
      --header 'X-Demo-Stripe-Secret-Key: ${MP_DEMO_STRIPE_SECRET_KEY}' \
      --header 'X-Demo-Stripe-Profile-Id: ${MP_DEMO_STRIPE_PROFILE_ID}'
  fi

  printf '✓ Registered %s with Claude Code.\n' "$MCP_NAME"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --catalog)
      [[ $# -ge 2 ]] || {
        printf 'Error: --catalog requires a JSON-file path.\n' >&2
        exit 1
      }
      [[ -z "$CATALOG_FILE" ]] || {
        printf 'Error: --catalog may be supplied only once.\n' >&2
        exit 1
      }
      CATALOG_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Error: unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

printf '\nStripe Tech Café — Machine Payments demo setup\n\n'

require_command claude
require_command curl
require_command python3

if [[ -n "$CATALOG_FILE" ]]; then
  validate_catalog_file "$CATALOG_FILE"
  printf 'Using custom fictional catalog: %s\n\n' "$CATALOG_FILE"
fi

if [[ -f "$ENV_FILE" ]]; then
  printf 'Found an existing local demo environment; values will be offered as defaults.\n\n'

  # This file is expected to be the mode-600 file generated by this script.
  # Do not run this script if you do not trust the existing file.
  # shellcheck disable=SC1090
  source "$ENV_FILE"

  OLD_PROFILE_ID="${MP_DEMO_STRIPE_PROFILE_ID:-}"
  OLD_SECRET_KEY="${MP_DEMO_STRIPE_SECRET_KEY:-}"
  OLD_CATALOG_PROFILE_ID="${MP_DEMO_CATALOG_PROFILE_ID:-}"
fi

printf 'Find your test-mode Stripe Profile ID at:\n'
printf '  https://dashboard.stripe.com/test/profiles\n'
printf 'Use the test-mode Network ID beginning with profile_test_.\n\n'

while true; do
  PROFILE_ID="$(prompt_value "Stripe test-mode Profile ID" "$OLD_PROFILE_ID")"

  if validate_profile_id "$PROFILE_ID"; then
    break
  fi

  printf 'Profile ID must begin with profile_test_.\n'
done

printf '\nFind a test-mode secret key at:\n'
printf '  https://dashboard.stripe.com/test/apikeys\n'
printf 'Use only an sk_test_ key. Live-mode keys are rejected.\n\n'

if [[ -n "$OLD_SECRET_KEY" ]] && ask_yes_no "Reuse the existing test secret key?"; then
  SECRET_KEY="$OLD_SECRET_KEY"
else
  while true; do
    SECRET_KEY="$(prompt_secret)"

    if validate_test_key "$SECRET_KEY"; then
      break
    fi

    printf 'Invalid key. Enter a non-empty key beginning exactly with sk_test_ and with no surrounding whitespace.\n'
  done
fi

if ! validate_test_key "$SECRET_KEY"; then
  printf 'Error: selected key is not a valid sk_test_ key.\n' >&2
  exit 1
fi

CATALOG_PROFILE_ID=""

if [[ -n "$CATALOG_FILE" ]]; then
  register_catalog "$CATALOG_FILE"
elif [[ -n "$OLD_CATALOG_PROFILE_ID" ]]; then
  printf '\nStandard setup uses the default Stripe Tech Café catalog.\n'
  printf 'Your previous custom-catalog selection will be removed from the local environment.\n'
fi

printf '\n'
if [[ -f "$ENV_FILE" ]]; then
  if ! ask_yes_no "Overwrite ${ENV_FILE}?"; then
    printf 'No changes made.\n'
    exit 0
  fi
fi

write_env_file

printf '\nA Link passkey is required before you run the payment exercise.\n'
printf 'Set one up at: https://app.link.com/settings\n'
printf 'Link verifies your test payment through mobile biometrics in the Link app,\n'
printf 'or through your laptop/browser-device password when using browser Link.\n\n'

if ask_yes_no "Register '${MCP_NAME}' with Claude Code now?"; then
  register_mcp
fi

printf '\nLast step — open a fresh shell, then run:\n\n'
printf '  source ~/.machine-payments-summit.env\n'
printf '  claude mcp list\n'
printf '  claude\n\n'

if [[ -n "${CATALOG_PROFILE_ID:-}" ]]; then
  printf 'Your Claude Code demo will use your registered custom fictional catalog.\n'
  printf 'The public Stripe Tech Café website remains unchanged.\n'
else
  printf 'Your Claude Code demo will use the default Stripe Tech Café catalog.\n'
fi
