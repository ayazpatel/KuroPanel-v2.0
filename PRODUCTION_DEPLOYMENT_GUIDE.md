# KuroPanel V2 Production Deployment Guide

## Overview

This guide covers the complete production deployment of KuroPanel V2 with Docker containers, optimized for security, performance, and scalability.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Production Environment                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Nginx     │  │   Apache    │  │  Supervisor │        │
│  │ Load Balancer│  │ Web Server  │  │  Process    │        │
│  │             │  │             │  │  Manager    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                 │                 │              │
│         └─────────────────┼─────────────────┘              │
│                           │                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   MySQL     │  │    Redis    │  │  Monitoring │        │
│  │  Database   │  │    Cache    │  │   Stack     │        │
│  │             │  │             │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### System Requirements

- **CPU**: 4+ cores (8+ recommended)
- **RAM**: 8GB minimum (16GB+ recommended)
- **Disk**: 50GB+ SSD storage
- **OS**: Ubuntu 20.04+, CentOS 8+, or Windows Server 2019+
- **Network**: Static IP, domain name, SSL certificates

### Software Requirements

- Docker 20.10+
- Docker Compose 2.0+
- Git 2.30+
- OpenSSL (for SSL certificates)

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/your-org/kuropanel-v2.git
cd kuropanel-v2
```

### 2. Configure Environment

```bash
# Copy and edit production environment
cp .env.production.example .env.production
nano .env.production
```

**Required Configuration:**

```bash
# Domain and SSL
DOMAIN=panel.yourdomain.com
APP_BASEURL=https://panel.yourdomain.com

# Database Security
DB_PASS=your_secure_database_password
MYSQL_ROOT_PASSWORD=your_secure_root_password

# Redis Security
REDIS_PASS=your_secure_redis_password

# Application Security
JWT_SECRET=your_jwt_secret_minimum_32_characters
ENCRYPTION_KEY=your_encryption_key_minimum_32_chars
SESSION_SECRET=your_session_secret_minimum_32_chars

# Email Configuration
SMTP_HOST=smtp.yourdomain.com
SMTP_USER=noreply@yourdomain.com
SMTP_PASS=your_smtp_password

# Telegram Integration (Optional)
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
TELEGRAM_CHAT_ID=your_telegram_chat_id
```

### 3. Setup SSL Certificates

```bash
# Option A: Let's Encrypt (Recommended)
certbot certonly --webroot -w ./public -d panel.yourdomain.com
mkdir -p ssl
cp /etc/letsencrypt/live/panel.yourdomain.com/fullchain.pem ssl/
cp /etc/letsencrypt/live/panel.yourdomain.com/privkey.pem ssl/

# Option B: Self-signed (Development)
./deploy-production.sh ssl panel.yourdomain.com
```

### 4. Deploy to Production

```bash
# Linux/macOS
./deploy-production.sh deploy

# Windows
.\deploy-production.ps1 -Action deploy
```

## Manual Deployment Steps

### 1. System Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create data directories
sudo mkdir -p /opt/kuropanel/{data,backups,logs,ssl}
sudo chown -R $USER:$USER /opt/kuropanel
```

### 2. Configure Data Paths

```bash
# Update .env.production with absolute paths
DATA_PATH=/opt/kuropanel/data
BACKUP_PATH=/opt/kuropanel/backups
SSL_PATH=/opt/kuropanel/ssl
```

### 3. Build and Deploy

```bash
# Build production images
docker-compose -f docker-compose.production.yml build

# Start core services
docker-compose -f docker-compose.production.yml up -d app database redis

# Wait for database initialization
sleep 60

# Run database setup
docker-compose -f docker-compose.production.yml exec app php spark migrate:latest

# Start all services
docker-compose -f docker-compose.production.yml up -d
```

## Service Management

### Start/Stop Services

```bash
# Start all services
docker-compose -f docker-compose.production.yml up -d

# Stop all services
docker-compose -f docker-compose.production.yml down

# Restart specific service
docker-compose -f docker-compose.production.yml restart app

# View service status
docker-compose -f docker-compose.production.yml ps
```

### Scaling Services

```bash
# Scale application instances
docker-compose -f docker-compose.production.yml up -d --scale app=3

# Scale with load balancer
docker-compose -f docker-compose.production.yml --profile with-nginx up -d --scale app=3
```

### Log Management

```bash
# View all logs
docker-compose -f docker-compose.production.yml logs -f

# View specific service logs
docker-compose -f docker-compose.production.yml logs -f app

# View last 100 lines
docker-compose -f docker-compose.production.yml logs --tail=100 app
```

## Monitoring and Observability

### Health Checks

```bash
# Application health
curl http://localhost/api/health

# Database health
docker exec kuropanel_db_prod mysqladmin ping -h localhost -u kuro_prod_user -p

# Redis health
docker exec kuropanel_redis_prod redis-cli ping
```

### Performance Monitoring

```bash
# Start monitoring stack
docker-compose -f docker-compose.production.yml --profile with-monitoring up -d

# Access Grafana: http://localhost:3000
# Access Prometheus: http://localhost:9090
```

### Log Aggregation

```bash
# Start ELK stack
docker-compose -f docker-compose.production.yml --profile with-logging up -d

# Access Kibana: http://localhost:5601
```

## Backup and Recovery

### Automated Backups

Backups are automatically created via cron jobs:

```bash
# Database backup (daily at 2 AM)
0 2 * * * /path/to/deploy-production.sh backup

# Full system backup (weekly)
0 2 * * 0 /path/to/backup-full.sh
```

### Manual Backup

```bash
# Create backup
./deploy-production.sh backup

# List backups
ls -la backups/deployment/
```

### Recovery

```bash
# Rollback to previous backup
./deploy-production.sh rollback

# Restore specific backup
./deploy-production.sh restore backup_20240729_120000.tar.gz
```

## Security Configuration

### Firewall Setup

```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### SSL/TLS Configuration

The production setup includes:
- TLS 1.2/1.3 only
- Strong cipher suites
- HSTS headers
- Perfect Forward Secrecy

### Security Headers

All security headers are configured:
- Content Security Policy
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- X-XSS-Protection
- Strict-Transport-Security

## Performance Optimization

### Database Tuning

MySQL is pre-configured for production with:
- InnoDB buffer pool: 2GB (adjustable)
- Query cache: Optimized
- Connection pooling: 500 connections
- Slow query logging: Enabled

### Application Caching

- **OPCache**: Enabled with optimized settings
- **Redis**: Session and application caching
- **Apache**: Compression and static file caching

### Resource Limits

```yaml
# Docker resource limits
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 2G
    reservations:
      cpus: '1.0'
      memory: 1G
```

## Troubleshooting

### Common Issues

#### Service Won't Start

```bash
# Check logs
docker-compose -f docker-compose.production.yml logs app

# Check system resources
docker stats

# Restart service
docker-compose -f docker-compose.production.yml restart app
```

#### Database Connection Issues

```bash
# Check database status
docker exec kuropanel_db_prod mysqladmin status -u root -p

# Test connection
docker exec kuropanel_app_prod php spark db:connect
```

#### SSL Certificate Issues

```bash
# Check certificate expiry
openssl x509 -in ssl/fullchain.pem -text -noout | grep "Not After"

# Renew Let's Encrypt certificate
certbot renew --dry-run
```

### Performance Issues

```bash
# Check resource usage
docker stats

# Check slow queries
docker exec kuropanel_db_prod mysql -u root -p -e "SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;"

# Check PHP errors
docker exec kuropanel_app_prod tail -f /var/log/kuropanel/php_errors.log
```

## Maintenance

### Regular Tasks

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose -f docker-compose.production.yml pull
docker-compose -f docker-compose.production.yml up -d

# Clean up old images
docker image prune -f

# Rotate logs
docker exec kuropanel_app_prod logrotate /etc/logrotate.d/kuropanel
```

### Database Maintenance

```bash
# Optimize tables
docker exec kuropanel_db_prod mysql -u root -p -e "OPTIMIZE TABLE kuropanel.*;"

# Check table integrity
docker exec kuropanel_db_prod mysql -u root -p -e "CHECK TABLE kuropanel.*;"

# Update statistics
docker exec kuropanel_db_prod mysql -u root -p -e "ANALYZE TABLE kuropanel.*;"
```

## Environment-Specific Configurations

### Development → Production Migration

1. **Database Migration**:
   ```bash
   # Export development data
   mysqldump -u root -p kuropanel_dev > dev_data.sql
   
   # Import to production
   docker exec -i kuropanel_db_prod mysql -u root -p kuropanel_prod < dev_data.sql
   ```

2. **File Migration**:
   ```bash
   # Copy uploaded files
   rsync -av ./writable/uploads/ production:/opt/kuropanel/data/uploads/
   ```

3. **Configuration Update**:
   ```bash
   # Update environment
   sed -i 's/CI_ENVIRONMENT=development/CI_ENVIRONMENT=production/' .env.production
   ```

### Multi-Server Deployment

For high-availability deployment across multiple servers:

1. **Load Balancer**: Use external load balancer (nginx, HAProxy)
2. **Database**: MySQL Master-Slave replication
3. **Sessions**: Redis cluster for session storage
4. **Files**: Shared storage (NFS, GlusterFS, or cloud storage)

## Support and Documentation

- **GitHub Issues**: https://github.com/your-org/kuropanel-v2/issues
- **Documentation**: https://docs.kuropanel.com
- **Discord**: https://discord.gg/kuropanel
- **Email**: support@kuropanel.com

---

**Production Deployment Checklist**

- [ ] System requirements met
- [ ] Environment variables configured
- [ ] SSL certificates installed
- [ ] Firewall configured
- [ ] Backups configured
- [ ] Monitoring enabled
- [ ] Health checks passing
- [ ] Performance tested
- [ ] Security headers verified
- [ ] Documentation updated
