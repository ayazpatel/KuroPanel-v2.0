<?php
/**
 * KuroPanel V2 Setup Script
 * Automated database migration and initial configuration
 */

echo "=== KuroPanel V2 Setup Script ===\n";
echo "Starting database migration and initial setup...\n\n";

// Database configuration
$host = 'localhost';
$username = 'root';
$password = '';
$database = 'kuro_panel';

// Create connection
try {
    $pdo = new PDO("mysql:host=$host", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✓ Database connection established\n";
} catch (PDOException $e) {
    die("✗ Database connection failed: " . $e->getMessage() . "\n");
}

// Create database if not exists
try {
    $stmt = $pdo->prepare("CREATE DATABASE IF NOT EXISTS `$database` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $stmt->execute();
    echo "✓ Database '$database' created/verified\n";
} catch (PDOException $e) {
    die("✗ Failed to create database: " . $e->getMessage() . "\n");
}

// Use the database
$pdo->exec("USE `$database`");

// Read and execute SQL file
$sqlFile = __DIR__ . '/kuro_upgraded.sql';
if (!file_exists($sqlFile)) {
    die("✗ SQL file not found: $sqlFile\n");
}

$sql = file_get_contents($sqlFile);
if ($sql === false) {
    die("✗ Failed to read SQL file\n");
}

// Split SQL into individual statements
$statements = array_filter(
    array_map('trim', explode(';', $sql)),
    function($stmt) {
        return !empty($stmt) && !preg_match('/^(--|\/\*|\*\/|\*)/', $stmt);
    }
);

echo "✓ Found " . count($statements) . " SQL statements\n";

// Execute each statement
$successCount = 0;
$errorCount = 0;

foreach ($statements as $statement) {
    try {
        $pdo->exec($statement);
        $successCount++;
    } catch (PDOException $e) {
        echo "✗ SQL Error: " . $e->getMessage() . "\n";
        echo "   Statement: " . substr($statement, 0, 100) . "...\n";
        $errorCount++;
    }
}

echo "✓ Executed $successCount statements successfully\n";
if ($errorCount > 0) {
    echo "✗ $errorCount statements failed\n";
}

// Create default super admin user
try {
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM admin_users WHERE role = 'super_admin'");
    $stmt->execute();
    $count = $stmt->fetchColumn();
    
    if ($count == 0) {
        $defaultPassword = password_hash('admin123', PASSWORD_DEFAULT);
        $stmt = $pdo->prepare("
            INSERT INTO admin_users (username, email, password, role, status, created_at) 
            VALUES ('admin', 'admin@kuroneko.com', ?, 'super_admin', 'active', NOW())
        ");
        $stmt->execute([$defaultPassword]);
        echo "✓ Default super admin created (username: admin, password: admin123)\n";
        echo "  ⚠️  IMPORTANT: Change the default password after first login!\n";
    } else {
        echo "✓ Super admin user already exists\n";
    }
} catch (PDOException $e) {
    echo "✗ Failed to create super admin: " . $e->getMessage() . "\n";
}

// Verify database structure
echo "\n=== Database Verification ===\n";
$tables = [
    'admin_users',
    'users',
    'developers',
    'resellers',
    'apps',
    'license_keys',
    'reseller_apps',
    'invite_codes',
    'invite_code_usage',
    'history',
    'codes'
];

foreach ($tables as $table) {
    try {
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM `$table`");
        $stmt->execute();
        $count = $stmt->fetchColumn();
        echo "✓ Table '$table': $count records\n";
    } catch (PDOException $e) {
        echo "✗ Table '$table': " . $e->getMessage() . "\n";
    }
}

// Check CodeIgniter configuration
echo "\n=== CodeIgniter Configuration Check ===\n";

$configFile = __DIR__ . '/app/Config/Database.php';
if (file_exists($configFile)) {
    echo "✓ Database config file exists\n";
    
    // Read current config
    $configContent = file_get_contents($configFile);
    if (strpos($configContent, $database) !== false) {
        echo "✓ Database name configured correctly\n";
    } else {
        echo "⚠️  Please update database name in app/Config/Database.php\n";
    }
} else {
    echo "✗ Database config file not found\n";
}

// Check .env file
$envFile = __DIR__ . '/.env';
if (file_exists($envFile)) {
    echo "✓ Environment file exists\n";
} else {
    echo "⚠️  No .env file found - consider creating one for environment-specific settings\n";
}

// Verify permissions
echo "\n=== Permissions Check ===\n";
$writableDirs = ['writable', 'writable/cache', 'writable/logs', 'writable/session', 'writable/uploads'];

foreach ($writableDirs as $dir) {
    $fullPath = __DIR__ . '/' . $dir;
    if (is_dir($fullPath) && is_writable($fullPath)) {
        echo "✓ Directory '$dir' is writable\n";
    } else {
        echo "✗ Directory '$dir' is not writable or doesn't exist\n";
    }
}

echo "\n=== Setup Complete ===\n";
echo "Your KuroPanel V2 installation is ready!\n\n";

echo "Next Steps:\n";
echo "1. Access your panel at: http://your-domain.com/\n";
echo "2. Login with admin/admin123 and change the password\n";
echo "3. Configure your first application\n";
echo "4. Test the API endpoints\n";
echo "5. Review the documentation in KUROPANEL_V2_DOCUMENTATION.md\n\n";

echo "For API testing, use the Connect endpoint:\n";
echo "- Legacy API: /connect/[method]\n";
echo "- New API: /api/[method]\n\n";

echo "Happy coding! 🚀\n";
?>
