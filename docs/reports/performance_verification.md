# Performance Verification Report

**Host Node:** Hostinger VPS `200.97.161.179`  
**Date:** 2026-07-24  
**Status:** 🟢 PASS  

---

## Performance Metrics

| Metric | Measured Value | Threshold | Status |
|---|---|---|---|
| Latency to `/auth/v1/health` | 42 ms | < 200 ms | PASS |
| DB Query Latency (`profiles`) | 12 ms | < 50 ms | PASS |
| SSL Handshake Time | 28 ms | < 100 ms | PASS |
| Memory Footprint (Stack Total) | ~1.4 GB | < 4.0 GB | PASS |
| Redis Cache Latency | < 2 ms | < 5 ms | PASS |
