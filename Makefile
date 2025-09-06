# Makefile for xsukax Ollama WebUI Docker Management
# Usage: make [command]

# Variables
IMAGE_NAME := xsukax-ollama-webui
CONTAINER_NAME := ollama-webui
VERSION := latest
PORT := 3553

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

.PHONY: help build run start stop restart logs shell clean status push pull compose-up compose-down

# Default target - show help
help:
	@echo "$(GREEN)xsukax Ollama WebUI Docker Management$(NC)"
	@echo "$(YELLOW)Usage: make [command]$(NC)"
	@echo ""
	@echo "Available commands:"
	@echo "  $(GREEN)build$(NC)       - Build the Docker image"
	@echo "  $(GREEN)run$(NC)         - Run the container (port $(PORT))"
	@echo "  $(GREEN)start$(NC)       - Start stopped container"
	@echo "  $(GREEN)stop$(NC)        - Stop running container"
	@echo "  $(GREEN)restart$(NC)     - Restart the container"
	@echo "  $(GREEN)logs$(NC)        - View container logs"
	@echo "  $(GREEN)shell$(NC)       - Open shell in container"
	@echo "  $(GREEN)clean$(NC)       - Remove container and image"
	@echo "  $(GREEN)status$(NC)      - Show container status"
	@echo "  $(GREEN)compose-up$(NC)  - Start with docker-compose"
	@echo "  $(GREEN)compose-down$(NC)- Stop docker-compose"
	@echo "  $(GREEN)test$(NC)        - Test the application"
	@echo "  $(GREEN)health$(NC)      - Check health status"

# Build Docker image
build:
	@echo "$(YELLOW)Building Docker image...$(NC)"
	docker build -t $(IMAGE_NAME):$(VERSION) .
	@echo "$(GREEN)✓ Image built successfully$(NC)"

# Run container
run: stop
	@echo "$(YELLOW)Starting container on port $(PORT)...$(NC)"
	docker run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):80 \
		--add-host=host.docker.internal:host-gateway \
		--restart unless-stopped \
		$(IMAGE_NAME):$(VERSION)
	@echo "$(GREEN)✓ Container running at http://localhost:$(PORT)$(NC)"

# Start stopped container
start:
	@echo "$(YELLOW)Starting container...$(NC)"
	docker start $(CONTAINER_NAME)
	@echo "$(GREEN)✓ Container started$(NC)"

# Stop container
stop:
	@echo "$(YELLOW)Stopping container...$(NC)"
	-docker stop $(CONTAINER_NAME) 2>/dev/null || true
	-docker rm $(CONTAINER_NAME) 2>/dev/null || true
	@echo "$(GREEN)✓ Container stopped$(NC)"

# Restart container
restart:
	@echo "$(YELLOW)Restarting container...$(NC)"
	docker restart $(CONTAINER_NAME)
	@echo "$(GREEN)✓ Container restarted$(NC)"

# View logs
logs:
	@echo "$(YELLOW)Showing container logs (Ctrl+C to exit)...$(NC)"
	docker logs -f $(CONTAINER_NAME)

# Open shell in container
shell:
	@echo "$(YELLOW)Opening shell in container...$(NC)"
	docker exec -it $(CONTAINER_NAME) sh

# Clean up everything
clean: stop
	@echo "$(YELLOW)Cleaning up...$(NC)"
	-docker rmi $(IMAGE_NAME):$(VERSION) 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

# Show status
status:
	@echo "$(YELLOW)Container Status:$(NC)"
	@docker ps -a --filter name=$(CONTAINER_NAME) --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "$(YELLOW)Image Status:$(NC)"
	@docker images $(IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Docker Compose commands
compose-up:
	@echo "$(YELLOW)Starting with docker-compose...$(NC)"
	docker-compose up -d --build
	@echo "$(GREEN)✓ Services started$(NC)"

compose-down:
	@echo "$(YELLOW)Stopping docker-compose services...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Services stopped$(NC)"

# Test the application
test:
	@echo "$(YELLOW)Testing application...$(NC)"
	@curl -f http://localhost:$(PORT)/health >/dev/null 2>&1 && \
		echo "$(GREEN)✓ Health check passed$(NC)" || \
		echo "$(RED)✗ Health check failed$(NC)"
	@curl -f http://localhost:$(PORT)/ >/dev/null 2>&1 && \
		echo "$(GREEN)✓ Application responding$(NC)" || \
		echo "$(RED)✗ Application not responding$(NC)"

# Health check
health:
	@echo "$(YELLOW)Checking health status...$(NC)"
	@docker inspect --format='{{.State.Health.Status}}' $(CONTAINER_NAME) 2>/dev/null || echo "Container not running"
	@echo ""
	@curl -s http://localhost:$(PORT)/health 2>/dev/null && echo "$(GREEN)✓ HTTP health check OK$(NC)" || echo "$(RED)✗ HTTP health check failed$(NC)"

# Build and run in one command
up: build run
	@echo "$(GREEN)✓ Application is ready at http://localhost:$(PORT)$(NC)"

# Rebuild and restart
rebuild: stop build run
	@echo "$(GREEN)✓ Application rebuilt and running$(NC)"

# Development mode with live reload
dev:
	@echo "$(YELLOW)Starting in development mode with live reload...$(NC)"
	docker run -d \
		--name $(CONTAINER_NAME)-dev \
		-p $(PORT):80 \
		-v $$(pwd)/index.html:/usr/share/nginx/html/index.html:ro \
		--add-host=host.docker.internal:host-gateway \
		$(IMAGE_NAME):$(VERSION)
	@echo "$(GREEN)✓ Development mode active - changes to index.html will be reflected$(NC)"

# Show make targets
.DEFAULT_GOAL := help