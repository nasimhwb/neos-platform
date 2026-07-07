import { Pool } from "pg";

export interface PgBouncerStats {
  pools: any[];
  stats: any[];
  clients: any[];
  status: "healthy" | "unhealthy";
}

export class PgBouncerService {
  static async getStats(): Promise<PgBouncerStats> {
    const host = process.env.POSTGRES_HOST || "localhost";
    const port = parseInt(process.env.POSTGRES_PORT || "6432", 10);
    const user = process.env.POSTGRES_SUPERUSER || "postgres";
    const password = process.env.POSTGRES_SUPERUSER_PASSWORD || "ChangeThisToASuperSecurePostgresSuperuserAdminPassword123!";
    
    // Connect to the virtual administration database 'pgbouncer'
    const pool = new Pool({
      host,
      port,
      user,
      password,
      database: "pgbouncer",
      connectionTimeoutMillis: 2000,
    });

    let client;
    try {
      client = await pool.connect();
      
      const poolsRes = await client.query("SHOW POOLS;");
      const statsRes = await client.query("SHOW STATS;");
      const clientsRes = await client.query("SHOW CLIENTS;");

      return {
        pools: poolsRes.rows,
        stats: statsRes.rows,
        clients: clientsRes.rows,
        status: "healthy"
      };
    } catch (e: any) {
      console.warn("PgBouncer connection failed, returning fallback mock stats:", e.message);
      return {
        pools: [
          { database: "postgres", user: "postgres", cl_active: 2, cl_waiting: 0, sv_active: 1, sv_idle: 1, pool_mode: "transaction" },
          { database: "neos_erp", user: "erp_user", cl_active: 8, cl_waiting: 0, sv_active: 4, sv_idle: 2, pool_mode: "transaction" },
          { database: "neos_crm", user: "crm_user", cl_active: 3, cl_waiting: 0, sv_active: 2, sv_idle: 1, pool_mode: "transaction" }
        ],
        stats: [
          { database: "postgres", total_query_count: 1450, total_query_time: 254200, total_received: 1045200, total_sent: 5450200 },
          { database: "neos_erp", total_query_count: 8200, total_query_time: 412000, total_received: 4504100, total_sent: 12542000 }
        ],
        clients: [
          { link: "client", user: "postgres", database: "postgres", state: "active", addr: "127.0.0.1", port: 54321 }
        ],
        status: "unhealthy" // Reflect offline state for SRE health check if connection failed
      };
    } finally {
      await pool.end();
    }
  }
}
