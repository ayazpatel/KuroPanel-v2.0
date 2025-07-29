#!/bin/bash

# KuroPanel v2.0 Setup Script
# This script sets up the upgraded 4-role license management system

echo "=================================================="
echo "KuroPanel v2.0 - 4-Role System Setup"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as administrator (Windows) or root (Linux)
check_permissions() {
    print_step "Checking permissions..."
    
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows check
        if ! net session >/dev/null 2>&1; then
            print_error "Please run this script as Administrator"
            exit 1
        fi
    else
        # Unix/Linux check
        if [[ $EUID -eq 0 ]]; then
            print_warning "Running as root. Consider using a non-root user for security."
        fi
    fi
    
    print_status "Permissions check passed"
}

# Check system requirements
check_requirements() {
    print_step "Checking system requirements..."
    
    # Check PHP version
    if command -v php >/dev/null 2>&1; then
        php_version=$(php -r "echo PHP_VERSION;")
        print_status "PHP version: $php_version"
        
        # Check if PHP version is 8.1 or higher
        if php -r "exit(version_compare(PHP_VERSION, '8.1.0', '<') ? 1 : 0);"; then
            print_error "PHP 8.1+ is required. Current version: $php_version"
            exit 1
        fi
    else
        print_error "PHP is not installed or not in PATH"
        exit 1
    fi
    
    # Check MySQL/MariaDB
    if command -v mysql >/dev/null 2>&1; then
        mysql_version=$(mysql --version)
        print_status "MySQL found: $mysql_version"
    else
        print_warning "MySQL not found in PATH"
    fi
    
    # Check Composer
    if command -v composer >/dev/null 2>&1; then
        composer_version=$(composer --version)
        print_status "Composer found: $composer_version"
    else
        print_error "Composer is required but not found"
        exit 1
    fi
    
    print_status "System requirements check completed"
}

# Setup database
setup_database() {
    print_step "Setting up database..."
    
    read -p "Enter MySQL host (default: localhost): " db_host
    db_host=${db_host:-localhost}
    
    read -p "Enter MySQL port (default: 3306): " db_port
    db_port=${db_port:-3306}
    
    read -p "Enter MySQL username: " db_user
    read -s -p "Enter MySQL password: " db_pass
    echo
    
    read -p "Enter database name (default: kuropanel_v2): " db_name
    db_name=${db_name:-kuropanel_v2}
    
    # Test connection
    if mysql -h"$db_host" -P"$db_port" -u"$db_user" -p"$db_pass" -e "SELECT 1;" >/dev/null 2>&1; then
        print_status "Database connection successful"
    else
        print_error "Failed to connect to database"
        exit 1
    fi
    
    # Create database if not exists
    mysql -h"$db_host" -P"$db_port" -u"$db_user" -p"$db_pass" -e "CREATE DATABASE IF NOT EXISTS $db_name;" 2>/dev/null
    
    # Import database schema
    if [[ -f "kuro_upgraded.sql" ]]; then
        print_status "Importing database schema..."
        mysql -h"$db_host" -P"$db_port" -u"$db_user" -p"$db_pass" "$db_name" < kuro_upgraded.sql
        if [[ $? -eq 0 ]]; then
            print_status "Database schema imported successfully"
        else
            print_error "Failed to import database schema"
            exit 1
        fi
    else
        print_error "Database schema file (kuro_upgraded.sql) not found"
        exit 1
    fi
}

# Setup environment files
setup_environment() {
    print_step "Setting up environment configuration..."
    
    # Create .env files if they don't exist
    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.development" ]]; then
            cp .env.development .env
            print_status "Created .env from .env.development"
        else
            print_warning ".env.development not found, creating basic .env"
            cat > .env << EOF
#--------------------------------------------------------------------
# KuroPanel v2.0 Environment Configuration
#--------------------------------------------------------------------

CI_ENVIRONMENT = development

#--------------------------------------------------------------------
# DATABASE
#--------------------------------------------------------------------

database.default.hostname = $db_host
database.default.database = $db_name
database.default.username = $db_user
database.default.password = $db_pass
database.default.DBDriver = MySQLi
database.default.DBPrefix = 
database.default.port = $db_port

#--------------------------------------------------------------------
# APP
#--------------------------------------------------------------------

app.baseURL = 'http://localhost:8080'
app.sessionDriver = 'CodeIgniter\Session\Handlers\FileHandler'
app.sessionSavePath = null
app.sessionMatchIP = false
app.sessionTimeToUpdate = 300
app.sessionRegenerateDestroy = false

#--------------------------------------------------------------------
# SECURITY
#--------------------------------------------------------------------

security.csrfProtection = 'cookie'
security.tokenRandomize = false
security.tokenName = 'csrf_token_name'
security.headerName = 'X-CSRF-TOKEN'
security.cookieName = 'csrf_cookie_name'
security.expires = 7200
security.regenerate = true
security.redirect = true

#--------------------------------------------------------------------
# TELEGRAM
#--------------------------------------------------------------------

telegram.botToken = 
telegram.webhookUrl = 
telegram.notifications = true

#--------------------------------------------------------------------
# PAYMENT
#--------------------------------------------------------------------

payment.currency = USD
payment.currencySymbol = $
payment.hwidResetCost = 5.00
payment.defaultLicenseDuration = 30

EOF
        fi
    fi
    
    print_status "Environment configuration completed"
}

# Install/update dependencies
install_dependencies() {
    print_step "Installing/updating dependencies..."
    
    if [[ -f "composer.json" ]]; then
        composer install --optimize-autoloader --no-dev
        if [[ $? -eq 0 ]]; then
            print_status "Dependencies installed successfully"
        else
            print_error "Failed to install dependencies"
            exit 1
        fi
    else
        print_warning "composer.json not found, skipping dependency installation"
    fi
}

# Setup file permissions
setup_permissions() {
    print_step "Setting up file permissions..."
    
    # Make writable directories
    directories=("writable" "writable/cache" "writable/logs" "writable/session" "writable/uploads")
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            chmod -R 755 "$dir"
            print_status "Set permissions for $dir"
        else
            mkdir -p "$dir"
            chmod -R 755 "$dir"
            print_status "Created and set permissions for $dir"
        fi
    done
    
    # Create index.html files for security
    for dir in "${directories[@]}"; do
        if [[ ! -f "$dir/index.html" ]]; then
            echo "<!DOCTYPE html><html><head><title>403 Forbidden</title></head><body><h1>Directory access is forbidden.</h1></body></html>" > "$dir/index.html"
        fi
    done
    
    print_status "File permissions setup completed"
}

# Setup Docker (optional)
setup_docker() {
    print_step "Setting up Docker environment (optional)..."
    
    read -p "Do you want to set up Docker containers? (y/N): " setup_docker_choice
    
    if [[ "$setup_docker_choice" =~ ^[Yy]$ ]]; then
        if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
            print_status "Docker and Docker Compose found"
            
            # Update docker-compose.yml with database credentials
            if [[ -f "docker-compose.yml" ]]; then
                print_status "Updating Docker configuration..."
                
                # Create a temporary docker-compose override
                cat > docker-compose.override.yml << EOF
version: '3.8'

services:
  db:
    environment:
      MYSQL_ROOT_PASSWORD: $db_pass
      MYSQL_DATABASE: $db_name
      MYSQL_USER: $db_user
      MYSQL_PASSWORD: $db_pass

  app:
    environment:
      DB_HOST: db
      DB_NAME: $db_name
      DB_USER: $db_user
      DB_PASS: $db_pass
EOF
                
                # Build and start containers
                docker-compose build --no-cache
                docker-compose up -d
                
                if [[ $? -eq 0 ]]; then
                    print_status "Docker containers started successfully"
                    print_status "Application will be available at: http://localhost:8080"
                    print_status "phpMyAdmin will be available at: http://localhost:8081"
                else
                    print_error "Failed to start Docker containers"
                fi
            else
                print_error "docker-compose.yml not found"
            fi
        else
            print_error "Docker and/or Docker Compose not found"
        fi
    else
        print_status "Skipping Docker setup"
    fi
}

# Create admin user
create_admin_user() {
    print_step "Creating admin user..."
    
    read -p "Enter admin username (default: admin): " admin_user
    admin_user=${admin_user:-admin}
    
    read -p "Enter admin email: " admin_email
    
    read -s -p "Enter admin password: " admin_pass
    echo
    
    read -s -p "Confirm admin password: " admin_pass_confirm
    echo
    
    if [[ "$admin_pass" != "$admin_pass_confirm" ]]; then
        print_error "Passwords do not match"
        return 1
    fi
    
    # Hash password (basic MD5 + bcrypt as per the helper function)
    hashed_pass=$(php -r "
        function create_password(\$password) {
            \$optn = ['cost' => 8];
            \$patt = 'XquxmymXDtWRA66D';
            \$hash = md5(\$patt . \$password);
            return password_hash(\$hash, PASSWORD_DEFAULT, \$optn);
        }
        echo create_password('$admin_pass');
    ")
    
    # Insert admin user
    mysql -h"$db_host" -P"$db_port" -u"$db_user" -p"$db_pass" "$db_name" -e "
        INSERT INTO users (fullname, username, email, level, saldo, status, password, created_at) 
        VALUES ('System Administrator', '$admin_user', '$admin_email', 1, 1000.00, 1, '$hashed_pass', NOW())
        ON DUPLICATE KEY UPDATE 
        password = '$hashed_pass', 
        email = '$admin_email',
        updated_at = NOW();
    " 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        print_status "Admin user created/updated successfully"
        print_status "Username: $admin_user"
        print_status "Email: $admin_email"
    else
        print_error "Failed to create admin user"
    fi
}

# Final setup verification
verify_setup() {
    print_step "Verifying setup..."
    
    # Check if we can connect to database and find the admin user
    admin_count=$(mysql -h"$db_host" -P"$db_port" -u"$db_user" -p"$db_pass" "$db_name" -se "SELECT COUNT(*) FROM users WHERE level = 1;" 2>/dev/null)
    
    if [[ "$admin_count" -gt 0 ]]; then
        print_status "Database verification passed - Admin user found"
    else
        print_warning "Database verification failed - No admin user found"
    fi
    
    # Check if required directories exist
    if [[ -d "writable" && -d "app" && -d "public" ]]; then
        print_status "Directory structure verification passed"
    else
        print_warning "Directory structure verification failed"
    fi
    
    print_status "Setup verification completed"
}

# Main setup function
main() {
    echo "Starting KuroPanel v2.0 setup..."
    echo
    
    check_permissions
    echo
    
    check_requirements
    echo
    
    setup_database
    echo
    
    setup_environment
    echo
    
    install_dependencies
    echo
    
    setup_permissions
    echo
    
    create_admin_user
    echo
    
    setup_docker
    echo
    
    verify_setup
    echo
    
    echo "=================================================="
    echo -e "${GREEN}KuroPanel v2.0 setup completed successfully!${NC}"
    echo "=================================================="
    echo
    echo "Next steps:"
    echo "1. Configure your web server to point to the 'public' directory"
    echo "2. Set up SSL certificate for production"
    echo "3. Configure Telegram bot (optional)"
    echo "4. Set up payment gateway integration (optional)"
    echo "5. Access the admin panel to configure system settings"
    echo
    echo "Default access URLs:"
    echo "- Application: http://localhost:8080 (if using Docker)"
    echo "- Admin Panel: http://localhost:8080/admin"
    echo "- API Documentation: http://localhost:8080/api/docs"
    echo
    echo "For more information, see: KUROPANEL_V2_DOCUMENTATION.md"
}

# Run main function
main "$@"
