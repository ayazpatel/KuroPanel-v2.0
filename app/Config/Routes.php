<?php

namespace Config;

use CodeIgniter\Config\Services;

// Create a new instance of our RouteCollection class.
$routes = Services::routes();

// Load the system's routing file first, so that the app and ENVIRONMENT
// can override as needed.
if (file_exists(SYSTEMPATH . 'Config/Routes.php')) {
	require SYSTEMPATH . 'Config/Routes.php';
}

/**
 * --------------------------------------------------------------------
 * Router Setup
 * --------------------------------------------------------------------
 */
$routes->setDefaultNamespace('App\Controllers');
$routes->setDefaultController('Home');
$routes->setDefaultMethod('index');
$routes->setTranslateURIDashes(false);
$routes->set404Override();
$routes->setAutoRoute(false);

/*
 * --------------------------------------------------------------------
 * Route Definitions - KuroPanel v2.0
 * --------------------------------------------------------------------
 */

// Public routes
$routes->get('/', 'Home::index');
$routes->match(['get', 'post'], 'login', 'Auth::login');
$routes->match(['get', 'post'], 'register', 'Auth::register');
$routes->get('logout', 'Auth::logout');

// Dashboard redirect based on user role
$routes->get('dashboard', 'Home::dashboard');

// Legacy support routes (backward compatibility)
$routes->get('dbg', 'Auth::index');
$routes->match(['get', 'post'], 'settings', 'User::settings');

// API Routes for app integration
$routes->group('api/v1', function ($routes) {
    $routes->post('validate-license', 'Api::validateLicense');
    $routes->post('activate-license', 'Api::activateLicense');
    $routes->get('app-info/(:num)', 'Api::getAppInfo/$1');
    $routes->get('check-maintenance/(:num)', 'Api::checkMaintenance/$1');
});

// Admin Routes (Level 1) - Full system access
$routes->group('admin', ['filter' => 'role'], function ($routes) {
	$routes->get('/', 'Admin::index');
	$routes->match(['get', 'post'], 'users/(:num)', 'Admin::users/$1');
	$routes->match(['get', 'post'], 'users', 'Admin::users');
	$routes->get('apps', 'Admin::apps');
	$routes->get('app/(:num)', 'Admin::appDetails/$1');
	$routes->match(['get', 'post'], 'settings', 'Admin::settings');
	$routes->get('licenses', 'Admin::licenses');
	$routes->get('reports', 'Admin::reports');
	$routes->get('logs', 'Admin::logs');
	
	// Legacy admin routes (backward compatibility)
	$routes->match(['get', 'post'], 'create-referral', 'User::ref_index');
	$routes->match(['get', 'post'], 'manage-users', 'User::manage_users');
	$routes->match(['get', 'post'], 'user/(:num)', 'User::user_edit/$1');
	
	/* --------------------------- Admin API Grouping -------------------------- */
	$routes->group('api', function ($routes) {
		$routes->match(['get', 'post'], 'users', 'User::api_get_users');
	});
});

// Developer Routes (Level 2) - App creators
$routes->group('developer', ['filter' => 'role'], function ($routes) {
	$routes->get('/', 'Developer::index');
	$routes->match(['get', 'post'], 'apps', 'Developer::apps');
	$routes->get('app/(:num)', 'Developer::appDetails/$1');
	$routes->match(['get', 'post'], 'generate-invite', 'Developer::generateInvite');
	$routes->post('set-maintenance/(:num)', 'Developer::setMaintenance/$1');
	$routes->get('licenses/(:num)', 'Developer::licenses/$1');
	$routes->get('licenses', 'Developer::licenses');
	$routes->get('invite-codes', 'Developer::inviteCodes');
});

// Reseller Routes (Level 3) - License distributors
$routes->group('reseller', ['filter' => 'role'], function ($routes) {
	$routes->get('/', 'Reseller::index');
	$routes->match(['get', 'post'], 'use-invite', 'Reseller::useInvite');
	$routes->match(['get', 'post'], 'generate-keys', 'Reseller::generateKeys');
	$routes->get('manage-keys/(:num)', 'Reseller::manageKeys/$1');
	$routes->get('manage-keys', 'Reseller::manageKeys');
	$routes->post('set-maintenance/(:num)', 'Reseller::setMaintenance/$1');
	$routes->post('update-branding/(:num)', 'Reseller::updateBranding/$1');
	$routes->get('key-portal', 'Reseller::keyPortal');
});

// User Routes (Level 4) - End users
$routes->group('user', ['filter' => 'role'], function ($routes) {
	$routes->get('/', 'User::index');
	$routes->match(['get', 'post'], 'purchase-license', 'User::purchaseLicense');
	$routes->match(['get', 'post'], 'activate-license', 'User::activateLicense');
	$routes->get('my-licenses', 'User::myLicenses');
	$routes->match(['get', 'post'], 'hwid-reset', 'User::requestHwidReset');
	$routes->match(['get', 'post'], 'profile', 'User::profile');
	$routes->get('add-balance', 'User::addBalance');
});

// Legacy Keys system (backward compatibility)
$routes->group('keys', function ($routes) {
	$routes->match(['get', 'post'], '/', 'Keys::index');
	$routes->match(['get', 'post'], 'generate', 'Keys::generate');
	$routes->get('(:num)', 'Keys::edit_key/$1');
	$routes->get('reset', 'Keys::api_key_reset');
	$routes->post('edit', 'Keys::edit_key');
	$routes->match(['get', 'post'], 'api', 'Keys::api_get_keys');
});

// Public Key Portal (for resellers to share with users)
$routes->group('portal', function ($routes) {
	$routes->get('(:any)', 'Portal::index/$1'); // Reseller's custom portal
	$routes->match(['get', 'post'], 'activate/(:any)', 'Portal::activate/$1');
});

// Connect API (legacy support)
$routes->match(['get', 'post'], 'connect', 'Connect::index');

// Webhook endpoints for payments, notifications, etc.
$routes->group('webhook', function ($routes) {
	$routes->post('payment', 'Webhook::payment');
	$routes->post('telegram', 'Webhook::telegram');
});
/*
 * --------------------------------------------------------------------
 * Additional Routing
 * --------------------------------------------------------------------
 *
 * There will often be times that you need additional routing and you
 * need it to be able to override any defaults in this file. Environment
 * based routes is one such time. require() additional route files here
 * to make that happen.
 *
 * You will have access to the $routes object within that file without
 * needing to reload it.
 */
if (file_exists(APPPATH . 'Config/' . ENVIRONMENT . '/Routes.php')) {
	require APPPATH . 'Config/' . ENVIRONMENT . '/Routes.php';
}
