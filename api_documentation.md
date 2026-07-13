# Tspace Portfolio Builder — Backend API Documentation

This documentation describes the real, fully implemented API endpoints designed to power the Flutter mobile portfolio-builder app.

---

## Base URL
All API requests should be sent to the base URL:
`http://127.0.0.1:8000/api`

---

## Authentication & Sync-On-Login

All routes listed under the **Protected Routes** section require a valid Bearer token returned by the registration, login, or sync endpoints:
`Authorization: Bearer <access_token>`

### 1. Sync Firebase User (Sync-On-Login)
Verifies a Firebase ID token claims cryptographically and synchronizes the user into the database, auto-creating a starting profile and portfolio if it's their first sign-in.
* **Method & Route:** `POST /auth/sync`
* **Request Body:**
  ```json
  {
    "id_token": "eyJhbGciOiJSUzI1NiIs...",
    "email": "user@example.com",
    "name": "Alex Developer",
    "uid": "firebase-uid-12345",
    "provider": "google.com"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "access_token": "tspace_abcdef...",
      "refresh_token": "refresh_abcdef...",
      "token_type": "Bearer",
      "user": {
        "id": 1,
        "email": "user@example.com",
        "full_name": "Alex Developer",
        "firebase_uid": "firebase-uid-12345",
        "auth_provider": "google.com",
        "plan_id": "free",
        "specialization": null,
        "onboarding_step": "step1",
        "is_published": false
      }
    }
  }
  ```

---

## Protected Routes (Auth Required)

### 2. Fetch User Profile Details
Returns details for the authenticated user, including their onboarding progress step, profile data, custom domains, and live site details.
* **Method & Route:** `GET /users/me`
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "id": 1,
      "name": "Alex Developer",
      "email": "user@example.com",
      "plan_id": "free",
      "specialization": "developer",
      "onboarding_step": "step2",
      "profile": {
        "user_id": 1,
        "full_name": "Alex Developer",
        "professional_title": "Software Engineer",
        "bio": "Building things with Flutter."
      }
    }
  }
  ```

### 3. Update Specialization Track
Updates the user's specialization choice and advances their onboarding step to `step2`.
* **Method & Route:** `PATCH /users/me/specialization`
* **Request Body:**
  ```json
  {
    "specialization": "developer"
  }
  ```
  *(Allowed options: `developer`, `designer`, `photographer`, `writer`, `videographer`, `musician`, `marketer`, `consultant`)*
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "id": 1,
      "specialization": "developer",
      "onboarding_step": "step2"
    }
  }
  ```

### 4. Update Dynamic Profile
Persists dynamic fields from the details form and advances the user to `step3`.
* **Method & Route:** `PUT /users/me/profile`
* **Request Body:**
  ```json
  {
    "bio": "Full-Stack mobile engineer with 5 years experience.",
    "skills": ["Flutter", "Dart", "Laravel", "PHP"],
    "avatar_url": "https://example.com/avatar.png"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "bio": "Full-Stack mobile engineer...",
      "skills": ["Flutter", "Dart", "Laravel", "PHP"],
      "avatar_url": "https://example.com/avatar.png"
    }
  }
  ```

### 5. Fetch Specialization Schemas
Returns the list of specialization paths along with their associated field specifications so the client can construct screens dynamically.
* **Method & Route:** `GET /specializations`
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "developer",
        "name": "Developer",
        "fields": [
          {"name": "github_link", "type": "url", "required": false}
        ]
      }
    ]
  }
  ```

### 6. List Pricing Plans
Returns available tiers along with feature sets and limit descriptors.
* **Method & Route:** `GET /plans`
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "free",
        "name": "Free Plan",
        "price": "0.00",
        "limits": {
          "projects": 1,
          "custom_domain": false,
          "analytics": false
        }
      }
    ]
  }
  ```

### 7. Select Pricing Tier
Sets the selected plan and advances the onboarding status to `step4`.
* **Method & Route:** `PATCH /users/me/plan`
* **Request Body:**
  ```json
  {
    "plan_id": "pro"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "id": 1,
      "plan_id": "pro",
      "onboarding_step": "step4"
    }
  }
  ```

### 8. List Design Templates
Returns templates, preview pictures, and styling variables.
* **Method & Route:** `GET /templates`
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "minimal_dark",
        "name": "Minimal Dark",
        "config": {
          "bg": "#0F172A",
          "card": "rgba(255,255,255,0.03)"
        }
      }
    ]
  }
  ```

### 9. Select Layout Template
Updates the layout design theme inside portfolio settings and advances onboarding to `step5`.
* **Method & Route:** `PATCH /users/me/template`
* **Request Body:**
  ```json
  {
    "template_id": "minimal_dark"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "id": 1,
      "theme_settings": {
        "layout_template": "minimal_dark"
      }
    }
  }
  ```

### 10. Check Subdomain Availability
Checks whether a chosen subdomain slug is available to be reserved.
* **Method & Route:** `GET /domains/check?subdomain=alex`
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "available": true
  }
  ```

### 11. Trigger Site Generation / Publication
Enqueues a background job to assemble details, configure themes, and publish the portfolio site.
* **Method & Route:** `POST /publish`
* **Response (202 Accepted):**
  ```json
  {
    "success": true,
    "job_id": "893c5fd3-c4b5-4fd3-a621-abcdef123456",
    "status": "queued",
    "message": "Site compilation and deployment job enqueued."
  }
  ```
* **Validation Errors (400 Bad Request):**
  Returns field-level verification errors if they attempt to build without choosing a track or setting a domain:
  ```json
  {
    "success": false,
    "message": "Please configure your portfolio domain slug before publishing."
  }
  ```

### 12. Check Publish Progress (Polling)
Returns the live progress and status steps of site compilation.
* **Method & Route:** `GET /publish/{job_id}/status`
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "job_id": "893c5fd3-c4b5-4fd3-a621-abcdef123456",
      "status": "processing",
      "progress_percent": 50,
      "error_message": null,
      "started_at": "2026-07-13T13:06:50Z",
      "completed_at": null
    }
  }
  ```

### 13. Fetch Live Site URL
Returns live site URLs and generation metrics once complete.
* **Method & Route:** `GET /sites/me`
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "live_url": "http://127.0.0.1:8000/public/alex",
      "published_at": "2026-07-13T13:07:00Z",
      "last_updated_at": "2026-07-13T13:07:00Z"
    }
  }
  ```
