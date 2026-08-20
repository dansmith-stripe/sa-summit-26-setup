
# Stripe Tech Café — Machine Payments workshop setup

This repository sets up the local tools for the Stripe Tech Café Machine Payments demo.

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
