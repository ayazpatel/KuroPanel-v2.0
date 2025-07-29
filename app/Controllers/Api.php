<?php

namespace App\Controllers;

use App\Models\LicenseKeyModel;
use App\Models\AppModel;

class Api extends BaseController
{
    protected $licenseModel, $appModel;

    public function __construct()
    {
        $this->licenseModel = new LicenseKeyModel();
        $this->appModel = new AppModel();
    }

    /**
     * Validate License Key
     */
    public function validateLicense()
    {
        $licenseKey = $this->request->getPost('license_key');
        $appId = $this->request->getPost('app_id');
        $hwid = $this->request->getPost('hwid');

        if (!$licenseKey || !$appId || !$hwid) {
            return $this->response->setJSON([
                'status' => false,
                'message' => 'Missing required parameters'
            ]);
        }

        $license = $this->licenseModel->where('license_key', $licenseKey)
                                     ->where('app_id', $appId)
                                     ->first();

        if (!$license) {
            return $this->response->setJSON([
                'status' => false,
                'message' => 'License not found'
            ]);
        }

        if ($license->status !== 'active') {
            return $this->response->setJSON([
                'status' => false,
                'message' => 'License is not active'
            ]);
        }

        // Check expiration
        if ($license->expires_at && strtotime($license->expires_at) < time()) {
            return $this->response->setJSON([
                'status' => false,
                'message' => 'License has expired'
            ]);
        }

        return $this->response->setJSON([
            'status' => true,
            'message' => 'License is valid',
            'data' => [
                'license_key' => $license->license_key,
                'expires_at' => $license->expires_at,
                'max_devices' => $license->max_devices,
                'device_count' => $license->device_count
            ]
        ]);
    }

    /**
     * Activate License Key
     */
    public function activateLicense()
    {
        $licenseKey = $this->request->getPost('license_key');
        $appId = $this->request->getPost('app_id');
        $hwid = $this->request->getPost('hwid');

        if (!$licenseKey || !$appId || !$hwid) {
            return $this->response->setJSON([
                'status' => false,
                'message' => 'Missing required parameters'
            ]);
        }

        $license = $this->licenseModel->where('license_key', $licenseKey)
                                     ->where('app_id', $appId)
                                     ->first();

        if (!$license) {
            return $this->response->setJSON([
                'status' => false,
                'message' => 'License not found'
            ]);
        }

        // Activate if not already activated
        if (!$license->activated_at) {
            $this->licenseModel->update($license->id, [
                'status' => 'active',
                'activated_at' => date('Y-m-d H:i:s'),
                'expires_at' => date('Y-m-d H:i:s', strtotime('+' . $license->duration_days . ' days'))
            ]);
        }

        return $this->response->setJSON([
            'status' => true,
            'message' => 'License activated successfully'
        ]);
    }

    /**
     * Get App Information
     */
    public function getAppInfo($appId)
    {
        $app = $this->appModel->find($appId);

        if (!$app) {
            return $this->response->setJSON([
                'status' => false,
                'message' => 'App not found'
            ]);
        }

        return $this->response->setJSON([
            'status' => true,
            'data' => [
                'app_name' => $app->app_name,
                'description' => $app->app_description,
                'version' => $app->current_version,
                'status' => $app->status
            ]
        ]);
    }

    /**
     * API Health Check
     */
    public function health()
    {
        return $this->response->setJSON([
            'status' => 'ok',
            'version' => '2.0.0',
            'timestamp' => date('Y-m-d H:i:s'),
            'system' => [
                'php_version' => PHP_VERSION,
                'ci_version' => \CodeIgniter\CodeIgniter::CI_VERSION,
                'database' => 'connected'
            ]
        ]);
    }

    /**
     * Check App Maintenance Status
     */
    public function checkMaintenance($appId)
    {
        $app = $this->appModel->find($appId);

        if (!$app) {
            return $this->response->setJSON([
                'status' => false,
                'message' => 'App not found'
            ]);
        }

        return $this->response->setJSON([
            'status' => true,
            'maintenance' => $app->maintenance_mode || $app->global_maintenance,
            'message' => $app->maintenance_message ?: $app->global_maintenance_message
        ]);
    }
}
