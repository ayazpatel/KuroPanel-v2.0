<?php

namespace App\Models;

use CodeIgniter\Model;

class AppModel extends Model
{
    protected $table = 'apps';
    protected $primaryKey = 'id_app';
    protected $useAutoIncrement = true;
    protected $returnType = 'object';
    protected $useSoftDeletes = false;
    protected $protectFields = true;
    protected $allowedFields = [
        'app_name', 'app_description', 'current_version', 'status',
        'maintenance_message', 'developer_id', 'global_maintenance',
        'global_maintenance_message', 'logo_url'
    ];

    protected $useTimestamps = true;
    protected $createdField = 'created_at';
    protected $updatedField = 'updated_at';

    protected $validationRules = [
        'app_name' => 'required|min_length[3]|max_length[255]',
        'developer_id' => 'required|integer',
        'current_version' => 'permit_empty|max_length[50]',
        'status' => 'permit_empty|in_list[active,deprecated,maintenance]'
    ];

    protected $validationMessages = [
        'app_name' => [
            'required' => 'App name is required',
            'min_length' => 'App name must be at least 3 characters',
            'max_length' => 'App name cannot exceed 255 characters'
        ],
        'developer_id' => [
            'required' => 'Developer ID is required',
            'integer' => 'Developer ID must be an integer'
        ]
    ];

    /**
     * Get apps by developer
     */
    public function getAppsByDeveloper($developerId)
    {
        return $this->where('developer_id', $developerId)
                   ->orderBy('created_at', 'DESC')
                   ->findAll();
    }

    /**
     * Get active apps
     */
    public function getActiveApps()
    {
        return $this->where('status', 'active')
                   ->orderBy('app_name', 'ASC')
                   ->findAll();
    }

    /**
     * Get apps with developer info
     */
    public function getAppsWithDeveloper($limit = null)
    {
        $builder = $this->select('apps.*, users.username as developer_username, users.fullname as developer_fullname')
                        ->join('users', 'users.id_users = apps.developer_id')
                        ->orderBy('apps.created_at', 'DESC');
        
        if ($limit !== null) {
            $builder->limit($limit);
        }
        
        return $builder->findAll();
    }

    /**
     * Get apps available to reseller
     */
    public function getAppsForReseller($resellerId)
    {
        return $this->select('apps.*, reseller_apps.status as assignment_status, reseller_apps.maintenance_mode as reseller_maintenance')
                   ->join('reseller_apps', 'reseller_apps.app_id = apps.id_app')
                   ->where('reseller_apps.reseller_id', $resellerId)
                   ->where('reseller_apps.status', 'active')
                   ->findAll();
    }

    /**
     * Check if app is in maintenance
     */
    public function isInMaintenance($appId, $resellerId = null)
    {
        $app = $this->find($appId);
        if (!$app) return false;

        // Check global maintenance
        if ($app->global_maintenance) {
            return [
                'maintenance' => true,
                'message' => $app->global_maintenance_message ?: 'App is under maintenance',
                'type' => 'global'
            ];
        }

        // Check reseller maintenance if applicable
        if ($resellerId) {
            $resellerAppModel = new ResellerAppModel();
            $resellerApp = $resellerAppModel->where('app_id', $appId)
                                           ->where('reseller_id', $resellerId)
                                           ->first();
            
            if ($resellerApp && $resellerApp->maintenance_mode) {
                return [
                    'maintenance' => true,
                    'message' => $resellerApp->maintenance_message ?: 'App is under maintenance',
                    'type' => 'reseller'
                ];
            }
        }

        return ['maintenance' => false];
    }

    /**
     * Get app statistics
     */
    public function getAppStats($appId)
    {
        $licenseModel = new LicenseKeyModel();
        
        return [
            'total_licenses' => $licenseModel->where('app_id', $appId)->countAllResults(),
            'active_licenses' => $licenseModel->where('app_id', $appId)->where('status', 'active')->countAllResults(),
            'expired_licenses' => $licenseModel->where('app_id', $appId)->where('status', 'expired')->countAllResults(),
            'total_users' => $licenseModel->where('app_id', $appId)->where('user_id IS NOT NULL')->distinct()->countAllResults('user_id')
        ];
    }

    /**
     * Set global maintenance mode
     */
    public function setGlobalMaintenance($appId, $enabled, $message = '')
    {
        return $this->update($appId, [
            'global_maintenance' => $enabled ? 1 : 0,
            'global_maintenance_message' => $message
        ]);
    }
}
