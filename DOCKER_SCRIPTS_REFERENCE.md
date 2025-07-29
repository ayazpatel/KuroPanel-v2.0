# 🐳 KuroPanel Docker Scripts Quick Reference

## Local Docker Testing Scripts

Fresh Docker test environment with complete cleanup and rebuild.

### Windows Batch Script
```batch
localDockerTest.bat
```
- Removes all containers, volumes, and networks
- Builds fresh containers with no cache
- Runs complete test suite
- Provides health checks and status reports

### Windows PowerShell Script
```powershell
# Standard fresh test
.\localDockerTest.ps1

# Full cleanup with image removal (slower but most thorough)
.\localDockerTest.ps1 -RemoveImages

# Setup only, skip tests (faster)
.\localDockerTest.ps1 -SkipTests

# Detailed output
.\localDockerTest.ps1 -Verbose

# Show help
.\localDockerTest.ps1 -Help
```

### Linux/macOS Script
```bash
# Standard fresh test
./localDockerTest.sh

# Full cleanup with image removal
./localDockerTest.sh --remove-images

# Setup only, skip tests
./localDockerTest.sh --skip-tests

# Detailed output
./localDockerTest.sh --verbose

# Show help
./localDockerTest.sh --help
```

## Regular Build Scripts

### PowerShell (`build.ps1`)
```powershell
.\build.ps1 build dev     # Build development containers
.\build.ps1 start dev     # Start development services
.\build.ps1 test          # Run tests
.\build.ps1 clean         # Clean up everything
.\build.ps1 shell         # Open container shell
```

### Makefile
```bash
make fresh-test           # Complete fresh test (calls localDockerTest.sh)
make fresh-test-no-images # Fresh test without removing images
make dev                  # Build and start development
make test                 # Run tests
make quick-test          # Quick test without rebuild
make clean               # Clean up everything
```

## What Each Script Does

### localDockerTest Scripts
1. **Stop & Remove** all existing containers
2. **Remove volumes** (fresh database)
3. **Remove networks** (clean network setup)
4. **Optional**: Remove images (with --remove-images flag)
5. **Build** fresh containers with --no-cache
6. **Start** all services
7. **Health check** all services (app, phpMyAdmin, database)
8. **Run tests** (unless --skip-tests)
9. **Report results** with colored output

### Regular Scripts
- Standard Docker operations
- Environment switching
- Quick testing without full cleanup
- Container management

## When to Use Which Script

### Use `localDockerTest` when:
- 🔄 Need completely fresh environment
- 🐛 Debugging Docker issues
- 🧪 Want to ensure tests run in clean state
- 📦 Testing after major changes
- 🚀 Before important deployments

### Use regular scripts when:
- 🏃‍♂️ Quick development iterations
- 🔧 Minor code changes
- ⚡ Fast testing cycles
- 🛠️ Day-to-day development

## Output Examples

### Successful Run
```
=======================================
  KuroPanel Local Docker Test Script
=======================================

[1/6] Stopping existing containers...
  ✓ Stopped: kuropanel_app
  ✓ Stopped: kuropanel_db

[6/6] Building and starting fresh containers...
  → Building containers...
  ✓ Build completed successfully
  ✓ Services started successfully

Performing health checks...
  → Checking Application...
  ✓ Application is ready
  → Checking Database...
  ✓ Database connection successful

Running test suite...
  ✓ All tests passed

=======================================
  🎉 ALL TESTS PASSED!
  📊 Fresh Docker environment is ready

  Services available at:
  • Application: http://localhost:8080
  • phpMyAdmin:  http://localhost:8081
  • Database:    localhost:3306
=======================================
```

## Troubleshooting

If scripts fail:
1. Check Docker Desktop is running
2. Ensure ports 8080, 8081, 3306 are free
3. Run with `--verbose` flag for details
4. Try `docker system prune -a` for complete cleanup
5. Check `docker-compose logs` for service issues

## Performance Tips

- Use `--skip-tests` for faster setup-only runs
- Regular scripts are faster for development
- `localDockerTest` is slower but more reliable
- Remove images only when necessary (slower but thorough)
