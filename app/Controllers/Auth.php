<?php

namespace App\Controllers;

use App\Models\CodeModel;
use App\Models\UserModel;
use CodeIgniter\Config\Services;

class Auth extends BaseController
{
    protected $userModel;

    public function __construct()
    {
        $this->userModel = new UserModel();
    }

    public function index()
    {
        /* ---------------------------- Debugmode --------------------------- */
        $a = $this->userModel->getUser(session('userid'));
        dd($a, session());
    }

    public function login()
    {
        if (session()->has('userid'))
            return redirect()->to('dashboard');

        if ($this->request->getPost())
            return $this->login_action();

        $data = [
            'title' => 'Login',
            'validation' => Services::validation(),
        ];
        return view('Auth/login', $data);
    }

    public function register()
    {
        if (session()->has('userid'))
            return redirect()->to('dashboard');

        if ($this->request->getPost())
            return $this->register_action();
        $data = [
            'title' => 'Register',
            'validation' => Services::validation(),
        ];
        return view('Auth/register', $data);
    }

    private function login_action()
    {
        $username = trim($this->request->getPost('username') ?? '');
        $password = trim($this->request->getPost('password') ?? '');
        $stay_log = trim($this->request->getPost('stay_log') ?? '');

        // Basic validation without database checks to avoid null parameter issues
        $form_rules = [
            'username' => [
                'label' => 'username',
                'rules' => 'required|alpha_numeric|min_length[4]|max_length[25]',
            ],
            'password' => [
                'label' => 'password',
                'rules' => 'required|min_length[6]|max_length[45]',
            ],
            'stay_log' => [
                'rules' => 'permit_empty|max_length[3]'
            ]
        ];

        $data = [
            'username' => $username,
            'password' => $password,
            'stay_log' => $stay_log
        ];

        if (!$this->validate($form_rules, $data)) {
            return redirect()->route('login')->withInput()->with('msgDanger', '<strong>Failed</strong> Please check the form.');
        }

        // Manual check for user existence to avoid validation null issues
        $cekUser = $this->userModel->getUser($username, 'username');
        if (!$cekUser) {
            return redirect()->route('login')->withInput()->with('msgDanger', '<strong>Failed</strong> Username is not registered.');
        }

        $hashPassword = create_password($password, false);
        if (password_verify($hashPassword, $cekUser->password)) {
            $time = new \CodeIgniter\I18n\Time;
            $sessionData = [
                'userid' => $cekUser->id_users,
                'unames' => $cekUser->username,
                'time_login' => $stay_log ? $time::now()->addHours(24) : $time::now()->addMinutes(30),
                'time_since' => $time::now(),
            ];
            session()->set($sessionData);
            return redirect()->to('dashboard');
        } else {
            return redirect()->route('login')->withInput()->with('msgDanger', '<strong>Failed</strong> Wrong password, please try again.');
        }
    }

    public function register_action()
    {
        $username = trim($this->request->getPost('username') ?? '');
        $password = trim($this->request->getPost('password') ?? '');
        $password2 = trim($this->request->getPost('password2') ?? '');
        $referral = trim($this->request->getPost('referral') ?? '');

        // Basic validation without database checks to avoid null parameter issues
        $form_rules = [
            'username' => [
                'label' => 'username',
                'rules' => 'required|alpha_numeric|min_length[4]|max_length[25]',
            ],
            'password' => [
                'label' => 'password',
                'rules' => 'required|min_length[6]|max_length[45]',
            ],
            'password2' => [
                'label' => 'password',
                'rules' => 'required|min_length[6]|max_length[45]|matches[password]',
                'errors' => [
                    'matches' => '{field} not match, check the {field}.'
                ]
            ],
            'referral' => [
                'label' => 'referral',
                'rules' => 'required|min_length[6]|alpha_numeric',
            ]
        ];

        $data = [
            'username' => $username,
            'password' => $password,
            'password2' => $password2,
            'referral' => $referral
        ];

        if (!$this->validate($form_rules, $data)) {
            return redirect()->route('register')->withInput()->with('msgDanger', '<strong>Failed</strong> Please check the form.');
        }

        // Manual check for username uniqueness to avoid validation null issues
        $existingUser = $this->userModel->getUser($username, 'username');
        if ($existingUser) {
            return redirect()->route('register')->withInput()->with('msgDanger', '<strong>Failed</strong> The username has been taken.');
        }

        $mCode = new CodeModel();
        $rCheck = $mCode->checkCode($referral);
        if (!$rCheck) {
            return redirect()->route('register')->withInput()->with('msgDanger', '<strong>Failed</strong> Wrong referral, please try again.');
        }

        if ($rCheck->used_by) {
            return redirect()->route('register')->withInput()->with('msgDanger', "<strong>Failed</strong> Wrong referral, code has been used by $rCheck->used_by.");
        }

        $hashPassword = create_password($password);
        $data_register = [
            'username' => $username,
            'password' => $hashPassword,
            'saldo' => $rCheck->set_saldo ?: 0,
            'uplink' => $rCheck->created_by
        ];
        $ids = $this->userModel->insert($data_register, true);
        if ($ids) {
            $mCode->useReferral($referral);
            $msg = "Register Successfully!";
            return redirect()->to('login')->with('msgSuccess', $msg);
        }

        return redirect()->route('register')->withInput()->with('msgDanger', '<strong>Failed</strong> Registration failed, please try again.');
    }

    public function logout()
    {
        if (session()->has('userid')) {
            $unset = ['userid', 'unames', 'time_login', 'time_since'];
            session()->remove($unset);
            session()->setFlashdata('msgSuccess', 'Logout successfuly.');
        }
        return redirect()->to('login');
    }
}
