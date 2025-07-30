<?= $this->extend('Layout/Main') ?>

<?= $this->section('title') ?>
Admin Dashboard
<?= $this->endSection() ?>

<?= $this->section('content') ?>
<!-- Page Header -->
<div class="page-header">
    <div class="row align-items-center">
        <div class="col">
            <h1 class="h3 mb-0">
                <i class="fas fa-crown text-warning me-2"></i>
                Admin Dashboard
            </h1>
            <p class="text-muted mb-0">Complete system overview and management</p>
        </div>
        <div class="col-auto">
            <div class="btn-group">
                <a href="/admin/users" class="btn btn-primary">
                    <i class="fas fa-users me-1"></i> Manage Users
                </a>
                <a href="/admin/apps" class="btn btn-outline-secondary">
                    <i class="fas fa-mobile-alt me-1"></i> All Apps
                </a>
            </div>
        </div>
    </div>
</div>

<!-- Welcome Card -->
<div class="row mb-4">
    <div class="col-12">
        <div class="card welcome-card">
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col">
                        <h4 class="text-white mb-1">Welcome back, <?= esc($user->fullname ?? $user->username) ?>!</h4>
                        <p class="text-white-50 mb-0">You have full administrative access to KuroPanel 2.0</p>
                    </div>
                    <div class="col-auto">
                        <i class="fas fa-crown fa-3x text-white-50"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Statistics Cards -->
<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card stat-card">
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col">
                        <h3 class="text-white mb-1"><?= $stats['total_users'] ?></h3>
                        <p class="text-white-50 mb-0">Total Users</p>
                    </div>
                    <div class="col-auto">
                        <i class="fas fa-users fa-2x text-white-50"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card stat-card-success">
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col">
                        <h3 class="text-white mb-1"><?= $stats['total_developers'] ?></h3>
                        <p class="text-white-50 mb-0">Developers</p>
                    </div>
                    <div class="col-auto">
                        <i class="fas fa-code fa-2x text-white-50"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card stat-card-info">
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col">
                        <h3 class="text-white mb-1"><?= $stats['total_resellers'] ?></h3>
                        <p class="text-white-50 mb-0">Resellers</p>
                    </div>
                    <div class="col-auto">
                        <i class="fas fa-store fa-2x text-white-50"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card stat-card-warning">
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col">
                        <h3 class="text-white mb-1"><?= $stats['total_apps'] ?></h3>
                        <p class="text-white-50 mb-0">Applications</p>
                    </div>
                    <div class="col-auto">
                        <i class="fas fa-mobile-alt fa-2x text-white-50"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

    <!-- Recent Users -->
    <div class="row">
        <div class="col-xl-6">
            <div class="card">
                <div class="card-body">
                    <div class="dropdown float-end">
                        <a href="#" class="dropdown-toggle arrow-none card-drop" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="mdi mdi-dots-vertical"></i>
                        </a>
                        <div class="dropdown-menu dropdown-menu-end">
                            <a href="javascript:void(0);" class="dropdown-item">View All</a>
                        </div>
                    </div>
                    <h4 class="header-title mb-3">Recent Users</h4>
                    <div class="table-responsive">
                        <table class="table table-borderless table-hover table-nowrap table-centered m-0">
                            <thead class="table-light">
                                <tr>
                                    <th>User</th>
                                    <th>Level</th>
                                    <th>Status</th>
                                    <th>Joined</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php if (!empty($recent_users)): ?>
                                    <?php foreach ($recent_users as $user): ?>
                                        <?php 
                                        // Handle both object and array format
                                        $username = is_object($user) ? $user->username : $user['username'];
                                        $email = is_object($user) ? $user->email : $user['email'];
                                        $level = is_object($user) ? $user->level : $user['level'];
                                        $status = is_object($user) ? $user->status : $user['status'];
                                        $created_at = is_object($user) ? $user->created_at : $user['created_at'];
                                        ?>
                                        <tr>
                                            <td>
                                                <h5 class="m-0 fw-normal"><?= esc($username) ?></h5>
                                                <p class="mb-0 text-muted"><small><?= esc($email) ?></small></p>
                                            </td>
                                            <td>
                                                <?php
                                                $levels = [1 => 'Admin', 2 => 'Developer', 3 => 'Reseller', 4 => 'User'];
                                                echo $levels[$level] ?? 'Unknown';
                                                ?>
                                            </td>
                                            <td>
                                                <?php if ($status): ?>
                                                    <span class="badge bg-success">Active</span>
                                                <?php else: ?>
                                                    <span class="badge bg-danger">Inactive</span>
                                                <?php endif; ?>
                                            </td>
                                            <td><?= date('M d, Y', strtotime($created_at)) ?></td>
                                        </tr>
                                    <?php endforeach; ?>
                                <?php else: ?>
                                    <tr>
                                        <td colspan="4" class="text-center">No users found</td>
                                    </tr>
                                <?php endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <!-- Recent Applications -->
        <div class="col-xl-6">
            <div class="card">
                <div class="card-body">
                    <div class="dropdown float-end">
                        <a href="#" class="dropdown-toggle arrow-none card-drop" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="mdi mdi-dots-vertical"></i>
                        </a>
                        <div class="dropdown-menu dropdown-menu-end">
                            <a href="javascript:void(0);" class="dropdown-item">View All</a>
                        </div>
                    </div>
                    <h4 class="header-title mb-3">Recent Applications</h4>
                    <div class="table-responsive">
                        <table class="table table-borderless table-hover table-nowrap table-centered m-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Application</th>
                                    <th>Developer</th>
                                    <th>Status</th>
                                    <th>Created</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php if (!empty($recent_apps)): ?>
                                    <?php foreach ($recent_apps as $app): ?>
                                        <?php 
                                        // Handle both object and array format
                                        $app_name = is_object($app) ? $app->app_name : $app['app_name'];
                                        $package_name = isset($app->package_name) ? (is_object($app) ? $app->package_name : $app['package_name']) : 'N/A';
                                        $developer_username = is_object($app) ? $app->developer_username : $app['developer_username'];
                                        $status = is_object($app) ? $app->status : $app['status'];
                                        $created_at = is_object($app) ? $app->created_at : $app['created_at'];
                                        ?>
                                        <tr>
                                            <td>
                                                <h5 class="m-0 fw-normal"><?= esc($app_name) ?></h5>
                                                <p class="mb-0 text-muted"><small><?= esc($package_name) ?></small></p>
                                            </td>
                                            <td><?= esc($developer_username) ?></td>
                                            <td>
                                                <?php if ($status): ?>
                                                    <span class="badge bg-success">Active</span>
                                                <?php else: ?>
                                                    <span class="badge bg-danger">Inactive</span>
                                                <?php endif; ?>
                                            </td>
                                            <td><?= date('M d, Y', strtotime($created_at)) ?></td>
                                        </tr>
                                    <?php endforeach; ?>
                                <?php else: ?>
                                    <tr>
                                        <td colspan="4" class="text-center">No applications found</td>
                                    </tr>
                                <?php endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
