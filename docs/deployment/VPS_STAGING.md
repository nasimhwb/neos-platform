# VPS Staging Deployment Guide

**Target Node:** Hostinger VPS (`200.97.161.179`)  
**Staging Endpoint:** `https://test.neosfacility.com`  
**Supabase Endpoint:** `https://supabase.neosfacility.com`  
**Repository Branch:** `feature/platform-dashboard`  

---

## 1. Quick Redeploy Command (Web Application Only)

To pull the latest code fix and rebuild the web application control center on the VPS without restarting PostgreSQL or core infrastructure:

```bash
cd /srv/neos/neos-platform
git pull origin feature/platform-dashboard
docker compose --env-file .env -f compose/compose.dashboard.yml build --no-cache dashboard
docker compose --env-file .env -f compose/compose.dashboard.yml up -d --no-deps dashboard
docker exec neos_dashboard printenv | grep SUPABASE
```

---

## 2. Full Stack Start & Status Check

```bash
cd /srv/neos/neos-platform
make up-apps
make doctor
```
