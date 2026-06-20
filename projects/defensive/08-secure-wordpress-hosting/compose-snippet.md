# Sanitized compose and ingress snippets

These snippets show the shape of the build without publishing the real domain, tunnel identifier, login path, or credentials.

## Docker Compose

```yaml
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_TABLE_PREFIX: site_
      WORDPRESS_CONFIG_EXTRA: "define('WP_HOME','https://example.com'); define('WP_SITEURL','https://example.com'); define('FORCE_SSL_ADMIN',false); define('DISALLOW_FILE_EDIT',true);"
    volumes:
      - wp_data:/var/www/html
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: mariadb:latest
    environment:
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped

volumes:
  wp_data:
  db_data:
```

The `.env` file stays out of git and uses redacted values in documentation:

```dotenv
MYSQL_DATABASE=wordpress
MYSQL_USER=<redacted>
MYSQL_PASSWORD=<redacted>
MYSQL_ROOT_PASSWORD=<redacted>
```

## Caddy

```caddyfile
{
    auto_https off
}

http://example.com {
    reverse_proxy 10.80.0.10:8080 {
        header_up X-Forwarded-Proto https
    }
}
```

`auto_https off` prevents a loop because Cloudflare terminates the outer TLS layer. `X-Forwarded-Proto` tells WordPress the original client request was HTTPS.

## Cloudflare rules

```text
Block admin path unless source is the documented admin address:
(http.request.uri.path contains "/wp-admin") and (ip.src ne 203.0.113.10)
```

```text
Rate-limit the unpublished login route:
path: /<hidden-login-path>
limit: 5 requests in 10 seconds
action: block for 1 minute
```

The real login path is omitted. The route is still protected by WAF rules, Turnstile, Wordfence, and 2FA.
