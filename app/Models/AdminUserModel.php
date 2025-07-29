<?php

namespace App\Models;

use CodeIgniter\Model;

class AdminUserModel extends Model
{
    protected $table = 'admin_users';
    protected $primaryKey = 'id';
    protected $useAutoIncrement = true;
    protected $returnType = 'object';
    protected $useSoftDeletes = false;
    protected $protectFields = true;
    protected $allowedFields = [
        'username',
        'email',
        'password',
        'role',
        'status',
        'last_login',
        'created_at'
    ];

    // Dates
    protected $useTimestamps = true;
    protected $dateFormat = 'datetime';
    protected $createdField = 'created_at';
    protected $updatedField = 'updated_at';
    protected $deletedField = 'deleted_at';

    // Validation
    protected $validationRules = [
        'username' => 'required|alpha_numeric|min_length[3]|max_length[50]|is_unique[admin_users.username,id,{id}]',
        'email' => 'required|valid_email|is_unique[admin_users.email,id,{id}]',
        'password' => 'required|min_length[8]',
        'role' => 'required|in_list[admin,super_admin]',
        'status' => 'required|in_list[active,inactive,suspended]'
    ];

    protected $validationMessages = [
        'username' => [
            'required' => 'Username is required',
            'alpha_numeric' => 'Username can only contain letters and numbers',
            'min_length' => 'Username must be at least 3 characters long',
            'max_length' => 'Username cannot exceed 50 characters',
            'is_unique' => 'Username already exists'
        ],
        'email' => [
            'required' => 'Email is required',
            'valid_email' => 'Please provide a valid email address',
            'is_unique' => 'Email already exists'
        ],
        'password' => [
            'required' => 'Password is required',
            'min_length' => 'Password must be at least 8 characters long'
        ],
        'role' => [
            'required' => 'Role is required',
            'in_list' => 'Role must be either admin or super_admin'
        ],
        'status' => [
            'required' => 'Status is required',
            'in_list' => 'Status must be active, inactive, or suspended'
        ]
    ];

    protected $skipValidation = false;
    protected $cleanValidationRules = true;

    // Callbacks
    protected $allowCallbacks = true;
    protected $beforeInsert = ['hashPassword'];
    protected $beforeUpdate = ['hashPassword'];

    /**
     * Hash password before saving
     */
    protected function hashPassword(array $data)
    {
        if (isset($data['data']['password'])) {
            $data['data']['password'] = password_hash($data['data']['password'], PASSWORD_DEFAULT);
        }
        return $data;
    }

    /**
     * Verify login credentials
     */
    public function verifyLogin(string $username, string $password): ?object
    {
        $user = $this->where('username', $username)
                     ->where('status', 'active')
                     ->first();

        if ($user && password_verify($password, $user->password)) {
            // Update last login
            $this->update($user->id, ['last_login' => date('Y-m-d H:i:s')]);
            return $user;
        }

        return null;
    }

    /**
     * Get active admins
     */
    public function getActiveAdmins(): array
    {
        return $this->where('status', 'active')->findAll();
    }

    /**
     * Get user by role
     */
    public function getByRole(string $role): array
    {
        return $this->where('role', $role)
                    ->where('status', 'active')
                    ->findAll();
    }

    /**
     * Create super admin user
     */
    public function createSuperAdmin(array $data): bool
    {
        $data['role'] = 'super_admin';
        $data['status'] = 'active';
        
        return $this->insert($data) ? true : false;
    }

    /**
     * Check if user exists
     */
    public function userExists(string $username, string $email): bool
    {
        return $this->where('username', $username)
                    ->orWhere('email', $email)
                    ->countAllResults() > 0;
    }

    /**
     * Get user stats
     */
    public function getStats(): array
    {
        return [
            'total' => $this->countAll(),
            'active' => $this->where('status', 'active')->countAllResults(),
            'inactive' => $this->where('status', 'inactive')->countAllResults(),
            'suspended' => $this->where('status', 'suspended')->countAllResults(),
            'admins' => $this->where('role', 'admin')->where('status', 'active')->countAllResults(),
            'super_admins' => $this->where('role', 'super_admin')->where('status', 'active')->countAllResults()
        ];
    }
}
