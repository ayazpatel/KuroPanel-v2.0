<?php

namespace App\Controllers;

use App\Models\AppModel;
use App\Models\LicenseKeyModel;
use App\Models\UserModel;
use App\Models\InviteCodeModel;
use App\Models\ResellerAppModel;
use CodeIgniter\Config\Services;

class Admin extends BaseController
{
    protected $model, $userid, $user;

    public function __construct()
    {
        $this->userid = session()->userid;
        $this->model = new UserModel();
        $this->user = $this->model->getUser($this->userid);
        
        // Check if user is admin
        if (!$this->user || $this->user->level != 1) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('Access denied');
        }
    }

    /**
     * Admin Dashboard
     */
    public function index()
    {
        $userModel = new UserModel();
        $appModel = new AppModel();
        $licenseModel = new LicenseKeyModel();
        
        $stats = [
            'total_users' => $userModel->countAllResults(),
            'total_developers' => $userModel->where('level', 2)->countAllResults(),
            'total_resellers' => $userModel->where('level', 3)->countAllResults(),
            'total_end_users' => $userModel->where('level', 4)->countAllResults(),
            'total_apps' => $appModel->countAllResults(),
            'total_licenses' => $licenseModel->countAllResults(),
            'active_licenses' => $licenseModel->where('status', 'active')->countAllResults()
        ];

        $recentUsers = $userModel->orderBy('created_at', 'DESC')->limit(10)->findAll();
        $recentApps = $appModel->getAppsWithDeveloper();

        $data = [
            'title' => 'Admin Dashboard',
            'user' => $this->user,
            'stats' => $stats,
            'recent_users' => $recentUsers,
            'recent_apps' => array_slice($recentApps, 0, 10)
        ];

        return view('Admin/dashboard', $data);
    }

    /**
     * Manage Users
     */
    public function users($level = null)
    {
        $userModel = new UserModel();
        
        if ($this->request->getMethod() === 'POST') {
            return $this->processUserAction();
        }

        $builder = $userModel->orderBy('created_at', 'DESC');
        
        if ($level && in_array($level, [2, 3, 4])) {
            $builder->where('level', $level);
        }
        
        $users = $builder->findAll();

        $data = [
            'title' => 'Manage Users',
            'user' => $this->user,
            'users' => $users,
            'filter_level' => $level
        ];

        return view('Admin/users', $data);
    }

    /**
     * Process user management actions
     */
    private function processUserAction()
    {
        $action = $this->request->getPost('action');
        $userId = $this->request->getPost('user_id');
        
        $userModel = new UserModel();
        
        switch ($action) {
            case 'create':
                return $this->createUser();
            case 'update_status':
                $status = $this->request->getPost('status');
                if ($userModel->update($userId, ['status' => $status])) {
                    return redirect()->back()->with('success', 'User status updated');
                }
                break;
            case 'update_level':
                $level = $this->request->getPost('level');
                if (in_array($level, [2, 3, 4]) && $userModel->update($userId, ['level' => $level])) {
                    return redirect()->back()->with('success', 'User level updated');
                }
                break;
            case 'delete':
                if ($userModel->delete($userId)) {
                    return redirect()->back()->with('success', 'User deleted');
                }
                break;
        }
        
        return redirect()->back()->with('error', 'Action failed');
    }

    /**
     * Create new user
     */
    private function createUser()
    {
        $rules = [
            'username' => 'required|min_length[3]|max_length[100]|is_unique[users.username]',
            'email' => 'permit_empty|valid_email|is_unique[users.email]',
            'fullname' => 'permit_empty|max_length[255]',
            'level' => 'required|in_list[2,3,4]',
            'password' => 'required|min_length[6]'
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $userModel = new UserModel();
        $data = [
            'username' => $this->request->getPost('username'),
            'email' => $this->request->getPost('email'),
            'fullname' => $this->request->getPost('fullname'),
            'level' => $this->request->getPost('level'),
            'password' => create_password($this->request->getPost('password')),
            'status' => 1,
            'saldo' => 0
        ];

        if ($userModel->insert($data)) {
            return redirect()->back()->with('success', 'User created successfully');
        }

        return redirect()->back()->with('error', 'Failed to create user');
    }

    /**
     * Manage Apps
     */
    public function apps()
    {
        $appModel = new AppModel();
        $apps = $appModel->getAppsWithDeveloper();

        $data = [
            'title' => 'Manage Apps',
            'user' => $this->user,
            'apps' => $apps
        ];

        return view('Admin/apps', $data);
    }

    /**
     * View App Details
     */
    public function appDetails($appId)
    {
        $appModel = new AppModel();
        $app = $appModel->find($appId);
        
        if (!$app) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('App not found');
        }

        $stats = $appModel->getAppStats($appId);
        $resellerModel = new ResellerAppModel();
        $resellers = $resellerModel->getAppResellers($appId, $app->developer_id);
        
        $licenseModel = new LicenseKeyModel();
        $licenses = $licenseModel->getDeveloperKeys($app->developer_id, $appId);

        $data = [
            'title' => 'App Details - ' . $app->app_name,
            'user' => $this->user,
            'app' => $app,
            'stats' => $stats,
            'resellers' => $resellers,
            'licenses' => array_slice($licenses, 0, 20) // Latest 20 licenses
        ];

        return view('Admin/app_details', $data);
    }

    /**
     * System Settings
     */
    public function settings()
    {
        if ($this->request->getMethod() === 'POST') {
            return $this->updateSettings();
        }

        // Load current settings (would need SystemSettingsModel)
        $settings = [
            'site_name' => 'KuroPanel',
            'maintenance_mode' => false,
            'registration_enabled' => true,
            'telegram_bot_token' => '',
            'hwid_reset_cost' => 5.00
        ];

        $data = [
            'title' => 'System Settings',
            'user' => $this->user,
            'settings' => $settings
        ];

        return view('Admin/settings', $data);
    }

    /**
     * Update system settings
     */
    private function updateSettings()
    {
        // Implementation would update system_settings table
        return redirect()->back()->with('success', 'Settings updated successfully');
    }

    /**
     * View All Licenses
     */
    public function licenses()
    {
        $licenseModel = new LicenseKeyModel();
        $licenses = $licenseModel->select('license_keys.*, apps.app_name, users.username as user_username, developers.username as developer_username, resellers.username as reseller_username')
                                ->join('apps', 'apps.id_app = license_keys.app_id')
                                ->leftJoin('users', 'users.id_users = license_keys.user_id')
                                ->join('users as developers', 'developers.id_users = license_keys.developer_id')
                                ->leftJoin('users as resellers', 'resellers.id_users = license_keys.reseller_id')
                                ->orderBy('license_keys.created_at', 'DESC')
                                ->limit(100)
                                ->findAll();

        $data = [
            'title' => 'All License Keys',
            'user' => $this->user,
            'licenses' => $licenses
        ];

        return view('Admin/licenses', $data);
    }

    /**
     * Generate Reports
     */
    public function reports()
    {
        $data = [
            'title' => 'System Reports',
            'user' => $this->user
        ];

        return view('Admin/reports', $data);
    }

    /**
     * Activity Logs
     */
    public function logs()
    {
        // Implementation would load from activity_logs table
        $data = [
            'title' => 'Activity Logs',
            'user' => $this->user,
            'logs' => []
        ];

        return view('Admin/logs', $data);
    }
}
