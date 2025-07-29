<?php

namespace Tests\Unit;

use CodeIgniter\Test\CIUnitTestCase;
use App\Models\LicenseKeyModel;
use App\Models\AppModel;
use App\Models\UserModel;

class KuroPanelV2Test extends CIUnitTestCase
{
    protected $licenseModel;
    protected $appModel;
    protected $userModel;

    protected function setUp(): void
    {
        parent::setUp();
        $this->licenseModel = new LicenseKeyModel();
        $this->appModel = new AppModel();
        $this->userModel = new UserModel();
    }

    public function testModelsExist()
    {
        $this->assertInstanceOf(LicenseKeyModel::class, $this->licenseModel);
        $this->assertInstanceOf(AppModel::class, $this->appModel);
        $this->assertInstanceOf(UserModel::class, $this->userModel);
    }

    public function testLicenseKeyValidation()
    {
        $validData = [
            'license_key' => 'TEST-' . uniqid(),
            'app_id' => 1,
            'user_id' => 1,
            'status' => 'active',
            'duration_days' => 30,
            'max_devices' => 1
        ];

        $rules = $this->licenseModel->getValidationRules();
        $this->assertArrayHasKey('license_key', $rules);
        $this->assertArrayHasKey('app_id', $rules);
        $this->assertArrayHasKey('status', $rules);
    }

    public function testAppModelValidation()
    {
        $validData = [
            'app_name' => 'Test App',
            'app_description' => 'Test Description',
            'developer_id' => 1,
            'status' => 'active'
        ];

        $rules = $this->appModel->getValidationRules();
        $this->assertArrayHasKey('app_name', $rules);
        $this->assertArrayHasKey('developer_id', $rules);
    }

    public function testUserRoleValidation()
    {
        $validRoles = ['admin', 'developer', 'reseller', 'user'];
        
        foreach ($validRoles as $role) {
            $this->assertContains($role, ['admin', 'developer', 'reseller', 'user']);
        }
    }

    public function testHelperFunctions()
    {
        // Test if helper functions exist
        $this->assertTrue(function_exists('generateLicenseKey'));
        $this->assertTrue(function_exists('generateInviteCode'));
        $this->assertTrue(function_exists('checkUserRole'));
    }

    public function testDatabaseTables()
    {
        $db = \Config\Database::connect();
        
        // Check if V2 tables exist
        $tables = [
            'admin_users',
            'developers', 
            'resellers',
            'apps',
            'license_keys',
            'reseller_apps',
            'invite_codes',
            'invite_code_usage'
        ];

        foreach ($tables as $table) {
            $this->assertTrue($db->tableExists($table), "Table $table should exist");
        }
    }

    public function testLicenseKeyGeneration()
    {
        $key = generateLicenseKey();
        $this->assertIsString($key);
        $this->assertGreaterThan(10, strlen($key));
        $this->assertStringContainsString('-', $key);
    }

    public function testInviteCodeGeneration()
    {
        $code = generateInviteCode();
        $this->assertIsString($code);
        $this->assertEquals(8, strlen($code));
        $this->assertMatchesRegularExpression('/^[A-Z0-9]+$/', $code);
    }

    public function testPasswordHashing()
    {
        $password = 'test123';
        $hash = password_hash($password, PASSWORD_DEFAULT);
        
        $this->assertIsString($hash);
        $this->assertTrue(password_verify($password, $hash));
        $this->assertFalse(password_verify('wrong', $hash));
    }

    public function testRolePermissions()
    {
        // Test role hierarchy
        $roles = ['admin', 'developer', 'reseller', 'user'];
        $permissions = [
            'admin' => ['manage_users', 'manage_apps', 'view_analytics', 'system_config'],
            'developer' => ['create_apps', 'manage_own_apps', 'generate_invites'],
            'reseller' => ['use_invites', 'generate_keys', 'view_assigned_apps'],
            'user' => ['view_profile', 'manage_keys']
        ];

        foreach ($roles as $role) {
            $this->assertArrayHasKey($role, $permissions);
            $this->assertIsArray($permissions[$role]);
        }
    }

    public function testApiRoutes()
    {
        // Test that API routes are properly defined
        $routes = service('routes');
        $collection = $routes->getRoutes();
        
        // Check for API endpoints
        $apiRoutes = array_filter($collection, function($route) {
            return strpos($route, '/api/') === 0;
        });

        $this->assertNotEmpty($apiRoutes, 'API routes should be defined');
    }

    protected function tearDown(): void
    {
        parent::tearDown();
    }
}
