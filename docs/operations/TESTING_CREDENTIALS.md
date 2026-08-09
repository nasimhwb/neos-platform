# Staging & Automated Testing Credentials

This document provides testing credentials and guidelines for AI agents, developers, and automated browser suites running verification on the NEOS Platform staging environment.

---

## 1. Primary Testing Account Credentials

| Attribute | Value |
|---|---|
| **Staging Endpoint** | `https://test.neosfacility.com` |
| **User ID / Email** | `tester@neosfacility.com` |
| **Password** | `Neos1234!` |
| **Default Role** | `Admin` / `Staff` |

---

## 2. Environment Variables Configuration

The credentials are stored in `.env.local` (for Next.js runtime environment) using the following key definitions:

```env
STAGING_TEST_USER_EMAIL=tester@neosfacility.com
STAGING_TEST_USER_PASSWORD=Neos1234!
```

---

## 3. Instruction for AI Agents & Automated Test Suites

When conducting browser verification or automated DevTools inspections on `https://test.neosfacility.com`:

1. **Authentication Flow**:
   - Navigate to `https://test.neosfacility.com/login`.
   - Enter email: `tester@neosfacility.com`.
   - Enter password: `Neos1234!`.
   - Click **Sign In** and wait for session token assignment.

2. **Session Persistence**:
   - The browser session stores auth tokens in `localStorage` under `sb-test-neosfacility-auth-token` and cookie `neos_session_id`.
   - If redirected to `/login`, re-authenticate using `tester@neosfacility.com` / `Neos1234!`.

3. **Verification Protocol**:
   - Always record failed network calls (URL, Method, Status, Response payload).
   - Capture browser console logs to diagnose JavaScript exceptions.
   - Do NOT mark any module as Complete until both automated agent check AND user manual confirmation pass.
