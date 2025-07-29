#!/bin/bash

# KuroPanel Test Runner Script
# This script runs various types of tests for the KuroPanel application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to run tests
run_tests() {
    local test_type=$1
    local test_path=${2:-""}
    
    print_status "Running $test_type tests..."
    
    case $test_type in
        "unit")
            ./vendor/bin/phpunit tests/unit $test_path --testdox
            ;;
        "database")
            ./vendor/bin/phpunit tests/database $test_path --testdox
            ;;
        "session")
            ./vendor/bin/phpunit tests/session $test_path --testdox
            ;;
        "all")
            ./vendor/bin/phpunit --testdox
            ;;
        "coverage")
            ./vendor/bin/phpunit --coverage-html coverage --coverage-text
            ;;
        *)
            print_error "Unknown test type: $test_type"
            exit 1
            ;;
    esac
}

# Function to setup test environment
setup_test_env() {
    print_status "Setting up test environment..."
    
    # Copy test environment file
    if [ -f ".env.testing" ]; then
        cp .env.testing .env
        print_success "Test environment configured"
    else
        print_warning "Test environment file not found, using default"
    fi
    
    # Clear cache
    if [ -d "writable/cache" ]; then
        rm -rf writable/cache/*
        print_success "Cache cleared"
    fi
    
    # Ensure writable directories have correct permissions
    chmod -R 777 writable/
    print_success "Permissions set"
}

# Function to cleanup after tests
cleanup_test_env() {
    print_status "Cleaning up test environment..."
    
    # Restore development environment if it exists
    if [ -f ".env.development" ]; then
        cp .env.development .env
        print_success "Development environment restored"
    fi
    
    # Clean up test artifacts
    if [ -d "writable/logs" ]; then
        find writable/logs -name "log-*.php" -type f -delete
        print_success "Test logs cleaned"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [test_type] [options]"
    echo ""
    echo "Test Types:"
    echo "  unit        - Run unit tests"
    echo "  database    - Run database tests"
    echo "  session     - Run session tests"
    echo "  all         - Run all tests (default)"
    echo "  coverage    - Run tests with coverage report"
    echo ""
    echo "Options:"
    echo "  --setup     - Setup test environment only"
    echo "  --cleanup   - Cleanup test environment only"
    echo "  --filter    - Filter tests by pattern"
    echo "  --verbose   - Verbose output"
    echo ""
    echo "Examples:"
    echo "  $0 all"
    echo "  $0 unit --filter=HealthTest"
    echo "  $0 coverage"
}

# Main execution
main() {
    local test_type="all"
    local filter=""
    local verbose=""
    local setup_only=false
    local cleanup_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            unit|database|session|all|coverage)
                test_type=$1
                shift
                ;;
            --setup)
                setup_only=true
                shift
                ;;
            --cleanup)
                cleanup_only=true
                shift
                ;;
            --filter)
                filter="--filter=$2"
                shift 2
                ;;
            --verbose)
                verbose="--verbose"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Header
    echo "======================================="
    echo "       KuroPanel Test Runner"
    echo "======================================="
    
    # Check if composer dependencies are installed
    if [ ! -d "vendor" ]; then
        print_error "Composer dependencies not found. Run 'composer install' first."
        exit 1
    fi
    
    # Setup only
    if [ "$setup_only" = true ]; then
        setup_test_env
        exit 0
    fi
    
    # Cleanup only
    if [ "$cleanup_only" = true ]; then
        cleanup_test_env
        exit 0
    fi
    
    # Run tests
    trap cleanup_test_env EXIT
    
    setup_test_env
    
    # Execute tests
    start_time=$(date +%s)
    
    if run_tests "$test_type" "$filter $verbose"; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        print_success "All tests completed successfully in ${duration} seconds!"
        
        # Show coverage directory if coverage was generated
        if [ "$test_type" = "coverage" ] && [ -d "coverage" ]; then
            print_status "Coverage report generated in ./coverage/index.html"
        fi
    else
        print_error "Some tests failed!"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
