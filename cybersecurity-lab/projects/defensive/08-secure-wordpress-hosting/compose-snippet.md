# Compose and ingress snippets

These snippets show the shape of the build.

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

The `.env` file stays out of git. The variables it sets:

```dotenv
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=<strong-password>
MYSQL_ROOT_PASSWORD=<strong-password>
```

## Caddy

```caddyfile
{
    auto_https off
}

http://example.com {
    reverse_proxy 192.168.80.10:8080 {
        header_up X-Forwarded-Proto https
    }
}
```

`auto_https off` prevents a loop because Cloudflare terminates the outer TLS layer. `X-Forwarded-Proto` tells WordPress the original client request was HTTPS.

## Cloudflare rules

```text
Block admin path unless the source is the admin IP:
(http.request.uri.path contains "/wp-admin") and (ip.src ne 203.0.113.10)
```

```text
Rate-limit the unpublished login route:
path: /<hidden-login-path>
limit: 5 requests in 10 seconds
action: block for 1 minute
```

The login path itself is kept private. The route is still protected by WAF rules, Turnstile, Wordfence, and 2FA.
