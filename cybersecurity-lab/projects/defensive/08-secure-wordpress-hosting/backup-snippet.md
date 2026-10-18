# Backup snippet

The live job runs daily at 02:00 and keeps seven days of database dumps.

## Backup script

```bash
#!/bin/bash
set -euo pipefail

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/home/analyst/backups/wordpress"
CONTAINER="wordpress-db-1"
DB_USER="${WP_DB_USER}"
DB_NAME="wordpress"
DB_PASSWORD="${WP_DB_PASSWORD}"

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
DB_USER="${WP_DB_USER}"
DB_NAME="wordpress"
docker exec -i wordpress-db-1 mariadb -u "$DB_USER" -p "$DB_NAME" < /home/analyst/backups/wordpress/wordpress-YYYY-MM-DD_HH-MM-SS.sql
```

Like the backup script, the restore command reads the database credentials from the environment, so they stay out of the repo.
