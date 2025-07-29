<?php

namespace App\Models;

use CodeIgniter\Model;

class InviteCodeModel extends Model
{
    protected $table = 'invite_codes';
    protected $primaryKey = 'id_invite';
    protected $useAutoIncrement = true;
    protected $returnType = 'object';
    protected $useSoftDeletes = false;
    protected $protectFields = true;
    protected $allowedFields = [
        'code', 'created_by', 'app_id', 'target_role', 'max_uses',
        'used_count', 'expires_at', 'status', 'metadata'
    ];

    protected $useTimestamps = true;
    protected $createdField = 'created_at';
    protected $updatedField = 'updated_at';

    protected $validationRules = [
        'code' => 'required|min_length[6]|max_length[100]|is_unique[invite_codes.code]',
        'created_by' => 'required|integer',
        'target_role' => 'required|in_list[developer,reseller,user]',
        'max_uses' => 'permit_empty|integer|greater_than[0]'
    ];

    /**
     * Generate invite code for app assignment
     */
    public function generateInviteCode($createdBy, $appId, $targetRole, $maxUses = 1, $expiresIn = null)
    {
        $code = generateInviteCode();
        
        $data = [
            'code' => $code,
            'created_by' => $createdBy,
            'app_id' => $appId,
            'target_role' => $targetRole,
            'max_uses' => $maxUses,
            'status' => 'active'
        ];
        
        if ($expiresIn) {
            $data['expires_at'] = date('Y-m-d H:i:s', strtotime($expiresIn));
        }
        
        if ($this->insert($data)) {
            return [
                'success' => true,
                'code' => $code,
                'invite_id' => $this->getInsertID()
            ];
        }
        
        return ['success' => false, 'message' => 'Failed to generate invite code'];
    }

    /**
     * Get invite codes created by user
     */
    public function getUserInviteCodes($userId)
    {
        return $this->select('invite_codes.*, apps.app_name')
                   ->leftJoin('apps', 'apps.id_app = invite_codes.app_id')
                   ->where('invite_codes.created_by', $userId)
                   ->orderBy('invite_codes.created_at', 'DESC')
                   ->findAll();
    }

    /**
     * Validate and use invite code
     */
    public function useInviteCode($code, $userId)
    {
        $invite = $this->where('code', $code)->first();
        
        if (!$invite) {
            return ['success' => false, 'message' => 'Invalid invite code'];
        }

        if ($invite->status !== 'active') {
            return ['success' => false, 'message' => 'Invite code is not active'];
        }

        if ($invite->expires_at && strtotime($invite->expires_at) < time()) {
            $this->update($invite->id_invite, ['status' => 'expired']);
            return ['success' => false, 'message' => 'Invite code has expired'];
        }

        if ($invite->used_count >= $invite->max_uses) {
            $this->update($invite->id_invite, ['status' => 'expired']);
            return ['success' => false, 'message' => 'Invite code usage limit reached'];
        }

        // Check if user already used this code
        $usageModel = new InviteCodeUsageModel();
        $alreadyUsed = $usageModel->where('invite_code_id', $invite->id_invite)
                                 ->where('used_by', $userId)
                                 ->first();
        
        if ($alreadyUsed) {
            return ['success' => false, 'message' => 'You have already used this invite code'];
        }

        return [
            'success' => true,
            'invite' => $invite
        ];
    }

    /**
     * Get invite code statistics
     */
    public function getInviteStats($inviteId)
    {
        $invite = $this->find($inviteId);
        if (!$invite) return null;

        $usageModel = new InviteCodeUsageModel();
        $usages = $usageModel->where('invite_code_id', $inviteId)->findAll();

        return [
            'invite' => $invite,
            'usage_count' => count($usages),
            'remaining_uses' => $invite->max_uses - count($usages),
            'usages' => $usages
        ];
    }

    /**
     * Deactivate invite code
     */
    public function deactivateCode($codeId, $userId)
    {
        $invite = $this->find($codeId);
        if (!$invite || $invite->created_by != $userId) {
            return false;
        }

        return $this->update($codeId, ['status' => 'disabled']);
    }
}
