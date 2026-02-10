## LoagmaPMS Backend (Laravel)

This directory contains the **Laravel 12** backend for the LoagmaPMS application.
It exposes REST APIs, handles database operations, and serves as the main backend for the Flutter client.

---

### Tech stack

- **Framework**: Laravel 12 (PHP 8.2+)
- **Database**: SQLite by default (can be switched to MySQL/PostgreSQL)
- **Build tools**: Vite for frontend assets (if needed)

---

### Folder structure (high level)

- `app/`
  - `Http/Controllers/` – HTTP controllers (e.g. `HealthController`)
  - `Models/` – Eloquent models (e.g. `User`)
  - `Providers/` – Application service providers
- `bootstrap/` – Framework bootstrap and routing configuration
- `config/` – Configuration files (app, database, cache, queue, etc.)
- `database/` – Migrations, factories, and seeders
- `public/` – Public web root (`index.php`)
- `resources/` – Blade views, frontend assets
- `routes/`
  - `web.php` – Web routes (views, browser-focused)
  - `api.php` – API routes (JSON APIs, prefixed with `/api`)
- `storage/` – Logs, compiled views, cache, file storage
- `tests/` – Feature and unit tests

---

### Environment configuration

1. **Create your `.env` file** (first time only):
   ```bash
   cp .env.example .env
   ```

2. **Generate the application key**:
   ```bash
   php artisan key:generate
   ```

3. **Configure database** (default is SQLite):
   - To use SQLite (recommended for quick start), keep:
     - `DB_CONNECTION=sqlite`
   - To switch to MySQL/PostgreSQL, update the DB section in `.env` accordingly.

4. **Useful `.env` variables** (from `.env.example`):
   - `APP_NAME` – Application name (e.g. `LoagmaPMS`)
   - `APP_ENV` – `local` / `production`
   - `APP_DEBUG` – `true` for local, `false` for production
   - `APP_URL` – Base URL for the backend (e.g. `http://localhost`)

---

### Running the backend (local)

From the `server` directory:

```bash
composer install
cp .env.example .env   # if not already done
php artisan key:generate
php artisan migrate
php artisan serve
```

By default the Laravel dev server runs on **`http://127.0.0.1:8000`**.

---

### Health API

The backend exposes a **health check** endpoint for monitoring and readiness checks.

- **Method**: `GET`
- **URL**: `http://127.0.0.1:8000/api/health`
- **Response (200 OK)**:

```json
{
  "status": "ok",
  "service": "LoagmaPMS API",
  "timestamp": "2026-02-10T12:34:56+00:00"
}
```

Implementation details:
- Route defined in `routes/api.php`
- Handled by `App\Http\Controllers\HealthController` (single-action controller)

---

### Swagger / OpenAPI documentation

An **OpenAPI 3.0** specification is provided for the backend APIs.

- File location: `docs/openapi.yaml`
- Contains documentation for:
  - `/api/health` – Health check endpoint

You can view this documentation using:

1. **Swagger UI (online)**  
   - Open `https://editor.swagger.io` in your browser.
   - Use `File` → `Import File` and select `docs/openapi.yaml`.

2. **Postman**  
   - In Postman, go to `APIs` → `Import` → `File` and select `docs/openapi.yaml`.

As you add new endpoints, extend `docs/openapi.yaml` with new paths, request bodies, and responses.

---

### Scripts (composer.json)

From the `server` directory, some useful composer scripts:

- `composer run setup` – Full initial setup (install deps, create `.env`, migrate, build assets).
- `composer run dev` – Run Laravel dev server, queue listener, logs, and Vite dev server together.
- `composer run test` – Run the test suite.

---

### Notes

- Keep your real `.env` file **out of version control**; only `.env.example` should be committed.
- Database migrations live under `database/migrations` – use them to evolve your schema.
- For new APIs, prefer creating dedicated controllers under `app/Http/Controllers` and registering routes in `routes/api.php`.
