#!/bin/bash
# KuroPanel Local Docker Test Script for Linux/macOS
# This script removes old containers and creates fresh ones for testing

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

# Configuration
PROJECT_NAME="kuropanel"
CONTAINERS=("${PROJECT_NAME}_app" "${PROJECT_NAME}_db" "${PROJECT_NAME}_phpmyadmin" "${PROJECT_NAME}_test")
IMAGES=("${PROJECT_NAME}_app" "${PROJECT_NAME}_database" "${PROJECT_NAME}_phpmyadmin" "${PROJECT_NAME}_test")
VOLUMES=("${PROJECT_NAME}_db_data")
NETWORKS=("${PROJECT_NAME}_kuropanel")

# Options
REMOVE_IMAGES=false
SKIP_TESTS=false
VERBOSE=false

# Functions
print_header() {
    echo -e "${CYAN}=======================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}=======================================${NC}"
}

print_step() {
    echo -e "${BLUE}[$1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}  → $1${NC}"
}

print_gray() {
    echo -e "${GRAY}  - $1${NC}"
}

show_usage() {
    echo "KuroPanel Local Docker Test Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --remove-images  Remove old Docker images (slower but more thorough)"
    echo "  --skip-tests     Skip running tests after setup"
    echo "  --verbose        Show detailed output"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Standard fresh test"
    echo "  $0 --remove-images      # Full cleanup with image removal"
    echo "  $0 --skip-tests         # Setup only, no tests"
    echo "  $0 --verbose            # Detailed output"
}

test_service_health() {
    local service_name="$1"
    local url="$2"
    local max_attempts="${3:-20}"
    local delay_seconds="${4:-2}"
    
    print_info "Checking $service_name..."
    
    for ((attempt=1; attempt<=max_attempts; attempt++)); do
        if curl -s -f "$url" >/dev/null 2>&1; then
            print_success "$service_name is ready"
            return 0
        fi
        
        if [ $VERBOSE = true ]; then
            echo "    Attempt $attempt/$max_attempts failed" >&2
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            sleep $delay_seconds
        fi
    done
    
    print_warning "$service_name check timed out after $max_attempts attempts"
    return 1
}

test_database_connection() {
    print_info "Checking database connection..."
    
    if docker-compose exec -T database mysqladmin ping -h localhost -u kuro_user -pkuro_password >/dev/null 2>&1; then
        print_success "Database connection successful"
        return 0
    else
        print_warning "Database connection check failed"
        return 1
    fi
}

remove_containers() {
    print_step "1/6" "Stopping existing containers..."
    
    for container in "${CONTAINERS[@]}"; do
        if docker stop "$container" >/dev/null 2>&1; then
            print_success "Stopped: $container"
        else
            print_gray "Not running: $container"
        fi
    done
    
    echo ""
    print_step "2/6" "Removing existing containers..."
    
    for container in "${CONTAINERS[@]}"; do
        if docker rm "$container" >/dev/null 2>&1; then
            print_success "Removed: $container"
        else
            print_gray "Not found: $container"
        fi
    done
}

remove_images() {
    echo ""
    print_step "Optional" "Removing old images..."
    
    for image in "${IMAGES[@]}"; do
        if docker rmi "$image" >/dev/null 2>&1; then
            print_success "Removed image: $image"
        else
            print_gray "Image not found: $image"
        fi
    done
}

remove_volumes() {
    echo ""
    print_step "3/6" "Removing volumes for fresh data..."
    
    for volume in "${VOLUMES[@]}"; do
        if docker volume rm "$volume" >/dev/null 2>&1; then
            print_success "Removed volume: $volume"
        else
            print_gray "Volume not found: $volume"
        fi
    done
}

remove_networks() {
    echo ""
    print_step "4/6" "Cleaning up networks..."
    
    for network in "${NETWORKS[@]}"; do
        if docker network rm "$network" >/dev/null 2>&1; then
            print_success "Removed network: $network"
        else
            print_gray "Network not found or in use: $network"
        fi
    done
}

cleanup_and_exit() {
    echo ""
    print_header "ERROR"
    print_error "Docker test setup failed!"
    echo ""
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo "1. Check if Docker is running"
    echo "2. Ensure ports 8080, 8081, 3306 are available"
    echo "3. Check Docker logs: docker-compose logs"
    echo "4. Try manual cleanup: docker system prune -a"
    echo "5. Run with --verbose for detailed output"
    echo ""
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --remove-images)
            REMOVE_IMAGES=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Set up error handling
trap cleanup_and_exit ERR

# Main execution
print_header "KuroPanel Local Docker Test Script"

echo -e "${YELLOW}Starting fresh Docker test environment...${NC}"
echo ""

# Step 1 & 2: Remove containers
remove_containers

# Optional: Remove images
if [ $REMOVE_IMAGES = true ]; then
    remove_images
fi

# Step 3: Remove volumes
remove_volumes

# Step 4: Remove networks
remove_networks

# Step 5: Setup test environment
echo ""
print_step "5/6" "Setting up test environment..."

if [ -f ".env.testing" ]; then
    cp .env.testing .env
    print_success "Test environment configured"
else
    print_warning ".env.testing not found, using current .env"
fi

# Step 6: Build and start fresh containers
echo ""
print_step "6/6" "Building and starting fresh containers..."

print_info "Building containers (this may take a few minutes)..."
if [ $VERBOSE = true ]; then
    docker-compose build --no-cache --parallel
else
    docker-compose build --no-cache --parallel >/dev/null 2>&1
fi

if [ $? -ne 0 ]; then
    print_error "Build failed!"
    exit 1
fi
print_success "Build completed successfully"

print_info "Starting services..."
docker-compose up -d
if [ $? -ne 0 ]; then
    print_error "Failed to start services!"
    exit 1
fi
print_success "Services started successfully"

# Wait for services to be ready
echo ""
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Health checks
echo ""
echo -e "${YELLOW}Performing health checks...${NC}"
test_service_health "Application" "http://localhost:8080" 30
test_service_health "phpMyAdmin" "http://localhost:8081" 15
test_database_connection

# Run tests (unless skipped)
test_result=0
if [ $SKIP_TESTS = false ]; then
    echo ""
    echo -e "${YELLOW}Running test suite...${NC}"
    
    print_info "Building test container..."
    docker-compose --profile testing build test --no-cache
    if [ $? -ne 0 ]; then
        print_error "Test container build failed!"
        exit 1
    fi
    
    print_info "Running tests..."
    docker-compose --profile testing run --rm test ./vendor/bin/phpunit --testdox
    test_result=$?
fi

# Restore original environment
if [ -f ".env.development" ]; then
    cp .env.development .env
    print_success "Development environment restored"
fi

# Final status
echo ""
print_header "Results"

if [ $SKIP_TESTS = true ] || [ $test_result -eq 0 ]; then
    if [ $SKIP_TESTS = true ]; then
        echo -e "${GREEN}🎉 FRESH DOCKER ENVIRONMENT READY!${NC}"
    else
        echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    fi
    echo -e "${GREEN}📊 Fresh Docker environment is ready${NC}"
    echo ""
    echo -e "${CYAN}Services available at:${NC}"
    echo "• Application: http://localhost:8080"
    echo "• phpMyAdmin:  http://localhost:8081"
    echo "• Database:    localhost:3306"
else
    echo -e "${RED}❌ TESTS FAILED!${NC}"
    echo -e "${RED}Check the test output above for details${NC}"
fi

echo ""
echo -e "${YELLOW}Current container status:${NC}"
docker-compose ps

exit $test_result
