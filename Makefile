# KuroPanel Docker Automation Makefile

.PHONY: help build start stop restart test logs clean shell setup

# Default environment
ENV ?= dev

# Colors
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)KuroPanel Docker Automation$(NC)"
	@echo "Usage: make [target] [ENV=dev|test]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

setup: ## Initial setup - copy environment files and install dependencies
	@echo "$(YELLOW)Setting up KuroPanel...$(NC)"
	@if [ "$(ENV)" = "test" ]; then \
		cp .env.testing .env; \
	else \
		cp .env.development .env; \
	fi
	@echo "$(GREEN)Environment file copied ($(ENV))$(NC)"

build: setup ## Build Docker containers
	@echo "$(YELLOW)Building Docker containers...$(NC)"
	@docker-compose build --no-cache
	@echo "$(GREEN)Build completed!$(NC)"

start: setup ## Start all services
	@echo "$(YELLOW)Starting services...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)Services started!$(NC)"
	@echo "$(BLUE)Application: http://localhost:8080$(NC)"
	@echo "$(BLUE)phpMyAdmin: http://localhost:8081$(NC)"

stop: ## Stop all services
	@echo "$(YELLOW)Stopping services...$(NC)"
	@docker-compose down
	@echo "$(GREEN)Services stopped!$(NC)"

restart: ## Restart all services
	@echo "$(YELLOW)Restarting services...$(NC)"
	@docker-compose restart
	@echo "$(GREEN)Services restarted!$(NC)"

test: ## Run tests
	@echo "$(YELLOW)Running tests...$(NC)"
	@cp .env.testing .env
	@docker-compose --profile testing build test
	@docker-compose --profile testing run --rm test ./vendor/bin/phpunit
	@if [ -f .env.development ]; then cp .env.development .env; fi
	@echo "$(GREEN)Tests completed!$(NC)"

test-unit: ## Run unit tests only
	@echo "$(YELLOW)Running unit tests...$(NC)"
	@cp .env.testing .env
	@docker-compose --profile testing run --rm test ./vendor/bin/phpunit tests/unit
	@if [ -f .env.development ]; then cp .env.development .env; fi

test-coverage: ## Run tests with coverage
	@echo "$(YELLOW)Running tests with coverage...$(NC)"
	@cp .env.testing .env
	@docker-compose --profile testing run --rm test ./vendor/bin/phpunit --coverage-html coverage --coverage-text
	@if [ -f .env.development ]; then cp .env.development .env; fi
	@echo "$(GREEN)Coverage report generated in ./coverage/$(NC)"

logs: ## Show logs
	@docker-compose logs -f

shell: ## Open shell in app container
	@docker-compose exec app bash

shell-test: ## Open shell in test container
	@docker-compose --profile testing run --rm test bash

clean: ## Clean up containers and volumes
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@docker-compose down -v --remove-orphans
	@docker system prune -f
	@echo "$(GREEN)Cleanup completed!$(NC)"

status: ## Show container status
	@docker-compose ps

rebuild: clean build start ## Clean, build and start

dev: ENV=dev
dev: build start ## Start development environment

prod: ## Start production environment (placeholder)
	@echo "$(YELLOW)Production deployment not configured yet$(NC)"

# Database commands
db-migrate: ## Run database migrations
	@docker-compose exec app php spark migrate

db-seed: ## Run database seeds
	@docker-compose exec app php spark db:seed

db-reset: ## Reset database (migrate:rollback and migrate)
	@docker-compose exec app php spark migrate:rollback
	@docker-compose exec app php spark migrate

# Composer commands
composer-install: ## Install composer dependencies
	@docker-compose exec app composer install

composer-update: ## Update composer dependencies
	@docker-compose exec app composer update

# Cache commands
cache-clear: ## Clear application cache
	@docker-compose exec app php spark cache:clear

# Quick development workflow
quick-test: ## Quick test run (no rebuild)
	@cp .env.testing .env
	@docker-compose --profile testing run --rm test ./vendor/bin/phpunit
	@if [ -f .env.development ]; then cp .env.development .env; fi

fresh-test: ## Complete fresh test environment (removes all containers/volumes)
	@./localDockerTest.sh

fresh-test-no-images: ## Fresh test without removing images (faster)
	@./localDockerTest.sh --skip-tests
