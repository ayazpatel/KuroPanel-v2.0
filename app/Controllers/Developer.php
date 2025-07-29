<?php

namespace App\Controllers;

use App\Models\AppModel;
use App\Models\LicenseKeyModel;
use App\Models\UserModel;
use App\Models\InviteCodeModel;
use App\Models\ResellerAppModel;
use CodeIgniter\Config\Services;

class Developer extends BaseController
{
    protected $model, $userid, $user;

    public function __construct()
    {
        $this->userid = session()->userid;
        $this->model = new UserModel();
        $this->user = $this->model->getUser($this->userid);
        
        // Check if user is developer or admin
        if (!$this->user || !in_array($this->user->level, [1, 2])) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('Access denied');
        }
    }

    /**
     * Developer Dashboard
     */
    public function index()
    {
        $appModel = new AppModel();
        $licenseModel = new LicenseKeyModel();
        
        $apps = $appModel->getAppsByDeveloper($this->userid);
        $stats = [
            'total_apps' => count($apps),
            'total_licenses' => 0,
            'active_licenses' => 0,
            'total_revenue' => 0
        ];
        
        foreach ($apps as $app) {
            $appStats = $appModel->getAppStats($app->id_app);
            $stats['total_licenses'] += $appStats['total_licenses'];
            $stats['active_licenses'] += $appStats['active_licenses'];
        }

        $data = [
            'title' => 'Developer Dashboard',
            'user' => $this->user,
            'apps' => $apps,
            'stats' => $stats
        ];

        return view('Developer/dashboard', $data);
    }

    /**
     * Manage Apps
     */
    public function apps()
    {
        $appModel = new AppModel();
        
        if ($this->request->getMethod() === 'POST') {
            return $this->createApp();
        }

        $apps = $appModel->getAppsByDeveloper($this->userid);
        
        $data = [
            'title' => 'Manage Apps',
            'user' => $this->user,
            'apps' => $apps
        ];

        return view('Developer/apps', $data);
    }

    /**
     * Create new app
     */
    private function createApp()
    {
        $appModel = new AppModel();
        
        $rules = [
            'app_name' => 'required|min_length[3]|max_length[255]',
            'app_description' => 'permit_empty|max_length[1000]',
            'current_version' => 'permit_empty|max_length[50]'
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $data = [
            'app_name' => $this->request->getPost('app_name'),
            'app_description' => $this->request->getPost('app_description'),
            'current_version' => $this->request->getPost('current_version') ?: '1.0.0',
            'developer_id' => $this->userid,
            'status' => 'active'
        ];

        if ($appModel->insert($data)) {
            return redirect()->to('/developer/apps')->with('success', 'App created successfully');
        }

        return redirect()->back()->withInput()->with('error', 'Failed to create app');
    }

    /**
     * App Details
     */
    public function appDetails($appId)
    {
        $appModel = new AppModel();
        $app = $appModel->find($appId);
        
        if (!$app || $app->developer_id != $this->userid) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('App not found');
        }

        $stats = $appModel->getAppStats($appId);
        $resellerModel = new ResellerAppModel();
        $resellers = $resellerModel->getAppResellers($appId, $this->userid);

        $data = [
            'title' => 'App Details - ' . $app->app_name,
            'user' => $this->user,
            'app' => $app,
            'stats' => $stats,
            'resellers' => $resellers
        ];

        return view('Developer/app_details', $data);
    }

    /**
     * Generate Invite Codes
     */
    public function generateInvite()
    {
        if ($this->request->getMethod() === 'POST') {
            return $this->processInviteGeneration();
        }

        $appModel = new AppModel();
        $apps = $appModel->getAppsByDeveloper($this->userid);

        $data = [
            'title' => 'Generate Invite Codes',
            'user' => $this->user,
            'apps' => $apps
        ];

        return view('Developer/generate_invite', $data);
    }

    /**
     * Process invite code generation
     */
    private function processInviteGeneration()
    {
        $rules = [
            'app_id' => 'required|integer',
            'target_role' => 'required|in_list[reseller]',
            'max_uses' => 'permit_empty|integer|greater_than[0]',
            'expires_in' => 'permit_empty'
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $appId = $this->request->getPost('app_id');
        
        // Verify app belongs to developer
        $appModel = new AppModel();
        $app = $appModel->find($appId);
        if (!$app || $app->developer_id != $this->userid) {
            return redirect()->back()->with('error', 'Invalid app selected');
        }

        $inviteModel = new InviteCodeModel();
        $result = $inviteModel->generateInviteCode(
            $this->userid,
            $appId,
            $this->request->getPost('target_role'),
            $this->request->getPost('max_uses') ?: 1,
            $this->request->getPost('expires_in')
        );

        if ($result['success']) {
            return redirect()->back()->with('success', 'Invite code generated: ' . $result['code']);
        }

        return redirect()->back()->with('error', $result['message']);
    }

    /**
     * Set Global Maintenance
     */
    public function setMaintenance($appId)
    {
        if ($this->request->getMethod() === 'POST') {
            $appModel = new AppModel();
            $app = $appModel->find($appId);
            
            if (!$app || $app->developer_id != $this->userid) {
                return $this->response->setJSON(['success' => false, 'message' => 'App not found']);
            }

            $enabled = $this->request->getPost('enabled') === '1';
            $message = $this->request->getPost('message') ?: '';

            if ($appModel->setGlobalMaintenance($appId, $enabled, $message)) {
                return $this->response->setJSON([
                    'success' => true,
                    'message' => 'Maintenance mode ' . ($enabled ? 'enabled' : 'disabled')
                ]);
            }

            return $this->response->setJSON(['success' => false, 'message' => 'Failed to update maintenance mode']);
        }

        return redirect()->to('/developer/apps');
    }

    /**
     * View Licenses
     */
    public function licenses($appId = null)
    {
        $licenseModel = new LicenseKeyModel();
        $appModel = new AppModel();
        
        if ($appId) {
            $app = $appModel->find($appId);
            if (!$app || $app->developer_id != $this->userid) {
                throw new \CodeIgniter\Exceptions\PageNotFoundException('App not found');
            }
            $licenses = $licenseModel->getDeveloperKeys($this->userid, $appId);
        } else {
            $licenses = $licenseModel->getDeveloperKeys($this->userid);
        }

        $apps = $appModel->getAppsByDeveloper($this->userid);

        $data = [
            'title' => 'License Keys',
            'user' => $this->user,
            'licenses' => $licenses,
            'apps' => $apps,
            'selected_app' => $appId
        ];

        return view('Developer/licenses', $data);
    }

    /**
     * Invite Codes Management
     */
    public function inviteCodes()
    {
        $inviteModel = new InviteCodeModel();
        $codes = $inviteModel->getUserInviteCodes($this->userid);

        $data = [
            'title' => 'Invite Codes',
            'user' => $this->user,
            'codes' => $codes
        ];

        return view('Developer/invite_codes', $data);
    }
}
