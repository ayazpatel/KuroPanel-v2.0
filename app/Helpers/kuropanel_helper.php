<?php

if (!function_exists('getRoleLabel')) {
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

if (!function_exists('getRoleBadge')) {
    function getRoleBadge($level)
    {
        $badges = [
            1 => '<span class="badge bg-danger">Admin</span>',
            2 => '<span class="badge bg-primary">Developer</span>',
            3 => '<span class="badge bg-success">Reseller</span>',
            4 => '<span class="badge bg-info">User</span>'
        ];
        
        return $badges[$level] ?? '<span class="badge bg-secondary">Unknown</span>';
    }
}

if (!function_exists('formatCurrency')) {
    function formatCurrency($amount)
    {
        return '$' . number_format($amount, 2);
    }
}

if (!function_exists('formatDate')) {
    function formatDate($date, $format = 'M d, Y')
    {
        if (!$date) return 'N/A';
        return date($format, strtotime($date));
    }
}

if (!function_exists('formatDateTime')) {
    function formatDateTime($datetime, $format = 'M d, Y H:i')
    {
        if (!$datetime) return 'N/A';
        return date($format, strtotime($datetime));
    }
}

if (!function_exists('getStatusBadge')) {
    function getStatusBadge($status)
    {
        $badges = [
            'active' => '<span class="badge bg-success">Active</span>',
            'inactive' => '<span class="badge bg-danger">Inactive</span>',
            'expired' => '<span class="badge bg-warning">Expired</span>',
            'suspended' => '<span class="badge bg-danger">Suspended</span>',
            'used' => '<span class="badge bg-info">Used</span>',
            'maintenance' => '<span class="badge bg-warning">Maintenance</span>',
            'deprecated' => '<span class="badge bg-secondary">Deprecated</span>'
        ];
        
        return $badges[$status] ?? '<span class="badge bg-secondary">' . ucfirst($status) . '</span>';
    }
}

if (!function_exists('generateLicenseKey')) {
    function generateLicenseKey($prefix = 'KP')
    {
        $parts = [
            $prefix,
            strtoupper(substr(md5(uniqid()), 0, 4)),
            strtoupper(substr(md5(uniqid()), 0, 4)),
            strtoupper(substr(md5(uniqid()), 0, 4)),
            strtoupper(substr(md5(uniqid()), 0, 4))
        ];
        
        return implode('-', $parts);
    }
}

if (!function_exists('generateInviteCode')) {
    function generateInviteCode($length = 8)
    {
        $characters = 'ABCDEFGHIJIKLMNOPQRSTUVWXYZ0123456789';
        $code = '';
        
        for ($i = 0; $i < $length; $i++) {
            $code .= $characters[rand(0, strlen($characters) - 1)];
        }
        
        return $code;
    }
}

if (!function_exists('timeAgo')) {
    function timeAgo($datetime)
    {
        if (!$datetime) return 'Never';
        
        $time = time() - strtotime($datetime);
        
        if ($time < 60) return 'Just now';
        if ($time < 3600) return floor($time/60) . ' minutes ago';
        if ($time < 86400) return floor($time/3600) . ' hours ago';
        if ($time < 2592000) return floor($time/86400) . ' days ago';
        if ($time < 31536000) return floor($time/2592000) . ' months ago';
        
        return floor($time/31536000) . ' years ago';
    }
}

if (!function_exists('sanitizeFilename')) {
    function sanitizeFilename($filename)
    {
        return preg_replace('/[^a-zA-Z0-9._-]/', '_', $filename);
    }
}

if (!function_exists('bytesToHuman')) {
    function bytesToHuman($bytes)
    {
        if ($bytes == 0) return '0 B';
        
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $factor = floor(log($bytes, 1024));
        
        return sprintf("%.2f %s", $bytes / pow(1024, $factor), $units[$factor]);
    }
}
