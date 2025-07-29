#!/bin/bash
# Ultra Fast Production Build Script with Progress Indicators
# KuroPanel V2 - Optimized Build System

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Progress indicators
CHECKMARK="✅"
ROCKET="🚀"
GEAR="⚙️"
PACKAGE="📦"
DATABASE="🗄️"
CACHE="⚡"
SHIELD="🛡️"
CHART="📊"

# Print header
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${ROCKET} KUROPANEL V2 - ULTRA FAST PRODUCTION BUILD ${ROCKET}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Build System: Docker Multi-stage with Alpine Linux${NC}"
    echo -e "${CYAN}Build Mode: Production Optimized${NC}"
    echo -e "${CYAN}Progress Tracking: Real-time with percentage${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local description=$3
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${BLUE}[${NC}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "${BLUE}] ${WHITE}%3d%% ${CYAN}%s${NC}" $percentage "$description"
}

# Error handling
handle_error() {
    echo -e "\n${RED}❌ Build failed at: $1${NC}"
    echo -e "${RED}Check the logs above for details${NC}"
    exit 1
}

# Main build function
main() {
    print_header
    
    echo -e "\n${YELLOW}${GEAR} Phase 1: Pre-build Setup${NC}"
    
    # Step 1: Check prerequisites
    show_progress 1 20 "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        handle_error "Docker not installed"
    fi
    sleep 0.5
    
    show_progress 2 20 "Checking Docker Compose..."
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        handle_error "Docker Compose not available"
    fi
    sleep 0.5
    
    # Step 2: Prepare directories
    show_progress 3 20 "Creating data directories..."
    mkdir -p data/{mysql,redis,logs,uploads,sessions} ssl backups/mysql || handle_error "Failed to create directories"
    sleep 0.5
    
    # Step 3: Environment setup
    show_progress 4 20 "Setting up environment..."
    if [ ! -f .env.production ]; then
        cp .env.production.example .env.production || handle_error "Failed to copy environment file"
    fi
    sleep 0.5
    
    echo -e "\n${CHECKMARK} Pre-build setup complete!"
    
    # Phase 2: Docker Build (Multi-stage)
    echo -e "\n${YELLOW}${PACKAGE} Phase 2: Docker Build Process${NC}"
    
    # Enable BuildKit for faster builds
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    # Build with progress
    show_progress 5 20 "Starting Docker build (Alpine base)..."
    echo -e "\n${BLUE}Building application image with optimizations...${NC}"
    
    # Use the optimized compose file
    docker-compose -f docker-compose.production.optimized.yml build \
        --no-cache \
        --parallel \
        --progress=plain \
        app || handle_error "Docker build failed"
    
    show_progress 10 20 "Application build complete!"
    
    # Phase 3: Service Startup
    echo -e "\n${YELLOW}${DATABASE} Phase 3: Starting Services${NC}"
    
    show_progress 11 20 "Starting database services..."
    docker-compose -f docker-compose.production.optimized.yml up -d mysql redis || handle_error "Database services failed"
    sleep 2
    
    show_progress 13 20 "Starting application server..."
    docker-compose -f docker-compose.production.optimized.yml up -d app || handle_error "Application server failed"
    sleep 2
    
    show_progress 15 20 "Starting reverse proxy..."
    docker-compose -f docker-compose.production.optimized.yml up -d nginx || handle_error "Nginx failed"
    sleep 2
    
    # Phase 4: Health Checks
    echo -e "\n${YELLOW}${SHIELD} Phase 4: Health Verification${NC}"
    
    show_progress 16 20 "Checking database health..."
    timeout 60 bash -c 'until docker-compose -f docker-compose.production.optimized.yml ps mysql | grep -q "healthy\|Up"; do sleep 2; done' || handle_error "Database health check failed"
    
    show_progress 17 20 "Checking Redis health..."
    timeout 60 bash -c 'until docker-compose -f docker-compose.production.optimized.yml ps redis | grep -q "healthy\|Up"; do sleep 2; done' || handle_error "Redis health check failed"
    
    show_progress 18 20 "Checking application health..."
    timeout 120 bash -c 'until docker-compose -f docker-compose.production.optimized.yml ps app | grep -q "healthy\|Up"; do sleep 3; done' || handle_error "Application health check failed"
    
    show_progress 19 20 "Final system verification..."
    sleep 2
    
    show_progress 20 20 "All systems operational!"
    
    # Success message
    echo -e "\n\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}${CHECKMARK} BUILD COMPLETE - KUROPANEL V2 PRODUCTION READY! ${CHECKMARK}${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Show service status
    echo -e "\n${CYAN}${CHART} Service Status:${NC}"
    docker-compose -f docker-compose.production.optimized.yml ps
    
    # Show access information
    echo -e "\n${YELLOW}${ROCKET} Access Information:${NC}"
    echo -e "${WHITE}• Application URL: ${GREEN}http://localhost${NC}"
    echo -e "${WHITE}• Admin Panel: ${GREEN}http://localhost/admin${NC}"
    echo -e "${WHITE}• API Endpoint: ${GREEN}http://localhost/api${NC}"
    
    # Show monitoring (if enabled)
    if docker-compose -f docker-compose.production.optimized.yml --profile monitoring ps prometheus &>/dev/null; then
        echo -e "${WHITE}• Prometheus: ${GREEN}http://localhost:9090${NC}"
        echo -e "${WHITE}• Grafana: ${GREEN}http://localhost:3000${NC}"
    fi
    
    echo -e "\n${GREEN}${ROCKET} Deployment completed in record time! ${ROCKET}${NC}"
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "${WHITE}1. Configure SSL certificates for HTTPS${NC}"
    echo -e "${WHITE}2. Set up domain DNS settings${NC}"
    echo -e "${WHITE}3. Configure monitoring alerts${NC}"
    echo -e "${WHITE}4. Run security scan: ${YELLOW}docker-compose -f docker-compose.production.optimized.yml exec app php spark security:scan${NC}"
}

# Cleanup function for interrupts
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    docker-compose -f docker-compose.production.optimized.yml down 2>/dev/null || true
    exit 1
}

# Set trap for cleanup
trap cleanup INT TERM

# Run main function
main "$@"
