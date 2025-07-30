<?= $this->extend('Layout/Starter') ?>

<?= $this->section('title') ?>
Reseller Dashboard
<?= $this->endSection() ?>

<?= $this->section('content') ?>
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="page-title-box">
                <h4 class="page-title">Reseller Dashboard</h4>
                <div class="page-title-right">
                    <ol class="breadcrumb m-0">
                        <li class="breadcrumb-item"><a href="javascript: void(0);">KuroPanel</a></li>
                        <li class="breadcrumb-item active">Reseller</li>
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
                <p>Role: Reseller (Level <?= $user->level ?>)</p>
                <p>Balance: $<?= number_format($user->saldo ?? 0, 2) ?></p>
            </div>
        </div>
    </div>

    <!-- Stats Cards -->
    <div class="row">
        <div class="col-xl-3 col-md-6">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mt-0 mb-4">Available Apps</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1"><?= $stats['available_apps'] ?? 0 ?></h2>
                            <p class="text-muted mb-1">Apps you can resell</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6">  
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mt-0 mb-4">Keys Generated</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1"><?= $stats['keys_generated'] ?? 0 ?></h2>
                            <p class="text-muted mb-1">Total license keys</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mt-0 mb-4">Active Keys</h4>
                    <div class="widget-chart-1">
                        <div class="widget-detail-1 text-end">
                            <h2 class="fw-normal pt-2 mb-1"><?= $stats['active_keys'] ?? 0 ?></h2>
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

    <!-- Available Apps -->
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-body">
                    <h4 class="header-title mb-3">Available Applications</h4>
                    <div class="table-responsive">
                        <table class="table table-borderless table-hover table-nowrap table-centered m-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Application</th>
                                    <th>Developer</th>
                                    <th>Status</th>
                                    <th>Your Keys</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php if (!empty($available_apps)): ?>
                                    <?php foreach ($available_apps as $app): ?>
                                        <?php 
                                        // Handle both object and array format
                                        $app_name = is_object($app) ? $app->app_name : $app['app_name'];
                                        $developer_username = is_object($app) ? $app->developer_username : $app['developer_username'];
                                        $status = is_object($app) ? $app->status : $app['status'];
                                        $key_count = is_object($app) ? ($app->key_count ?? 0) : ($app['key_count'] ?? 0);
                                        $id_app = is_object($app) ? $app->id_app : $app['id_app'];
                                        ?>
                                        <tr>
                                            <td>
                                                <h5 class="m-0 fw-normal"><?= esc($app_name) ?></h5>
                                            </td>
                                            <td><?= esc($developer_username) ?></td>
                                            <td>
                                                <?php if ($status): ?>
                                                    <span class="badge bg-success">Active</span>
                                                <?php else: ?>
                                                    <span class="badge bg-danger">Inactive</span>
                                                <?php endif; ?>
                                            </td>
                                            <td><?= $key_count ?></td>
                                            <td>
                                                <a href="/reseller/generate-keys?app=<?= $id_app ?>" class="btn btn-sm btn-primary">Generate Keys</a>
                                                <a href="/reseller/manage-keys/<?= $id_app ?>" class="btn btn-sm btn-info">Manage</a>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                <?php else: ?>
                                    <tr>
                                        <td colspan="5" class="text-center">No applications available for resale</td>
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
                            <a href="/reseller/use-invite" class="btn btn-primary btn-block mb-2">Use Invite Code</a>
                        </div>
                        <div class="col-md-3">
                            <a href="/reseller/generate-keys" class="btn btn-success btn-block mb-2">Generate Keys</a>
                        </div>
                        <div class="col-md-3">
                            <a href="/reseller/manage-keys" class="btn btn-info btn-block mb-2">Manage Keys</a>
                        </div>
                        <div class="col-md-3">
                            <a href="/reseller/key-portal" class="btn btn-warning btn-block mb-2">Key Portal</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
