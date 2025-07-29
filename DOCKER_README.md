# KuroPanel Docker Setup

This document describes the Docker containerization and automated testing setup for the KuroPanel CodeIgniter 4 application.

## 🐳 Docker Architecture

The setup includes the following services:

- **app**: Main PHP/Apache application container
- **database**: MySQL 8.0 database
- **phpmyadmin**: Database management interface
- **test**: Dedicated testing container

## 📋 Prerequisites

- Docker Desktop installed
- Docker Compose installed
- Git installed

## 🚀 Quick Start

### Windows (PowerShell)
```powershell
# Build and start development environment
.\build.ps1 build dev
.\build.ps1 start dev

# Or use batch file
build.bat build dev
build.bat start dev
```

### Linux/macOS (Make)
```bash
# Build and start development environment
make dev

# Or manually
make build ENV=dev
make start ENV=dev
```

## 🛠️ Available Commands

### PowerShell Script (`build.ps1`)

```powershell
# Build containers
.\build.ps1 build [dev|test]

# Start services
.\build.ps1 start [dev|test]

# Stop services
.\build.ps1 stop

# Restart services
.\build.ps1 restart

# Run tests
.\build.ps1 test

# View logs
.\build.ps1 logs

# Clean up
.\build.ps1 clean

# Open shell
.\build.ps1 shell
```

### Makefile Commands

```bash
# Show all available commands
make help

# Development workflow
make dev                 # Build and start development environment
make test               # Run all tests
make test-unit          # Run unit tests only
make test-coverage      # Run tests with coverage report

# Container management
make build              # Build containers
make start              # Start services
make stop               # Stop services
make restart            # Restart services
make clean              # Clean up everything

# Database operations
make db-migrate         # Run migrations
make db-seed           # Run database seeds
make db-reset          # Reset database

# Utility commands
make logs              # View logs
make shell             # Open app container shell
make status            # Show container status
```

## 🌐 Service URLs

After starting the services:

- **Application**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8081
  - Server: `database`
  - Username: `root`
  - Password: `root_password`

## 🧪 Testing

### Automated Testing

The setup includes comprehensive testing automation:

```bash
# Run all tests
make test

# Run specific test types
make test-unit
./run-tests.sh unit

# Run tests with coverage
make test-coverage
./run-tests.sh coverage

# Run database tests
./run-tests.sh database

# Filter tests
./run-tests.sh unit --filter=HealthTest
```

### Test Environments

- **Development** (`.env.development`): Full MySQL setup
- **Testing** (`.env.testing`): SQLite in-memory database for fast tests

### Test Structure

```
tests/
├── unit/           # Unit tests
├── database/       # Database integration tests
├── session/        # Session tests
└── _support/       # Test support classes
```

## 🗄️ Database Configuration

### Development Database
- **Host**: `database` (container name)
- **Database**: `kuropanel`
- **Username**: `kuro_user`
- **Password**: `kuro_password`
- **Port**: `3306`

### Test Database
- **Type**: SQLite in-memory
- **Auto-reset**: After each test

## 📁 Project Structure

```
KuroPanel/
├── docker/
│   └── apache/
│       └── 000-default.conf    # Apache configuration
├── app/                        # CodeIgniter application
├── public/                     # Web root
├── tests/                      # Test files
├── writable/                   # Cache, logs, sessions
├── Dockerfile                  # Main app container
├── Dockerfile.test             # Testing container
├── docker-compose.yml          # Service orchestration
├── .env.development           # Development environment
├── .env.testing              # Testing environment
├── build.ps1                 # PowerShell automation script
├── build.bat                 # Batch automation script
├── Makefile                  # Make automation
└── run-tests.sh             # Advanced test runner
```

## 🔧 Configuration

### Environment Variables

The setup uses different environment files for different stages:

- `.env.development`: Development with MySQL
- `.env.testing`: Testing with SQLite
- `.env.production`: Production (to be configured)

### Docker Compose Profiles

- **default**: app, database, phpmyadmin
- **testing**: Includes test container

## 📊 Development Workflow

### 1. Initial Setup
```bash
# Clone repository
git clone <repository-url>
cd KuroPanel

# Build and start
make dev
```

### 2. Development Cycle
```bash
# Make code changes...

# Run tests
make test

# Check logs if needed
make logs

# Restart if configuration changed
make restart
```

### 3. Testing Workflow
```bash
# Quick test run
make quick-test

# Full test suite with coverage
make test-coverage

# Test specific components
./run-tests.sh unit --filter=UserModel
```

## 🐛 Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check what's using the ports
   netstat -ano | findstr :8080
   netstat -ano | findstr :3306
   ```

2. **Permission Issues**
   ```bash
   # Fix writable directory permissions
   make shell
   chmod -R 777 writable/
   ```

3. **Database Connection Issues**
   ```bash
   # Check database container status
   make status
   
   # Check database logs
   docker-compose logs database
   ```

4. **Build Failures**
   ```bash
   # Clean build
   make clean
   make build
   ```

### Reset Everything
```bash
# Nuclear option - clean everything and start fresh
make clean
docker system prune -a
make dev
```

## 📈 Performance Optimization

### Docker Build Optimization
- Multi-stage builds for smaller images
- `.dockerignore` to exclude unnecessary files
- Layer caching for faster rebuilds

### Application Optimization
- OpCache enabled in production
- Composer autoloader optimization
- Asset compression enabled

## 🔒 Security Considerations

- Environment-specific configurations
- Secrets managed through environment variables
- Non-root user in containers (production)
- Security headers configured in Apache

## 📝 Logging

Logs are available through:
```bash
# All services
make logs

# Specific service
docker-compose logs app
docker-compose logs database

# Follow logs
docker-compose logs -f app
```

Log files are also available in:
- Application logs: `writable/logs/`
- Apache logs: Container `/var/log/apache2/`
- Database logs: Container `/var/log/mysql/`

## 🚀 Production Deployment

For production deployment:

1. Create `.env.production` with production settings
2. Modify `docker-compose.yml` for production
3. Set up proper SSL certificates
4. Configure reverse proxy (nginx)
5. Set up monitoring and backups

## 🤝 Contributing

1. Make changes in feature branches
2. Run full test suite: `make test-coverage`
3. Ensure all tests pass
4. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
