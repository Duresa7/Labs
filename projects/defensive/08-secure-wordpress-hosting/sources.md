# Sources

## Cloudflare edge controls

- **Cloudflare Tunnel documentation.** `https://developers.cloudflare.com/tunnel/`
  The tunnel pattern used to publish the application without a direct WAN port-forward.
- **Cloudflare WAF, "Custom rules."** `https://developers.cloudflare.com/waf/custom-rules/`
  The rule model used for admin-path filtering.
- **Cloudflare WAF, "Rate limiting rules."** `https://developers.cloudflare.com/waf/rate-limiting-rules/`
  The login-path throttling control.
- **Cloudflare Bots, "Bot Fight Mode."** `https://developers.cloudflare.com/bots/get-started/bot-fight-mode/`
  The bot-mitigation toggle used ahead of the WordPress origin.
- **Cloudflare Turnstile documentation.** `https://developers.cloudflare.com/turnstile/`
  The bot challenge used on login and password reset forms.

## WordPress and proxy hardening

- **WordPress Developer Resources, "Hardening WordPress."** `https://developer.wordpress.org/advanced-administration/security/hardening/`
  General WordPress hardening reference.
- **WordPress Developer Resources, "Editing wp-config.php."** `https://developer.wordpress.org/advanced-administration/wordpress/wp-config/`
  Configuration constants such as file-editing controls.
- **Wordfence, "Login Security Options."** `https://www.wordfence.com/help/login-security/`
  Two-factor authentication and XML-RPC authentication controls.
- **WPS Hide Login, WordPress.org plugin page.** `https://wordpress.org/plugins/wps-hide-login/`
  The login-path hiding technique, cited without publishing the live path.
- **Caddy documentation, "reverse_proxy."** `https://caddyserver.com/docs/caddyfile/directives/reverse_proxy`
  The Caddy reverse-proxy behavior and forwarded headers.
- **Docker Compose documentation, "Use secrets."** `https://docs.docker.com/compose/how-tos/use-secrets/`
  Background for keeping secrets out of compose files and documentation.

## Backups and related portfolio context

- **MariaDB documentation, "mariadb-dump."** `https://mariadb.com/docs/server/clients-and-utilities/backup-restore-and-import-clients/mariadb-dump`
  The database dump utility used by the backup job.
- **man7.org, "crontab(5)."** `https://man7.org/linux/man-pages/man5/crontab.5.html`
  The cron schedule format used for the daily backup.
- **Network-Lab, "Zone-based firewall."** `https://github.com/Duresa7/Network-Lab/blob/main/projects/02-zone-based-firewall/README.md`
  The segmentation model that keeps the WordPress and management tiers separated.
- **Homelab-Project, "Ingress flow."** `https://github.com/Duresa7/Homelab-Project/blob/main/diagrams/ingress-flow.md`
  Public context for the Cloudflare Tunnel and reverse-proxy path.
