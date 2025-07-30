<?php

namespace App\Controllers;

use App\Models\AppModel;
use App\Models\UserModel;
use App\Models\LicenseKeyModel;

class Portal extends BaseController
{
    protected $appModel;
    protected $userModel;
    protected $licenseKeyModel;

    public function __construct()
    {
        $this->appModel = new AppModel();
        $this->userModel = new UserModel();
        $this->licenseKeyModel = new LicenseKeyModel();
    }

    /**
     * Display reseller's public portal
     */
    public function index($portalCode = null)
    {
        if (empty($portalCode)) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('Portal not found');
        }

        // Find reseller by portal code
        $reseller = $this->userModel->where('portal_code', $portalCode)
                                  ->where('user_level', 3)
                                  ->first();

        if (!$reseller) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('Portal not found');
        }

        // Get reseller's available apps
        $apps = $this->appModel->getAppsByReseller($reseller['id']);

        $data = [
            'reseller' => $reseller,
            'apps' => $apps,
            'portal_code' => $portalCode
        ];

        return view('Portal/index', $data);
    }

    /**
     * Handle license activation from portal
     */
    public function activate($portalCode = null)
    {
        if (empty($portalCode)) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('Portal not found');
        }

        // Find reseller by portal code
        $reseller = $this->userModel->where('portal_code', $portalCode)
                                  ->where('user_level', 3)
                                  ->first();

        if (!$reseller) {
            throw new \CodeIgniter\Exceptions\PageNotFoundException('Portal not found');
        }

        if ($this->request->getMethod() === 'POST') {
            $licenseKey = $this->request->getPost('license_key');
            $hwid = $this->request->getPost('hwid');

            if (empty($licenseKey) || empty($hwid)) {
                session()->setFlashdata('error', 'License key and HWID are required');
                return redirect()->back();
            }

            // Find the license
            $license = $this->licenseKeyModel->where('license_key', $licenseKey)
                                        ->where('reseller_id', $reseller['id'])
                                        ->first();

            if (!$license) {
                session()->setFlashdata('error', 'Invalid license key');
                return redirect()->back();
            }

            if ($license['status'] === 'used') {
                session()->setFlashdata('error', 'License key is already activated');
                return redirect()->back();
            }

            if ($license['status'] === 'expired') {
                session()->setFlashdata('error', 'License key has expired');
                return redirect()->back();
            }

            // Activate the license
            $updateData = [
                'status' => 'used',
                'hwid' => $hwid,
                'activated_at' => date('Y-m-d H:i:s'),
                'updated_at' => date('Y-m-d H:i:s')
            ];

            if ($this->licenseKeyModel->update($license['id'], $updateData)) {
                session()->setFlashdata('success', 'License activated successfully!');
                
                // Get app details for display
                $app = $this->appModel->find($license['app_id']);
                
                $data = [
                    'license' => $license,
                    'app' => $app,
                    'reseller' => $reseller
                ];
                
                return view('Portal/success', $data);
            } else {
                session()->setFlashdata('error', 'Failed to activate license');
                return redirect()->back();
            }
        }

        $data = [
            'reseller' => $reseller,
            'portal_code' => $portalCode
        ];

        return view('Portal/activate', $data);
    }
}
