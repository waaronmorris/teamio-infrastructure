# TeamIO Development Makefile
# Run these commands from the dev/ directory

.PHONY: help up down restart logs build clean db-shell db-reset migrate

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# Docker Compose Commands
# =============================================================================

up: ## Start all services
	docker compose up -d

up-logs: ## Start all services with logs
	docker compose up

down: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## View logs (all services)
	docker compose logs -f

logs-backend: ## View backend logs
	docker compose logs -f backend

logs-frontend: ## View frontend logs
	docker compose logs -f frontend

logs-db: ## View database logs
	docker compose logs -f db

build: ## Rebuild all containers
	docker compose build

build-backend: ## Rebuild backend container
	docker compose build backend

build-frontend: ## Rebuild frontend container
	docker compose build frontend

# =============================================================================
# Database Commands
# =============================================================================

db-shell: ## Open PostgreSQL shell
	docker compose exec db psql -U teamio -d teamio

db-reset: ## Reset database (removes all data)
	docker compose down -v
	docker compose up -d db
	@echo "Waiting for database to be ready..."
	@sleep 5
	docker compose up -d backend

# =============================================================================
# Development Shortcuts
# =============================================================================

backend-only: ## Start only db + backend (for local frontend dev)
	docker compose up -d db backend

db-only: ## Start only database (for local dev)
	docker compose up -d db

# =============================================================================
# Cleanup
# =============================================================================

clean: ## Stop services and remove volumes
	docker compose down -v

clean-all: ## Remove everything including images
	docker compose down -v --rmi local
	docker system prune -f

# =============================================================================
# Tools
# =============================================================================

pgadmin: ## Start pgAdmin database UI
	docker compose --profile tools up -d pgadmin
	@echo "pgAdmin available at http://localhost:5050"

status: ## Show service status
	docker compose ps
