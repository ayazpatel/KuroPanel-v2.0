<?php

namespace App\Controllers;

use App\Models\KeysModel;
use App\Models\LicenseKeyModel;
use App\Models\AppModel;

class Connect extends BaseController
{
    protected $model, $licenseModel, $appModel, $maintenance, $staticWords;

    public function __construct()
    {
        // Support both old and new models for compatibility
        $this->model = new KeysModel(); // Legacy support
        $this->licenseModel = new LicenseKeyModel(); // New system
        $this->appModel = new AppModel(); // New system
        $this->maintenance = false;
        $this->staticWords = "Vm8Lk7Uj2JmsjCPVPVjrLa7zgfx3uz9E";
    }

    public function index()
    {
        if ($this->request->getPost()) {
            return $this->index_post();
        } else {
            $nata = [
                "web_info" => [
                    "_client" => BASE_NAME,
                    "license" => "Qp5KSGTquetnUkjX6UVBAURH8hTkZuLM",
                    "version" => "2.0.0", // Updated version
                ],
                "web__dev" => [
                    "author" => "Hitler Deep",
                    "telegram" => "https://t.me/HITLER_MOD"
                ],
            ];

            return $this->response->setJSON($nata);
        }
    }

    public function index_post()
    {
        $isMT = $this->maintenance;
        $game = $this->request->getPost('game');
        $uKey = $this->request->getPost('user_key');
        $sDev = $this->request->getPost('serial');
        
        // New system also supports app_id parameter
        $appId = $this->request->getPost('app_id');

        $form_rules = [
            'user_key' => 'required|alpha_numeric|min_length[1]|max_length[36]',
            'serial' => 'required|alpha_dash'
        ];
        
        // Make game optional for new system
        if (!$appId) {
            $form_rules['game'] = 'required|alpha_dash';
        }

        if (!$this->validate($form_rules)) {
            $data = [
                'status' => false,
                'reason' => "Bad Parameter",
            ];
            return $this->response->setJSON($data);
        }

        // Check for system maintenance
        if ($isMT) {
            $data = [
                'status' => false,
                'reason' => 'MAINTENANCE'
            ];
            return $this->response->setJSON($data);
        }

        // Try new system first, then fall back to legacy
        if ($appId) {
            return $this->handleNewSystemAuth($appId, $uKey, $sDev);
        } elseif ($game) {
            return $this->handleLegacyAuth($game, $uKey, $sDev);
        } else {
            $data = [
                'status' => false,
                'reason' => 'INVALID PARAMETER - Missing app_id or game'
            ];
            return $this->response->setJSON($data);
        }
    }

    /**
     * Handle authentication with new license system
     */
    private function handleNewSystemAuth($appId, $licenseKey, $hwid)
    {
        $time = new \CodeIgniter\I18n\Time();
        
        // Check if app exists and is active
        $app = $this->appModel->find($appId);
        if (!$app || $app->status !== 'active') {
            return $this->response->setJSON([
                'status' => false,
                'reason' => 'APP NOT FOUND OR INACTIVE'
            ]);
        }

        // Check app maintenance mode
        if ($app->maintenance_mode) {
            return $this->response->setJSON([
                'status' => false,
                'reason' => 'APP MAINTENANCE - ' . ($app->maintenance_message ?: 'Please try again later')
            ]);
        }

        // Find license key
        $license = $this->licenseModel->where('license_key', $licenseKey)
                                     ->where('app_id', $appId)
                                     ->first();

        if (!$license) {
            return $this->response->setJSON([
                'status' => false,
                'reason' => 'LICENSE NOT FOUND'
            ]);
        }

        // Check license status
        if ($license->status !== 'active') {
            $reason = $license->status === 'expired' ? 'LICENSE EXPIRED' : 
                     ($license->status === 'suspended' ? 'LICENSE SUSPENDED' : 'LICENSE INACTIVE');
            return $this->response->setJSON([
                'status' => false,
                'reason' => $reason
            ]);
        }

        // Check expiration
        if ($license->expires_at && $time->isAfter($license->expires_at)) {
            // Update status to expired
            $this->licenseModel->update($license->id, ['status' => 'expired']);
            return $this->response->setJSON([
                'status' => false,
                'reason' => 'LICENSE EXPIRED'
            ]);
        }

        // Handle device management
        $deviceResult = $this->manageDevices($license, $hwid);
        if (!$deviceResult['success']) {
            return $this->response->setJSON([
                'status' => false,
                'reason' => $deviceResult['reason']
            ]);
        }

        // Generate auth token
        $real = "$appId-$licenseKey-$hwid-$this->staticWords";
        $token = md5($real);

        // Log successful authentication
        $this->logAuthentication($license->id, $hwid, 'success');

        return $this->response->setJSON([
            'status' => true,
            'data' => [
                'token' => $token,
                'rng' => $time->getTimestamp(),
                'app_info' => [
                    'name' => $app->app_name,
                    'version' => $app->current_version ?: '1.0.0'
                ]
            ]
        ]);
    }

    /**
     * Handle legacy authentication (backward compatibility)
     */
    private function handleLegacyAuth($game, $uKey, $sDev)
    {
        $time = new \CodeIgniter\I18n\Time();
        $model = $this->model;
        $findKey = $model->getKeysGame(['user_key' => $uKey, 'game' => $game]);

        if ($findKey) {
            if ($findKey->status != 1) {
                return $this->response->setJSON([
                    'status' => false,
                    'reason' => 'USER BLOCKED'
                ]);
            }

            $id_keys = $findKey->id_keys;
            $duration = $findKey->duration;
            $expired = $findKey->expired_date;
            $max_dev = $findKey->max_devices;
            $devices = $findKey->devices;

            // Check expiration and set if first use
            if (!$expired) {
                $setExpired = $time::now()->addDays($duration);
                $model->update($id_keys, ['expired_date' => $setExpired]);
                $data['status'] = true;
            } else {
                if ($time::now()->isBefore($expired)) {
                    $data['status'] = true;
                } else {
                    return $this->response->setJSON([
                        'status' => false,
                        'reason' => 'EXPIRED KEY'
                    ]);
                }
            }

            // Handle device management (legacy method)
            $devicesAdd = $this->checkDevicesAdd($sDev, $devices, $max_dev);
            if ($devicesAdd) {
                if (is_array($devicesAdd)) {
                    $model->update($id_keys, $devicesAdd);
                }
                
                $real = "$game-$uKey-$sDev-$this->staticWords";
                return $this->response->setJSON([
                    'status' => true,
                    'data' => [
                        'token' => md5($real),
                        'rng' => $time->getTimestamp()
                    ]
                ]);
            } else {
                return $this->response->setJSON([
                    'status' => false,
                    'reason' => 'MAX DEVICE REACHED'
                ]);
            }
        } else {
            return $this->response->setJSON([
                'status' => false,
                'reason' => 'USER OR GAME NOT REGISTERED'
            ]);
        }
    }

    /**
     * Manage devices for new license system
     */
    private function manageDevices($license, $hwid)
    {
        $devices = $license->devices ? json_decode($license->devices, true) : [];
        
        // Check if device already registered
        if (in_array($hwid, $devices)) {
            return ['success' => true];
        }

        // Check device limit
        if (count($devices) >= $license->max_devices) {
            return ['success' => false, 'reason' => 'MAX DEVICE LIMIT REACHED'];
        }

        // Add new device
        $devices[] = $hwid;
        $this->licenseModel->update($license->id, [
            'devices' => json_encode($devices),
            'device_count' => count($devices),
            'last_used_at' => date('Y-m-d H:i:s')
        ]);

        return ['success' => true];
    }

    /**
     * Legacy device management (backward compatibility)
     */
    private function checkDevicesAdd($serial, $devices, $max_dev)
    {
        if (!$devices) {
            return ['devices' => $serial];
        }

        $lsDevice = explode(",", $devices);
        $cDevices = count($lsDevice);
        $serialOn = in_array($serial, $lsDevice);

        if ($serialOn) {
            return true;
        } else {
            if ($cDevices < $max_dev) {
                array_push($lsDevice, $serial);
                $setDevice = implode(",", array_filter($lsDevice));
                return ['devices' => $setDevice];
            } else {
                return false;
            }
        }
    }

    /**
     * Log authentication attempts
     */
    private function logAuthentication($licenseId, $hwid, $status)
    {
        // Log to activity_logs table (if exists)
        try {
            $db = \Config\Database::connect();
            if ($db->tableExists('activity_logs')) {
                $db->table('activity_logs')->insert([
                    'user_id' => null,
                    'action' => 'license_auth',
                    'description' => "License authentication: $status, HWID: $hwid",
                    'ip_address' => $this->request->getIPAddress(),
                    'created_at' => date('Y-m-d H:i:s')
                ]);
            }
        } catch (\Exception $e) {
            // Ignore logging errors to prevent breaking authentication
            log_message('error', 'Connect API logging failed: ' . $e->getMessage());
        }
    }

    /**
     * Health Check Endpoint
     */
    public function health()
    {
        return $this->response->setJSON([
            'status' => 'ok',
            'version' => '2.0.0',
            'endpoint' => 'connect',
            'timestamp' => date('Y-m-d H:i:s')
        ]);
    }
}
