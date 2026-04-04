# TeamIO Development Makefile
# Run these commands from the dev/ directory

.PHONY: help up down restart logs build clean db-shell db-reset migrate qa qa-github qa-dry qa-full qa-logs qa-report

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

db-seed: ## Load sample data into database
	@echo "Loading seed data..."
	docker compose exec -T db psql -U teamio -d teamio < seed-data.sql
	@echo "Seed data loaded!"

db-fresh: ## Reset database and load seed data
	$(MAKE) db-reset
	@echo "Waiting for migrations to complete..."
	@sleep 10
	$(MAKE) db-seed

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

# =============================================================================
# QA Chaos Agent
# =============================================================================

qa: ## Run QA chaos agent (5 min crawl, local report only)
	docker compose --profile qa run --rm qa-agent

qa-github: ## Run QA agent and file bugs as GitHub issues
	FILE_GITHUB_ISSUES=true docker compose --profile qa run --rm qa-agent

qa-dry: ## Dry run - shows what issues would be filed
	FILE_GITHUB_ISSUES=true DRY_RUN=true docker compose --profile qa run --rm qa-agent

qa-full: ## Full run with AI + PostHog + GitHub issues
	FILE_GITHUB_ISSUES=true docker compose --profile qa run --rm \
		-e ANTHROPIC_API_KEY=$(ANTHROPIC_API_KEY) \
		-e POSTHOG_API_KEY=$(POSTHOG_API_KEY) \
		-e POSTHOG_PROJECT_ID=$(POSTHOG_PROJECT_ID) \
		qa-agent

qa-review: ## AI reviews PostHog errors and files GitHub tickets
	docker compose --profile qa run --rm \
		-e ANTHROPIC_API_KEY=$(ANTHROPIC_API_KEY) \
		-e POSTHOG_API_KEY=$(POSTHOG_API_KEY) \
		-e POSTHOG_PROJECT_ID=$(POSTHOG_PROJECT_ID) \
		-e FILE_GITHUB_ISSUES=$(FILE_GITHUB_ISSUES) \
		-e GH_TOKEN=$(GH_TOKEN) \
		--entrypoint "npx" qa-agent tsx src/posthog-reviewer.ts

qa-review-dry: ## AI reviews PostHog (dry run, no tickets filed)
	docker compose --profile qa run --rm \
		-e ANTHROPIC_API_KEY=$(ANTHROPIC_API_KEY) \
		-e POSTHOG_API_KEY=$(POSTHOG_API_KEY) \
		-e POSTHOG_PROJECT_ID=$(POSTHOG_PROJECT_ID) \
		--entrypoint "npx" qa-agent tsx src/posthog-reviewer.ts

qa-build: ## Rebuild the QA agent container
	docker compose --profile qa build qa-agent

qa-logs: ## View QA agent logs
	docker compose --profile qa logs -f qa-agent

qa-report: ## Copy latest report from container volume
	@docker run --rm -v teamio-network_qa_reports:/reports alpine sh -c 'ls -t /reports/*.md | head -1 | xargs cat' 2>/dev/null || echo "No reports found. Run 'make qa' first."

db-seed-zips: ## Load zip code data for discovery
	@echo "Loading zip code data..."
	docker compose exec -T db psql -U teamio -d teamio < seed-zip-codes.sql
	@echo "Zip codes loaded!"
