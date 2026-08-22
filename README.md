# Machine Payments Demo Setup

Set up Claude Code to complete a fictional, test-mode Machine Payments purchase through the hosted Stripe Tech Café MCP server.

The demo uses:

- Claude Code for MCP catalog discovery and buyer interaction
- Link for explicit test-mode payment approval and passkey verification
- Stripe test mode for the resulting PaymentIntent
- The hosted Machine Payments service at `https://machine-payments.stripedemos.com`

> **Test mode only.** No real money moves. No food, drink, service, external work, research, ticket, message, customer-data access, or deliverable is created.

## What this repository configures

The setup script:

- saves your local test-mode credentials in `~/.mpp-demo.env` with mode `600`;
- registers the `mpp-demo` MCP server with Claude Code;
- validates that Link CLI supports the required MPP `--test` and `--context` options;
- optionally registers a fictional custom catalog for your local demo context.

The public Stripe Tech Café landing page remains static. A custom catalog appears only through Claude Code/MCP.

## Requirements

Before starting, make sure you have:

1. Claude Code installed and available as `claude`.
2. `curl` and Python 3 available in your terminal.
3. A Stripe test-mode Network Profile ID beginning with `profile_test_`.
4. A Stripe test secret key beginning with `sk_test_`.
5. A Link passkey configured at https://app.link.com/settings under **Passkeys**.

Do not use a live Stripe key. Do not share secret keys, Network Profile IDs, Shared Payment Tokens, approval URLs, or raw terminal output containing credentials.

## Standard setup

Clone the repository and run setup:

    git clone https://github.com/dansmith-stripe/mpp-demo-setup.git
    cd mpp-demo-setup
    bash ./setup.sh

The script prompts for:

- your Stripe test-mode Network Profile ID; and
- your Stripe test secret key.

The secret-key prompt is intentionally visible so you can verify that the key pasted correctly. Do not share your screen or terminal while entering it.

The script checks your Link CLI installation. If Link CLI is missing or does not support the required MPP options, setup can offer to install or update it.

During Claude MCP registration, corporate authentication or a hardware security-key prompt may appear. Output remains visible. Complete the prompt and wait rather than interrupting the script.

After setup completes, open a fresh terminal and run:

    source ~/.mpp-demo.env
    claude mcp list
    claude

Confirm that `mpp-demo` appears in `claude mcp list`.

## Buy a fictional order

In Claude Code, ask to discover the menu:

    What can I order from Stripe Tech Café today?

Choose an item, review the exact test-mode quote, and explicitly approve the specific amount only after confirming that Link visibly identifies the payment as **Test mode**.

For the default menu, the normal fulfillment is:

    Instant fictional confirmation — no real delivery or external work

Do not ask for a pickup window, delivery window, slot, schedule, hold, reservation, expiry, or time zone for an `instant` item.

The expected flow is:

    MCP catalog discovery
    → exact quote
    → explicit buyer approval
    → Link test-mode passkey verification
    → MPP payment challenge and retry
    → Stripe test-mode PaymentIntent receipt

After payment, verify the `pi_...` PaymentIntent in the same Stripe test-mode sandbox whose `sk_test_...` key you used. Confirm that `livemode` is `false`.

## Optional: custom fictional catalog

Custom catalogs are optional and appear only through Claude Code/MCP. They do not change the public Stripe Tech Café website.

### Recommended: instant fictional catalog

Start with the default example:

    cp examples/custom-catalog.example.json examples/my-fictional-catalog.json

Edit `examples/my-fictional-catalog.json` to create a fictional menu. Keep a clear test-mode/non-affiliation disclaimer and use:

    "fulfillment_type": "instant"

for normal no-scheduling items.

Register the catalog:

    bash ./setup.sh --catalog ./examples/my-fictional-catalog.json

Then start a fresh Claude Code session:

    source ~/.mpp-demo.env
    claude

Ask Claude to show the custom menu, choose an item, review the exact quote, and complete the same explicit-approval and Link test-mode flow.

A successful registration creates an opaque local catalog-profile reference. Do not share that reference, your credentials, raw headers, or the full catalog-registration response.

### Advanced: scheduled fictional catalog

The default custom-catalog example uses `instant` and is recommended for normal demos.

Use the scheduled example only when you intentionally want to demonstrate advanced pickup-window or simulated-service-window behavior:

    cp examples/custom-catalog.scheduled.example.json examples/my-scheduled-catalog.json
    bash ./setup.sh --catalog ./examples/my-scheduled-catalog.json

The scheduled example uses the supported fulfillment types:

    "fulfillment_type": "pickup_window"
    "fulfillment_type": "agent_delivery_window"

Scheduled examples can show fulfillment windows and timing details. They still never create a real pickup, delivery, service, external task, research request, ticket, message, customer-data access, or deliverable.

## Return to the default menu

Run setup without `--catalog`:

    bash ./setup.sh

This rewrites the local environment file without a custom catalog-profile reference.

## Reset local setup

Run the reset script from the repository directory:

    source ./reset.sh

Using `source` is recommended because it clears the currently loaded Machine Payments variables from your shell.

The reset script:

- removes `~/.mpp-demo.env`;
- clears the current shell variables when sourced;
- can remove the local `mpp-demo` Claude Code MCP registration.

It does not delete hosted catalog profiles, test PaymentIntents, orders, or another person’s state.

If Claude requests authentication or a hardware security-key confirmation while removing the MCP server, complete the prompt normally. Do not suppress or time out the Claude CLI output.

## Troubleshooting

### `link-cli` is missing or does not support the required MPP options

Setup checks whether Link CLI supports both `--test` and `--context`.

If Link CLI is missing, allow setup to install it. If it is installed but too old, allow setup to update it.

If your terminal still resolves an older binary afterward, open a fresh terminal and run:

    command -v link-cli
    type -a link-cli
    link-cli --version
    link-cli mpp pay --schema

The schema output must include both `test:` and `context:`.

### Setup appears paused during Claude MCP registration

Corporate authentication or a hardware security-key prompt may appear when setup removes or adds the Claude MCP server.

The script intentionally leaves Claude CLI output visible. Complete the browser, macOS, terminal, or security-key prompt, then wait for the command to finish. Do not interrupt the script or suppress its output.

### `mpp-demo` does not appear in Claude Code

Open a fresh terminal and run:

    source ~/.mpp-demo.env
    claude mcp list

If `mpp-demo` is still absent, rerun setup from the repository directory:

    bash ./setup.sh

When prompted, choose to register the MCP server. Then start a new Claude Code session:

    claude

### A custom catalog is rejected

The setup script displays only a sanitized HTTP status, error code, and safe message.

Check that:

- the catalog is valid JSON;
- every standard item uses `"fulfillment_type": "instant"`;
- advanced scheduled items use only `"pickup_window"` or `"agent_delivery_window"`;
- each item references a valid `counter_id`; and
- the catalog includes a clear fictional/test-mode disclaimer.

When reporting an issue, share only the HTTP status and the sanitized error code/message. Do not share credentials, Profile IDs, headers, approval URLs, tokens, raw API responses, or the full catalog JSON.

### Claude shows the wrong catalog

The default menu is used whenever setup runs without `--catalog`.

To return to the default Stripe Tech Café menu:

    bash ./setup.sh

To use a custom catalog again:

    bash ./setup.sh --catalog ./examples/my-fictional-catalog.json

After either change, open a fresh terminal and run:

    source ~/.mpp-demo.env
    claude

### I need to start over

From the repository directory, run:

    source ./reset.sh

This removes the local environment file and can remove the `mpp-demo` Claude MCP registration. It does not delete test PaymentIntents, hosted catalog profiles, or another person’s demo state.
