<!DOCTYPE html>
<html>
<head>
    <title><?= $title ?? 'Developer Dashboard' ?></title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-4">
        <h1>Developer Dashboard</h1>
        
        <div class="row">
            <div class="col-md-12">
                <div class="alert alert-info">
                    <h4>Welcome, <?= $user->fullname ?? $user->username ?></h4>
                    <p>Role: Developer (Level <?= $user->level ?>)</p>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-md-3">
                <div class="card">
                    <div class="card-body">
                        <h5>Total Apps</h5>
                        <h3><?= $stats['total_apps'] ?? 0 ?></h3>
                    </div>
                </div>
            </div>
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
