# Stripe Tech Café — Machine Payments workshop setup

This repository configures the local tools for the Stripe Tech Café Machine Payments demo.

The demo is entirely test mode:

- No real money moves.
- No food is prepared or delivered.
- No fictional Agent Counter item creates research, tickets, messages, customer-data access, external work, or a deliverable.
- The actual purchase flow happens through Claude Code, MCP, Link, and the Machine Payments Protocol—not through the public webpage.

The public [Stripe Tech Café page](https://machine-payments.stripedemos.com/) is a static example storefront. It does not change when you use a custom catalog.

## Before you begin

You need:

1. Claude Code installed and signed in.
2. A Stripe test-mode secret key beginning with `sk_test_`.
3. A test-mode Stripe Business Network Profile ID beginning with `profile_test_`.
4. A Link passkey configured for the Link account you will use in the exercise.

Set up your Link passkey before beginning:

1. Visit <https://app.link.com/settings>.
2. Open **Settings**.
3. Select **Passkeys**.
4. Add a passkey.

During payment approval, Link verifies your purchase through mobile biometric authentication if you use the Link mobile app, or with your laptop/browser-device password if you use Link in the browser.

## Clone the setup repository

    git clone https://github.com/dansmith-stripe/sa-summit-26-setup.git
    cd sa-summit-26-setup

## Standard Stripe Tech Café setup

Run:

    bash ./setup.sh

The script asks for:

1. Your test-mode Stripe Profile ID (`profile_test_...`).
2. Your Stripe test-mode secret key (`sk_test_...`).

It saves your local configuration to:

    ~/.machine-payments-summit.env

with file permissions set to `600`, then registers the `summit-booking-demo` MCP server with Claude Code.

Open a fresh shell and start Claude Code:

    source ~/.machine-payments-summit.env
    claude mcp list
    claude

Claude Code should show `summit-booking-demo` as connected.

Ask Claude:

> Use the Machine Payments demo to list the available services.

Without a custom catalog, Claude discovers the default Stripe Tech Café menu.

## Use a custom fictional catalog

Use a custom catalog when you want to test different fictional business names, offerings, service names, descriptions, prices, or fulfillment wording.

Copy the example:

    cp examples/custom-catalog.example.json examples/my-fictional-catalog.json

Edit the copied file:

    nano examples/my-fictional-catalog.json

Then register it:

    bash ./setup.sh --catalog ./examples/my-fictional-catalog.json

Start a fresh shell and launch Claude Code:

    source ~/.machine-payments-summit.env
    claude

Ask Claude:

> Use the Machine Payments demo to list the available services.

Claude Code should discover your custom fictional catalog through MCP.

### Default immediate fulfillment

The default catalog flow uses `instant_simulation`, with this standard fulfillment label:

> Immediate fictional confirmation — no real delivery or external work

This is the recommended workshop configuration. The attendee flow is:

> Discover catalog → select item → see final quote → explicitly authorize → approve through Link in test mode → passkey verification → receipt

There is no attendee-visible appointment, delivery window, reservation, pickup time, or hold expiry in the default demo path.

### Catalog rules

Your catalog may include:

- a fictional business name and business type;
- one or two fictional counters;
- one to eight fictional items;
- safe item names and descriptions;
- USD prices;
- immediate fictional fulfillment labels.

`amount` is expressed in USD cents:

- `100` means `$1.00 USD`
- `500` means `$5.00 USD`
- `1250` means `$12.50 USD`

Catalogs must remain fictional and test mode only. Do not describe or request real food, goods, services, research, ticket creation, messaging, customer-data access, external work, or deliverables.

Each registration creates a new immutable catalog profile. Editing a JSON file cannot alter an existing checkout, payment approval, or receipt.

The public Stripe Tech Café webpage remains static. Your custom items appear only in Claude Code/MCP.

### Optional advanced scheduled fulfillment

The hosted demo may also support these advanced, SA-custom-catalog-only fulfillment types:

- `pickup_window`
- `agent_delivery_window`

Use them only when you intentionally want to demonstrate a fictional scheduled reservation flow. They add availability lookup, selected-window, and internal expiry concepts, so they are not recommended for the standard workshop demo.

To return to the default Stripe Tech Café catalog, run standard setup again without `--catalog`:

    bash ./setup.sh

## Reset local setup

To remove the local Claude MCP registration and local environment file, run:

    source ./reset.sh

Using `source` is recommended because it also clears the current terminal’s Machine Payments variables. Running `bash ./reset.sh` can remove local files and MCP configuration, but cannot remove variables that were already loaded into your current terminal.

`reset.sh` removes only local setup on your computer. It does not delete hosted payment records or custom catalog profiles, and it never affects another person’s demo data.

After reset, rerun either:

    bash ./setup.sh

or:

    bash ./setup.sh --catalog ./examples/my-fictional-catalog.json

## Workshop payment flow

The standard exercise flow is:

1. Claude Code discovers a fictional catalog through MCP.
2. You choose one fictional item.
3. Claude shows the merchant, item, exact amount, currency, and fictional no-fulfillment disclaimer.
4. You explicitly authorize the exact test-mode purchase.
5. Link shows the exact test-mode payment for approval.
6. Link verifies the purchase with your passkey:
   - mobile biometric verification in the Link app; or
   - your laptop/browser-device password when using Link in the browser.
7. The Machine Payments Protocol completes an HTTP `402` challenge and Shared Payment Token retry.
8. One test-mode PaymentIntent is created in your sandbox account.
9. Claude shows the final receipt.

Always verify the merchant, item, amount, currency, and fictional disclaimer before approving a payment.
