// ==============================================================================
// NEOS PLATFORM DASHBOARD — Mock Service Data
// All services return realistic, well-structured mock data.
// Real implementations will swap these out progressively.
// ==============================================================================

import type {
  SystemMetrics, PlatformInfo, DockerStatus, DockerContainer,
  DockerNetwork, DockerVolume, Application, PostgresStats,
  RedisStats, MinioStats, BackupRecord, DeploymentRecord,
  SSLCertificate, Alert, UptimeMonitor, PlatformUser, LogEntry,
  FirewallRule, SecurityEvent,
} from "@/lib/types";

// ------------------------------------------------------------------------------
// System
// ------------------------------------------------------------------------------
export const mockSystemMetrics: SystemMetrics = {
  cpu: { usage: 34.2, cores: 4, model: "Intel(R) Xeon(R) E-2136 @ 3.30GHz" },
  memory: { total: 4294967296, used: 2684354560, free: 1610612736, usagePercent: 62.5 },
  disk: { total: 107374182400, used: 42949672960, free: 64424509440, usagePercent: 40.0, mountPoint: "/" },
  swap: { total: 2147483648, used: 268435456, free: 1879048192, usagePercent: 12.5 },
  network: { rxBytes: 1073741824, txBytes: 536870912, rxRate: 102400, txRate: 51200 },
  loadAverage: [1.24, 1.15, 0.98],
  uptime: 1209600,
  hostname: "neos-vps-kvm2",
  os: "Ubuntu 24.04 LTS",
  kernel: "6.8.0-31-generic",
  serverTime: new Date().toISOString(),
};

export const mockPlatformInfo: PlatformInfo = {
  version: "2.0.0",
  gitCommit: "f191489",
  gitBranch: "feature/platform-v2",
  lastDeployment: new Date(Date.now() - 86400000 * 2).toISOString(),
  deploymentColor: "blue",
  environment: "production",
};

// ------------------------------------------------------------------------------
// Docker
// ------------------------------------------------------------------------------
export const mockDockerStatus: DockerStatus = {
  version: "26.1.3",
  containers: { total: 24, running: 21, stopped: 2, paused: 1 },
  images: 18,
  networks: 5,
  volumes: 9,
  serverTime: new Date().toISOString(),
};

export const mockContainers: DockerContainer[] = [
  { id: "abc001", name: "neos_traefik", image: "traefik:v3.0", state: "running", status: "Up 14 days", created: "2024-06-21T10:00:00Z", ports: ["80:80", "443:443"], networks: ["neos-public", "neos-private"], cpuUsage: 0.8, memoryUsage: 52428800, memoryLimit: 268435456, labels: {} },
  { id: "abc002", name: "neos_postgres", image: "postgres:16.3-alpine", state: "running", status: "Up 14 days", created: "2024-06-21T10:00:00Z", ports: [], networks: ["neos-database", "neos-monitoring"], cpuUsage: 3.2, memoryUsage: 524288000, memoryLimit: 1610612736, labels: {} },
  { id: "abc003", name: "neos_redis", image: "redis:8.0-M02-alpine", state: "running", status: "Up 14 days", created: "2024-06-21T10:00:00Z", ports: [], networks: ["neos-database"], cpuUsage: 0.4, memoryUsage: 12582912, memoryLimit: 536870912, labels: {} },
  { id: "abc004", name: "neos_minio", image: "minio/minio:RELEASE.2024-06-06", state: "running", status: "Up 14 days", created: "2024-06-21T10:00:00Z", ports: [], networks: ["neos-storage", "neos-monitoring"], cpuUsage: 1.1, memoryUsage: 104857600, memoryLimit: 536870912, labels: {} },
  { id: "abc005", name: "neos_prometheus", image: "prom/prometheus:v2.52.0", state: "running", status: "Up 14 days", created: "2024-06-21T10:00:00Z", ports: [], networks: ["neos-monitoring"], cpuUsage: 0.6, memoryUsage: 209715200, memoryLimit: 536870912, labels: {} },
  { id: "abc006", name: "neos_grafana", image: "grafana/grafana:11.0.0", state: "running", status: "Up 14 days", created: "2024-06-21T10:00:00Z", ports: [], networks: ["neos-monitoring"], cpuUsage: 0.3, memoryUsage: 157286400, memoryLimit: 536870912, labels: {} },
  { id: "abc007", name: "neos_loki", image: "grafana/loki:3.0.0", state: "running", status: "Up 14 days", created: "2024-06-21T10:00:00Z", ports: [], networks: ["neos-monitoring"], cpuUsage: 0.5, memoryUsage: 131072000, memoryLimit: 536870912, labels: {} },
  { id: "abc008", name: "neos_pgbouncer", image: "edoburu/pgbouncer:1.22.0", state: "running", status: "Up 14 days", created: "2024-06-21T10:00:00Z", ports: ["6432:6432"], networks: ["neos-database", "neos-private"], cpuUsage: 0.1, memoryUsage: 8388608, memoryLimit: 268435456, labels: {} },
  { id: "abc009", name: "neos-app-blue", image: "nginx:1.26-alpine", state: "running", status: "Up 2 days", created: "2024-07-05T08:00:00Z", ports: [], networks: ["neos-private", "neos-database", "neos-storage"], cpuUsage: 0.2, memoryUsage: 20971520, memoryLimit: 268435456, labels: {} },
  { id: "abc010", name: "neos-app-green", image: "nginx:1.26-alpine", state: "stopped", status: "Exited (0) 2 days ago", created: "2024-07-03T08:00:00Z", ports: [], networks: ["neos-private", "neos-database", "neos-storage"], cpuUsage: 0, memoryUsage: 0, memoryLimit: 268435456, labels: {} },
];

export const mockNetworks: DockerNetwork[] = [
  { id: "net001", name: "neos-public", driver: "bridge", scope: "local", subnet: "172.20.0.0/16", gateway: "172.20.0.1", containers: 2 },
  { id: "net002", name: "neos-private", driver: "bridge", scope: "local", subnet: "172.21.0.0/16", gateway: "172.21.0.1", containers: 8 },
  { id: "net003", name: "neos-database", driver: "bridge", scope: "local", subnet: "172.22.0.0/16", gateway: "172.22.0.1", containers: 5 },
  { id: "net004", name: "neos-storage", driver: "bridge", scope: "local", subnet: "172.23.0.0/16", gateway: "172.23.0.1", containers: 3 },
  { id: "net005", name: "neos-monitoring", driver: "bridge", scope: "local", subnet: "172.24.0.0/16", gateway: "172.24.0.1", containers: 7 },
];

export const mockVolumes: DockerVolume[] = [
  { name: "neos_postgres_data", driver: "local", mountpoint: "/srv/neos/shared/data/postgres", usageBytes: 2147483648, labels: {} },
  { name: "neos_redis_data", driver: "local", mountpoint: "/srv/neos/shared/data/redis", usageBytes: 10485760, labels: {} },
  { name: "neos_minio_data", driver: "local", mountpoint: "/srv/neos/shared/data/minio", usageBytes: 5368709120, labels: {} },
  { name: "neos_prometheus_data", driver: "local", mountpoint: "/srv/neos/shared/data/prometheus", usageBytes: 524288000, labels: {} },
  { name: "neos_grafana_data", driver: "local", mountpoint: "/srv/neos/shared/data/grafana", usageBytes: 52428800, labels: {} },
  { name: "neos_loki_data", driver: "local", mountpoint: "/srv/neos/shared/data/loki", usageBytes: 1073741824, labels: {} },
  { name: "neos_alertmanager_data", driver: "local", mountpoint: "/srv/neos/shared/data/alertmanager", usageBytes: 5242880, labels: {} },
  { name: "neos_uptime_kuma_data", driver: "local", mountpoint: "/srv/neos/shared/data/uptime-kuma", usageBytes: 10485760, labels: {} },
];

// ------------------------------------------------------------------------------
// Applications
// ------------------------------------------------------------------------------
export const mockApplications: Application[] = [
  { id: "neos-app", name: "neos-app", displayName: "Neos App", description: "Core client application", status: "healthy", version: "2.1.0", container: "neos-app-blue", image: "nginx:1.26-alpine", domain: "app.neos-platform.local", port: 80, lastDeployment: new Date(Date.now() - 86400000 * 2).toISOString(), healthCheck: "/", color: "violet", icon: "globe", dbName: "neos_app", redisDb: 4 },
  { id: "erp", name: "erp", displayName: "Neos ERP", description: "Enterprise Resource Planning", status: "healthy", version: "1.4.2", container: "neos_erp_app", image: "nginx:1.26-alpine", domain: "erp.neos-platform.local", port: 80, lastDeployment: new Date(Date.now() - 86400000 * 5).toISOString(), healthCheck: "/", color: "blue", icon: "building2", dbName: "neos_erp", redisDb: 0 },
  { id: "crm", name: "crm", displayName: "Neos CRM", description: "Customer Relationship Management", status: "healthy", version: "1.2.0", container: "neos_crm_app", image: "nginx:1.26-alpine", domain: "crm.neos-platform.local", port: 80, lastDeployment: new Date(Date.now() - 86400000 * 7).toISOString(), healthCheck: "/", color: "cyan", icon: "users", dbName: "neos_crm", redisDb: 1 },
  { id: "hrms", name: "hrms", displayName: "Neos HRMS", description: "Human Resources Management System", status: "healthy", version: "1.1.5", container: "neos_hrms_app", image: "nginx:1.26-alpine", domain: "hrms.neos-platform.local", port: 80, lastDeployment: new Date(Date.now() - 86400000 * 10).toISOString(), healthCheck: "/", color: "green", icon: "users2", dbName: "neos_hrms" },
  { id: "billing", name: "billing", displayName: "Billing Dashboard", description: "Invoicing and payments", status: "healthy", version: "1.0.8", container: "neos_billing_app", image: "nginx:1.26-alpine", domain: "billing.neos-platform.local", port: 80, lastDeployment: new Date(Date.now() - 86400000 * 14).toISOString(), healthCheck: "/", color: "amber", icon: "credit-card", dbName: "neos_billing" },
  { id: "inventory", name: "inventory", displayName: "Inventory", description: "Stock and inventory tracking", status: "degraded", version: "1.3.1", container: "neos_inventory_app", image: "nginx:1.26-alpine", domain: "inventory.neos-platform.local", port: 80, lastDeployment: new Date(Date.now() - 86400000 * 3).toISOString(), healthCheck: "/", color: "orange", icon: "package", dbName: "neos_inventory", redisDb: 2 },
  { id: "visitor", name: "visitor", displayName: "Visitor Management", description: "Guest and visitor tracking system", status: "healthy", version: "1.0.2", container: "neos_visitor_app", image: "nginx:1.26-alpine", domain: "visitor.neos-platform.local", port: 80, lastDeployment: new Date(Date.now() - 86400000 * 21).toISOString(), healthCheck: "/", color: "pink", icon: "badge", dbName: "neos_visitor" },
  { id: "ai", name: "ai", displayName: "AI Services", description: "Machine learning and AI workflows", status: "unknown", version: "0.9.0", container: "neos_ai_app", image: "nginx:1.26-alpine", domain: "ai.neos-platform.local", port: 80, lastDeployment: new Date(Date.now() - 86400000 * 30).toISOString(), healthCheck: "/", color: "purple", icon: "brain", redisDb: 3 },
];

// ------------------------------------------------------------------------------
// PostgreSQL
// ------------------------------------------------------------------------------
export const mockPostgresStats: PostgresStats = {
  version: "PostgreSQL 16.3 on x86_64-pc-linux-musl",
  uptime: 1209600,
  connections: { active: 8, idle: 12, total: 20, max: 100 },
  status: "healthy",
  databases: [
    { name: "postgres", owner: "postgres", sizeBytes: 7340032, connections: 3, tables: 12, encoding: "UTF8" },
    { name: "neos_app", owner: "neos_app_user", sizeBytes: 524288000, connections: 2, tables: 47, encoding: "UTF8" },
    { name: "neos_erp", owner: "erp_user", sizeBytes: 1073741824, connections: 3, tables: 124, encoding: "UTF8" },
    { name: "neos_crm", owner: "crm_user", sizeBytes: 268435456, connections: 1, tables: 38, encoding: "UTF8" },
    { name: "neos_hrms", owner: "hrms_user", sizeBytes: 157286400, connections: 1, tables: 29, encoding: "UTF8" },
    { name: "neos_billing", owner: "billing_user", sizeBytes: 104857600, connections: 1, tables: 18, encoding: "UTF8" },
    { name: "neos_inventory", owner: "inventory_user", sizeBytes: 209715200, connections: 2, tables: 31, encoding: "UTF8" },
  ],
  users: [
    { name: "postgres", superuser: true, canLogin: true, canCreateDb: true, canCreateRole: true },
    { name: "supabase_admin", superuser: true, canLogin: true, canCreateDb: true, canCreateRole: true },
    { name: "authenticator", superuser: false, canLogin: true, canCreateDb: false, canCreateRole: false },
    { name: "neos_app_user", superuser: false, canLogin: true, canCreateDb: false, canCreateRole: false },
    { name: "erp_user", superuser: false, canLogin: true, canCreateDb: false, canCreateRole: false },
    { name: "crm_user", superuser: false, canLogin: true, canCreateDb: false, canCreateRole: false },
  ],
};

// ------------------------------------------------------------------------------
// Redis
// ------------------------------------------------------------------------------
export const mockRedisStats: RedisStats = {
  version: "8.0.0",
  uptime: 1209600,
  status: "healthy",
  memory: { used: 12582912, max: 536870912, usagePercent: 2.3, fragmentation: 1.12 },
  keys: { total: 4821, expiring: 312, expired: 18240, evicted: 0 },
  clients: { connected: 8, blocked: 0, max: 512 },
  persistence: { aofEnabled: true, rdbEnabled: true, lastSave: new Date(Date.now() - 3600000).toISOString(), lastBgSaveStatus: "ok" },
  stats: { totalCommands: 9823441, opsPerSec: 124, hitRate: 94.7, networkInput: 1073741824, networkOutput: 536870912 },
};

// ------------------------------------------------------------------------------
// MinIO
// ------------------------------------------------------------------------------
export const mockMinioStats: MinioStats = {
  status: "healthy",
  version: "RELEASE.2024-06-06T09-36-42Z",
  totalBuckets: 5,
  totalObjects: 12847,
  totalSizeBytes: 5368709120,
  buckets: [
    { name: "supabase-storage", created: "2024-06-21T10:00:00Z", sizeBytes: 3221225472, objects: 8234, policy: "private" },
    { name: "erp-uploads", created: "2024-06-21T10:00:00Z", sizeBytes: 1073741824, objects: 3241, policy: "private" },
    { name: "inventory-assets", created: "2024-06-21T10:00:00Z", sizeBytes: 536870912, objects: 982, policy: "private" },
    { name: "ai-models", created: "2024-06-21T10:00:00Z", sizeBytes: 524288000, objects: 47, policy: "private" },
    { name: "platform-backups", created: "2024-06-21T10:00:00Z", sizeBytes: 12582912, objects: 343, policy: "private" },
  ],
  users: [
    { accessKey: "supabase_user", status: "enabled", policies: ["supabase-storage-rw"], created: "2024-06-21T10:00:00Z" },
    { accessKey: "erp_user", status: "enabled", policies: ["erp-uploads-rw"], created: "2024-06-21T10:00:00Z" },
    { accessKey: "inventory_user", status: "enabled", policies: ["inventory-assets-rw"], created: "2024-06-21T10:00:00Z" },
  ],
};

// ------------------------------------------------------------------------------
// Backups
// ------------------------------------------------------------------------------
export const mockBackups: BackupRecord[] = [
  { id: "bk001", timestamp: new Date(Date.now() - 3600000).toISOString(), type: "full", status: "success", sizeBytes: 4294967296, duration: 847, components: ["postgres", "redis", "minio", "ssl", "configs"], verified: true, checksum: "sha256:a1b2c3d4e5f6", encrypted: true, retentionDays: 14, expiresAt: new Date(Date.now() + 86400000 * 12).toISOString() },
  { id: "bk002", timestamp: new Date(Date.now() - 86400000).toISOString(), type: "full", status: "success", sizeBytes: 4227858432, duration: 821, components: ["postgres", "redis", "minio", "ssl", "configs"], verified: true, checksum: "sha256:b2c3d4e5f6a1", encrypted: true, retentionDays: 14, expiresAt: new Date(Date.now() + 86400000 * 13).toISOString() },
  { id: "bk003", timestamp: new Date(Date.now() - 86400000 * 2).toISOString(), type: "full", status: "success", sizeBytes: 4160749568, duration: 798, components: ["postgres", "redis", "minio", "ssl", "configs"], verified: true, checksum: "sha256:c3d4e5f6a1b2", encrypted: true, retentionDays: 14, expiresAt: new Date(Date.now() + 86400000 * 12).toISOString() },
  { id: "bk004", timestamp: new Date(Date.now() - 86400000 * 3).toISOString(), type: "full", status: "failed", sizeBytes: 0, duration: 120, components: ["postgres", "redis"], verified: false, checksum: "", encrypted: true, retentionDays: 14, expiresAt: new Date(Date.now() + 86400000 * 11).toISOString() },
  { id: "bk005", timestamp: new Date(Date.now() - 86400000 * 4).toISOString(), type: "full", status: "success", sizeBytes: 4026531840, duration: 762, components: ["postgres", "redis", "minio", "ssl", "configs"], verified: true, checksum: "sha256:d4e5f6a1b2c3", encrypted: true, retentionDays: 14, expiresAt: new Date(Date.now() + 86400000 * 10).toISOString() },
];

// ------------------------------------------------------------------------------
// Deployments
// ------------------------------------------------------------------------------
export const mockDeployments: DeploymentRecord[] = [
  { id: "dep001", releaseId: "2024-07-05-003", timestamp: new Date(Date.now() - 86400000 * 2).toISOString(), status: "success", color: "blue", gitCommit: "f191489", gitBranch: "feature/platform-v2", triggeredBy: "github-actions", duration: 142, healthChecks: 12 },
  { id: "dep002", releaseId: "2024-07-03-001", timestamp: new Date(Date.now() - 86400000 * 4).toISOString(), status: "success", color: "green", gitCommit: "abcc13f", gitBranch: "feature/platform-v2", triggeredBy: "github-actions", duration: 138, healthChecks: 12 },
  { id: "dep003", releaseId: "2024-07-01-002", timestamp: new Date(Date.now() - 86400000 * 6).toISOString(), status: "failed", color: "blue", gitCommit: "8de421b", gitBranch: "feature/platform-v2", triggeredBy: "github-actions", duration: 45, healthChecks: 3, notes: "Healthcheck failed on new container after 45s" },
  { id: "dep004", releaseId: "2024-06-28-001", timestamp: new Date(Date.now() - 86400000 * 9).toISOString(), status: "success", color: "green", gitCommit: "7ca319e", gitBranch: "feature/platform-v2", triggeredBy: "github-actions", duration: 155, healthChecks: 12 },
];

// ------------------------------------------------------------------------------
// SSL Certificates
// ------------------------------------------------------------------------------
export const mockSSLCerts: SSLCertificate[] = [
  { domain: "neos-platform.local", issuer: "Let's Encrypt", validFrom: "2024-05-01T00:00:00Z", validTo: new Date(Date.now() + 86400000 * 45).toISOString(), daysRemaining: 45, status: "valid", autoRenew: true },
  { domain: "app.neos-platform.local", issuer: "Let's Encrypt", validFrom: "2024-05-01T00:00:00Z", validTo: new Date(Date.now() + 86400000 * 45).toISOString(), daysRemaining: 45, status: "valid", autoRenew: true },
  { domain: "erp.neos-platform.local", issuer: "Let's Encrypt", validFrom: "2024-05-01T00:00:00Z", validTo: new Date(Date.now() + 86400000 * 20).toISOString(), daysRemaining: 20, status: "expiring", autoRenew: true },
  { domain: "monitor.neos-platform.local", issuer: "Let's Encrypt", validFrom: "2024-05-01T00:00:00Z", validTo: new Date(Date.now() + 86400000 * 60).toISOString(), daysRemaining: 60, status: "valid", autoRenew: true },
  { domain: "s3.neos-platform.local", issuer: "Let's Encrypt", validFrom: "2024-05-01T00:00:00Z", validTo: new Date(Date.now() + 86400000 * 60).toISOString(), daysRemaining: 60, status: "valid", autoRenew: true },
  { domain: "supabase.neos-platform.local", issuer: "Let's Encrypt", validFrom: "2024-05-01T00:00:00Z", validTo: new Date(Date.now() + 86400000 * 58).toISOString(), daysRemaining: 58, status: "valid", autoRenew: true },
];

// ------------------------------------------------------------------------------
// Alerts
// ------------------------------------------------------------------------------
export const mockAlerts: Alert[] = [
  { id: "alt001", name: "DiskSpaceWarning", severity: "warning", status: "firing", message: "Disk usage at 40% — review growth rate", startsAt: new Date(Date.now() - 7200000).toISOString(), labels: { instance: "neos-vps", severity: "warning" } },
  { id: "alt002", name: "InventoryAppDegraded", severity: "warning", status: "firing", message: "Inventory container health check returning degraded status", startsAt: new Date(Date.now() - 1800000).toISOString(), labels: { container: "neos_inventory_app", severity: "warning" } },
  { id: "alt003", name: "BackupFailure", severity: "critical", status: "resolved", message: "Daily backup failed on 2024-07-04 — retried successfully", startsAt: new Date(Date.now() - 86400000 * 3).toISOString(), endsAt: new Date(Date.now() - 86400000 * 3 + 3600000).toISOString(), labels: { component: "backup", severity: "critical" } },
];

// ------------------------------------------------------------------------------
// Uptime Monitors
// ------------------------------------------------------------------------------
export const mockUptimeMonitors: UptimeMonitor[] = [
  { name: "Platform App", url: "https://app.neos-platform.local", status: "up", uptimePercent: 99.97, avgResponseMs: 124, lastChecked: new Date(Date.now() - 60000).toISOString() },
  { name: "ERP", url: "https://erp.neos-platform.local", status: "up", uptimePercent: 99.94, avgResponseMs: 98, lastChecked: new Date(Date.now() - 60000).toISOString() },
  { name: "CRM", url: "https://crm.neos-platform.local", status: "up", uptimePercent: 99.91, avgResponseMs: 112, lastChecked: new Date(Date.now() - 60000).toISOString() },
  { name: "Inventory", url: "https://inventory.neos-platform.local", status: "up", uptimePercent: 98.20, avgResponseMs: 247, lastChecked: new Date(Date.now() - 60000).toISOString() },
  { name: "MinIO API", url: "https://s3.neos-platform.local/minio/health/live", status: "up", uptimePercent: 100.00, avgResponseMs: 42, lastChecked: new Date(Date.now() - 60000).toISOString() },
];

// ------------------------------------------------------------------------------
// Security
// ------------------------------------------------------------------------------
export const mockFirewallRules: FirewallRule[] = [
  { port: "22", protocol: "tcp", action: "allow", from: "anywhere", comment: "SSH" },
  { port: "80", protocol: "tcp", action: "allow", from: "anywhere", comment: "HTTP (Traefik redirect)" },
  { port: "443", protocol: "tcp", action: "allow", from: "anywhere", comment: "HTTPS" },
  { port: "443", protocol: "udp", action: "allow", from: "anywhere", comment: "HTTP/3 QUIC" },
  { port: "6432", protocol: "tcp", action: "allow", from: "172.0.0.0/8", comment: "PgBouncer internal" },
  { port: "9090", protocol: "tcp", action: "deny", from: "anywhere", comment: "Prometheus (internal only)" },
];

export const mockSecurityEvents: SecurityEvent[] = [
  { timestamp: new Date(Date.now() - 3600000).toISOString(), type: "blocked", ip: "185.224.128.17", details: "Fail2Ban: 5 failed SSH attempts", severity: "warning" },
  { timestamp: new Date(Date.now() - 7200000).toISOString(), type: "blocked", ip: "45.142.212.100", details: "Fail2Ban: 10 failed HTTP auth attempts", severity: "warning" },
  { timestamp: new Date(Date.now() - 14400000).toISOString(), type: "login", ip: "203.0.113.42", details: "Successful SSH login as nasim", severity: "info" },
  { timestamp: new Date(Date.now() - 28800000).toISOString(), type: "port_scan", ip: "192.168.1.200", details: "Port scan detected on ports 22, 80, 443", severity: "warning" },
];

// ------------------------------------------------------------------------------
// Users
// ------------------------------------------------------------------------------
export const mockUsers: PlatformUser[] = [
  { id: "usr001", email: "admin@neos-platform.local", name: "Platform Admin", role: "admin", lastLogin: new Date(Date.now() - 3600000).toISOString(), createdAt: "2024-06-21T10:00:00Z", active: true },
  { id: "usr002", email: "devops@neos-platform.local", name: "DevOps Engineer", role: "operator", lastLogin: new Date(Date.now() - 86400000).toISOString(), createdAt: "2024-06-25T10:00:00Z", active: true },
  { id: "usr003", email: "viewer@neos-platform.local", name: "Dashboard Viewer", role: "viewer", lastLogin: new Date(Date.now() - 86400000 * 7).toISOString(), createdAt: "2024-07-01T10:00:00Z", active: false },
];

// ------------------------------------------------------------------------------
// Logs
// ------------------------------------------------------------------------------
export const mockLogs: LogEntry[] = [
  { timestamp: new Date(Date.now() - 60000).toISOString(), level: "info", source: "traefik", message: "Starting Traefik v3.0 with HTTP/3 support" },
  { timestamp: new Date(Date.now() - 120000).toISOString(), level: "warn", source: "neos-app-blue", message: "High memory usage detected: 85% of limit" },
  { timestamp: new Date(Date.now() - 180000).toISOString(), level: "info", source: "postgres", message: "Checkpoint complete: wrote 1247 buffers" },
  { timestamp: new Date(Date.now() - 300000).toISOString(), level: "error", source: "neos_inventory_app", message: "Health check timeout after 5s — retrying" },
  { timestamp: new Date(Date.now() - 600000).toISOString(), level: "info", source: "minio", message: "Object lifecycle rule applied to supabase-storage: 128 objects transitioned" },
  { timestamp: new Date(Date.now() - 900000).toISOString(), level: "info", source: "redis", message: "Background save completed successfully" },
  { timestamp: new Date(Date.now() - 1200000).toISOString(), level: "warn", source: "alertmanager", message: "DiskSpaceWarning alert still firing after 2h" },
  { timestamp: new Date(Date.now() - 1800000).toISOString(), level: "info", source: "promtail", message: "Successfully scraped 12 log streams" },
];
