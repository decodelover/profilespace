# Tspace Portfolio Builder 🚀

Tspace is a premium, personal portfolio builder application that allows developers, designers, and writers to build and publish beautiful bento-grid styled sites in seconds. Users fill out their professional details and project links, select their style guidelines, and the platform auto-generates their public-facing layout.

---

## Key Features

- **Mesh Gradient welcome & login screens** with interactive floating visual particles.
- **Form-driven details capture** covering name, title, bio, skills, profile avatar URL, and accent color schemes.
- **Dark & Light Mode custom themes** applied dynamically to bento blocks.
- **Publishing Plan Tiers**:
  - **Free Plan:** Publishes instantly to a built-in subdomain (e.g. `tspace.me/username`) and supports **1 project showcase**.
  - **Pro Plan ($8/mo):** Connects to a **custom domain** (e.g. `yourname.com`) and supports **unlimited projects**.
- **Auto-Build Engine:** Automatically constructs profile details and projects blocks inside the bento layout based on the user's role.
- **Immersive Launch Screen:** Features a live phone frame preview that updates in real-time, matching the theme selection and accent color before launching with confetti effects.

---

## Tech Stack

- **Frontend:** Flutter Web (with dark-first theming, GoRouter navigation, and BLoC state management)
- **Backend:** Laravel REST API (routing database profile configurations and domain mapping)
- **Database:** SQLite (local development storage)

---

## Getting Started

### 1. Backend Setup (Laravel)
Ensure you have PHP 8.2+ and Composer installed.

```bash
cd backend
composer install
php -r "file_exists('.env') || copy('.env.example', '.env');"
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

*The backend server will run on `http://127.0.0.1:8000`.*

### 2. Frontend Setup (Flutter)
Ensure you have the Flutter SDK installed.

```bash
flutter pub get
flutter run -d web-server --web-port=3000 --web-hostname=localhost
```

*Open your browser and navigate to `http://localhost:3000` to interact with the application.*

---

## Security & Privacy (Hiding Secrets)

Sensitive keys, environment configurations, and database files are **fully excluded** from version control to prevent leaks:
- The local SQLite database (`backend/database/database.sqlite`) is ignored via `backend/database/.gitignore`.
- Secrets and keys (`backend/.env` and `backend/.env.production`) are ignored via `backend/.gitignore`.
- Session keys, cache buffers, and vendor scripts are fully ignored globally.

---

## Continuous Integration (GitHub Actions)

The repository includes a automated testing workflow `.github/workflows/laravel_ci.yml` that validates test assertions on every push to `main` or `master`. Tests execute inside a fast, isolated in-memory SQLite buffer (`:memory:`).
