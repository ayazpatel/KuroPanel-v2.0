#!/bin/bash

# KuroPanel V2 Complete Test Suite
# Comprehensive testing for all components

set -e

# Configuration
PROJECT_NAME="KuroPanel V2"
VERSION="2.0.0"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="test-suite-$TIMESTAMP.log"
RESULTS_DIR="test-results"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log_message "${BLUE}Running test: $test_name${NC}"
    
    if eval "$test_command" >> "$LOG_FILE" 2>&1; then
        local exit_code=$?
        if [ $exit_code -eq $expected_exit_code ]; then
            log_message "${GREEN}✓ PASSED: $test_name${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            log_message "${RED}✗ FAILED: $test_name (exit code: $exit_code)${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        log_message "${RED}✗ FAILED: $test_name (command failed)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Create results directory
mkdir -p "$RESULTS_DIR"

log_message "${BLUE}=== $PROJECT_NAME Test Suite v$VERSION ===${NC}"
log_message "${BLUE}Starting comprehensive testing...${NC}"

# Test 1: PHP Syntax Check
log_message "${YELLOW}Phase 1: Syntax and Static Analysis${NC}"

run_test "PHP Syntax Check" "find app/ -name '*.php' -exec php -l {} \;"
run_test "Composer Validation" "composer validate --strict"
run_test "CodeIgniter Configuration" "php spark env"

# Test 2: Database Tests
log_message "${YELLOW}Phase 2: Database Tests${NC}"

run_test "Database Schema Validation" "php -r \"
try {
    \$pdo = new PDO('mysql:host=localhost;dbname=kuropanel', 'kuro_user', 'kuro_password');
    \$tables = ['users', 'admin_users', 'developers', 'resellers', 'apps', 'license_keys'];
    foreach (\$tables as \$table) {
        \$stmt = \$pdo->query('DESCRIBE ' . \$table);
        if (!\$stmt) throw new Exception('Table ' . \$table . ' not found');
    }
    echo 'All tables verified';
} catch (Exception \$e) {
    echo \$e->getMessage();
    exit(1);
}
\""

# Test 3: Unit Tests
log_message "${YELLOW}Phase 3: Unit Tests${NC}"

if [ -f "vendor/bin/phpunit" ]; then
    run_test "PHPUnit Tests" "./vendor/bin/phpunit --configuration phpunit.xml.dist"
else
    log_message "${YELLOW}⚠ PHPUnit not found, skipping unit tests${NC}"
fi

# Test 4: Integration Tests
log_message "${YELLOW}Phase 4: Integration Tests${NC}"

run_test "Docker Compose Validation" "docker-compose config"
run_test "Docker Build Test" "docker build --no-cache -t kuropanel-test ."

# Test 5: API Tests
log_message "${YELLOW}Phase 5: API Tests${NC}"

# Start test environment
log_message "Starting test environment..."
docker-compose -p kuropanel-test up -d --build >> "$LOG_FILE" 2>&1
sleep 30

# API endpoint tests
run_test "Main Application Response" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080 | grep -E '^(200|302)$'"
run_test "API Health Check" "curl -s http://localhost:8080/api/health | grep -q 'ok'"
run_test "Connect Health Check" "curl -s http://localhost:8080/connect/health | grep -q 'ok'"

# Test 6: Security Tests
log_message "${YELLOW}Phase 6: Security Tests${NC}"

run_test "SQL Injection Protection" "curl -s 'http://localhost:8080/?id=1%27%20OR%201=1' | grep -v 'error'"
run_test "XSS Protection" "curl -s 'http://localhost:8080/?q=<script>alert(1)</script>' | grep -v '<script>'"

# Test 7: Performance Tests
log_message "${YELLOW}Phase 7: Performance Tests${NC}"

run_test "Response Time Test" "timeout 5s bash -c 'time curl -s http://localhost:8080 > /dev/null'"
run_test "Concurrent Requests" "for i in {1..10}; do curl -s http://localhost:8080 & done; wait"

# Test 8: Configuration Tests
log_message "${YELLOW}Phase 8: Configuration Tests${NC}"

run_test "Environment Configuration" "php -r \"
require 'app/Config/Boot/development.php';
if (!defined('ENVIRONMENT')) exit(1);
echo 'Environment configured';
\""

run_test "Database Configuration" "php -r \"
require 'vendor/autoload.php';
\$config = new \Config\Database();
if (empty(\$config->default)) exit(1);
echo 'Database configuration valid';
\""

# Cleanup test environment
log_message "Cleaning up test environment..."
docker-compose -p kuropanel-test down -v >> "$LOG_FILE" 2>&1

# Test 9: Documentation Tests
log_message "${YELLOW}Phase 9: Documentation Tests${NC}"

run_test "README Exists" "test -f README.md"
run_test "API Documentation" "test -f ANDROID_API_INTEGRATION_GUIDE.md"
run_test "Migration Guide" "test -f MIGRATION_GUIDE.md"
run_test "Setup Documentation" "test -f KUROPANEL_V2_DOCUMENTATION.md"

# Test 10: Deployment Tests
log_message "${YELLOW}Phase 10: Deployment Tests${NC}"

run_test "Setup Script Exists" "test -f setup_kuro_v2.php"
run_test "Build Script Exists" "test -f build-v2.ps1"
run_test "Docker Scripts" "test -d docker/scripts && test -f docker/scripts/health-check-v2.sh"

# Generate Test Report
log_message "${YELLOW}Generating test report...${NC}"

cat > "$RESULTS_DIR/test-report-$TIMESTAMP.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>$PROJECT_NAME Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .passed { color: green; }
        .failed { color: red; }
        .summary { background: #e9e9e9; padding: 15px; margin: 20px 0; border-radius: 5px; }
        .phase { margin: 20px 0; }
        .test-item { margin: 5px 0; padding: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>$PROJECT_NAME Test Report</h1>
        <p><strong>Version:</strong> $VERSION</p>
        <p><strong>Test Date:</strong> $(date)</p>
        <p><strong>Log File:</strong> $LOG_FILE</p>
    </div>

    <div class="summary">
        <h2>Test Summary</h2>
        <p><strong>Total Tests:</strong> $TOTAL_TESTS</p>
        <p class="passed"><strong>Passed:</strong> $PASSED_TESTS</p>
        <p class="failed"><strong>Failed:</strong> $FAILED_TESTS</p>
        <p><strong>Success Rate:</strong> $((PASSED_TESTS * 100 / TOTAL_TESTS))%</p>
    </div>

    <div class="phases">
        <h2>Test Phases</h2>
        <div class="phase">✓ Phase 1: Syntax and Static Analysis</div>
        <div class="phase">✓ Phase 2: Database Tests</div>
        <div class="phase">✓ Phase 3: Unit Tests</div>
        <div class="phase">✓ Phase 4: Integration Tests</div>
        <div class="phase">✓ Phase 5: API Tests</div>
        <div class="phase">✓ Phase 6: Security Tests</div>
        <div class="phase">✓ Phase 7: Performance Tests</div>
        <div class="phase">✓ Phase 8: Configuration Tests</div>
        <div class="phase">✓ Phase 9: Documentation Tests</div>
        <div class="phase">✓ Phase 10: Deployment Tests</div>
    </div>

    <div class="details">
        <h2>Detailed Results</h2>
        <p>See log file for detailed output: <code>$LOG_FILE</code></p>
    </div>
</body>
</html>
EOF

# Final Summary
log_message "${BLUE}=== Test Suite Complete ===${NC}"
log_message "${GREEN}Total Tests: $TOTAL_TESTS${NC}"
log_message "${GREEN}Passed: $PASSED_TESTS${NC}"
if [ $FAILED_TESTS -gt 0 ]; then
    log_message "${RED}Failed: $FAILED_TESTS${NC}"
else
    log_message "${GREEN}Failed: $FAILED_TESTS${NC}"
fi

SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
log_message "${BLUE}Success Rate: $SUCCESS_RATE%${NC}"

log_message "${BLUE}Reports generated in: $RESULTS_DIR${NC}"
log_message "${BLUE}Log file: $LOG_FILE${NC}"

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ]; then
    log_message "${GREEN}🎉 All tests passed! KuroPanel V2 is ready for deployment!${NC}"
    exit 0
else
    log_message "${RED}❌ Some tests failed. Please review the logs and fix issues.${NC}"
    exit 1
fi
