# Uptime Kuma Service

This directory is reserved for custom Uptime Kuma builds.

## Default Deployment
Uses the official Uptime Kuma image (`louislam/uptime-kuma:1.23.11-alpine`) configured in `compose/compose.apps.yml` under the `infrastructure` profile.
Sends notifications via Webhooks to Discord/Slack/Telegram if platforms drop.
