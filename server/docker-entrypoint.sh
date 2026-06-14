#!/bin/sh
# Runtime setup, then start Apache. Runs on every container start (deploy/restart).
# Both artisan commands are idempotent; failures are logged but must NOT stop Apache from
# starting (e.g. a transient TiDB SSL connection drop should not take the whole app down).

php artisan migrate --force      || echo "[entrypoint] migrate failed (continuing)"
php artisan staff:make-admin     || echo "[entrypoint] staff:make-admin failed (continuing)"

# Re-assert ownership in case the artisan commands wrote root-owned log/cache files.
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true

exec apache2-foreground
