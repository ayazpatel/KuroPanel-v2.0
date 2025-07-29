<!DOCTYPE html>
<html>
<head>
    <title><?= $title ?? 'Reseller Dashboard' ?></title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-4">
        <h1>Reseller Dashboard</h1>
        
        <div class="row">
            <div class="col-md-12">
                <div class="alert alert-info">
                    <h4>Welcome, <?= $user->fullname ?? $user->username ?></h4>
                    <p>Role: Reseller (Level <?= $user->level ?>)</p>
                    <p>Balance: $<?= number_format($user->saldo ?? 0, 2) ?></p>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-md-3">
                <div class="card">
                    <div class="card-body">
                        <h5>Assigned Apps</h5>
                        <h3><?= $stats['assigned_apps'] ?? 0 ?></h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card">
                    <div class="card-body">
                        <h5>Keys Generated</h5>
                        <h3><?= $stats['total_keys_generated'] ?? 0 ?></h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card">
                    <div class="card-body">
                        <h5>Active Keys</h5>
                        <h3><?= $stats['active_keys'] ?? 0 ?></h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card">
                    <div class="card-body">
                        <h5>Total Users</h5>
                        <h3><?= $stats['total_users'] ?? 0 ?></h3>
                    </div>
                </div>
            </div>
        </div>

        <div class="row mt-4">
            <div class="col-md-12">
                <div class="card">
                    <div class="card-header">
                        <h5>Assigned Applications</h5>
                    </div>
                    <div class="card-body">
                        <?php if (isset($apps) && !empty($apps)): ?>
                            <div class="table-responsive">
                                <table class="table table-striped">
                                    <thead>
                                        <tr>
                                            <th>App Name</th>
                                            <th>Developer</th>
                                            <th>Commission</th>
                                            <th>Status</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php foreach ($apps as $app): ?>
                                        <tr>
                                            <td><?= htmlspecialchars($app->app_name) ?></td>
                                            <td><?= htmlspecialchars($app->developer_name ?? 'N/A') ?></td>
                                            <td><?= $app->commission_rate ?? 0 ?>%</td>
                                            <td>
                                                <span class="badge bg-<?= $app->status === 'active' ? 'success' : 'danger' ?>">
                                                    <?= ucfirst($app->status) ?>
                                                </span>
                                            </td>
                                            <td>
                                                <a href="/reseller/generate-keys?app=<?= $app->id_app ?>" class="btn btn-sm btn-primary">Generate Keys</a>
                                                <a href="/reseller/manage-keys/<?= $app->id_app ?>" class="btn btn-sm btn-info">Manage</a>
                                            </td>
                                        </tr>
                                        <?php endforeach; ?>
                                    </tbody>
                                </table>
                            </div>
                        <?php else: ?>
                            <div class="alert alert-warning">
                                <h5>No Applications Assigned</h5>
                                <p>You don't have any applications assigned yet. Use an invite code to get access to applications.</p>
                                <a href="/reseller/use-invite" class="btn btn-primary">Use Invite Code</a>
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
                        <a href="/reseller/use-invite" class="btn btn-success me-2">Use Invite Code</a>
                        <a href="/reseller/generate-keys" class="btn btn-primary me-2">Generate Keys</a>
                        <a href="/reseller/manage-keys" class="btn btn-info me-2">Manage Keys</a>
                        <a href="/reseller/key-portal" class="btn btn-warning">Key Portal</a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
