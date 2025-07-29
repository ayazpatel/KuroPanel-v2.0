<?php

namespace App\Models;

use CodeIgniter\Model;

class ResellerAppModel extends Model
{
    protected $table = 'reseller_apps';
    protected $primaryKey = 'id';
    protected $useAutoIncrement = true;
    protected $returnType = 'object';
    protected $useSoftDeletes = false;
    protected $protectFields = true;
    protected $allowedFields = [
        'reseller_id', 'app_id', 'developer_id', 'invite_code',
        'status', 'custom_pricing', 'commission_rate', 'maintenance_mode',
        'maintenance_message', 'custom_logo_url', 'custom_description'
    ];

    protected $useTimestamps = true;
    protected $createdField = 'created_at';
    protected $updatedField = 'updated_at';

    protected $validationRules = [
        'reseller_id' => 'required|integer',
        'app_id' => 'required|integer',
        'developer_id' => 'required|integer',
        'invite_code' => 'required|min_length[6]|max_length[100]|is_unique[reseller_apps.invite_code]',
        'status' => 'permit_empty|in_list[active,suspended,revoked]'
    ];

    /**
     * Assign app to reseller via invite code
     */
    public function assignAppToReseller($inviteCode, $resellerId)
    {
        // First check if invite code exists and is valid
        $inviteModel = new InviteCodeModel();
        $invite = $inviteModel->where('code', $inviteCode)
                             ->where('status', 'active')
                             ->where('target_role', 'reseller')
                             ->first();
        
        if (!$invite) {
            return ['success' => false, 'message' => 'Invalid or expired invite code'];
        }

        if ($invite->expires_at && strtotime($invite->expires_at) < time()) {
            return ['success' => false, 'message' => 'Invite code has expired'];
        }

        if ($invite->used_count >= $invite->max_uses) {
            return ['success' => false, 'message' => 'Invite code usage limit reached'];
        }

        // Check if reseller already has access to this app
        $existing = $this->where('reseller_id', $resellerId)
                         ->where('app_id', $invite->app_id)
                         ->first();
        
        if ($existing) {
            return ['success' => false, 'message' => 'You already have access to this app'];
        }

        // Assign app to reseller
        $data = [
            'reseller_id' => $resellerId,
            'app_id' => $invite->app_id,
            'developer_id' => $invite->created_by,
            'invite_code' => $inviteCode,
            'status' => 'active'
        ];

        if ($this->insert($data)) {
            // Update invite code usage
            $inviteModel->update($invite->id_invite, [
                'used_count' => $invite->used_count + 1
            ]);

            // Log the usage
            $inviteUsageModel = new InviteCodeUsageModel();
            $inviteUsageModel->insert([
                'invite_code_id' => $invite->id_invite,
                'used_by' => $resellerId,
                'ip_address' => service('request')->getIPAddress()
            ]);

            return ['success' => true, 'message' => 'App assigned successfully'];
        }

        return ['success' => false, 'message' => 'Failed to assign app'];
    }

    /**
     * Get reseller's assigned apps with details
     */
    public function getResellerApps($resellerId)
    {
        return $this->select('reseller_apps.*, apps.app_name, apps.app_description, apps.current_version, apps.logo_url, users.username as developer_name')
                   ->join('apps', 'apps.id_app = reseller_apps.app_id')
                   ->join('users', 'users.id_users = reseller_apps.developer_id')
                   ->where('reseller_apps.reseller_id', $resellerId)
                   ->where('reseller_apps.status', 'active')
                   ->orderBy('reseller_apps.created_at', 'DESC')
                   ->findAll();
    }

    /**
     * Get developer's resellers for an app
     */
    public function getAppResellers($appId, $developerId)
    {
        return $this->select('reseller_apps.*, users.username, users.fullname, users.telegram_username')
                   ->join('users', 'users.id_users = reseller_apps.reseller_id')
                   ->where('reseller_apps.app_id', $appId)
                   ->where('reseller_apps.developer_id', $developerId)
                   ->orderBy('reseller_apps.created_at', 'DESC')
                   ->findAll();
    }

    /**
     * Set reseller maintenance mode for app
     */
    public function setResellerMaintenance($resellerId, $appId, $enabled, $message = '')
    {
        return $this->where('reseller_id', $resellerId)
                   ->where('app_id', $appId)
                   ->set([
                       'maintenance_mode' => $enabled ? 1 : 0,
                       'maintenance_message' => $message
                   ])
                   ->update();
    }

    /**
     * Update reseller branding for app
     */
    public function updateResellerBranding($resellerId, $appId, $branding)
    {
        $allowedFields = ['custom_logo_url', 'custom_description'];
        $updateData = array_intersect_key($branding, array_flip($allowedFields));
        
        return $this->where('reseller_id', $resellerId)
                   ->where('app_id', $appId)
                   ->set($updateData)
                   ->update();
    }

    /**
     * Get reseller stats for app
     */
    public function getResellerAppStats($resellerId, $appId)
    {
        $licenseModel = new LicenseKeyModel();
        
        return [
            'total_keys_generated' => $licenseModel->where('reseller_id', $resellerId)->where('app_id', $appId)->countAllResults(),
            'active_keys' => $licenseModel->where('reseller_id', $resellerId)->where('app_id', $appId)->where('status', 'active')->countAllResults(),
            'used_keys' => $licenseModel->where('reseller_id', $resellerId)->where('app_id', $appId)->where('user_id IS NOT NULL')->countAllResults(),
            'total_revenue' => $licenseModel->selectSum('price')->where('reseller_id', $resellerId)->where('app_id', $appId)->get()->getRow()->price ?? 0
        ];
    }

    /**
     * Revoke reseller access to app
     */
    public function revokeAccess($resellerId, $appId, $developerId)
    {
        return $this->where('reseller_id', $resellerId)
                   ->where('app_id', $appId)
                   ->where('developer_id', $developerId)
                   ->set(['status' => 'revoked'])
                   ->update();
    }
}
