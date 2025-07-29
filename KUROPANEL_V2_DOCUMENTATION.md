# KuroPanel v2.0 - 4-Role License Management System

## 🎯 System Overview

KuroPanel has been upgraded from a 2-role system (Admin/Reseller) to a comprehensive 4-role license-based app distribution system with the following roles:

1. **Admin (Level 1)** - System administrator with full access
2. **Developer (Level 2)** - App creators and managers  
3. **Reseller (Level 3)** - License key distributors
4. **User (Level 4)** - End users who purchase and use licenses

## 👥 Role Hierarchy & Permissions

### 🔴 Admin (Level 1)
**Purpose**: System management and oversight

**Permissions**:
- Manage all users (create, edit, delete, change roles)
- View all apps, licenses, and transactions
- Access system settings and configuration
- Generate system reports and analytics
- Monitor activity logs
- Backup and restore system
- Override any restrictions

**Key Features**:
- Complete system oversight
- User role management
- Financial transaction monitoring  
- System maintenance tools

### 🔵 Developer (Level 2)  
**Purpose**: Create and manage applications

**Permissions**:
- Create and manage own apps
- Upload app versions via Google Drive links
- Set global maintenance mode with custom messages
- Generate invite codes for resellers
- Add patch notes and app status updates
- View analytics for own apps
- Manage assigned resellers

**Key Features**:
- App lifecycle management
- Version control system
- Global maintenance control
- Reseller invitation system
- Developer analytics dashboard

### 🟡 Reseller (Level 3)
**Purpose**: Distribute license keys to end users

**Permissions**:
- Access apps via developer invite codes
- Generate license keys for assigned apps
- Set reseller-level maintenance mode
- Customize branding (logo, description, Telegram info)
- Manage generated keys and users
- Create multi-device licenses (1, 10, 1000+ devices)
- Run user key portal

**Key Features**:
- License key generation
- Multi-device support
- Custom branding options
- User key portal
- Reseller-specific maintenance
- Commission tracking

### 🟢 User (Level 4)
**Purpose**: End users who purchase and use licenses

**Permissions**:
- Purchase single-device license keys
- Activate licenses with HWID
- View license information and status
- Request HWID resets (paid feature)
- Manage profile and Telegram settings
- Add balance for purchases

**Key Features**:
- License activation system
- HWID management
- Balance and payment system
- Profile management
- License history tracking

## 🔑 License Key System

### Key Types
1. **Single Device** - One HWID per license (for end users)
2. **Multi Device** - Multiple HWIDs per license (for resellers)

### Key Generation Flow
```
Developer → Creates App → Generates Invite Code → Reseller Uses Code → Gets Access → Generates Keys → User Purchases → Activates License
```

### Key Redemption Process
1. **Direct Purchase**: User buys from platform directly
2. **Reseller Portal**: User gets key from reseller, creates account during activation
3. **Existing Account**: Key gets added to existing user account

## 🛠️ Database Schema Changes

### New Tables Added
- `apps` - Application management
- `app_versions` - Version control for apps
- `license_keys` - New license system
- `reseller_apps` - App assignments to resellers
- `invite_codes` - Developer-to-reseller invitations
- `invite_code_usage` - Usage tracking
- `transactions` - Financial transactions
- `activity_logs` - System activity logging
- `hwid_resets` - HWID reset requests
- `system_settings` - Configuration management
- `notifications` - User notifications

### Updated Tables
- `users` - Extended with new fields for all roles
  - Email, business info, branding fields
  - Telegram integration fields
  - Profile and security settings
  - Activity tracking

## 📱 App Integration Features

### Maintenance Modes
1. **Global Maintenance** (Developer level)
   - Affects all users of the app
   - Custom maintenance message
   - Complete app shutdown capability

2. **Reseller Maintenance** (Reseller level)  
   - Only affects reseller's users
   - Independent of global maintenance
   - Reseller-specific messaging

### App Check Flow
```
App Start → Check Global Maintenance → Check Reseller Maintenance → Validate License → Check HWID → Allow Access
```

### API Endpoints
- `POST /api/v1/validate-license` - Validate license key
- `POST /api/v1/activate-license` - Activate with HWID  
- `GET /api/v1/app-info/{id}` - Get app information
- `GET /api/v1/check-maintenance/{id}` - Check maintenance status

## 💳 Payment & Licensing System

### Balance System
- Users and resellers must add balance
- Supports multiple payment methods (integration ready)
- Transaction logging and history

### Pricing Structure
- **Base License**: $5 per 30 days (configurable)
- **HWID Reset**: $5 per reset (configurable)
- **Reseller Commission**: Configurable percentage

### Key Pricing
- Developers set base pricing
- Resellers can add markup
- Volume discounts available
- Multi-device pricing scales

## 🤖 Telegram Integration

### Bot Features
- **Unified Bot**: One bot for all notifications
- **Developer Channel**: Direct user notifications
- **Reseller Channel**: Reseller-specific notifications  
- **License Alerts**: Expiry warnings and updates
- **Registration Links**: Automatic bot joining

### Notification Types
- License expiry warnings (7 days, 3 days, 1 day)
- HWID reset confirmations
- Payment confirmations
- Maintenance mode alerts
- New app version notifications

## 🔄 Migration from v1.0

### Data Migration
1. **User Levels**: 
   - Old Level 1 (Admin) → New Level 1 (Admin)
   - Old Level 2 (Reseller) → New Level 3 (Reseller)
   - Create new Developer and User accounts as needed

2. **License Keys**:
   - Migrate from `keys_code` to `license_keys`
   - Convert existing keys to new format
   - Maintain HWID compatibility

3. **Referral System**:
   - Convert to new invite code system
   - Maintain existing referral relationships

### Compatibility
- Legacy API endpoints maintained
- Old key validation still works
- Gradual migration path available

## 🚀 New Features Summary

### ✅ For Developers
- Complete app lifecycle management
- Version control with Google Drive
- Global maintenance control
- Reseller management system
- Advanced analytics dashboard

### ✅ For Resellers  
- Multi-device license generation
- Custom branding capabilities
- Independent maintenance control
- User key portal system
- Commission tracking

### ✅ For Users
- Direct license purchasing
- HWID management system
- Profile customization
- Telegram integration
- Balance management

### ✅ For Admins
- Complete system oversight
- Advanced reporting tools
- User role management
- System configuration
- Activity monitoring

## 📊 Dashboard Features

### Role-Specific Dashboards
1. **Admin Dashboard**: System overview, user statistics, app monitoring
2. **Developer Dashboard**: App performance, license analytics, reseller management  
3. **Reseller Dashboard**: Key generation stats, user management, revenue tracking
4. **User Dashboard**: License status, balance info, recent activity

### Analytics & Reporting
- Real-time license usage statistics
- Revenue tracking and commission reports
- User activity and engagement metrics
- App performance and version adoption
- System health and maintenance reports

## 🔐 Security Enhancements

### Authentication
- Enhanced session management
- Role-based access control (RBAC)
- Failed login attempt tracking
- Account lockout protection

### License Security
- Advanced HWID validation
- Encrypted license keys
- Anti-tampering measures
- Usage monitoring and alerts

### API Security
- Rate limiting on all endpoints
- API key authentication
- Request validation and sanitization
- Audit logging for all actions

## 📋 Installation & Setup

### Requirements
- PHP 8.1+
- MySQL 8.0+
- CodeIgniter 4.4+
- Web server (Apache/Nginx)

### Installation Steps
1. Import new database schema (`kuro_upgraded.sql`)
2. Update configuration files
3. Run migration scripts
4. Configure Telegram bot
5. Set up payment integration
6. Test role-based access

### Configuration
- Update `.env` files for different environments
- Configure Telegram bot tokens
- Set up payment gateway credentials
- Adjust system settings via admin panel

This upgraded system provides a comprehensive license management solution suitable for software distribution businesses of any size, from individual developers to enterprise-level operations.
