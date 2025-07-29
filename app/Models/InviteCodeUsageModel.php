<?php

namespace App\Models;

use CodeIgniter\Model;

class InviteCodeUsageModel extends Model
{
    protected $table = 'invite_code_usage';
    protected $primaryKey = 'id';
    protected $useAutoIncrement = true;
    protected $returnType = 'object';
    protected $useSoftDeletes = false;
    protected $protectFields = true;
    protected $allowedFields = [
        'invite_code_id', 'used_by', 'used_at', 'ip_address', 'user_agent'
    ];

    protected $useTimestamps = false; // Has custom used_at field

    /**
     * Log invite code usage
     */
    public function logUsage($inviteCodeId, $userId, $ipAddress = null, $userAgent = null)
    {
        $data = [
            'invite_code_id' => $inviteCodeId,
            'used_by' => $userId,
            'used_at' => date('Y-m-d H:i:s'),
            'ip_address' => $ipAddress,
            'user_agent' => $userAgent
        ];

        return $this->insert($data);
    }

    /**
     * Get usage history for invite code
     */
    public function getUsageHistory($inviteCodeId)
    {
        return $this->select('invite_code_usage.*, users.username, users.fullname')
                   ->join('users', 'users.id_users = invite_code_usage.used_by')
                   ->where('invite_code_usage.invite_code_id', $inviteCodeId)
                   ->orderBy('invite_code_usage.used_at', 'DESC')
                   ->findAll();
    }

    /**
     * Get user's invite code usage history
     */
    public function getUserUsageHistory($userId)
    {
        return $this->select('invite_code_usage.*, invite_codes.code, apps.app_name')
                   ->join('invite_codes', 'invite_codes.id_invite = invite_code_usage.invite_code_id')
                   ->leftJoin('apps', 'apps.id_app = invite_codes.app_id')
                   ->where('invite_code_usage.used_by', $userId)
                   ->orderBy('invite_code_usage.used_at', 'DESC')
                   ->findAll();
    }
}
