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

    public function ref_index()
    {
        $user  = $this->user;
        if ($user->level != 1)
            return redirect()->to('dashboard')->with('msgWarning', 'Access Denied!');

        if ($this->request->getPost())
            return $this->reff_action();

        $mCode = new CodeModel();
        $validation = Services::validation();
        $data = [
            'title' => 'Referral',
            'user' => $user,
            'time' => $this->time,
            'code' => $mCode->getCode(),
            'total_code' => $mCode->countAllResults(),
            'validation' => $validation
        ];
        return view('Admin/referral', $data);
    }

    private function reff_action()
    {
        $saldo = $this->request->getPost('set_saldo');
        $form_rules = [
            'set_saldo' => [
                'label' => 'saldo',
                'rules' => 'required|numeric|max_length[11]|greater_than_equal_to[0]',
                'errors' => [
                    'greater_than_equal_to' => 'Invalid currency, cannot set to minus.'
                ]
            ]
        ];

        if (!$this->validate($form_rules)) {
            return redirect()->back()->withInput()->with('msgDanger', 'Failed, check the form');
        } else {
            $code = random_string('alnum', 6);
            $codeHash = create_password($code, false);
            $referral_code = [
                'code' => $codeHash,
                'set_saldo' => ($saldo < 1 ? 0 : $saldo),
                'created_by' => session('unames')
            ];
            $mCode = new CodeModel();
            $ids = $mCode->insert($referral_code, true);
            if ($ids) {
                $msg = "Referral : $code";
                return redirect()->back()->with('msgSuccess', $msg);
            }
        }
    }

    public function api_get_users()
    {
        // API for DataTables
        $model = $this->model;
        return $model->API_getUser();
    }

    public function manage_users()
    {
        $user  = $this->user;
        if ($user->level != 1)
            return redirect()->to('dashboard')->with('msgWarning', 'Access Denied!');

        $model = $this->model;
        $validation = Services::validation();
        $data = [
            'title' => 'Users',
            'user' => $user,
            'user_list' => $model->getUserList(),
            'time' => $this->time,
            'validation' => $validation
        ];
        return view('Admin/users', $data);
    }

    public function user_edit($userid = false)
    {
        $user = $this->user;
        if ($user->level != 1)
            return redirect()->to('dashboard')->with('msgWarning', 'Access Denied!');

        if ($this->request->getPost())
            return $this->user_edit_action();

        $model = $this->model;
        $validation = Services::validation();

        $data = [
            'title' => 'Settings',
            'user' => $user,
            'target' => $model->getUser($userid),
            'user_list' => $model->getUserList(),
            'time' => $this->time,
            'validation' => $validation,
        ];
        return view('Admin/user_edit', $data);
    }

    private function user_edit_action()
    {
        $model = $this->model;
        $userid = $this->request->getPost('user_id');

        $target = $model->getUser($userid);
        if (!$target) {
            $msg = "User no longer exists.";
            return redirect()->to('dashboard')->with('msgDanger', $msg);
        }

        $username = $this->request->getPost('username');

        $form_rules = [
            'username' => [
                'label' => 'username',
                'rules' => "required|alpha_numeric|min_length[4]|max_length[25]|is_unique[users.username,username,$target->username]",
                'errors' => [
                    'is_unique' => 'The {field} has taken by other.'
                ]
            ],
            'fullname' => [
                'label' => 'name',
                'rules' => 'permit_empty|alpha_space|min_length[4]|max_length[155]',
                'errors' => [
                    'alpha_space' => 'The {field} only allow alphabetical characters and spaces.'
                ]
            ],
            'level' => [
                'label' => 'roles',
                'rules' => 'required|numeric|in_list[1,2]',
                'errors' => [
                    'in_list' => 'Invalid {field}.'
                ]
            ],
            'status' => [
                'label' => 'status',
                'rules' => 'required|numeric|in_list[0,1]',
                'errors' => [
                    'in_list' => 'Invalid {field} account.'
                ]
            ],
            'saldo' => [
                'label' => 'saldo',
                'rules' => 'permit_empty|numeric|max_length[11]|greater_than_equal_to[0]',
                'errors' => [
                    'greater_than_equal_to' => 'Invalid currency, cannot set to minus.'
                ]
            ],
            'uplink' => [
                'label' => 'uplink',
                'rules' => 'required|alpha_numeric|is_not_unique[users.username,username,]',
                'errors' => [
                    'is_not_unique' => 'Uplink not registered anymore.'
                ]
            ]
        ];

        if (!$this->validate($form_rules)) {
            return redirect()->back()->withInput()->with('msgDanger', 'Something wrong! Please check the form');
        } else {
            $fullname = $this->request->getPost('fullname');
            $level = $this->request->getPost('level');
            $status = $this->request->getPost('status');
            $saldo = $this->request->getPost('saldo');
            $uplink = $this->request->getPost('uplink');

            $data_update = [
                'username' => $username,
                'fullname' => esc($fullname),
                'level' => $level,
                'status' => $status,
                'saldo' => (($saldo < 1) ? 0 : $saldo),
                'uplink' => $uplink,
            ];

            $update = $model->update($userid, $data_update);
            if ($update) {
                return redirect()->back()->with('msgSuccess', "Successfuly update $target->username.");
            }
        }
    }

    public function settings()
    {
        if ($this->request->getPost('password_form'))
            return $this->passwd_act();

        if ($this->request->getPost('fullname_form'))
            return $this->fullname_act();

        $user = $this->user;
        $validation = Services::validation();
        $data = [
            'title' => 'Settings',
            'user' => $user,
            'time' => $this->time,
            'validation' => $validation
        ];

        return view('User/settings', $data);
    }

    private function passwd_act()
    {
        $current = $this->request->getPost('current');
        $password = $this->request->getPost('password');

        $user = $this->user;
        $currHash = create_password($current, false);
        $validation = Services::validation();

        if (!password_verify($currHash, $user->password)) {
            $msg = "Wrong current password.";
            $validation->setError('current', $msg);
        } elseif ($current == $password) {
            $msg = "Nothing to change.";
            $validation->setError('password', $msg);
        }

        $form_rules = [
            'current' => [
                'label' => 'current',
                'rules' => 'required|min_length[6]|max_length[45]',
            ],
            'password' => [
                'label' => 'password',
                'rules' => 'required|min_length[6]|max_length[45]',
            ],
            'password2' => [
                'label' => 'confirm',
                'rules' => 'required|min_length[6]|max_length[45]|matches[password]',
                'errors' => [
                    'matches' => '{field} not match, check the {field}.'
                ]
            ],
        ];

        if (!$this->validate($form_rules)) {
            return redirect()->back()->withInput()->with('msgDanger', 'Something wrong! Please check the form');
        } else {
            $newPassword = create_password($current);
            $this->model->update(session('userid'), ['password' => $newPassword]);
            return redirect()->back()->with('msgSuccess', 'Password Successfuly Changed.');
        }
    }

    private function fullname_act()
    {
        $user = $this->user;
        $newName = $this->request->getPost('fullname');

        if ($user->fullname == $newName) {
            $validation = Services::validation();
            $msg = "Nothing to change.";
            $validation->setError('fullname', $msg);
        }

        $form_rules = [
            'fullname' => [
                'label' => 'name',
                'rules' => 'required|alpha_space|min_length[4]|max_length[155]',
                'errors' => [
                    'alpha_space' => 'The {field} only allow alphabetical characters and spaces.'
                ]
            ]
        ];

        if (!$this->validate($form_rules)) {
            return redirect()->back()->withInput()->with('msgDanger', 'Failed! Please check the form');
        } else {
            $this->model->update(session('userid'), ['fullname' => esc($newName)]);
            return redirect()->back()->with('msgSuccess', 'Account Detail Successfuly Changed.');
        }
    }
}
