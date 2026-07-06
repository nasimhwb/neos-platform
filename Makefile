# ==============================================================================
# NEOS PLATFORM SHARED INFRASTRUCTURE - MAKEFILE COMMANDS
# ==============================================================================
# Use this Makefile to run host operations and manage docker container stacks.

.PHONY: bootstrap up down restart ps logs reload-nginx backup restore config-check

# Combined docker compose command referencing all modular configurations
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
	@echo "Starting full VPS provisioning..."
	chmod +x bootstrap/*.sh backups/*.sh
	sudo ./bootstrap/install.sh

# 2. Deploy Container Stacks (Base infrastructure)
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

# 5. Service Status Check
ps:
	$(COMPOSE_CMD) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# 6. Tail Logs (usage: make logs service=db)
service ?= 
logs:
	@if [ -z "$(service)" ]; then \
		$(COMPOSE_CMD) logs -f; \
	else \
		$(COMPOSE_CMD) logs -f $(service); \
	fi

# 7. Reload Nginx reverse-proxy
reload-nginx:
	@echo "Reloading Nginx configurations..."
	$(COMPOSE_CMD) exec -t reverse-proxy nginx -s reload

# 8. Trigger Database & Storage Backup
backup:
	@echo "Triggering backup script..."
	./backups/backup.sh

# 9. Trigger Restore Script (usage: make restore archive=path/to/archive.tar.gz)
archive ?=
restore:
	@if [ -z "$(archive)" ]; then \
		echo "Error: Please specify the backup archive path. Example: make restore archive=/srv/neos/backups/neos_backup_...tar.gz"; \
		exit 1; \
	fi; \
	./backups/restore.sh $(archive)

# 10. Validate Compose Configurations Syntax
config-check:
	@echo "Validating Docker Compose configurations..."
	$(COMPOSE_CMD) config
