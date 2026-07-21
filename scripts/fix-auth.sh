#!/bin/bash
# ==============================================================================
# NEOS PLATFORM — PRODUCTION AUTH RECOVERY SCRIPT
# ==============================================================================
# Applies all fixes needed to restore authentication:
#   1. Creates missing PostgreSQL roles (02-supabase-compat.sql)
#   2. Restarts GoTrue to trigger auth schema migration
#   3. Applies app schema (client_profiles, roles, user_roles)
#   4. Backfills profiles for existing auth users
#   5. Validates final state
#
# Usage:
#   bash scripts/fix-auth.sh
#
# IMPORTANT: Run diagnose-auth.sh first and review the output before running this.
# ==============================================================================

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_DIR/.env"
COMPOSE_CMD="docker compose --env-file $ENV_FILE -f $REPO_DIR/compose/compose.supabase.yml"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  NEOS Platform — Auth Recovery Script${NC}"
echo -e "${CYAN}  $(date)${NC}"
echo -e "${CYAN}================================================================${NC}"

# Load env
if [ -f "$ENV_FILE" ]; then
  set -a; source <(tr -d '\r' < "$ENV_FILE"); set +a
  echo -e "${GREEN}[OK]${NC} .env loaded"
else
  echo -e "${RED}[FAIL]${NC} .env not found at $ENV_FILE. Aborting."
  exit 1
fi

# -----------------------------------------------------------------------
# STEP 1: Set passwords on roles (idempotent — uses env vars)
# -----------------------------------------------------------------------
echo ""
echo -e "${CYAN}--- Step 1: Setting role passwords from .env ---${NC}"

ADMIN_PASS="${POSTGRES_SUPABASE_ADMIN_PASSWORD:-change_this_admin_password_123}"
AUTH_PASS="${POSTGRES_AUTHENTICATOR_PASSWORD:-change_this_supabase_auth_password_in_prod}"

docker exec -t neos_postgres psql -U postgres <<SQL
  -- Update passwords (safe to re-run)
  DO \$\$
  BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname='supabase_admin') THEN
      ALTER ROLE supabase_admin WITH LOGIN PASSWORD '$ADMIN_PASS';
      RAISE NOTICE 'supabase_admin password updated';
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname='authenticator') THEN
      ALTER ROLE authenticator WITH LOGIN PASSWORD '$AUTH_PASS';
      RAISE NOTICE 'authenticator password updated';
    END IF;
  END
  \$\$;
SQL
echo -e "${GREEN}[OK]${NC} Passwords set on roles"

# -----------------------------------------------------------------------
# STEP 2: Apply supabase compatibility roles (02-supabase-compat.sql)
# -----------------------------------------------------------------------
echo ""
echo -e "${CYAN}--- Step 2: Applying Supabase compatibility roles ---${NC}"
COMPAT_SQL="$REPO_DIR/configs/postgres/init-scripts/02-supabase-compat.sql"
if [ -f "$COMPAT_SQL" ]; then
  docker exec -i neos_postgres psql -U postgres < "$COMPAT_SQL" 2>&1 | grep -v "^$" | head -40
  echo -e "${GREEN}[OK]${NC} Compatibility roles applied"
else
  echo -e "${RED}[FAIL]${NC} $COMPAT_SQL not found. Cannot continue."
  exit 1
fi

# -----------------------------------------------------------------------
# STEP 3: Restart GoTrue to run auth schema migrations
# -----------------------------------------------------------------------
echo ""
echo -e "${CYAN}--- Step 3: Restarting GoTrue to apply auth schema migrations ---${NC}"
$COMPOSE_CMD restart supabase-auth
echo "Waiting 15s for GoTrue migrations to complete..."
sleep 15

# Check GoTrue is healthy
for i in {1..6}; do
  health=$(docker exec neos_supabase_auth wget -qO- http://localhost:9999/health 2>/dev/null | grep -o '"status":"[^"]*"' | head -1 || echo "")
  if echo "$health" | grep -q "ok"; then
    echo -e "${GREEN}[OK]${NC} GoTrue is healthy"
    break
  fi
  echo "  Waiting for GoTrue... attempt $i/6"
  sleep 5
done

# Verify auth schema was created
AUTH_EXISTS=$(docker exec -t neos_postgres psql -U postgres -d postgres -tAc \
  "SELECT 1 FROM information_schema.schemata WHERE schema_name='auth';" 2>/dev/null | tr -d '[:space:]')
if [ "$AUTH_EXISTS" = "1" ]; then
  echo -e "${GREEN}[OK]${NC} auth schema exists"
else
  echo -e "${RED}[FAIL]${NC} auth schema still missing after GoTrue restart."
  echo "Check GoTrue logs: docker logs neos_supabase_auth --tail 50"
  exit 1
fi

# -----------------------------------------------------------------------
# STEP 4: Grant permissions on auth schema to required roles
# -----------------------------------------------------------------------
echo ""
echo -e "${CYAN}--- Step 4: Granting permissions on auth schema ---${NC}"
docker exec -t neos_postgres psql -U postgres -d postgres <<SQL
  GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role, authenticator, dashboard_user;
  GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_admin;
  ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth
    GRANT SELECT ON TABLES TO authenticated, anon, service_role;
SQL
echo -e "${GREEN}[OK]${NC} Auth schema permissions granted"

# -----------------------------------------------------------------------
# STEP 5: Apply app schema (client_profiles, roles, user_roles)
# -----------------------------------------------------------------------
echo ""
echo -e "${CYAN}--- Step 5: Applying application schema (03-app-schema.sql) ---${NC}"
APP_SQL="$REPO_DIR/configs/postgres/init-scripts/03-app-schema.sql"
if [ -f "$APP_SQL" ]; then
  docker exec -i neos_postgres psql -U postgres -d postgres < "$APP_SQL" 2>&1 | grep -v "^$" | head -60
  echo -e "${GREEN}[OK]${NC} App schema applied"
else
  echo -e "${RED}[FAIL]${NC} $APP_SQL not found."
  exit 1
fi

# -----------------------------------------------------------------------
# STEP 6: Restart PostgREST to reload schema cache
# -----------------------------------------------------------------------
echo ""
echo -e "${CYAN}--- Step 6: Restarting PostgREST to reload schema ---${NC}"
$COMPOSE_CMD restart supabase-rest
sleep 5
echo -e "${GREEN}[OK]${NC} PostgREST restarted"

# -----------------------------------------------------------------------
# STEP 7: Validation
# -----------------------------------------------------------------------
echo ""
echo -e "${CYAN}--- Step 7: Validation ---${NC}"

auth_users=$(docker exec -t neos_postgres psql -U postgres -d postgres -tAc \
  "SELECT count(*) FROM auth.users;" 2>/dev/null | tr -d '[:space:]')
echo -e "  auth.users count: $auth_users"

profiles=$(docker exec -t neos_postgres psql -U postgres -d postgres -tAc \
  "SELECT count(*) FROM public.client_profiles;" 2>/dev/null | tr -d '[:space:]')
echo -e "  client_profiles count: $profiles"

orphans=$(docker exec -t neos_postgres psql -U postgres -d postgres -tAc \
  "SELECT count(*) FROM auth.users u WHERE NOT EXISTS (SELECT 1 FROM public.client_profiles p WHERE p.id=u.id);" 2>/dev/null | tr -d '[:space:]')
if [ "$orphans" = "0" ]; then
  echo -e "  ${GREEN}[OK]${NC} All auth users have profiles"
else
  echo -e "  ${YELLOW}[WARN]${NC} $orphans users without profiles (backfill may need re-run)"
fi

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}  Auth recovery steps completed!${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify webapp SUPABASE_ANON_KEY matches JWT_SECRET in .env"
echo "  2. Import existing users from hosted Supabase (see audit report)"
echo "  3. Configure SMTP for password reset (add to .env and restart)"
echo "  4. Run: bash scripts/diagnose-auth.sh  (for final validation)"
