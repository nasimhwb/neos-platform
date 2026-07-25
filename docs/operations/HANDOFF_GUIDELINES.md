# NEOS Platform — Handoff & Session Sync Guidelines

**Last Updated:** 2026-07-25  
**Target Repository:** `nasimhwb/neos-platform` / `nasimhwb/neos-app`

---

## 1. Multi-Machine & Agent Continuity Rules

To ensure seamless switching across machines (e.g. Workstation to Secondary Laptop) and engineering sessions:

1. **Auto-Commit & Sync Threshold**:
   - Whenever completing a batch audit, page diagnostic, or feature fix, all documentation files (`APPLICATION_AUDIT.md`, `MODULE_STATUS.md`, `PROJECT_STATUS.md`, `INVESTIGATION_LOG.md`, `CHANGELOG.md`) must be committed and pushed to GitHub immediately.
   - When token/request quota approaches low levels (~2% remaining capacity or session handoff), the active agent/engineer must immediately push all untracked files and uncommitted changes to remote `origin`.

2. **Source of Truth Files**:
   - `docs/operations/APPLICATION_AUDIT.md`: Complete audit matrix of all sidebar pages.
   - `docs/operations/MODULE_STATUS.md`: Live readiness matrix for each module.
   - `docs/operations/PROJECT_STATUS.md`: High-level metrics & staging status.
   - `docs/investigations/INVESTIGATION_LOG.md`: Technical investigation & empirical root cause log.
   - `docs/operations/CHANGELOG.md`: Chronological log of code, database, and infrastructure changes.

3. **Resume Protocol for Next Session / Device**:
   ```bash
   git pull origin feature/platform-dashboard
   ```
   - Inspect `docs/operations/APPLICATION_AUDIT.md` to pick up exact remaining sidebar audit items or prioritized fixes without restarting completed work.
