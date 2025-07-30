<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $this->renderSection('title') ?> - KuroPanel 2.0</title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    
    <!-- Custom CSS -->
    <style>
        :root {
            --primary-color: #6f42c1;
            --secondary-color: #6c757d;
            --success-color: #198754;
            --danger-color: #dc3545;
            --warning-color: #ffc107;
            --info-color: #0dcaf0;
            --dark-color: #212529;
            --light-color: #f8f9fa;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
        }
        
        .navbar-brand {
            font-weight: bold;
            font-size: 1.5rem;
        }
        
        .sidebar {
            min-height: 100vh;
            background: linear-gradient(135deg, var(--primary-color), #8b5fbf);
            color: white;
            padding: 0;
        }
        
        .sidebar .nav-link {
            color: rgba(255, 255, 255, 0.8);
            padding: 12px 20px;
            border-radius: 0;
            transition: all 0.3s ease;
        }
        
        .sidebar .nav-link:hover,
        .sidebar .nav-link.active {
            color: white;
            background-color: rgba(255, 255, 255, 0.1);
            transform: translateX(3px);
        }
        
        .sidebar .nav-link i {
            width: 20px;
            margin-right: 10px;
        }
        
        .main-content {
            min-height: 100vh;
            padding: 0;
        }
        
        .content-wrapper {
            padding: 20px;
        }
        
        .page-header {
            background: white;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .card {
            border: none;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        
        .card:hover {
            transform: translateY(-2px);
        }
        
        .stat-card {
            background: linear-gradient(135deg, var(--primary-color), #8b5fbf);
            color: white;
        }
        
        .stat-card-success {
            background: linear-gradient(135deg, var(--success-color), #20c997);
        }
        
        .stat-card-info {
            background: linear-gradient(135deg, var(--info-color), #0ea5e9);
        }
        
        .stat-card-warning {
            background: linear-gradient(135deg, var(--warning-color), #f59e0b);
        }
        
        .btn-primary {
            background: linear-gradient(135deg, var(--primary-color), #8b5fbf);
            border: none;
        }
        
        .btn-primary:hover {
            background: linear-gradient(135deg, #5a2d91, var(--primary-color));
        }
        
        .table {
            background: white;
            border-radius: 10px;
            overflow: hidden;
        }
        
        .table thead th {
            background-color: var(--light-color);
            border-bottom: 2px solid var(--primary-color);
            font-weight: 600;
        }
        
        .badge {
            font-size: 0.8rem;
            padding: 6px 12px;
        }
        
        .user-profile {
            display: flex;
            align-items: center;
            padding: 15px 20px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            margin-bottom: 10px;
        }
        
        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 10px;
        }
        
        .welcome-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 15px;
        }
        
        .quick-action-btn {
            border-radius: 10px;
            padding: 15px;
            text-align: center;
            transition: all 0.3s ease;
            text-decoration: none;
            display: block;
            color: white;
        }
        
        .quick-action-btn:hover {
            transform: translateY(-3px);
            color: white;
        }
        
        .loading {
            display: none;
        }
        
        .alert {
            border-radius: 10px;
            border: none;
        }
    </style>
    
    <?= $this->renderSection('css') ?>
</head>
<body>
    <div class="container-fluid">
        <div class="row">
            <!-- Sidebar -->
            <div class="col-md-3 col-lg-2 sidebar">
                <!-- User Profile -->
                <div class="user-profile">
                    <div class="user-avatar">
                        <i class="fas fa-user"></i>
                    </div>
                    <div>
                        <div class="fw-bold"><?= esc(session()->get('username') ?? 'User') ?></div>
                        <small class="text-white-50"><?= ucfirst(getRoleLabel(session()->get('user_level') ?? 4)) ?></small>
                    </div>
                </div>
                
                <!-- Navigation -->
                <nav class="nav flex-column">
                    <?php $userLevel = session()->get('user_level') ?? 4; ?>
                    
                    <!-- Dashboard -->
                    <a class="nav-link <?= (uri_string() == 'dashboard' || uri_string() == '') ? 'active' : '' ?>" href="/dashboard">
                        <i class="fas fa-tachometer-alt"></i> Dashboard
                    </a>
                    
                    <?php if ($userLevel == 1): // Admin ?>
                        <a class="nav-link <?= (strpos(uri_string(), 'admin') === 0) ? 'active' : '' ?>" href="/admin">
                            <i class="fas fa-crown"></i> Admin Panel
                        </a>
                        <a class="nav-link" href="/admin/users">
                            <i class="fas fa-users"></i> Manage Users
                        </a>
                        <a class="nav-link" href="/admin/apps">
                            <i class="fas fa-mobile-alt"></i> All Apps
                        </a>
                        <a class="nav-link" href="/admin/licenses">
                            <i class="fas fa-key"></i> All Licenses
                        </a>
                        <a class="nav-link" href="/admin/reports">
                            <i class="fas fa-chart-bar"></i> Reports
                        </a>
                    <?php elseif ($userLevel == 2): // Developer ?>
                        <a class="nav-link <?= (strpos(uri_string(), 'developer') === 0) ? 'active' : '' ?>" href="/developer">
                            <i class="fas fa-code"></i> Developer Panel
                        </a>
                        <a class="nav-link" href="/developer/apps">
                            <i class="fas fa-mobile-alt"></i> My Apps
                        </a>
                        <a class="nav-link" href="/developer/licenses">
                            <i class="fas fa-key"></i> License Keys
                        </a>
                        <a class="nav-link" href="/developer/generate-invite">
                            <i class="fas fa-envelope"></i> Generate Invites
                        </a>
                        <a class="nav-link" href="/developer/invite-codes">
                            <i class="fas fa-ticket-alt"></i> Invite Codes
                        </a>
                    <?php elseif ($userLevel == 3): // Reseller ?>
                        <a class="nav-link <?= (strpos(uri_string(), 'reseller') === 0) ? 'active' : '' ?>" href="/reseller">
                            <i class="fas fa-store"></i> Reseller Panel
                        </a>
                        <a class="nav-link" href="/reseller/use-invite">
                            <i class="fas fa-ticket-alt"></i> Use Invite Code
                        </a>
                        <a class="nav-link" href="/reseller/generate-keys">
                            <i class="fas fa-key"></i> Generate Keys
                        </a>
                        <a class="nav-link" href="/reseller/manage-keys">
                            <i class="fas fa-cogs"></i> Manage Keys
                        </a>
                        <a class="nav-link" href="/reseller/key-portal">
                            <i class="fas fa-external-link-alt"></i> Key Portal
                        </a>
                    <?php else: // User ?>
                        <a class="nav-link <?= (strpos(uri_string(), 'user') === 0) ? 'active' : '' ?>" href="/user">
                            <i class="fas fa-user"></i> User Panel
                        </a>
                        <a class="nav-link" href="/user/purchase-license">
                            <i class="fas fa-shopping-cart"></i> Purchase License
                        </a>
                        <a class="nav-link" href="/user/my-licenses">
                            <i class="fas fa-key"></i> My Licenses
                        </a>
                        <a class="nav-link" href="/user/add-balance">
                            <i class="fas fa-wallet"></i> Add Balance
                        </a>
                    <?php endif; ?>
                    
                    <!-- Common Links -->
                    <a class="nav-link" href="/user/profile">
                        <i class="fas fa-user-cog"></i> Profile
                    </a>
                    <a class="nav-link" href="/logout">
                        <i class="fas fa-sign-out-alt"></i> Logout
                    </a>
                </nav>
            </div>
            
            <!-- Main Content -->
            <div class="col-md-9 col-lg-10 main-content">
                <div class="content-wrapper">
                    <!-- Flash Messages -->
                    <?php if (session()->getFlashdata('success')): ?>
                        <div class="alert alert-success alert-dismissible fade show" role="alert">
                            <i class="fas fa-check-circle me-2"></i>
                            <?= session()->getFlashdata('success') ?>
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    <?php endif; ?>
                    
                    <?php if (session()->getFlashdata('error')): ?>
                        <div class="alert alert-danger alert-dismissible fade show" role="alert">
                            <i class="fas fa-exclamation-circle me-2"></i>
                            <?= session()->getFlashdata('error') ?>
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    <?php endif; ?>
                    
                    <?php if (session()->getFlashdata('warning')): ?>
                        <div class="alert alert-warning alert-dismissible fade show" role="alert">
                            <i class="fas fa-exclamation-triangle me-2"></i>
                            <?= session()->getFlashdata('warning') ?>
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    <?php endif; ?>
                    
                    <?php if (session()->getFlashdata('info')): ?>
                        <div class="alert alert-info alert-dismissible fade show" role="alert">
                            <i class="fas fa-info-circle me-2"></i>
                            <?= session()->getFlashdata('info') ?>
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    <?php endif; ?>
                    
                    <!-- Page Content -->
                    <?= $this->renderSection('content') ?>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    <!-- Custom JS -->
    <script>
        // Auto-hide alerts after 5 seconds
        setTimeout(function() {
            $('.alert').fadeOut('slow');
        }, 5000);
        
        // Loading states for buttons
        $(document).on('click', '.btn-loading', function() {
            $(this).html('<i class="fas fa-spinner fa-spin"></i> Loading...').prop('disabled', true);
        });
        
        // Confirmation dialogs
        $(document).on('click', '.btn-confirm', function(e) {
            if (!confirm('Are you sure you want to perform this action?')) {
                e.preventDefault();
            }
        });
    </script>
    
    <?= $this->renderSection('js') ?>
</body>
</html>
