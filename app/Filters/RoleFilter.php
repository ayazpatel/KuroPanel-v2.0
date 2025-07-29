<?php

namespace App\Filters;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Filters\FilterInterface;

class RoleFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $session = session();
        
        // Check if user is logged in
        if (!$session->has('userid')) {
            return redirect()->to('/login')->with('error', 'Please login to continue');
        }

        // Get user from session or database
        $userModel = new \App\Models\UserModel();
        $user = $userModel->find($session->get('userid'));
        
        if (!$user) {
            $session->destroy();
            return redirect()->to('/login')->with('error', 'User not found');
        }

        // Check if user is active
        if (!$user->status) {
            return redirect()->to('/login')->with('error', 'Your account has been deactivated');
        }

        // Check role permissions
        if ($arguments) {
            $allowedRoles = explode(',', $arguments[0]);
            $allowedRoles = array_map('trim', $allowedRoles);
            
            if (!in_array($user->level, $allowedRoles)) {
                // Redirect based on user's actual role
                switch ($user->level) {
                    case 1: // Admin
                        return redirect()->to('/admin')->with('error', 'Access denied');
                    case 2: // Developer
                        return redirect()->to('/developer')->with('error', 'Access denied');
                    case 3: // Reseller
                        return redirect()->to('/reseller')->with('error', 'Access denied');
                    case 4: // User
                        return redirect()->to('/user')->with('error', 'Access denied');
                    default:
                        return redirect()->to('/login')->with('error', 'Invalid user role');
                }
            }
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // Do nothing
    }
}
