<?php

namespace App\Models;

use CodeIgniter\Model;

class LicenseKeyModel extends Model
{
    protected $table = 'license_keys';
    protected $primaryKey = 'id';
    protected $useAutoIncrement = true;
    protected $returnType = 'object';
    protected $useSoftDeletes = false;
    protected $protectFields = true;
    protected $allowedFields = [
        'license_key', 'app_id', 'user_id', 'reseller_id', 'developer_id',
        'key_type', 'max_devices', 'duration_days', 'price', 'status',
        'activated_at', 'expires_at', 'devices', 'device_count',
        'last_used', 'usage_count', 'notes', 'metadata'
    ];

    protected $useTimestamps = true;
    protected $createdField = 'created_at';
    protected $updatedField = 'updated_at';

    protected $validationRules = [
        'license_key' => 'required|min_length[10]|max_length[100]|is_unique[license_keys.license_key]',
        'app_id' => 'required|integer',
        'developer_id' => 'required|integer',
        'key_type' => 'permit_empty|in_list[single,multi]',
        'max_devices' => 'permit_empty|integer|greater_than[0]',
        'duration_days' => 'required|integer|greater_than[0]',
        'price' => 'permit_empty|decimal'
    ];

    protected $validationMessages = [
        'license_key' => [
            'required' => 'License key is required',
            'is_unique' => 'License key already exists'
        ],
        'app_id' => [
            'required' => 'App ID is required',
            'integer' => 'App ID must be an integer'
        ]
    ];

    /**
     * Get user's license keys
     */
    public function getUserLicenses($userId, $status = null)
    {
        $builder = $this->select('license_keys.*, apps.app_name, apps.logo_url as app_logo')
                       ->join('apps', 'apps.id_app = license_keys.app_id')
                       ->where('license_keys.user_id', $userId);
        
        if ($status) {
            $builder->where('license_keys.status', $status);
        }
        
        return $builder->orderBy('license_keys.created_at', 'DESC')->findAll();
    }

    /**
     * Get reseller's generated keys
     */
    public function getResellerKeys($resellerId, $appId = null)
    {
        $builder = $this->select('license_keys.*, apps.app_name, users.username as user_username')
                       ->join('apps', 'apps.id_app = license_keys.app_id')
                       ->leftJoin('users', 'users.id_users = license_keys.user_id')
                       ->where('license_keys.reseller_id', $resellerId);
        
        if ($appId) {
            $builder->where('license_keys.app_id', $appId);
        }
        
        return $builder->orderBy('license_keys.created_at', 'DESC')->findAll();
    }

    /**
     * Get developer's app keys
     */
    public function getDeveloperKeys($developerId, $appId = null)
    {
        $builder = $this->select('license_keys.*, apps.app_name, users.username as user_username, resellers.username as reseller_username')
                       ->join('apps', 'apps.id_app = license_keys.app_id')
                       ->leftJoin('users', 'users.id_users = license_keys.user_id')
                       ->leftJoin('users as resellers', 'resellers.id_users = license_keys.reseller_id')
                       ->where('license_keys.developer_id', $developerId);
        
        if ($appId) {
            $builder->where('license_keys.app_id', $appId);
        }
        
        return $builder->orderBy('license_keys.created_at', 'DESC')->findAll();
    }

    /**
     * Activate license key
     */
    public function activateLicense($licenseKey, $userId, $hwid = null)
    {
        $key = $this->where('license_key', $licenseKey)->first();
        
        if (!$key) {
            return ['success' => false, 'message' => 'Invalid license key'];
        }

        if ($key->status !== 'active') {
            return ['success' => false, 'message' => 'License key is not active'];
        }

        if ($key->user_id && $key->user_id != $userId) {
            return ['success' => false, 'message' => 'License key is already assigned to another user'];
        }

        // Check device limit
        $devices = json_decode($key->devices ?: '[]', true);
        if ($hwid && $key->key_type === 'single' && count($devices) > 0 && !in_array($hwid, $devices)) {
            return ['success' => false, 'message' => 'Device limit reached'];
        }

        // Add device if provided and not already exists
        if ($hwid && !in_array($hwid, $devices)) {
            $devices[] = $hwid;
        }

        // Calculate expiry date
        $expiresAt = date('Y-m-d H:i:s', strtotime('+' . $key->duration_days . ' days'));

        $updateData = [
            'user_id' => $userId,
            'activated_at' => date('Y-m-d H:i:s'),
            'expires_at' => $expiresAt,
            'devices' => json_encode($devices),
            'device_count' => count($devices),
            'last_used' => date('Y-m-d H:i:s'),
            'usage_count' => $key->usage_count + 1
        ];

        $this->update($key->id_key, $updateData);

        return [
            'success' => true,
            'message' => 'License activated successfully',
            'expires_at' => $expiresAt
        ];
    }

    /**
     * Check if license is valid for HWID
     */
    public function validateLicense($licenseKey, $hwid)
    {
        $key = $this->where('license_key', $licenseKey)->first();
        
        if (!$key) {
            return ['valid' => false, 'message' => 'Invalid license key'];
        }

        if ($key->status !== 'active') {
            return ['valid' => false, 'message' => 'License is not active'];
        }

        if ($key->expires_at && strtotime($key->expires_at) < time()) {
            $this->update($key->id_key, ['status' => 'expired']);
            return ['valid' => false, 'message' => 'License has expired'];
        }

        // Check HWID
        $devices = json_decode($key->devices ?: '[]', true);
        if (!empty($devices) && !in_array($hwid, $devices)) {
            return ['valid' => false, 'message' => 'Device not authorized'];
        }

        // Update last used
        $this->update($key->id_key, [
            'last_used' => date('Y-m-d H:i:s'),
            'usage_count' => $key->usage_count + 1
        ]);

        return [
            'valid' => true,
            'key_info' => $key,
            'expires_at' => $key->expires_at
        ];
    }

    /**
     * Generate new license key
     */
    public function generateKey($appId, $developerId, $resellerId = null, $config = [])
    {
        $licenseKey = generateLicenseKey();
        
        $defaultConfig = [
            'key_type' => 'single',
            'max_devices' => 1,
            'duration_days' => 30,
            'price' => 0.00
        ];
        
        $config = array_merge($defaultConfig, $config);
        
        $data = [
            'license_key' => $licenseKey,
            'app_id' => $appId,
            'developer_id' => $developerId,
            'reseller_id' => $resellerId,
            'key_type' => $config['key_type'],
            'max_devices' => $config['max_devices'],
            'duration_days' => $config['duration_days'],
            'price' => $config['price'],
            'status' => 'active'
        ];
        
        if ($this->insert($data)) {
            return [
                'success' => true,
                'license_key' => $licenseKey,
                'key_id' => $this->getInsertID()
            ];
        }
        
        return ['success' => false, 'message' => 'Failed to generate license key'];
    }

    /**
     * Get expiring licenses
     */
    public function getExpiringLicenses($days = 7)
    {
        return $this->select('license_keys.*, apps.app_name, users.username, users.telegram_username')
                   ->join('apps', 'apps.id_app = license_keys.app_id')
                   ->join('users', 'users.id_users = license_keys.user_id')
                   ->where('license_keys.status', 'active')
                   ->where('license_keys.expires_at <=', date('Y-m-d H:i:s', strtotime('+' . $days . ' days')))
                   ->where('license_keys.expires_at >', date('Y-m-d H:i:s'))
                   ->findAll();
    }

    /**
     * Add device to license
     */
    public function addDeviceToLicense($keyId, $hwid)
    {
        $key = $this->find($keyId);
        if (!$key) return false;

        $devices = json_decode($key->devices ?: '[]', true);
        
        if (count($devices) >= $key->max_devices) {
            return ['success' => false, 'message' => 'Device limit reached'];
        }
        
        if (!in_array($hwid, $devices)) {
            $devices[] = $hwid;
            return $this->update($keyId, [
                'devices' => json_encode($devices),
                'device_count' => count($devices)
            ]);
        }
        
        return ['success' => true, 'message' => 'Device already registered'];
    }
}
