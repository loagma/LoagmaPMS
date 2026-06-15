#!/bin/sh
# Runtime setup, then start Apache. Runs on every container start (deploy/restart).

# Diagnostic — prints to the Render logs whether the container actually received the env vars.
# (If these say NO, Render is not injecting them into THIS service.)
echo "[entrypoint] MASTER_OTP present: $([ -n "$MASTER_OTP" ] && echo yes || echo NO); ADMIN_MOBILE present: $([ -n "$ADMIN_MOBILE" ] && echo yes || echo NO)"

# Cache config NOW, while Render's env vars are visible to this CLI process. Apache/mod_php
# does not reliably expose runtime env vars to web requests, so the app must read values from
# the cached config file (config()) rather than env() at request time. Re-run on every start
# so the cache always reflects the current environment.
php artisan config:clear >/dev/null 2>&1 || true
php artisan config:cache || echo "[entrypoint] config:cache failed (continuing)"

# Both artisan commands are idempotent; failures are logged but must NOT stop Apache from
# starting (e.g. a transient TiDB SSL connection drop should not take the whole app down).
php artisan migrate --force      || echo "[entrypoint] migrate failed (continuing)"
php artisan staff:make-admin     || echo "[entrypoint] staff:make-admin failed (continuing)"

# Re-assert ownership in case the artisan commands wrote root-owned log/cache files.
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true

exec apache2-foreground
