// ==============================================================================
// NEOS PLATFORM DASHBOARD — TypeScript Type Definitions
// ==============================================================================

export type ServiceStatus = "healthy" | "degraded" | "unhealthy" | "unknown";
export type ContainerState = "running" | "stopped" | "restarting" | "paused" | "exited";
export type DeploymentColor = "blue" | "green";
export type DeploymentStatus = "success" | "failed" | "running" | "cancelled";
export type BackupStatus = "success" | "failed" | "pending" | "running";
export type AlertSeverity = "critical" | "warning" | "info";

// ------------------------------------------------------------------------------
// System
// ------------------------------------------------------------------------------
export interface SystemMetrics {
  cpu: {
    usage: number; // percentage 0-100
    cores: number;
    model: string;
  };
  memory: {
    total: number; // bytes
    used: number;
    free: number;
    usagePercent: number;
  };
  disk: {
    total: number;
    used: number;
    free: number;
    usagePercent: number;
    mountPoint: string;
  };
  swap: {
    total: number;
    used: number;
    free: number;
    usagePercent: number;
  };
  network: {
    rxBytes: number;
    txBytes: number;
    rxRate: number; // bytes per second
    txRate: number;
  };
  loadAverage: [number, number, number]; // 1m, 5m, 15m
  uptime: number; // seconds
  hostname: string;
  os: string;
  kernel: string;
  serverTime: string; // ISO8601
}

export interface PlatformInfo {
  version: string;
  gitCommit: string;
  gitBranch: string;
  lastDeployment: string; // ISO8601
  deploymentColor: DeploymentColor;
  environment: string;
}

// ------------------------------------------------------------------------------
// Docker
// ------------------------------------------------------------------------------
export interface DockerContainer {
  id: string;
  name: string;
  image: string;
  state: ContainerState;
  status: string; // human-readable "Up 2 hours"
  created: string;
  ports: string[];
  networks: string[];
  cpuUsage: number;
  memoryUsage: number;
  memoryLimit: number;
  labels: Record<string, string>;
}

export interface DockerNetwork {
  id: string;
  name: string;
  driver: string;
  scope: string;
  subnet: string;
  gateway: string;
  containers: number;
}

export interface DockerVolume {
  name: string;
  driver: string;
  mountpoint: string;
  usageBytes: number;
  labels: Record<string, string>;
}

export interface DockerImage {
  id: string;
  repository: string;
  tag: string;
  size: number;
  created: string;
}

export interface DockerStatus {
  version: string;
  containers: {
    total: number;
    running: number;
    stopped: number;
    paused: number;
  };
  images: number;
  networks: number;
  volumes: number;
  serverTime: string;
}

// ------------------------------------------------------------------------------
// Applications
// ------------------------------------------------------------------------------
export interface Application {
  id: string;
  name: string;
  displayName: string;
  description: string;
  status: ServiceStatus;
  version: string;
  container: string;
  image: string;
  domain: string;
  port: number;
  lastDeployment: string;
  healthCheck: string;
  color: string; // Tailwind color class prefix
  icon: string;
  dbName?: string;
  redisDb?: number;
}

// ------------------------------------------------------------------------------
// PostgreSQL
// ------------------------------------------------------------------------------
export interface PostgresDatabase {
  name: string;
  owner: string;
  sizeBytes: number;
  connections: number;
  tables: number;
  encoding: string;
}

export interface PostgresConnection {
  pid: number;
  user: string;
  database: string;
  state: string;
  query: string;
  duration: number;
}

export interface PostgresUser {
  name: string;
  superuser: boolean;
  canLogin: boolean;
  canCreateDb: boolean;
  canCreateRole: boolean;
}

export interface PostgresStats {
  version: string;
  uptime: number;
  connections: {
    active: number;
    idle: number;
    total: number;
    max: number;
  };
  databases: PostgresDatabase[];
  users: PostgresUser[];
  status: ServiceStatus;
}

// ------------------------------------------------------------------------------
// Redis
// ------------------------------------------------------------------------------
export interface RedisStats {
  version: string;
  uptime: number;
  status: ServiceStatus;
  memory: {
    used: number;
    max: number;
    usagePercent: number;
    fragmentation: number;
  };
  keys: {
    total: number;
    expiring: number;
    expired: number;
    evicted: number;
  };
  clients: {
    connected: number;
    blocked: number;
    max: number;
  };
  persistence: {
    aofEnabled: boolean;
    rdbEnabled: boolean;
    lastSave: string;
    lastBgSaveStatus: string;
  };
  stats: {
    totalCommands: number;
    opsPerSec: number;
    hitRate: number;
    networkInput: number;
    networkOutput: number;
  };
}

// ------------------------------------------------------------------------------
// MinIO Object Storage
// ------------------------------------------------------------------------------
export interface MinioBucket {
  name: string;
  created: string;
  sizeBytes: number;
  objects: number;
  policy: string;
}

export interface MinioUser {
  accessKey: string;
  status: "enabled" | "disabled";
  policies: string[];
  created: string;
}

export interface MinioStats {
  status: ServiceStatus;
  version: string;
  totalBuckets: number;
  totalObjects: number;
  totalSizeBytes: number;
  buckets: MinioBucket[];
  users: MinioUser[];
}

// ------------------------------------------------------------------------------
// Backups
// ------------------------------------------------------------------------------
export interface BackupRecord {
  id: string;
  timestamp: string;
  type: "full" | "incremental";
  status: BackupStatus;
  sizeBytes: number;
  duration: number; // seconds
  components: string[]; // ['postgres', 'redis', 'minio', 'ssl', 'configs']
  verified: boolean;
  checksum: string;
  encrypted: boolean;
  retentionDays: number;
  expiresAt: string;
}

// ------------------------------------------------------------------------------
// Deployments
// ------------------------------------------------------------------------------
export interface DeploymentRecord {
  id: string;
  releaseId: string;
  timestamp: string;
  status: DeploymentStatus;
  color: DeploymentColor;
  gitCommit: string;
  gitBranch: string;
  triggeredBy: string;
  duration: number; // seconds
  healthChecks: number;
  notes?: string;
}

// ------------------------------------------------------------------------------
// SSL Certificates
// ------------------------------------------------------------------------------
export interface SSLCertificate {
  domain: string;
  issuer: string;
  validFrom: string;
  validTo: string;
  daysRemaining: number;
  status: "valid" | "expiring" | "expired" | "pending";
  autoRenew: boolean;
}

// ------------------------------------------------------------------------------
// Security
// ------------------------------------------------------------------------------
export interface FirewallRule {
  port: string;
  protocol: string;
  action: "allow" | "deny";
  from: string;
  comment: string;
}

export interface SecurityEvent {
  timestamp: string;
  type: "login" | "blocked" | "fail2ban" | "port_scan";
  ip: string;
  details: string;
  severity: AlertSeverity;
}

// ------------------------------------------------------------------------------
// Monitoring / Alerts
// ------------------------------------------------------------------------------
export interface Alert {
  id: string;
  name: string;
  severity: AlertSeverity;
  status: "firing" | "resolved";
  message: string;
  startsAt: string;
  endsAt?: string;
  labels: Record<string, string>;
}

export interface UptimeMonitor {
  name: string;
  url: string;
  status: "up" | "down" | "pending";
  uptimePercent: number;
  avgResponseMs: number;
  lastChecked: string;
}

// ------------------------------------------------------------------------------
// Platform Users
// ------------------------------------------------------------------------------
export interface PlatformUser {
  id: string;
  email: string;
  name: string;
  role: "admin" | "operator" | "viewer";
  lastLogin: string;
  createdAt: string;
  active: boolean;
}

// ------------------------------------------------------------------------------
// Logs
// ------------------------------------------------------------------------------
export interface LogEntry {
  timestamp: string;
  level: "error" | "warn" | "info" | "debug";
  source: string;
  message: string;
  labels?: Record<string, string>;
}

// ------------------------------------------------------------------------------
// API Responses
// ------------------------------------------------------------------------------
export interface ApiResponse<T> {
  data: T;
  timestamp: string;
  source: "live" | "mock" | "cached";
}

export interface ApiError {
  error: string;
  message: string;
  code: number;
}
