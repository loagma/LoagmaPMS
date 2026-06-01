# LoagmaPMS

Windows desktop PMS for Loagma — Flutter frontend + Laravel API backend.

---

## Stack

| Layer | Tech |
|-------|------|
| Desktop client | Flutter (Windows) |
| API server | Laravel 11 (PHP 8.2+) |
| Database | TiDB Cloud (MySQL-compatible) |

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Flutter SDK | 3.x | `flutter doctor` must pass |
| PHP | 8.2+ | With `pdo_mysql`, `mbstring`, `openssl` extensions |
| Composer | 2.x | |
| Inno Setup | 6.x | Only for building the installer EXE |

---

## Project structure

```
LoagmaPMS/
├── client/          # Flutter app
├── server/          # Laravel API
├── installer/       # Inno Setup script + output
│   └── loagmapms_setup.iss
├── docs/            # Design docs and plans
└── release.bat      # One-shot build script (see below)
```

---

## Development setup

### 1. Server

```bash
cd server
cp .env.example .env          # fill in DB_* credentials
composer install
php artisan key:generate
php artisan migrate
php artisan db:seed --class=DocumentSeriesSeeder
php artisan serve             # runs on http://localhost:8000
```

### 2. Client

By default the app points to the **production** API (`https://loagmapms-hd5u.onrender.com`).

To hit your local server:

```bash
cd client
flutter pub get
flutter run -d windows --dart-define=USE_LOCAL=true
```

To override the URL entirely:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://192.168.1.x:8000
```

---

## Building a release

### Quick (recommended)

Double-click **`release.bat`** from the repo root — it handles everything:

1. Detects the version from `client/pubspec.yaml`
2. Runs `flutter build windows --release`
3. Packages the output into `release_output/LoagmaPMS_vX.X.X_TIMESTAMP/`
4. Creates a ZIP of the release folder
5. Compiles the Inno Setup installer → `installer/output/LoagmaPMS_Setup_vX.X.X.exe`

> Inno Setup must be installed at `C:\Program Files (x86)\Inno Setup 6\` for step 5 to run.

### Manual steps

```bat
:: 1. Build Flutter release
cd client
flutter build windows --release

:: 2. Output lands here:
::    client\build\windows\x64\runner\Release\

:: 3. Compile installer (adjust version as needed)
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" /DAppVersion=1.0.0 installer\loagmapms_setup.iss

:: 4. Installer output:
::    installer\output\LoagmaPMS_Setup_v1.0.0.exe
```

---

## Bumping the version

Edit `client/pubspec.yaml`:

```yaml
version: 1.2.0+4   # semver+build_number
```

`release.bat` picks this up automatically.

---

## Document series (voucher numbering)

After any fresh migration, seed the series table so all forms show the correct next number:

```bash
cd server
php artisan db:seed --class=DocumentSeriesSeeder
```

To manage series numbers at runtime use the **Reset Voucher** screen inside the app.
