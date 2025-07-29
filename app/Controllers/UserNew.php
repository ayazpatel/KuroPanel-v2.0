<?php

namespace App\Controllers;

use App\Models\LicenseKeyModel;
use App\Models\UserModel;
use App\Models\ResellerAppModel;
use App\Models\AppModel;
use CodeIgniter\Config\Services;

class User extends BaseController
{
    protected $model, $userid, $user;

    public function __construct()
    {
        $this->userid = session()->userid;
        $this->model = new UserModel();
        $this->user = $this->model->getUser($this->userid);
        $this->time = new \CodeIgniter\I18n\Time;
        
        // Check if user is logged in and is a regular user or admin
        if (!$this->user || !in_array($this->user->level, [1, 4])) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('Access denied');
        }
    }

    /**
     * User Dashboard
     */
    public function index()
    {
        $licenseModel = new LicenseKeyModel();
        $userLicenses = $licenseModel->getUserLicenses($this->userid);
        
        $stats = [
            'total_licenses' => count($userLicenses),
            'active_licenses' => count(array_filter($userLicenses, fn($l) => $l->status === 'active')),
            'expired_licenses' => count(array_filter($userLicenses, fn($l) => $l->status === 'expired')),
            'current_balance' => $this->user->saldo
        ];

        $data = [
            'title' => 'User Dashboard',
            'user' => $this->user,
            'time' => $this->time,
            'licenses' => $userLicenses,
            'stats' => $stats
        ];

        return view('User/dashboard', $data);
    }

    /**
     * Purchase License Keys
     */
    public function purchaseLicense()
    {
        if ($this->request->getMethod() === 'POST') {
            return $this->processPurchase();
        }

        $appModel = new AppModel();
        $availableApps = $appModel->getActiveApps();

        $data = [
            'title' => 'Purchase License',
            'user' => $this->user,
            'apps' => $availableApps
        ];

        return view('User/purchase_license', $data);
    }

    /**
     * Process license purchase
     */
    private function processPurchase()
    {
        $rules = [
            'app_id' => 'required|integer',
            'duration_days' => 'required|integer|greater_than[0]'
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $appId = $this->request->getPost('app_id');
        $durationDays = $this->request->getPost('duration_days');
        
        // Basic pricing logic (would be more complex in real app)
        $basePrice = 5.00; // Base price per 30 days
        $price = ($durationDays / 30) * $basePrice;
        
        if ($this->user->saldo < $price) {
            return redirect()->back()->with('error', 'Insufficient balance. Please add funds to your account.');
        }

        $appModel = new AppModel();
        $app = $appModel->find($appId);
        if (!$app) {
            return redirect()->back()->with('error', 'Invalid app selected');
        }

        $licenseModel = new LicenseKeyModel();
        $result = $licenseModel->generateKey($appId, $app->developer_id, null, [
            'key_type' => 'single',
            'max_devices' => 1,
            'duration_days' => $durationDays,
            'price' => $price
        ]);

        if ($result['success']) {
            // Deduct balance
            $newBalance = $this->user->saldo - $price;
            $this->model->update($this->userid, ['saldo' => $newBalance]);
            
            // Activate the license immediately for direct purchases
            $licenseModel->activateLicense($result['license_key'], $this->userid);
            
            return redirect()->back()->with('success', 'License purchased successfully! Key: ' . $result['license_key']);
        }

        return redirect()->back()->with('error', 'Failed to purchase license');
    }

    /**
     * Activate License Key
     */
    public function activateLicense()
    {
        if ($this->request->getMethod() === 'POST') {
            return $this->processActivation();
        }

        $data = [
            'title' => 'Activate License Key',
            'user' => $this->user
        ];

        return view('User/activate_license', $data);
    }

    /**
     * Process license activation
     */
    private function processActivation()
    {
        $licenseKey = $this->request->getPost('license_key');
        $hwid = $this->request->getPost('hwid');
        
        if (!$licenseKey) {
            return redirect()->back()->with('error', 'Please enter a license key');
        }

        $licenseModel = new LicenseKeyModel();
        $result = $licenseModel->activateLicense($licenseKey, $this->userid, $hwid);

        if ($result['success']) {
            return redirect()->to('/user')->with('success', $result['message']);
        }

        return redirect()->back()->with('error', $result['message']);
    }

    /**
     * My License Keys
     */
    public function myLicenses()
    {
        $licenseModel = new LicenseKeyModel();
        $licenses = $licenseModel->getUserLicenses($this->userid);

        $data = [
            'title' => 'My License Keys',
            'user' => $this->user,
            'licenses' => $licenses
        ];

        return view('User/my_licenses', $data);
    }

    /**
     * Request HWID Reset
     */
    public function requestHwidReset()
    {
        if ($this->request->getMethod() === 'POST') {
            return $this->processHwidReset();
        }

        $licenseModel = new LicenseKeyModel();
        $licenses = $licenseModel->getUserLicenses($this->userid, 'active');

        $data = [
            'title' => 'Request HWID Reset',
            'user' => $this->user,
            'licenses' => $licenses
        ];

        return view('User/hwid_reset', $data);
    }

    /**
     * Process HWID reset request
     */
    private function processHwidReset()
    {
        $licenseKeyId = $this->request->getPost('license_key_id');
        $reason = $this->request->getPost('reason');
        $cost = 5.00; // HWID reset cost
        
        if ($this->user->saldo < $cost) {
            return redirect()->back()->with('error', 'Insufficient balance for HWID reset');
        }

        // In a real app, this would create a request in hwid_resets table
        // For now, we'll just deduct the cost and reset the device
        $licenseModel = new LicenseKeyModel();
        $license = $licenseModel->find($licenseKeyId);
        
        if (!$license || $license->user_id != $this->userid) {
            return redirect()->back()->with('error', 'Invalid license selected');
        }

        // Reset devices and deduct cost
        $licenseModel->update($licenseKeyId, [
            'devices' => json_encode([]),
            'device_count' => 0
        ]);
        
        $this->model->update($this->userid, ['saldo' => $this->user->saldo - $cost]);

        return redirect()->back()->with('success', 'HWID reset completed successfully');
    }

    /**
     * Profile Settings
     */
    public function profile()
    {
        if ($this->request->getMethod() === 'POST') {
            return $this->updateProfile();
        }

        $data = [
            'title' => 'Profile Settings',
            'user' => $this->user
        ];

        return view('User/profile', $data);
    }

    /**
     * Update user profile
     */
    private function updateProfile()
    {
        $rules = [
            'fullname' => 'permit_empty|max_length[255]',
            'email' => 'permit_empty|valid_email',
            'telegram_username' => 'permit_empty|max_length[100]'
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $updateData = [
            'fullname' => $this->request->getPost('fullname'),
            'email' => $this->request->getPost('email'),
            'telegram_username' => $this->request->getPost('telegram_username')
        ];

        if ($this->model->update($this->userid, $updateData)) {
            return redirect()->back()->with('success', 'Profile updated successfully');
        }

        return redirect()->back()->with('error', 'Failed to update profile');
    }

    /**
     * Add Balance (Placeholder for payment integration)
     */
    public function addBalance()
    {
        $data = [
            'title' => 'Add Balance',
            'user' => $this->user
        ];

        return view('User/add_balance', $data);
    }
}
