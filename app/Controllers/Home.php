<?php

namespace App\Controllers;

class Home extends BaseController
{
	public function index()
	{
		return view('welcome_message');
	}

	public function dashboard()
	{
		// Check if user is logged in
		if (!session()->get('isLoggedIn')) {
			return redirect()->to('/login');
		}

		$userLevel = session()->get('user_level');
		$userId = session()->get('user_id');

		// Redirect based on user role/level
		switch ($userLevel) {
			case 1: // Admin
				return redirect()->to('/admin');
			case 2: // Developer
				return redirect()->to('/developer');
			case 3: // Reseller
				return redirect()->to('/reseller');
			case 4: // User
				return redirect()->to('/user');
			default:
				// If level is not recognized, show a basic dashboard
				$data = [
					'title' => 'Dashboard',
					'user_id' => $userId,
					'user_level' => $userLevel
				];
				return view('dashboard', $data);
		}
	}
}
