<?php

if (!function_exists('getRoleLabel')) {
    /**
     * Get role label by level
     */
    function getRoleLabel($level)
    {
        $roles = [
            1 => 'Admin',
            2 => 'Developer', 
            3 => 'Reseller',
            4 => 'User'
        ];
        
        return $roles[$level] ?? 'Unknown';
    }
}

if (!function_exists('getLevel')) {
    /**
     * Get level name (alias for getRoleLabel)
     */
    function getLevel($level)
    {
        return getRoleLabel($level);
    }
}

if (!function_exists('create_password')) {
    /**
     * Create hashed password
     */
    function create_password($password)
    {
        return password_hash($password, PASSWORD_DEFAULT);
    }
}

if (!function_exists('verify_password')) {
    /**
     * Verify password against hash
     */
    function verify_password($password, $hash)
    {
        return password_verify($password, $hash);
    }
}

if (!function_exists('formatCurrency')) {
    /**
     * Format currency
     */
    function formatCurrency($amount)
    {
        return '$' . number_format($amount, 2);
    }
}

if (!function_exists('getStatusBadge')) {
    /**
     * Get status badge HTML
     */
    function getStatusBadge($status)
    {
        if ($status) {
            return '<span class="badge bg-success">Active</span>';
        } else {
            return '<span class="badge bg-danger">Inactive</span>';
        }
    }
}

if (!function_exists('timeAgo')) {
    /**
     * Get time ago format
     */
    function timeAgo($datetime)
    {
        $time = new \CodeIgniter\I18n\Time($datetime);
        return $time->humanize();
    }
}
