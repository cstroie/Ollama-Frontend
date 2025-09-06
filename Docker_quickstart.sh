#!/bin/bash

# Quick Start Script for xsukax Ollama WebUI Docker
# This script automates the Docker setup and deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="xsukax-ollama-webui"
CONTAINER_NAME="ollama-webui"
PORT=3553

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   xsukax Ollama WebUI Docker Setup${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}➜ $1${NC}"
}

check_docker() {
    print_info "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker is installed"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    print_success "Docker daemon is running"
}

check_ollama() {
    print_info "Checking Ollama installation..."
    if ! command -v ollama &> /dev/null; then
        print_error "Ollama is not installed"
        echo "Visit: https://ollama.ai to install Ollama"
        echo "Or the container won't be able to connect to Ollama"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Ollama is installed"
        
        # Check if Ollama is running
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            print_success "Ollama is running"
        else
            print_info "Starting Ollama with CORS enabled..."
            OLLAMA_ORIGINS=* ollama serve &
            sleep 3
            print_success "Ollama started with CORS enabled"
        fi
    fi
}

check_port() {
    print_info "Checking port availability..."
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_error "Port $PORT is already in use"
        read -p "Stop the service using port $PORT? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker stop $(docker ps -q --filter "publish=$PORT") 2>/dev/null || true
            print_success "Port $PORT is now available"
        else
            print_error "Cannot continue with port $PORT in use"
            exit 1
        fi
    else
        print_success "Port $PORT is available"
    fi
}

check_files() {
    print_info "Checking required files..."
    local missing_files=()
    
    for file in "index.html" "Dockerfile" "nginx.conf" "default.conf"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_error "Missing required files: ${missing_files[*]}"
        echo "Please ensure all Docker files are in the current directory"
        exit 1
    fi
    print_success "All required files are present"
}

build_image() {
    print_info "Building Docker image..."
    if docker build -t $IMAGE_NAME:latest . > /dev/null 2>&1; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        echo "Run 'docker build -t $IMAGE_NAME:latest .' to see detailed error"
        exit 1
    fi
}

stop_existing() {
    if docker ps -a | grep -q $CONTAINER_NAME; then
        print_info "Stopping existing container..."
        docker stop $CONTAINER_NAME > /dev/null 2>&1 || true
        docker rm $CONTAINER_NAME > /dev/null 2>&1 || true
        print_success "Existing container removed"
    fi
}

run_container() {
    print_info "Starting container..."
    
    # Detect OS for proper host networking
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        EXTRA_ARGS="--add-host=host.docker.internal:host-gateway"
    elif [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        EXTRA_ARGS="--add-host=host.docker.internal:host-gateway"
    else
        EXTRA_ARGS=""
    fi
    
    if docker run -d \
        --name $CONTAINER_NAME \
        -p $PORT:80 \
        $EXTRA_ARGS \
        --restart unless-stopped \
        $IMAGE_NAME:latest > /dev/null 2>&1; then
        print_success "Container started successfully"
    else
        print_error "Failed to start container"
        echo "Run 'docker logs $CONTAINER_NAME' to see detailed error"
        exit 1
    fi
}

wait_for_health() {
    print_info "Waiting for application to be ready..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f http://localhost:$PORT/health > /dev/null 2>&1; then
            print_success "Application is healthy"
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    print_error "Application health check timed out"
    return 1
}

show_info() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Deployment Successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Access the application at:${NC}"
    echo -e "${YELLOW}  http://localhost:$PORT${NC}"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo -e "  ${YELLOW}docker logs $CONTAINER_NAME${NC}        - View logs"
    echo -e "  ${YELLOW}docker stop $CONTAINER_NAME${NC}        - Stop container"
    echo -e "  ${YELLOW}docker start $CONTAINER_NAME${NC}       - Start container"
    echo -e "  ${YELLOW}docker restart $CONTAINER_NAME${NC}     - Restart container"
    echo -e "  ${YELLOW}make help${NC}                        - Show all make commands (if make is installed)"
    echo ""
    echo -e "${BLUE}Ollama Configuration:${NC}"
    echo -e "  Ensure Ollama is running with: ${YELLOW}OLLAMA_ORIGINS=* ollama serve${NC}"
    echo ""
}

# Main execution
main() {
    print_header
    
    # Run all checks
    check_docker
    check_files
    check_ollama
    check_port
    
    # Build and deploy
    stop_existing
    build_image
    run_container
    
    # Wait and verify
    wait_for_health
    
    # Show success info
    show_info
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main

# Open browser (optional)
read -p "Open browser now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:$PORT
    elif command -v open &> /dev/null; then
        open http://localhost:$PORT
    elif command -v start &> /dev/null; then
        start http://localhost:$PORT
    else
        print_info "Please open http://localhost:$PORT in your browser"
    fi
fi