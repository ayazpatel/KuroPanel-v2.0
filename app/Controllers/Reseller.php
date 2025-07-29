<?php

namespace App\Controllers;

use App\Models\AppModel;
use App\Models\LicenseKeyModel;
use App\Models\UserModel;
use App\Models\ResellerAppModel;
use App\Models\InviteCodeModel;
use CodeIgniter\Config\Services;

class Reseller extends BaseController
{
    protected $model, $userid, $user;

    public function __construct()
    {
        $this->userid = session()->userid;
        $this->model = new UserModel();
        $this->user = $this->model->getUser($this->userid);
        
        // Check if user is reseller or admin
        if (!$this->user || !in_array($this->user->level, [1, 3])) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('Access denied');
        }
    }

    /**
     * Reseller Dashboard
     */
    public function index()
    {
        $resellerAppModel = new ResellerAppModel();
        $licenseModel = new LicenseKeyModel();
        
        $assignedApps = $resellerAppModel->getResellerApps($this->userid);
        
        $stats = [
            'assigned_apps' => count($assignedApps),
            'total_keys_generated' => 0,
            'active_keys' => 0,
            'total_users' => 0
        ];

        foreach ($assignedApps as $app) {
            $appStats = $resellerAppModel->getResellerAppStats($this->userid, $app->id_app);
            $stats['total_keys_generated'] += $appStats['total_keys_generated'];
            $stats['active_keys'] += $appStats['active_keys'];
        }

        $data = [
            'title' => 'Reseller Dashboard',
            'user' => $this->user,
            'apps' => $assignedApps,
            'stats' => $stats
        ];

        return view('Reseller/dashboard', $data);
    }

    /**
     * Use Invite Code
     */
    public function useInvite()
    {
        if ($this->request->getMethod() === 'POST') {
            return $this->processInviteCode();
        }

        $data = [
            'title' => 'Use Invite Code',
            'user' => $this->user
        ];

        return view('Reseller/use_invite', $data);
    }

    /**
     * Process invite code usage
     */
    private function processInviteCode()
    {
        $inviteCode = $this->request->getPost('invite_code');
        
        if (!$inviteCode) {
            return redirect()->back()->with('error', 'Please enter an invite code');
        }

        $resellerAppModel = new ResellerAppModel();
        $result = $resellerAppModel->assignAppToReseller($inviteCode, $this->userid);

        if ($result['success']) {
            return redirect()->to('/reseller')->with('success', $result['message']);
        }

        return redirect()->back()->with('error', $result['message']);
    }

    /**
     * Generate License Keys
     */
    public function generateKeys()
    {
        if ($this->request->getMethod() === 'POST') {
            return $this->processKeyGeneration();
        }

        $resellerAppModel = new ResellerAppModel();
        $assignedApps = $resellerAppModel->getResellerApps($this->userid);

        $data = [
            'title' => 'Generate License Keys',
            'user' => $this->user,
            'apps' => $assignedApps
        ];

        return view('Reseller/generate_keys', $data);
    }

    /**
     * Process license key generation
     */
    private function processKeyGeneration()
    {
        $rules = [
            'app_id' => 'required|integer',
            'key_type' => 'required|in_list[single,multi]',
            'max_devices' => 'permit_empty|integer|greater_than[0]',
            'duration_days' => 'required|integer|greater_than[0]',
            'quantity' => 'required|integer|greater_than[0]|less_than_equal_to[100]'
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $appId = $this->request->getPost('app_id');
        
        // Verify reseller has access to this app
        $resellerAppModel = new ResellerAppModel();
        $hasAccess = $resellerAppModel->where('reseller_id', $this->userid)
                                     ->where('app_id', $appId)
                                     ->where('status', 'active')
                                     ->first();
        
        if (!$hasAccess) {
            return redirect()->back()->with('error', 'You do not have access to this app');
        }

        $licenseModel = new LicenseKeyModel();
        $quantity = $this->request->getPost('quantity');
        $generatedKeys = [];
        
        $config = [
            'key_type' => $this->request->getPost('key_type'),
            'max_devices' => $this->request->getPost('max_devices') ?: 1,
            'duration_days' => $this->request->getPost('duration_days'),
            'price' => $this->request->getPost('price') ?: 0
        ];

        for ($i = 0; $i < $quantity; $i++) {
            $result = $licenseModel->generateKey($appId, $hasAccess->developer_id, $this->userid, $config);
            if ($result['success']) {
                $generatedKeys[] = $result['license_key'];
            }
        }

        if (count($generatedKeys) > 0) {
            session()->setFlashdata('generated_keys', $generatedKeys);
            return redirect()->back()->with('success', count($generatedKeys) . ' license keys generated successfully');
        }

        return redirect()->back()->with('error', 'Failed to generate license keys');
    }

    /**
     * Manage Generated Keys
     */
    public function manageKeys($appId = null)
    {
        $licenseModel = new LicenseKeyModel();
        $resellerAppModel = new ResellerAppModel();
        
        if ($appId) {
            // Verify access to app
            $hasAccess = $resellerAppModel->where('reseller_id', $this->userid)
                                         ->where('app_id', $appId)
                                         ->where('status', 'active')
                                         ->first();
            if (!$hasAccess) {
                throw new \CodeIgniter\Exceptions\PageNotFoundException('App not found');
            }
            $keys = $licenseModel->getResellerKeys($this->userid, $appId);
        } else {
            $keys = $licenseModel->getResellerKeys($this->userid);
        }

        $assignedApps = $resellerAppModel->getResellerApps($this->userid);

        $data = [
            'title' => 'Manage License Keys',
            'user' => $this->user,
            'keys' => $keys,
            'apps' => $assignedApps,
            'selected_app' => $appId
        ];

        return view('Reseller/manage_keys', $data);
    }

    /**
     * Set App Maintenance Mode
     */
    public function setMaintenance($appId)
    {
        if ($this->request->getMethod() === 'POST') {
            $resellerAppModel = new ResellerAppModel();
            
            // Verify access
            $hasAccess = $resellerAppModel->where('reseller_id', $this->userid)
                                         ->where('app_id', $appId)
                                         ->where('status', 'active')
                                         ->first();
            
            if (!$hasAccess) {
                return $this->response->setJSON(['success' => false, 'message' => 'Access denied']);
            }

            $enabled = $this->request->getPost('enabled') === '1';
            $message = $this->request->getPost('message') ?: '';

            if ($resellerAppModel->setResellerMaintenance($this->userid, $appId, $enabled, $message)) {
                return $this->response->setJSON([
                    'success' => true,
                    'message' => 'Maintenance mode ' . ($enabled ? 'enabled' : 'disabled')
                ]);
            }

            return $this->response->setJSON(['success' => false, 'message' => 'Failed to update maintenance mode']);
        }

        return redirect()->to('/reseller');
    }

    /**
     * Update Branding
     */
    public function updateBranding($appId)
    {
        if ($this->request->getMethod() === 'POST') {
            $resellerAppModel = new ResellerAppModel();
            
            $branding = [
                'custom_logo_url' => $this->request->getPost('custom_logo_url'),
                'custom_description' => $this->request->getPost('custom_description')
            ];

            if ($resellerAppModel->updateResellerBranding($this->userid, $appId, $branding)) {
                return redirect()->back()->with('success', 'Branding updated successfully');
            }

            return redirect()->back()->with('error', 'Failed to update branding');
        }

        return redirect()->to('/reseller');
    }

    /**
     * Key Portal for Users
     */
    public function keyPortal()
    {
        $data = [
            'title' => 'License Key Portal',
            'user' => $this->user
        ];

        return view('Reseller/key_portal', $data);
    }
}
