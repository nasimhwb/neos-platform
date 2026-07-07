import os from "os";
import { exec } from "child_process";
import { SystemMetrics } from "../types";
import { mockSystemMetrics } from "../mock-data";
import { localCache } from "./cache";

const CACHE_KEY = "system_metrics";
const CACHE_TTL = 3000; // 3 seconds

export class SystemService {
  private static lastCpuTime = { idle: 0, total: 0 };
  private static lastNetworkBytes = { rx: 0, tx: 0, time: 0 };

  private static execPromise(command: string): Promise<string> {
    return new Promise((resolve) => {
      exec(command, (error, stdout) => {
        if (error) resolve("");
        else resolve(stdout.trim());
      });
    });
  }

  private static getCpuUsage(): number {
    const cpus = os.cpus();
    let idle = 0;
    let total = 0;
    
    for (const cpu of cpus) {
      for (const type in cpu.times) {
        total += (cpu.times as any)[type];
      }
      idle += cpu.times.idle;
    }
    
    const idleDiff = idle - this.lastCpuTime.idle;
    const totalDiff = total - this.lastCpuTime.total;
    let usage = 0;
    
    if (totalDiff > 0) {
      usage = Math.round((1 - idleDiff / totalDiff) * 100);
    }
    
    this.lastCpuTime = { idle, total };
    return Math.max(0, Math.min(100, usage));
  }

  static async getMetrics(): Promise<{ metrics: SystemMetrics; source: "live" | "cached" }> {
    const cached = localCache.get<SystemMetrics>(CACHE_KEY, CACHE_TTL);
    if (cached) {
      return { metrics: cached, source: "cached" };
    }

    try {
      const isLinux = os.platform() === "linux";
      
      // 1. Host information
      const hostname = os.hostname();
      const platformOS = `${os.type()} ${os.arch()} ${os.release()}`;
      let kernel = os.release();
      let ubuntuVersion = "N/A";
      
      if (isLinux) {
        const kernelInfo = await this.execPromise("uname -r");
        if (kernelInfo) kernel = kernelInfo;
        
        const osRelease = await this.execPromise("cat /etc/os-release");
        const prettyNameMatch = osRelease.match(/PRETTY_NAME="([^"]+)"/);
        if (prettyNameMatch) {
          ubuntuVersion = prettyNameMatch[1];
        }
      } else {
        ubuntuVersion = `Windows ${os.release()}`;
      }

      // 2. CPU Details
      const cpuCores = os.cpus().length;
      const cpuModel = os.cpus()[0]?.model || "Unknown CPU";
      const cpuUsage = this.getCpuUsage();

      // 3. CPU Temperature (Linux only)
      let cpuTemp: number | undefined = undefined;
      if (isLinux) {
        const tempRaw = await this.execPromise("cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null");
        if (tempRaw) {
          cpuTemp = parseFloat(tempRaw) / 1000;
        }
      }

      // 4. Memory
      const totalMem = os.totalmem();
      const freeMem = os.freemem();
      const usedMem = totalMem - freeMem;
      const memoryUsagePercent = Math.round((usedMem / totalMem) * 100);

      // 5. Swap Memory
      let swapTotal = 0;
      let swapUsed = 0;
      let swapFree = 0;
      let swapUsagePercent = 0;
      
      if (isLinux) {
        const meminfo = await this.execPromise("cat /proc/meminfo");
        const totalMatch = meminfo.match(/SwapTotal:\s+(\d+)\s+kB/);
        const freeMatch = meminfo.match(/SwapFree:\s+(\d+)\s+kB/);
        if (totalMatch && freeMatch) {
          swapTotal = parseInt(totalMatch[1], 10) * 1024;
          swapFree = parseInt(freeMatch[1], 10) * 1024;
          swapUsed = swapTotal - swapFree;
          swapUsagePercent = swapTotal > 0 ? Math.round((swapUsed / swapTotal) * 100) : 0;
        }
      }

      // 6. Disk Usage
      let diskTotal = 0;
      let diskUsed = 0;
      let diskFree = 0;
      let diskUsagePercent = 0;
      let mountPoint = "/";

      if (isLinux) {
        const dfOutput = await this.execPromise("df -B1 /");
        const lines = dfOutput.split("\n");
        if (lines.length > 1) {
          const parts = lines[1].split(/\s+/);
          diskTotal = parseInt(parts[1], 10);
          diskUsed = parseInt(parts[2], 10);
          diskFree = parseInt(parts[3], 10);
          diskUsagePercent = Math.round((diskUsed / diskTotal) * 100);
          mountPoint = parts[5] || "/";
        }
      } else {
        // Windows fallback disk
        const wmicDisk = await this.execPromise("wmic logicaldisk where \"DeviceID='C:'\" get Size,FreeSpace /value");
        const sizeMatch = wmicDisk.match(/Size=(\d+)/);
        const freeMatch = wmicDisk.match(/FreeSpace=(\d+)/);
        if (sizeMatch && freeMatch) {
          diskTotal = parseInt(sizeMatch[1], 10);
          diskFree = parseInt(freeMatch[1], 10);
          diskUsed = diskTotal - diskFree;
          diskUsagePercent = Math.round((diskUsed / diskTotal) * 100);
          mountPoint = "C:";
        }
      }

      // 7. Load Averages
      const loadAverage = os.loadavg() as [number, number, number];

      // 8. Network Interface Telemetry
      let rxBytes = 0;
      let txBytes = 0;
      let rxRate = 0;
      let txRate = 0;
      const now = Date.now();

      if (isLinux) {
        const netDev = await this.execPromise("cat /proc/net/dev");
        const lines = netDev.split("\n");
        // Sum all interface rx/tx bytes except loopback
        for (const line of lines) {
          if (line.includes(":") && !line.includes("lo:")) {
            const parts = line.trim().split(/:\s*/)[1].split(/\s+/);
            rxBytes += parseInt(parts[0], 10) || 0;
            txBytes += parseInt(parts[8], 10) || 0;
          }
        }
        
        const timeDiff = (now - this.lastNetworkBytes.time) / 1000;
        if (timeDiff > 0 && this.lastNetworkBytes.time > 0) {
          rxRate = Math.max(0, Math.round((rxBytes - this.lastNetworkBytes.rx) / timeDiff));
          txRate = Math.max(0, Math.round((txBytes - this.lastNetworkBytes.tx) / timeDiff));
        }
        this.lastNetworkBytes = { rx: rxBytes, tx: txBytes, time: now };
      }

      const metrics: SystemMetrics = {
        cpu: {
          usage: cpuUsage,
          cores: cpuCores,
          model: cpuModel,
        },
        memory: {
          total: totalMem,
          used: usedMem,
          free: freeMem,
          usagePercent: memoryUsagePercent,
        },
        disk: {
          total: diskTotal || mockSystemMetrics.disk.total,
          used: diskUsed || mockSystemMetrics.disk.used,
          free: diskFree || mockSystemMetrics.disk.free,
          usagePercent: diskUsagePercent || mockSystemMetrics.disk.usagePercent,
          mountPoint,
        },
        swap: {
          total: swapTotal,
          used: swapUsed,
          free: swapFree,
          usagePercent: swapUsagePercent,
        },
        network: {
          rxBytes: rxBytes || mockSystemMetrics.network.rxBytes,
          txBytes: txBytes || mockSystemMetrics.network.txBytes,
          rxRate: rxRate || mockSystemMetrics.network.rxRate,
          txRate: txRate || mockSystemMetrics.network.txRate,
        },
        loadAverage,
        uptime: os.uptime(),
        hostname,
        os: platformOS,
        kernel,
        serverTime: new Date().toISOString(),
      };

      // Handle optional properties or sub-extensions if needed
      if (cpuTemp !== undefined) {
        (metrics.cpu as any).temperature = cpuTemp;
      }
      (metrics as any).ubuntuVersion = ubuntuVersion;

      localCache.set(CACHE_KEY, metrics);
      return { metrics, source: "live" };
    } catch (e) {
      console.error("Failed to query live system metrics, using mock fallback:", e);
      return { metrics: mockSystemMetrics, source: "live" };
    }
  }
}
