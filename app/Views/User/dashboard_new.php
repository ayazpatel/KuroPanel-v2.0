<?= $this->extend('Layout/Starter') ?>

<?= $this->section('title') ?>
User Dashboard
<?= $this->endSection() ?>

<?= $this->section('content') ?>
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="page-title-box">
                <h4 class="page-title">User Dashboard</h4>
                <div class="page-title-right">
                    <ol class="breadcrumb m-0">
                        <li class="breadcrumb-item"><a href="javascript: void(0);">KuroPanel</a></li>
                        <li class="breadcrumb-item active">User</li>
                    </ol>
                </div>
            </div>
        </div>
    </div>

    <!-- Welcome Message -->
    <div class="row">
        <div class="col-12">
            <div class="alert alert-info">
                <h4>Welcome, <?= esc($user->fullname ?? $user->username) ?></h4>
                <p>Role: User (Level <?= $user->level ?>)</p>
                <p>Balance: $<?= number_format($user->saldo ?? 0, 2) ?></p>
            </div>
        </div>
    </div>

    <!-- Stats Cards -->
    <div class="row">
        <div class="col-xl-3 col-md-6">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mt-0 mb-4">My Licenses</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1"><?= $stats['total_licenses'] ?? 0 ?></h2>
                            <p class="text-muted mb-1">Total licenses owned</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6">  
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mt-0 mb-4">Active Licenses</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1"><?= $stats['active_licenses'] ?? 0 ?></h2>
                            <p class="text-muted mb-1">Currently active</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mt-0 mb-4">Expired Licenses</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1"><?= $stats['expired_licenses'] ?? 0 ?></h2>
                            <p class="text-muted mb-1">Need renewal</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mt-0 mb-4">Total Spent</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1">$<?= number_format($stats['total_spent'] ?? 0, 2) ?></h2>
                            <p class="text-muted mb-1">On licenses</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- My Licenses -->
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mb-3">My Licenses</h4>
                    <div class="table-responsive">
                        <table class="table table-borderless table-hover table-nowrap table-centered m-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Application</th>
                                    <th>License Key</th>
                                    <th>Status</th>
                                    <th>Expires</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php if (!empty($user_licenses)): ?>
                                    <?php foreach ($user_licenses as $license): ?>
                                        <?php 
                                        // Handle both object and array format
                                        $app_name = is_object($license) ? $license->app_name : $license['app_name'];
                                        $license_key = is_object($license) ? $license->license_key : $license['license_key'];
                                        $status = is_object($license) ? $license->status : $license['status'];
                                        $expires_at = is_object($license) ? $license->expires_at : $license['expires_at'];
                                        $id_license = is_object($license) ? $license->id_license : $license['id_license'];
                                        ?>
                                        <tr>
                                            <td>
                                                <h5 class="m-0 fw-normal"><?= esc($app_name) ?></h5>
                                            </td>
                                            <td>
                                                <code><?= esc(substr($license_key, 0, 10)) ?>...<?= esc(substr($license_key, -5)) ?></code>
                                            </td>
                                            <td>
                                                <?php if ($status == 'active'): ?>
                                                    <span class="badge bg-success">Active</span>
                                                <?php elseif ($status == 'expired'): ?>
                                                    <span class="badge bg-danger">Expired</span>
                                                <?php else: ?>
                                                    <span class="badge bg-warning">Inactive</span>
                                                <?php endif; ?>
                                            </td>
                                            <td><?= $expires_at ? date('M d, Y', strtotime($expires_at)) : 'Never' ?></td>
                                            <td>
                                                <a href="/user/activate-license?id=<?= $id_license ?>" class="btn btn-sm btn-primary">Activate</a>
                                                <a href="/user/hwid-reset?id=<?= $id_license ?>" class="btn btn-sm btn-warning">Reset HWID</a>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                <?php else: ?>
                                    <tr>
                                        <td colspan="5" class="text-center">No licenses found</td>
                                    </tr>
                                <?php endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Quick Actions -->
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mb-3">Quick Actions</h4>
                    <div class="row">
                        <div class="col-md-3">
                            <a href="/user/purchase-license" class="btn btn-primary btn-block mb-2">Purchase License</a>
                        </div>
                        <div class="col-md-3">
                            <a href="/user/activate-license" class="btn btn-success btn-block mb-2">Activate License</a>
                        </div>
                        <div class="col-md-3">
                            <a href="/user/my-licenses" class="btn btn-info btn-block mb-2">My Licenses</a>
                        </div>
                        <div class="col-md-3">
                            <a href="/user/profile" class="btn btn-warning btn-block mb-2">Edit Profile</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
