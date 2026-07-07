import fs from "fs";
import path from "path";

export interface AuditRecord {
  timestamp: string;
  action: "Restart" | "Deploy" | "Restore" | "Configuration" | "Login" | "Logout";
  actor: string;
  details: string;
  ip: string;
  status: "success" | "failed";
}

export class AuditService {
  private static getLogPath(): string {
    // Check if running on target host with /srv/neos/shared
    const prodDir = "/srv/neos/shared";
    if (fs.existsSync(prodDir)) {
      return path.join(prodDir, "audit.jsonl");
    }
    
    // Local fallback inside dashboard
    const localDir = path.join(process.cwd(), "logs");
    if (!fs.existsSync(localDir)) {
      fs.mkdirSync(localDir, { recursive: true });
    }
    return path.join(localDir, "audit.jsonl");
  }

  static async logAction(
    action: AuditRecord["action"],
    actor: string,
    details: string,
    ip: string,
    status: AuditRecord["status"] = "success"
  ): Promise<void> {
    const record: AuditRecord = {
      timestamp: new Date().toISOString(),
      action,
      actor,
      details,
      ip,
      status,
    };
    
    const logPath = this.getLogPath();
    const line = JSON.stringify(record) + "\n";
    
    try {
      await fs.promises.appendFile(logPath, line, "utf8");
    } catch (error) {
      console.error("Failed to write audit log:", error);
    }
  }

  static async getLogs(limit = 100): Promise<AuditRecord[]> {
    const logPath = this.getLogPath();
    if (!fs.existsSync(logPath)) {
      return [];
    }
    
    try {
      const content = await fs.promises.readFile(logPath, "utf8");
      const lines = content.trim().split("\n").filter(Boolean);
      const records = lines.map(line => JSON.parse(line) as AuditRecord);
      
      // Return reverse chronological order (newest first)
      return records.reverse().slice(0, limit);
    } catch (error) {
      console.error("Failed to read audit logs:", error);
      return [];
    }
  }
}
