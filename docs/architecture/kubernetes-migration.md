# Kubernetes Migration Roadmap

This document outlines the architectural mapping and step-by-step roadmap for migrating the NEOS Platform from Docker Compose to a Kubernetes (k8s/k3s) cluster.

---

## 1. Architectural Component Mapping

To ensure zero vendor lock-in and a smooth transition, we have decoupled configs, networks, and data storage. They translate directly to Kubernetes constructs:

| Docker Compose Concept | Kubernetes Equivalent | Migration Strategy |
| :--- | :--- | :--- |
| **Containers / Services** | **Pods / Deployments** | Convert service definitions to K8s Deployments (using tools like `kompose` or writing Helm Charts). |
| **Named Bridge Networks** | **Network Policies & Services** | Core networks (`neos-database`, `neos-private`) translate to namespace-isolated DNS endpoints. Use `NetworkPolicies` to restrict pod communication. |
| **Host Bind Volumes** | **Persistent Volume Claims (PVC)** | Map persistent volumes (`postgres_data`, `redis_data`) to PVCs managed by a StorageClass (e.g. CSI Longhorn, OpenEBS, or Cloud block storage). |
| **Nginx Proxy Gateway** | **Ingress Controller** | Replace Nginx container with a cluster-wide Ingress Controller (e.g., **Nginx Ingress** or **Traefik Ingress**). Route rules translate to `Ingress` YAML resources. |
| **Environment Variables (`.env`)** | **ConfigMaps & Secrets** | Migrate standard variables to `ConfigMaps` and passwords/access keys to `Secrets`. |

---

## 2. Step-by-Step Migration Plan

### Step 1: Export Database & Storage Data
1. Run the final backup on the VPS: `make backup`.
2. Retrieve the `.tar.gz` archive containing Postgres dumps, Redis state, and MinIO storage files.

### Step 2: Provision Kubernetes Cluster
1. Set up a lightweight cluster (e.g., **K3s** for single-node VPS, or a managed cloud service like **EKS/GKE** for high availability).
2. Install the **Nginx Ingress Controller** and **Cert-Manager** (for automated Let's Encrypt certificate resolution).

### Step 3: Apply ConfigMaps & Secrets
Convert the `.env` configuration file to Kubernetes Secrets:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secrets
type: Opaque
data:
  postgres-password: <BASE64_ENCODED_PASSWORD>
```

### Step 4: Provision Persistent Volumes
Define PVCs to allocate disk space for PostgreSQL, Redis, and MinIO:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### Step 5: Convert and Apply Manifests
Deploy PostgreSQL, Redis, and applications as Pod Deployments. Ensure the database links to `postgres-pvc` and references `postgres-secrets`.

### Step 6: Route Traffic (Ingress)
Write `Ingress` resources to define public routing rules matching the domains:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: erp-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  rules:
    - host: erp.neos-platform.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: erp-service
                port:
                  number: 8000
  tls:
    - hosts:
        - erp.neos-platform.local
      secretName: erp-ssl-cert
```

### Step 7: Restore Backups
1. Extract data files onto the new PV storage mounts.
2. Load database dumps into the new cluster PostgreSQL pods.
