# NEOS Platform Dashboard Operations Runbook

This document details the configuration, deployment, troubleshooting, and maintenance of the NEOS Platform Dashboard.

## Project Setup & Configuration

The Dashboard is written in Next.js 15 and is located in the `dashboard/` directory.

### Environment Variables

The dashboard requires configuration via environment variables specified in `.env` (derived from `.env.example` in the repository root):

| Variable | Description | Default |
|---|---|---|
| `NEXT_PUBLIC_PLATFORM_NAME` | Name displayed in the header and title. | `NEOS Platform` |
| `BASE_DOMAIN` | The target domain for proxy routing. | `neos-platform.local` |
| `DASHBOARD_SECRET` | Secret key used for session encryption. | (Generate a random 32+ char key) |
| `DASHBOARD_DB_PASSWORD` | Password for PostgreSQL dashboard access. | (Secured database password) |

---

## Local Development

To run the dashboard in development mode on your host machine:

1. Navigate to the `dashboard/` folder:
   ```bash
   cd dashboard/
   ```
2. Install npm dependencies:
   ```bash
   npm install
   ```
3. Start the Next.js development server:
   ```bash
   npm run dev
   ```
4. Access the dashboard via [http://localhost:3000](http://localhost:3000).

---

## Production Deployment

The dashboard is integrated into the NEOS Docker Compose orchestration stack (`compose/compose.dashboard.yml`).

### Deploying the Dashboard

To build the Next.js production bundle and launch the container on the VPS:
```bash
make up-dashboard
```

This target compiles the Next.js application in standalone mode, builds the `neos_dashboard:latest` Docker image, and starts the container behind the Traefik proxy.

The Traefik router maps incoming HTTPS traffic on:
`https://dashboard.neos-platform.local` (or your configured `BASE_DOMAIN`) to the dashboard service container on port 3000.

---

## Troubleshooting

### Redirect Loops
If you experience a redirect loop when accessing `/`, verify that `/app/page.tsx` correctly redirects to `/applications` instead of `/` or `(dashboard)/`.

### Style/Tailwind Compile Failures
The project uses Tailwind CSS v4. Custom theme configurations must be specified in `app/globals.css` using the `@theme` block. Avoid declaring duplicate CSS variables in standard classes if they clash with Tailwind compiler candidates.

### Container Crash or Unhealthy State
If the container health check fails:
1. View logs for the container:
   ```bash
   docker logs neos_dashboard
   ```
2. Ensure environment variables are correctly populated in the `.env` file at the root of the repository.
