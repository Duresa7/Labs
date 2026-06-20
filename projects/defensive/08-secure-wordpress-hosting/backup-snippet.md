# Sanitized backup snippet

The live job runs daily at 02:00 and keeps seven days of database dumps. Paths use `/home/analyst` as the public placeholder for the real Unix user.

## Backup script

```bash
#!/bin/bash
set -euo pipefail

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/home/analyst/backups/wordpress"
CONTAINER="wordpress-db-1"
DB_USER="<redacted>"
DB_NAME="wordpress"
DB_PASSWORD="<redacted>"

mkdir -p "$BACKUP_DIR"
docker exec "$CONTAINER" mariadb-dump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/wordpress-$DATE.sql"

find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete

echo "Backup completed: wordpress-$DATE.sql"
```

## Cron

```cron
0 2 * * * /home/analyst/backups/wordpress-backup.sh >> /home/analyst/backups/backup.log 2>&1
```

## Restore

```bash
DB_USER="<redacted>"
DB_NAME="wordpress"
docker exec -i wordpress-db-1 mariadb -u "$DB_USER" -p "$DB_NAME" < /home/analyst/backups/wordpress/wordpress-YYYY-MM-DD_HH-MM-SS.sql
```

The restore command is documented with the same redaction rule as the backup script: real database credentials stay out of the repo.
