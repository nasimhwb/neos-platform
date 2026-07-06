# ==============================================================================
# NEOS PLATFORM SHARED INFRASTRUCTURE - MAKEFILE COMMANDS v3
# ==============================================================================
# Master orchestration interface for Hostinger VPS private cloud nodes.

.PHONY: bootstrap up up-apps down restart ps logs reload-nginx doctor backup restore verify-backup config-check update clean

# Compile all modular compose files
COMPOSE_CMD = docker compose \
	-f compose/compose.base.yml \
	-f compose/compose.database.yml \
	-f compose/compose.storage.yml \
	-f compose/compose.monitoring.yml \
	-f compose/compose.proxy.yml \
	-f compose/compose.security.yml \
	-f compose/compose.apps.yml

# 1. System Host Provisioning
bootstrap:
	@echo "Bootstrapping VPS node environment..."
	chmod +x bootstrap/*.sh backups/*.sh scripts/*.sh
	sudo ./bootstrap/install.sh

# 2. Deploy Container Stacks (Infrastructure core)
up:
	@echo "Starting Neos Platform Infrastructure..."
	$(COMPOSE_CMD) up -d --build --remove-orphans

# 3. Deploy App Stacks (Launches the app profiles)
up-apps:
	@echo "Starting Neos Platform Infrastructure with Apps..."
	$(COMPOSE_CMD) --profile apps --profile infrastructure up -d --build

# 4. Tear Down Container Stacks
down:
	@echo "Stopping Neos Platform Infrastructure..."
	$(COMPOSE_CMD) down --remove-orphans

# 5. Service Restart Trigger
restart:
	@echo "Restarting Neos Platform containers..."
	$(COMPOSE_CMD) restart

# 6. Service Status Check
ps:
	$(COMPOSE_CMD) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# 7. Tail Logs (usage: make logs service=db)
service ?= 
logs:
	@if [ -z "$(service)" ]; then \
		$(COMPOSE_CMD) logs -f; \
	else \
		$(COMPOSE_CMD) logs -f $(service); \
	fi

# 8. Reload Nginx configs
reload-nginx:
	@echo "Reloading Nginx proxy configurations..."
	$(COMPOSE_CMD) exec -t reverse-proxy nginx -s reload

# 9. Holistic System Diagnosis
doctor:
	@echo "Running diagnostic health check..."
	chmod +x scripts/doctor.sh
	./scripts/doctor.sh

# 10. Trigger Data Backups
backup:
	@echo "Running shared database and storage backup..."
	chmod +x backups/backup.sh
	./backups/backup.sh

# 11. Trigger Backup Verification
verify-backup:
	@echo "Running backup verification check..."
	chmod +x backups/verify-backup.sh
	./backups/verify-backup.sh

# 12. Trigger Restore Script (usage: make restore archive=path/to/archive.tar.gz)
archive ?=
restore:
	@if [ -z "$(archive)" ]; then \
		echo "Error: Please specify the backup archive path. Example: make restore archive=/srv/neos/shared/backups/neos_backup_...tar.gz"; \
		exit 1; \
	fi; \
	chmod +x backups/restore.sh; \
	./backups/restore.sh $(archive)

# 13. Validate Compose Configuration Syntax
config-check:
	@echo "Validating Docker Compose configs..."
	$(COMPOSE_CMD) config

# 14. Git codebase pull
update:
	@echo "Pulling latest git changes..."
	git pull

# 15. Garbage Collection and System cleanup
clean:
	@echo "Cleaning up dangling volumes and container cache..."
	docker system prune -af --volumes
