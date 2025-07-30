<?= $this->extend('Layout/Starter') ?>

<?= $this->section('title') ?>
Developer Dashboard
<?= $this->endSection() ?>

<?= $this->section('content') ?>
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="page-title-box">
                <h4 class="page-title">Developer Dashboard</h4>
                <div class="page-title-right">
                    <ol class="breadcrumb m-0">
                        <li class="breadcrumb-item"><a href="javascript: void(0);">KuroPanel</a></li>
                        <li class="breadcrumb-item active">Developer</li>
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
                <p>Role: Developer (Level <?= $user->level ?>)</p>
            </div>
        </div>
    </div>

    <!-- Stats Cards -->
    <div class="row">
        <div class="col-xl-3 col-md-6">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mt-0 mb-4">Total Apps</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1"><?= $stats['total_apps'] ?? 0 ?></h2>
                            <p class="text-muted mb-1">Applications created</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6">  
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mt-0 mb-4">Total Licenses</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1"><?= $stats['total_licenses'] ?? 0 ?></h2>
                            <p class="text-muted mb-1">License keys generated</p>
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
                    <h4 class="header-title mt-0 mb-4">Revenue</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1">$<?= number_format($stats['total_revenue'] ?? 0, 2) ?></h2>
                            <p class="text-muted mb-1">Total earnings</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Recent Apps -->
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mb-3">Your Applications</h4>
                    <div class="table-responsive">
                        <table class="table table-borderless table-hover table-nowrap table-centered m-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Application</th>
                                    <th>Version</th>
                                    <th>Status</th>
                                    <th>Created</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php if (!empty($apps)): ?>
                                    <?php foreach ($apps as $app): ?>
                                        <?php 
                                        // Handle both object and array format
                                        $app_name = is_object($app) ? $app->app_name : $app['app_name'];
                                        $current_version = is_object($app) ? ($app->current_version ?? '1.0.0') : ($app['current_version'] ?? '1.0.0');
                                        $status = is_object($app) ? $app->status : $app['status'];
                                        $created_at = is_object($app) ? $app->created_at : $app['created_at'];
                                        $id_app = is_object($app) ? $app->id_app : $app['id_app'];
                                        ?>
                                        <tr>
                                            <td>
                                                <h5 class="m-0 fw-normal"><?= esc($app_name) ?></h5>
                                            </td>
                                            <td><?= esc($current_version) ?></td>
                                            <td>
                                                <?php if ($status): ?>
                                                    <span class="badge bg-success">Active</span>
                                                <?php else: ?>
                                                    <span class="badge bg-danger">Inactive</span>
                                                <?php endif; ?>
                                            </td>
                                            <td><?= date('M d, Y', strtotime($created_at)) ?></td>
                                            <td>
                                                <a href="/developer/app/<?= $id_app ?>" class="btn btn-sm btn-primary">View</a>
                                                <a href="/developer/licenses/<?= $id_app ?>" class="btn btn-sm btn-info">Licenses</a>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                <?php else: ?>
                                    <tr>
                                        <td colspan="5" class="text-center">No applications found</td>
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
                            <a href="/developer/apps" class="btn btn-primary btn-block mb-2">Manage Apps</a>
                        </div>
                        <div class="col-md-3">
                            <a href="/developer/generate-invite" class="btn btn-success btn-block mb-2">Generate Invite</a>
                        </div>
                        <div class="col-md-3">
                            <a href="/developer/licenses" class="btn btn-info btn-block mb-2">View Licenses</a>
                        </div>
                        <div class="col-md-3">
                            <a href="/developer/invite-codes" class="btn btn-warning btn-block mb-2">Invite Codes</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
            <div class="col-md-3">
                <div class="card">
                    <div class="card-body">
                        <h5>Active Licenses</h5>
                        <h3><?= $stats['active_licenses'] ?? 0 ?></h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card">
                    <div class="card-body">
                        <h5>Total Revenue</h5>
                        <h3>$<?= number_format($stats['total_revenue'] ?? 0, 2) ?></h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card">
                    <div class="card-body">
                        <h5>Resellers</h5>
                        <h3><?= $stats['total_resellers'] ?? 0 ?></h3>
                    </div>
                </div>
            </div>
        </div>

        <div class="row mt-4">
            <div class="col-md-12">
                <div class="card">
                    <div class="card-header">
                        <h5>Your Applications</h5>
                    </div>
                    <div class="card-body">
                        <?php if (isset($apps) && !empty($apps)): ?>
                            <div class="table-responsive">
                                <table class="table table-striped">
                                    <thead>
                                        <tr>
                                            <th>App Name</th>
                                            <th>Version</th>
                                            <th>Status</th>
                                            <th>Licenses</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php foreach ($apps as $app): ?>
                                        <tr>
                                            <td><?= esc($app->app_name) ?></td>
                                            <td><?= esc($app->current_version) ?></td>
                                            <td>
                                                <span class="badge bg-<?= $app->status === 'active' ? 'success' : 'danger' ?>">
                                                    <?= ucfirst($app->status) ?>
                                                </span>
                                            </td>
                                            <td><?= $app->license_count ?? 0 ?></td>
                                            <td>
                                                <a href="/developer/app/<?= $app->id_app ?>" class="btn btn-sm btn-primary">View</a>
                                                <a href="/developer/licenses/<?= $app->id_app ?>" class="btn btn-sm btn-info">Licenses</a>
                                            </td>
                                        </tr>
                                        <?php endforeach; ?>
                                    </tbody>
                                </table>
                            </div>
                        <?php else: ?>
                            <div class="alert alert-warning">
                                <h5>No Applications Found</h5>
                                <p>You haven't created any applications yet.</p>
                                <a href="/developer/apps" class="btn btn-primary">Create Your First App</a>
                            </div>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>

        <div class="row mt-4">
            <div class="col-md-12">
                <div class="card">
                    <div class="card-header">
                        <h5>Quick Actions</h5>
                    </div>
                    <div class="card-body">
                        <a href="/developer/apps" class="btn btn-primary me-2">Manage Apps</a>
                        <a href="/developer/generate-invite" class="btn btn-success me-2">Generate Invite Code</a>
                        <a href="/developer/invite-codes" class="btn btn-info me-2">View Invite Codes</a>
                        <a href="/developer/licenses" class="btn btn-warning">View All Licenses</a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
