# Android App Integration Guide - Connect API v2.0

## 🔄 **Connect.php Updated for v2.0 System**

Your Android app's authentication endpoint has been upgraded to support both the **legacy system** (backward compatibility) and the **new 4-role license system**.

---

## 📱 **For Your Android App - API Usage**

### **Base URL Structure**
```
POST: https://yourdomain.com/connect
```

### **Two Authentication Methods Available:**

## 🔧 **Method 1: Legacy System (Backward Compatible)**

**Your existing Android app code will continue to work without changes!**

### Request Parameters:
```json
{
    "game": "your_game_name",
    "user_key": "license_key_here", 
    "serial": "device_hwid_here"
}
```

### Response Format:
```json
// Success
{
    "status": true,
    "data": {
        "token": "authentication_token",
        "rng": 1643723400
    }
}

// Error
{
    "status": false,
    "reason": "ERROR_MESSAGE"
}
```

---

## 🚀 **Method 2: New System (Enhanced Features)**

**For new apps or when you want to use advanced features:**

### Request Parameters:
```json
{
    "app_id": 1,
    "user_key": "license_key_here",
    "serial": "device_hwid_here"
}
```

### Enhanced Response:
```json
// Success
{
    "status": true,
    "data": {
        "token": "authentication_token",
        "rng": 1643723400,
        "app_info": {
            "name": "Your App Name",
            "version": "1.2.0"
        }
    }
}

// Error
{
    "status": false,
    "reason": "ERROR_MESSAGE"
}
```

---

## 🔍 **Error Messages Reference**

| Error Message | Meaning | Action |
|---------------|---------|---------|
| `Bad Parameter` | Invalid/missing parameters | Check request format |
| `MAINTENANCE` | System under maintenance | Show maintenance message |
| `APP NOT FOUND OR INACTIVE` | App doesn't exist or disabled | Contact support |
| `APP MAINTENANCE` | Specific app maintenance | Show app maintenance message |
| `LICENSE NOT FOUND` | Invalid license key | User needs valid license |
| `LICENSE EXPIRED` | License has expired | User needs to renew |
| `LICENSE SUSPENDED` | License suspended by admin | Contact support |
| `MAX DEVICE LIMIT REACHED` | Too many devices registered | User needs HWID reset |
| `USER BLOCKED` | User account blocked | Contact support |
| `USER OR GAME NOT REGISTERED` | Invalid game/license combo | Check credentials |

---

## 🛠️ **Android Implementation Examples**

### **Using Legacy Method (No Changes Required)**
```java
// Your existing code continues to work!
Map<String, String> params = new HashMap<>();
params.put("game", "my_game");
params.put("user_key", userLicenseKey);
params.put("serial", getDeviceId());

// POST to /connect
// Handle response as before
```

### **Using New System Method**
```java
Map<String, String> params = new HashMap<>();
params.put("app_id", "1"); // Your app ID from admin panel
params.put("user_key", userLicenseKey);
params.put("serial", getDeviceId());

// POST to /connect
// Get enhanced response with app info
```

---

## 📊 **System Information Endpoint**

### **GET /connect** (Without POST data)
Returns system information:

```json
{
    "web_info": {
        "_client": "KuroPanel",
        "license": "system_license",
        "version": "2.0.0"
    },
    "web__dev": {
        "author": "Hitler Deep",
        "telegram": "https://t.me/HITLER_MOD"
    }
}
```

---

## 🔐 **New System Advantages**

### **Enhanced Security:**
- App-specific license validation
- Better device management (JSON-based)
- Activity logging and monitoring
- Per-app maintenance modes

### **Better User Experience:**
- App version information in response
- More detailed error messages  
- Automatic license expiration handling
- Device limit management

### **Developer Benefits:**
- Multiple apps per developer
- Individual app maintenance control
- Better analytics and reporting
- Reseller system integration

---

## 🚦 **Migration Strategy for Your Android App**

### **Phase 1: No Changes Required** ✅
- Current app continues working
- All existing users authenticated  
- Zero downtime migration

### **Phase 2: Optional Enhancement** (Future)
- Update app to use `app_id` parameter
- Show app version info to users
- Handle enhanced error messages
- Utilize new features

### **Phase 3: Advanced Features** (Future)
- Integrate with user dashboard
- HWID reset functionality
- License purchase integration
- Real-time notifications

---

## 🧪 **Testing Your Integration**

### **Test Legacy Authentication:**
```bash
curl -X POST https://yourdomain.com/connect \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "game=test_game&user_key=your_key&serial=test_hwid"
```

### **Test New System Authentication:**
```bash
curl -X POST https://yourdomain.com/connect \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "app_id=1&user_key=your_key&serial=test_hwid"
```

### **Test System Info:**
```bash
curl -X GET https://yourdomain.com/connect
```

---

## ⚡ **Key Benefits for Your Android App**

1. **✅ Backward Compatibility** - Existing app works without changes
2. **🚀 Enhanced Features** - New system offers more functionality  
3. **🔒 Better Security** - Improved authentication and validation
4. **📊 Better Analytics** - Detailed logging and monitoring
5. **🎯 Scalability** - Support for multiple apps and versions
6. **🛡️ Maintenance Control** - Per-app maintenance modes
7. **📱 User Experience** - Better error handling and information

---

## 🎯 **Next Steps**

1. **Test existing integration** - Verify your current app still works
2. **Review error handling** - Update for new error messages if needed
3. **Plan enhancement** - Consider migrating to new system for benefits
4. **Monitor usage** - Check activity logs for authentication patterns

Your Android app integration is **fully compatible** and **ready to use** with the upgraded system! 🎉
