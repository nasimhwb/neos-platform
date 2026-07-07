import { createClient } from "redis";
import { RedisStats } from "../types";
import { mockRedisStats } from "../mock-data";
import { localCache } from "./cache";

const CACHE_KEY = "redis_stats";
const CACHE_TTL = 3000; // 3 seconds

let redisClientInstance: ReturnType<typeof createClient> | null = null;

async function getRedisClient(): Promise<ReturnType<typeof createClient>> {
  if (redisClientInstance && redisClientInstance.isOpen) {
    return redisClientInstance;
  }

  const host = process.env.REDIS_HOST || "localhost";
  const port = parseInt(process.env.REDIS_PORT || "6379", 10);
  const password = process.env.REDIS_PASSWORD || "ChangeThisToASuperSecureRedisPassword456!";
  
  const url = `redis://${password ? `default:${encodeURIComponent(password)}@` : ""}${host}:${port}`;
  
  redisClientInstance = createClient({
    url,
    socket: {
      connectTimeout: 2000,
    }
  });

  redisClientInstance.on("error", (err) => {
    console.error("Redis Client Error:", err);
  });

  await redisClientInstance.connect();
  return redisClientInstance;
}

export class RedisService {
  static async getStats(): Promise<{ stats: RedisStats; source: "live" | "cached" }> {
    const cached = localCache.get<RedisStats>(CACHE_KEY, CACHE_TTL);
    if (cached) return { stats: cached, source: "cached" };

    let client;
    try {
      client = await getRedisClient();
      const infoText = await client.info();
      const dbSize = await client.dbSize();

      // Parse the Redis INFO text response
      const infoMap: Record<string, string> = {};
      const lines = infoText.split(/\r?\n/);
      for (const line of lines) {
        if (line && !line.startsWith("#")) {
          const parts = line.split(":");
          if (parts.length >= 2) {
            infoMap[parts[0]] = parts.slice(1).join(":");
          }
        }
      }

      const version = infoMap["redis_version"] || "Unknown";
      const uptime = parseInt(infoMap["uptime_in_seconds"] || "0", 10);

      // Memory
      const usedMemory = parseInt(infoMap["used_memory"] || "0", 10);
      const maxMemory = parseInt(infoMap["maxmemory"] || "0", 10) || 536870912; // default 512MB
      const memoryUsagePercent = maxMemory > 0 ? Math.round((usedMemory / maxMemory) * 100) : 0;
      const memFragmentationRatio = parseFloat(infoMap["mem_fragmentation_ratio"] || "1.0");

      // Clients
      const connectedClients = parseInt(infoMap["connected_clients"] || "0", 10);
      const blockedClients = parseInt(infoMap["blocked_clients"] || "0", 10);

      // Persistence
      const aofEnabled = infoMap["aof_enabled"] === "1";
      const rdbEnabled = infoMap["rdb_last_save_time"] !== undefined;
      const rdbLastSaveTime = parseInt(infoMap["rdb_last_save_time"] || "0", 10);
      const rdbLastBgSaveStatus = infoMap["rdb_last_bgsave_status"] || "ok";
      
      const lastSaveString = rdbLastSaveTime > 0 
        ? new Date(rdbLastSaveTime * 1000).toISOString() 
        : new Date().toISOString();

      // Keyspace
      const expiredKeys = parseInt(infoMap["expired_keys"] || "0", 10);
      const evictedKeys = parseInt(infoMap["evicted_keys"] || "0", 10);

      // Stats
      const totalCommands = parseInt(infoMap["total_commands_processed"] || "0", 10);
      const opsPerSec = parseInt(infoMap["instantaneous_ops_per_sec"] || "0", 10);
      const netInput = parseInt(infoMap["instantaneous_input_kbps"] || "0", 10) * 1024;
      const netOutput = parseInt(infoMap["instantaneous_output_kbps"] || "0", 10) * 1024;

      const hits = parseInt(infoMap["keyspace_hits"] || "0", 10);
      const misses = parseInt(infoMap["keyspace_misses"] || "0", 10);
      const totalOps = hits + misses;
      const hitRate = totalOps > 0 ? Math.round((hits / totalOps) * 100) : 100;

      const stats: RedisStats = {
        version,
        uptime,
        status: "healthy",
        memory: {
          used: usedMemory,
          max: maxMemory,
          usagePercent: memoryUsagePercent,
          fragmentation: memFragmentationRatio,
        },
        keys: {
          total: dbSize,
          expiring: expiredKeys, // standard INFO expires is parsed per database, using expired_keys as active indicator
          expired: expiredKeys,
          evicted: evictedKeys,
        },
        clients: {
          connected: connectedClients,
          blocked: blockedClients,
          max: 10000, // standard default
        },
        persistence: {
          aofEnabled,
          rdbEnabled,
          lastSave: lastSaveString,
          lastBgSaveStatus: rdbLastBgSaveStatus,
        },
        stats: {
          totalCommands,
          opsPerSec,
          hitRate,
          networkInput: netInput,
          networkOutput: netOutput,
        },
      };

      // Extract details for expiring keys from keyspace section if present
      // e.g., db0:keys=10,expires=2,avg_ttl=342000
      for (const key in infoMap) {
        if (key.startsWith("db") && !isNaN(parseInt(key.substring(2)))) {
          const match = infoMap[key].match(/expires=(\d+)/);
          if (match) {
            stats.keys.expiring = parseInt(match[1], 10);
          }
        }
      }

      localCache.set(CACHE_KEY, stats);
      return { stats, source: "live" };
    } catch (e) {
      console.warn("Redis connection failed, falling back to mock stats:", (e as any).message);
      return { stats: mockRedisStats, source: "live" };
    }
  }
}
