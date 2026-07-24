import { NextRequest, NextResponse } from "next/server";
import { Pool } from "pg";

let poolInstance: Pool | null = null;

function getPool(): Pool {
  if (poolInstance) return poolInstance;
  const host = process.env.POSTGRES_HOST || "localhost";
  const port = parseInt(process.env.POSTGRES_PORT || "6432", 10);
  const user = process.env.POSTGRES_SUPERUSER || "postgres";
  const password = process.env.POSTGRES_SUPERUSER_PASSWORD || "ChangeThisToASuperSecurePostgresSuperuserAdminPassword123!";
  const database = "postgres";

  poolInstance = new Pool({
    host,
    port,
    user,
    password,
    database,
    connectionTimeoutMillis: 5000,
  });
  return poolInstance;
}

export async function GET(request: NextRequest) {
  const pool = getPool();
  let client;

  try {
    client = await pool.connect();

    // 1. Count auth.users
    const countUsersRes = await client.query("SELECT count(*) as count FROM auth.users;");
    const countUsers = countUsersRes.rows[0]?.count;

    // 2. Count auth.identities
    const countIdentitiesRes = await client.query("SELECT count(*) as count FROM auth.identities;");
    const countIdentities = countIdentitiesRes.rows[0]?.count;

    // 3. List users missing auth.identities
    const missingIdentitiesRes = await client.query(
      "SELECT u.id, u.email, u.created_at FROM auth.users u WHERE NOT EXISTS (SELECT 1 FROM auth.identities i WHERE i.user_id = u.id) LIMIT 20;"
    );

    // 4. Verify instance_id
    const instanceIdRes = await client.query(
      "SELECT instance_id, count(*) as count FROM auth.users GROUP BY instance_id;"
    );

    // 5. Verify aud
    const audRes = await client.query(
      "SELECT aud, count(*) as count FROM auth.users GROUP BY aud;"
    );

    // 6. Verify role
    const roleRes = await client.query(
      "SELECT role, count(*) as count FROM auth.users GROUP BY role;"
    );

    // 7. Verify raw_app_meta_data
    const appMetaDataRes = await client.query(
      "SELECT id, email, raw_app_meta_data FROM auth.users LIMIT 10;"
    );

    // 8. Verify public.profiles exists
    const profilesExistRes = await client.query(
      "SELECT table_schema, table_name, table_type FROM information_schema.tables WHERE table_name = 'profiles';"
    );

    // 9. Show GRANTS on public.profiles
    const grantsRes = await client.query(
      "SELECT grantee, privilege_type FROM information_schema.role_table_grants WHERE table_name = 'profiles' OR table_name = 'client_profiles';"
    );

    // 10. Show RLS policies on public.client_profiles and public.profiles
    const policiesRes = await client.query(
      "SELECT schemaname, tablename, policyname, roles, cmd, qual, with_check FROM pg_policies WHERE tablename IN ('client_profiles', 'profiles');"
    );

    return NextResponse.json({
      phase1_evidence: {
        "1_count_auth_users": countUsers,
        "2_count_auth_identities": countIdentities,
        "3_users_missing_identities": missingIdentitiesRes.rows,
        "4_instance_id_distribution": instanceIdRes.rows,
        "5_aud_distribution": audRes.rows,
        "6_role_distribution": roleRes.rows,
        "7_raw_app_meta_data_sample": appMetaDataRes.rows,
        "8_public_profiles_table_type": profilesExistRes.rows,
        "9_table_grants": grantsRes.rows,
        "10_rls_policies": policiesRes.rows,
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: "Database query failed", message: error.message, stack: error.stack },
      { status: 500 }
    );
  } finally {
    if (client) client.release();
  }
}
