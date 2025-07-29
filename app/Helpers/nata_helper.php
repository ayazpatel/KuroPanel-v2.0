<?php

/**
 * create_password
 *
 * @param  mixed $password
 * @param  mixed $enc
 * @return string
 */
function create_password($password, $enc = true)
{
    $optn = ['cost' => 8];
    $patt = "XquxmymXDtWRA66D";
    $hash = md5($patt . $password);
    $pass = password_hash($hash, PASSWORD_DEFAULT, $optn);
    return ($enc ? $pass : $hash);
}

function getName($user)
{
    if ($user->fullname) {
        return word_limiter($user->fullname, 1, '');
    } else {
        return $user->username;
    }
}

function getLevel($level = 0)
{
    switch ($level) {
        case '1':
            return 'Admin';
        case '2':
            return 'Developer';
        case '3':
            return 'Reseller';
        case '4':
            return 'User';
        default:
            return 'Unknown';
    }
}

/**
 * Get role permissions
 */
function getRolePermissions($level)
{
    $permissions = [
        1 => [ // Admin
            'manage_users', 'manage_developers', 'manage_resellers', 'manage_apps',
            'system_settings', 'view_all_transactions', 'generate_reports',
            'manage_system', 'view_logs', 'backup_system'
        ],
        2 => [ // Developer
            'create_apps', 'manage_own_apps', 'generate_invite_codes',
            'set_global_maintenance', 'view_own_analytics', 'manage_versions',
            'view_own_transactions'
        ],
        3 => [ // Reseller
            'generate_license_keys', 'manage_own_users', 'set_reseller_maintenance',
            'view_assigned_apps', 'manage_branding', 'view_own_transactions',
            'use_invite_codes'
        ],
        4 => [ // User
            'purchase_licenses', 'view_own_licenses', 'request_hwid_reset',
            'view_profile', 'update_profile'
        ]
    ];
    
    return $permissions[$level] ?? [];
}

/**
 * Check if user has permission
 */
function hasPermission($userLevel, $permission)
{
    $permissions = getRolePermissions($userLevel);
    return in_array($permission, $permissions);
}

/**
 * Get level color for UI
 */
function getLevelColor($level)
{
    switch ($level) {
        case '1': return 'danger';   // Admin - Red
        case '2': return 'primary';  // Developer - Blue
        case '3': return 'warning';  // Reseller - Yellow
        case '4': return 'success';  // User - Green
        default: return 'secondary';
    }
}

/**
 * Generate license key
 */
function generateLicenseKey($prefix = 'KP')
{
    $timestamp = time();
    $random = strtoupper(bin2hex(random_bytes(8)));
    $checksum = substr(md5($timestamp . $random), 0, 4);
    return $prefix . '-' . $timestamp . '-' . $random . '-' . strtoupper($checksum);
}

/**
 * Generate invite code
 */
function generateInviteCode($length = 12)
{
    $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    $code = '';
    for ($i = 0; $i < $length; $i++) {
        $code .= $characters[random_int(0, strlen($characters) - 1)];
    }
    return $code;
}

/**
 * Format currency
 */
function formatCurrency($amount, $currency = '$')
{
    return $currency . number_format($amount, 2);
}

/**
 * Validate HWID format
 */
function validateHWID($hwid)
{
    // Basic HWID validation - adjust as needed
    return preg_match('/^[A-F0-9]{32}$/i', $hwid);
}

/**
 * Generate API token
 */
function generateApiToken()
{
    return bin2hex(random_bytes(32));
}

function setMessage($msg, $color = 'secondary')
{
    return [$msg, $color];
}

function getDevice($devices)
{
    $total = 0;
    $listDevice = "";
    if ($devices) {
        $clean_comma = reduce_multiples($devices, ",", true);
        $ex = explode(',', $clean_comma);
        $listDevice = "";
        foreach ($ex as $ld) {
            $listDevice .= "$ld\n";
        }
        $total = count($ex);
    }
    return (object) ['total' => $total, 'devices' => trim($listDevice)];
}

function setDevice($devicesPost, $max)
{
    // dont touch this forever please -_-
    if ($devicesPost) {
        $clean_enter = reduce_multiples($devicesPost, "\n", true);
        $ez = [''];
        $ef = array_unique(array_filter(preg_replace("/[^A-Za-z0-9]/", "", explode("\n", $clean_enter))));
        $ex = array_filter(array_merge($ez, $ef));
        foreach ($ex as $k => $item) {
            if ($k <= $max) {
                $result[] = trim($item);
            }
        }
        return implode(",", array_unique($result));
    }
}

function getPrice($price, $duration, $device_max)
{
    $priceReal = $price[$duration];
    $result = ($priceReal * $device_max);
    return ($result <= 0) ? false : $result;
}
