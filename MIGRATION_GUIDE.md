# KuroPanel Migration Guide: v1.0 → v2.0

This guide will help you migrate your existing KuroPanel installation from the 2-role system to the new 4-role license management system.

## ⚠️ Important: Backup First!

**Before starting the migration, create a complete backup of:**
- Database
- All application files
- Configuration files

```bash
# Database backup
mysqldump -u username -p kuropanel > kuropanel_backup_$(date +%Y%m%d).sql

# File backup
tar -czf kuropanel_files_backup_$(date +%Y%m%d).tar.gz /path/to/kuropanel/
```

## 🗂️ Migration Overview

### What Changes:
- Database schema expanded with new tables
- User roles restructured (2 → 4 roles)
- License key system completely rewritten
- New API endpoints for app integration
- Enhanced security and permissions

### What Stays Compatible:
- Existing user accounts (with role mapping)
- Basic authentication system
- Core license validation (with updates)
- Docker container setup

## 📋 Migration Steps

### Step 1: Prepare New Database Schema

1. **Create new database** (recommended) or **backup existing**:
```sql
CREATE DATABASE kuropanel_v2;
```

2. **Import new schema**:
```bash
mysql -u username -p kuropanel_v2 < kuro_upgraded.sql
```

### Step 2: Migrate User Data

Run this SQL to migrate existing users to new role system:

```sql
-- Migrate users from old system
INSERT INTO kuropanel_v2.users (
    id_users, fullname, username, level, saldo, status, uplink, password, created_at, updated_at
)
SELECT 
    id_users,
    fullname,
    username,
    CASE 
        WHEN level = 1 THEN 1  -- Admin stays Admin
        WHEN level = 2 THEN 3  -- Old Reseller becomes new Reseller
        ELSE 4                 -- Default to User
    END as level,
    saldo,
    status,
    uplink,
    password,
    created_at,
    updated_at
FROM kuropanel.users;
```

### Step 3: Migrate License Keys

Convert existing keys to new format:

```sql
-- Create temporary app for existing keys
INSERT INTO kuropanel_v2.apps (app_name, app_description, developer_id, status)
VALUES ('Legacy App', 'Migrated from v1.0 system', 1, 'active');

SET @app_id = LAST_INSERT_ID();

-- Migrate license keys
INSERT INTO kuropanel_v2.license_keys (
    license_key, app_id, user_id, developer_id, key_type, max_devices, 
    duration_days, status, created_at, activated_at, expires_at, devices, device_count
)
SELECT 
    user_key as license_key,
    @app_id as app_id,
    (SELECT u.id_users FROM kuropanel_v2.users u WHERE u.username = k.registrator LIMIT 1) as user_id,
    1 as developer_id,  -- Assign to admin
    'single' as key_type,
    COALESCE(max_devices, 1) as max_devices,
    COALESCE(duration, 30) as duration_days,
    CASE 
        WHEN status = 1 THEN 'active'
        ELSE 'expired'
    END as status,
    created_at,
    created_at as activated_at,
    expired_date as expires_at,
    devices,
    CASE 
        WHEN devices IS NOT NULL THEN (LENGTH(devices) - LENGTH(REPLACE(devices, ',', '')) + 1)
        ELSE 0
    END as device_count
FROM kuropanel.keys_code k;
```

### Step 4: Migrate History/Activity Logs

```sql
-- Migrate history to activity logs
INSERT INTO kuropanel_v2.activity_logs (user_id, action, description, created_at)
SELECT 
    (SELECT u.id_users FROM kuropanel_v2.users u WHERE u.username = h.user_do LIMIT 1) as user_id,
    'legacy_action' as action,
    h.info as description,
    h.created_at
FROM kuropanel.history h
WHERE h.user_do IS NOT NULL;
```

### Step 5: Update Configuration Files

1. **Copy and update environment files**:
```bash
cp .env .env.backup
cp .env.development .env
```

2. **Update database configuration** in `.env`:
```env
database.default.database = kuropanel_v2
# Update other settings as needed
```

3. **Update any custom configurations**

### Step 6: Update Application Files

1. **Backup current controllers and models**:
```bash
mkdir -p backup/Controllers backup/Models backup/Config
cp -r app/Controllers/* backup/Controllers/
cp -r app/Models/* backup/Models/
cp app/Config/Routes.php backup/Config/Routes.php
```

2. **Routes are automatically updated** - The existing `Routes.php` has been upgraded with new role-based routing while maintaining backward compatibility.

3. **Replace with new files** (from upgrade package):
- New Controllers (Admin, Developer, Reseller, User)
- New Models (AppModel, LicenseKeyModel, etc.)
- **Updated Connect.php** - Android API endpoint with backward compatibility
- Updated Filters (RoleFilter added)

4. **Android App Compatibility**: 
   - ✅ **No changes required** - Your existing Android app will continue working
   - ✅ **Enhanced features available** - New system offers app_id parameter for advanced features
   - ✅ **Detailed documentation** - See `ANDROID_API_INTEGRATION_GUIDE.md`

5. **Update custom modifications** if any

### Step 7: Test Migration

1. **Start the application**:
```bash
php spark serve
# OR using Docker:
docker-compose up -d
```

2. **Test login with existing users**

3. **Verify data integrity**:
```sql
-- Check user migration
SELECT level, COUNT(*) FROM users GROUP BY level;

-- Check license key migration  
SELECT status, COUNT(*) FROM license_keys GROUP BY status;

-- Check app creation
SELECT * FROM apps WHERE app_name = 'Legacy App';
```

## 🔄 Post-Migration Setup

### Create Additional Roles

After migration, you may want to create proper Developer accounts:

```sql
-- Example: Convert specific resellers to developers
UPDATE users SET level = 2 WHERE username IN ('developer1', 'developer2');
```

### Setup New Apps

1. **Login as admin** → Go to Developer section
2. **Create proper apps** to replace the legacy app
3. **Generate invite codes** for resellers
4. **Test the new workflow**

### Configure New Features

1. **Telegram Integration**:
   - Set up bot token in settings
   - Configure notification preferences

2. **Payment System**:
   - Configure payment gateways
   - Set pricing structures

3. **System Settings**:
   - HWID reset costs
   - Default license durations
   - Commission rates

## 🔍 Verification Checklist

After migration, verify these items:

- [ ] All existing users can login
- [ ] User roles are correctly assigned
- [ ] Existing license keys work
- [ ] HWID validation functions
- [ ] Admin panel accessible
- [ ] Role-based permissions work
- [ ] API endpoints respond correctly
- [ ] Docker containers start (if using Docker)

## 🐛 Troubleshooting

### Common Issues

**1. Login Failures**
- Check user table migration
- Verify password hashing compatibility
- Check session configuration

**2. License Key Issues**
- Verify license_keys table data
- Check API endpoint configuration
- Test HWID validation

**3. Permission Errors**
- Check role assignments
- Verify route filters
- Test role-based access

**4. Database Connection**
- Update .env configuration
- Check database credentials
- Verify database name

### Recovery Process

If migration fails:

1. **Restore from backup**:
```bash
mysql -u username -p kuropanel < kuropanel_backup_YYYYMMDD.sql
```

2. **Restore files**:
```bash
tar -xzf kuropanel_files_backup_YYYYMMDD.tar.gz
```

3. **Revert configuration**:
```bash
cp .env.backup .env
```

## 📞 Support

If you encounter issues during migration:

1. Check logs in `writable/logs/`
2. Review database migration scripts
3. Verify file permissions
4. Check system requirements
5. Consult the full documentation: `KUROPANEL_V2_DOCUMENTATION.md`

## 🎯 Next Steps After Migration

1. **Train your team** on the new interface
2. **Update documentation** for end users
3. **Test all workflows** thoroughly  
4. **Configure monitoring** and backups
5. **Plan rollout** of new features

The migration process should take 1-2 hours for most installations. Plan for additional time to test and configure the new features.
