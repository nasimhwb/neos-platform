import http from "http";
import os from "os";
import { DockerStatus, DockerContainer, DockerNetwork, DockerVolume, DockerImage } from "../types";
import { mockDockerStatus, mockContainers, mockNetworks, mockVolumes } from "../mock-data";
import { localCache } from "./cache";

const CACHE_KEY_PREFIX = "docker_";
const CACHE_TTL_SHORT = 2000; // 2 seconds
const CACHE_TTL_LONG = 5000;  // 5 seconds

export class DockerService {
  private static isWindows = os.platform() === "win32";
  private static socketPath = os.platform() === "win32" ? "\\\\.\\pipe\\docker_engine" : "/var/run/docker.sock";

  private static request(path: string, method: "GET" | "POST" = "GET", postData?: string): Promise<any> {
    return new Promise((resolve, reject) => {
      const options = {
        socketPath: this.socketPath,
        path,
        method,
        headers: {
          "Host": "docker",
          ...(postData ? { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(postData) } : {})
        }
      };

      const req = http.request(options, (res) => {
        let data = "";
        res.on("data", chunk => data += chunk);
        res.on("end", () => {
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            try {
              resolve(data ? JSON.parse(data) : true);
            } catch (e) {
              resolve(data); // If not JSON, return raw string
            }
          } else {
            reject(new Error(`Docker API returned status code ${res.statusCode}: ${data}`));
          }
        });
      });

      req.on("error", (err) => {
        reject(err);
      });

      if (postData) {
        req.write(postData);
      }
      req.end();
    });
  }

  static async getDockerStatus(): Promise<{ status: DockerStatus; source: "live" | "cached" }> {
    const cacheKey = `${CACHE_KEY_PREFIX}status`;
    const cached = localCache.get<DockerStatus>(cacheKey, CACHE_TTL_SHORT);
    if (cached) return { status: cached, source: "cached" };

    try {
      const versionInfo = await this.request("/v1.41/version");
      const systemInfo = await this.request("/v1.41/info");
      
      const status: DockerStatus = {
        version: versionInfo.Version || "Unknown",
        containers: {
          total: systemInfo.Containers || 0,
          running: systemInfo.ContainersRunning || 0,
          stopped: systemInfo.ContainersStopped || 0,
          paused: systemInfo.ContainersPaused || 0,
        },
        images: systemInfo.Images || 0,
        networks: mockDockerStatus.networks, // Fallback if listing needed
        volumes: mockDockerStatus.volumes,   // Fallback if listing needed
        serverTime: new Date().toISOString(),
      };

      try {
        const nets = await this.request("/v1.41/networks");
        status.networks = nets.length;
      } catch {}

      try {
        const vols = await this.request("/v1.41/volumes");
        status.volumes = vols.Volumes ? vols.Volumes.length : 0;
      } catch {}

      localCache.set(cacheKey, status);
      return { status, source: "live" };
    } catch (e) {
      if (process.env.ENVIRONMENT === "production" || process.env.NODE_ENV === "production") {
        throw e;
      }
      console.warn("Docker socket not accessible, falling back to mock status:", (e as any).message);
      return { status: mockDockerStatus, source: "live" };
    }
  }

  static async getContainers(): Promise<{ containers: DockerContainer[]; source: "live" | "cached" }> {
    const cacheKey = `${CACHE_KEY_PREFIX}containers`;
    const cached = localCache.get<DockerContainer[]>(cacheKey, CACHE_TTL_SHORT);
    if (cached) return { containers: cached, source: "cached" };

    try {
      const rawContainers = await this.request("/v1.41/containers/json?all=1");
      const containers: DockerContainer[] = [];

      for (const raw of rawContainers) {
        const ports = (raw.Ports || []).map((p: any) => 
          p.PublicPort ? `${p.IP || "0.0.0.0"}:${p.PublicPort}->${p.PrivatePort}/${p.Type}` : `${p.PrivatePort}/${p.Type}`
        );

        let cpuUsage = 0;
        let memoryUsage = 0;
        let memoryLimit = 0;

        // Fetch container stats in a short non-blocking way, or read from cache
        if (raw.State === "running") {
          const statsKey = `${CACHE_KEY_PREFIX}stats_${raw.Id}`;
          const cachedStats = localCache.get<{ cpu: number; mem: number; limit: number }>(statsKey, CACHE_TTL_LONG);
          
          if (cachedStats) {
            cpuUsage = cachedStats.cpu;
            memoryUsage = cachedStats.mem;
            memoryLimit = cachedStats.limit;
          } else {
            // Retrieve stats asynchronously. To prevent slow requests, we fire and cache it for the next poll
            this.request(`/v1.41/containers/${raw.Id}/stats?stream=false`)
              .then((stats) => {
                let calculatedCpu = 0;
                let calculatedMem = 0;
                let limit = 0;
                
                if (stats.cpu_stats && stats.precpu_stats) {
                  const cpuDelta = stats.cpu_stats.cpu_usage.total_usage - stats.precpu_stats.cpu_usage.total_usage;
                  const systemDelta = stats.cpu_stats.system_cpu_usage - stats.precpu_stats.system_cpu_usage;
                  const numCpus = stats.cpu_stats.online_cpus || 1;
                  if (systemDelta > 0 && cpuDelta > 0) {
                    calculatedCpu = (cpuDelta / systemDelta) * numCpus * 100;
                  }
                }
                
                if (stats.memory_stats) {
                  calculatedMem = stats.memory_stats.usage || 0;
                  limit = stats.memory_stats.limit || 0;
                }

                localCache.set(statsKey, { cpu: calculatedCpu, mem: calculatedMem, limit });
              })
              .catch(() => {});
          }
        }

        containers.push({
          id: raw.Id.substring(0, 12),
          name: (raw.Names || ["/unknown"])[0].replace(/^\//, ""),
          image: raw.Image,
          state: raw.State as any,
          status: raw.Status,
          created: new Date(raw.Created * 1000).toISOString(),
          ports,
          networks: Object.keys(raw.NetworkSettings?.Networks || {}),
          cpuUsage: Math.round(cpuUsage * 10) / 10,
          memoryUsage,
          memoryLimit,
          labels: raw.Labels || {},
        });
      }

      localCache.set(cacheKey, containers);
      return { containers, source: "live" };
    } catch (e) {
      if (process.env.ENVIRONMENT === "production" || process.env.NODE_ENV === "production") {
        throw e;
      }
      console.warn("Docker socket not accessible, falling back to mock containers:", (e as any).message);
      return { containers: mockContainers, source: "live" };
    }
  }

  static async getNetworks(): Promise<{ networks: DockerNetwork[]; source: "live" | "cached" }> {
    const cacheKey = `${CACHE_KEY_PREFIX}networks`;
    const cached = localCache.get<DockerNetwork[]>(cacheKey, CACHE_TTL_LONG);
    if (cached) return { networks: cached, source: "cached" };

    try {
      const rawNetworks = await this.request("/v1.41/networks");
      const networks: DockerNetwork[] = rawNetworks.map((raw: any) => ({
        id: raw.Id.substring(0, 12),
        name: raw.Name,
        driver: raw.Driver,
        scope: raw.Scope,
        subnet: raw.IPAM?.Config?.[0]?.Subnet || "—",
        gateway: raw.IPAM?.Config?.[0]?.Gateway || "—",
        containers: Object.keys(raw.Containers || {}).length,
      }));

      localCache.set(cacheKey, networks);
      return { networks, source: "live" };
    } catch (e) {
      if (process.env.ENVIRONMENT === "production" || process.env.NODE_ENV === "production") {
        throw e;
      }
      return { networks: mockNetworks, source: "live" };
    }
  }

  static async getVolumes(): Promise<{ volumes: DockerVolume[]; source: "live" | "cached" }> {
    const cacheKey = `${CACHE_KEY_PREFIX}volumes`;
    const cached = localCache.get<DockerVolume[]>(cacheKey, CACHE_TTL_LONG);
    if (cached) return { volumes: cached, source: "cached" };

    try {
      const rawVols = await this.request("/v1.41/volumes");
      const list = rawVols.Volumes || [];
      const volumes: DockerVolume[] = list.map((raw: any) => ({
        name: raw.Name,
        driver: raw.Driver,
        mountpoint: raw.Mountpoint,
        usageBytes: 0, // Not easily exposed without extra query
        labels: raw.Labels || {},
      }));

      localCache.set(cacheKey, volumes);
      return { volumes, source: "live" };
    } catch (e) {
      if (process.env.ENVIRONMENT === "production" || process.env.NODE_ENV === "production") {
        throw e;
      }
      return { volumes: mockVolumes, source: "live" };
    }
  }

  static async restartContainer(id: string): Promise<boolean> {
    try {
      await this.request(`/v1.41/containers/${id}/restart`, "POST");
      return true;
    } catch (e) {
      console.error(`Failed to restart container ${id}:`, e);
      return false;
    }
  }

  static async getContainerLogs(id: string, limit = 100): Promise<string> {
    try {
      const options = {
        socketPath: this.socketPath,
        path: `/v1.41/containers/${id}/logs?stdout=true&stderr=true&tail=${limit}&timestamps=true`,
        method: "GET",
        headers: { "Host": "docker" }
      };

      return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
          const chunks: Buffer[] = [];
          res.on("data", chunk => chunks.push(chunk));
          res.on("end", () => {
            if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
              const fullBuffer = Buffer.concat(chunks);
              resolve(this.parseDockerLogs(fullBuffer));
            } else {
              reject(new Error(`Docker log API returned status code ${res.statusCode}`));
            }
          });
        });
        req.on("error", reject);
        req.end();
      });
    } catch (e) {
      return `Failed to fetch logs for container ${id}: ${(e as any).message}`;
    }
  }

  private static parseDockerLogs(buffer: Buffer): string {
    let offset = 0;
    let logText = "";
    while (offset < buffer.length) {
      if (offset + 8 > buffer.length) break;
      const size = buffer.readUInt32BE(offset + 4);
      offset += 8;
      if (offset + size > buffer.length) break;
      const chunk = buffer.toString("utf8", offset, offset + size);
      logText += chunk;
      offset += size;
    }
    return logText || buffer.toString("utf8"); // Fallback if logs aren't frame multiplexed
  }
}
