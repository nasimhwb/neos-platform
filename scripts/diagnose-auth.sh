#!/bin/bash
# ==============================================================================
# NEOS PLATFORM — PRODUCTION DIAGNOSTIC SCRIPT
# ==============================================================================
# Run this from the VPS terminal to get a complete picture of the auth stack.
#
# Usage:
#   bash scripts/diagnose-auth.sh
#
# Output: Prints a full diagnostic report to stdout.
# ==============================================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_DIR/.env"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS="${GREEN}[PASS]${NC}"; FAIL="${RED}[FAIL]${NC}"; WARN="${YELLOW}[WARN]${NC}"

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  NEOS Platform — Auth Stack Diagnostic Report${NC}"
echo -e "${CYAN}  $(date)${NC}"
echo -e "${CYAN}================================================================${NC}"

# Load env
if [ -f "$ENV_FILE" ]; then
  set -a; source <(tr -d '\r' < "$ENV_FILE"); set +a
  echo -e "${PASS} .env loaded from $ENV_FILE"
else
  echo -e "${WARN} .env not found at $ENV_FILE — using container defaults"
fi

echo ""
echo -e "${CYAN}--- 1. Container Status ---${NC}"
for container in neos_postgres neos_supabase_auth neos_supabase_rest neos_supabase_gateway neos_supabase_realtime neos_supabase_storage; do
  status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not found")
  health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no healthcheck{{end}}' "$container" 2>/dev/null || echo "n/a")
  if [ "$status" = "running" ]; then
    echo -e "  ${PASS} $container — status: $status, health: $health"
  else
    echo -e "  ${FAIL} $container — status: $status"
  fi
done

echo ""
echo -e "${CYAN}--- 2. PostgreSQL Databases ---${NC}"
docker exec neos_postgres psql -U postgres -tAc \
  "SELECT datname FROM pg_database WHERE datistemplate=false ORDER BY datname;" 2>/dev/null | \
  while read -r db; do echo "  database: $db"; done

echo ""
echo -e "${CYAN}--- 3. Required Supabase Roles ---${NC}"
for role in anon authenticated service_role authenticator supabase_admin supabase_auth_admin; do
  exists=$(docker exec neos_postgres psql -U postgres -tAc \
    "SELECT 1 FROM pg_roles WHERE rolname='$role';" 2>/dev/null | tr -d '[:space:]')
  if [ "$exists" = "1" ]; then
    echo -e "  ${PASS} Role '$role' exists"
  else
    echo -e "  ${FAIL} Role '$role' MISSING — run 02-supabase-compat.sql"
  fi
done

echo ""
echo -e "${CYAN}--- 4. Auth Schema & Tables ---${NC}"
auth_schema=$(docker exec neos_postgres psql -U postgres -d postgres -tAc \
  "SELECT 1 FROM information_schema.schemata WHERE schema_name='auth';" 2>/dev/null | tr -d '[:space:]')
if [ "$auth_schema" = "1" ]; then
  echo -e "  ${PASS} auth schema exists"
  auth_count=$(docker exec neos_postgres psql -U postgres -d postgres -tAc \
    "SELECT count(*) FROM auth.users;" 2>/dev/null | tr -d '[:space:]')
  echo -e "  ${PASS} auth.users count: $auth_count"
  echo ""
  echo "  Recent auth.users (last 10):"
  docker exec neos_postgres psql -U postgres -d postgres -c \
    "SELECT id, email, confirmed_at IS NOT NULL AS confirmed, created_at FROM auth.users ORDER BY created_at DESC LIMIT 10;" 2>/dev/null
else
  echo -e "  ${FAIL} auth schema MISSING — GoTrue has not run migrations yet"
  echo -e "       → Start GoTrue container and check logs"
fi

echo ""
echo -e "${CYAN}--- 5. Application Tables (public schema) ---${NC}"
tables=$(docker exec neos_postgres psql -U postgres -d postgres -tAc \
  "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;" 2>/dev/null)
if [ -z "$tables" ]; then
  echo -e "  ${FAIL} No tables in public schema — run 03-app-schema.sql"
else
  echo "$tables" | while read -r t; do
    if [ -n "$t" ]; then
      cnt=$(docker exec neos_postgres psql -U postgres -d postgres -tAc \
        "SELECT count(*) FROM public.$t;" 2>/dev/null | tr -d '[:space:]')
      echo -e "  ${PASS} public.$t (rows: $cnt)"
    fi
  done
fi

# Check client_profiles specifically
cp_exists=$(docker exec neos_postgres psql -U postgres -d postgres -tAc \
  "SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='client_profiles';" 2>/dev/null | tr -d '[:space:]')
if [ "$cp_exists" != "1" ]; then
  echo -e "  ${FAIL} public.client_profiles MISSING — run 03-app-schema.sql"
fi

echo ""
echo -e "${CYAN}--- 6. Profile ↔ Auth User Sync ---${NC}"
if [ "$auth_schema" = "1" ] && [ "$cp_exists" = "1" ]; then
  orphan_auth=$(docker exec neos_postgres psql -U postgres -d postgres -tAc \
    "SELECT count(*) FROM auth.users u WHERE NOT EXISTS (SELECT 1 FROM public.client_profiles p WHERE p.id = u.id);" 2>/dev/null | tr -d '[:space:]')
  orphan_profile=$(docker exec neos_postgres psql -U postgres -d postgres -tAc \
    "SELECT count(*) FROM public.client_profiles p WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p.id);" 2>/dev/null | tr -d '[:space:]')
  if [ "$orphan_auth" = "0" ]; then
    echo -e "  ${PASS} All auth.users have a client_profiles row"
  else
    echo -e "  ${FAIL} $orphan_auth auth.users missing a client_profiles row — run backfill in 03-app-schema.sql"
  fi
  if [ "$orphan_profile" != "0" ]; then
    echo -e "  ${WARN} $orphan_profile client_profiles rows with no auth.users match (orphaned profiles)"
  fi
fi

echo ""
echo -e "${CYAN}--- 7. GoTrue Environment (Key Settings) ---${NC}"
docker inspect neos_supabase_auth --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | \
  grep -E "^(GOTRUE_DATABASE_URL|GOTRUE_SITE_URL|GOTRUE_URI_ALLOW_LIST|API_EXTERNAL_URL|GOTRUE_JWT_SECRET|GOTRUE_MAILER_AUTOCONFIRM|GOTRUE_SMTP_HOST)" | \
  while IFS='=' read -r key val; do
    if [[ "$key" == *"SECRET"* ]] || [[ "$key" == *"PASS"* ]]; then
      echo "  $key=[REDACTED]"
    else
      echo "  $key=$val"
    fi
  done

echo ""
echo -e "${CYAN}--- 8. GoTrue Logs (last 20 lines) ---${NC}"
docker logs neos_supabase_auth --tail 20 2>&1 | sed 's/^/  /'

echo ""
echo -e "${CYAN}--- 9. PostgREST Logs (last 20 lines) ---${NC}"
docker logs neos_supabase_rest --tail 20 2>&1 | sed 's/^/  /'

echo ""
echo -e "${CYAN}--- 10. GoTrue Health Endpoint ---${NC}"
gotrue_health=$(docker exec neos_supabase_auth wget -qO- http://localhost:9999/health 2>/dev/null || echo "UNREACHABLE")
echo "  Response: $gotrue_health"

echo ""
echo -e "${CYAN}--- 11. JWT Secret Status ---${NC}"
jwt_in_env=$(grep -s "^JWT_SECRET=" "$ENV_FILE" | cut -d= -f2-)
if [ -n "$jwt_in_env" ]; then
  echo -e "  ${PASS} JWT_SECRET is set in .env (length: ${#jwt_in_env} chars)"
  echo -e "  ${WARN} IMPORTANT: Verify webapp SUPABASE_ANON_KEY was generated from THIS secret"
  echo -e "  ${WARN} If keys don't match, ALL PostgREST calls will return 401"
else
  echo -e "  ${FAIL} JWT_SECRET not found in .env — all auth is broken"
fi

anon_key=$(grep -s "^SUPABASE_ANON_KEY=" "$ENV_FILE" | cut -d= -f2-)
svc_key=$(grep -s "^SUPABASE_SERVICE_KEY=" "$ENV_FILE" | cut -d= -f2-)
if [ -n "$anon_key" ]; then
  echo -e "  ${PASS} SUPABASE_ANON_KEY is set in .env"
else
  echo -e "  ${WARN} SUPABASE_ANON_KEY not in .env — webapp may be using wrong key"
fi

echo ""
echo -e "${CYAN}--- 12. SMTP Configuration ---${NC}"
smtp_host=$(grep -s "^SMTP_HOST=" "$ENV_FILE" | cut -d= -f2-)
smtp_user=$(grep -s "^SMTP_USER=" "$ENV_FILE" | cut -d= -f2-)
smtp_pass=$(grep -s "^SMTP_PASS=" "$ENV_FILE" | cut -d= -f2-)
if [ -z "$smtp_host" ] || [ "$smtp_pass" = "SG.placeholder_password_for_prod_gotrue" ]; then
  echo -e "  ${FAIL} SMTP not configured — password reset and OTP will NOT work"
  echo -e "       → Set SMTP_HOST, SMTP_USER, SMTP_PASS in .env"
else
  echo -e "  ${PASS} SMTP host: $smtp_host, user: $smtp_user"
fi

echo ""
echo -e "${CYAN}--- 13. AI / Gemini API Configuration ---${NC}"
gemini_key=$(grep -s "^GEMINI_API_KEY=" "$ENV_FILE" | cut -d= -f2-)
groq_key=$(grep -s "^GROQ_API_KEY=" "$ENV_FILE" | cut -d= -f2-)

if [ -n "$gemini_key" ] && [ "$gemini_key" != "AIzaSy_placeholder_key_here" ]; then
  echo -e "  ${PASS} GEMINI_API_KEY is set in .env (active keys: $(echo "$gemini_key" | tr ',' '\n' | wc -l))"
else
  echo -e "  ${WARN} GEMINI_API_KEY missing or placeholder in .env"
  echo -e "       → AI Copilot, Dev Prompt generator, and Error analyzer will use Groq or fallback"
fi

if [ -n "$groq_key" ] && [ "$groq_key" != "gsk_placeholder_key_here" ]; then
  echo -e "  ${PASS} GROQ_API_KEY is set in .env (fallback provider active)"
else
  echo -e "  ${WARN} GROQ_API_KEY missing or placeholder in .env"
fi

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  Diagnostic complete. Review FAILs and WARNs above.${NC}"
echo -e "${CYAN}================================================================${NC}"

