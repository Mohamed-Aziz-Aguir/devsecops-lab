
# Pre-push DevSecOps Add-on

## One-time setup
pip install pre-commit
pre-commit install
git config core.hooksPath .githooks

# SonarQube (optional quick SAST)
export SONAR_HOST_URL=http://localhost:9000
export SONAR_TOKEN=<token>

## Usage
# Blocks push if issues are found
git push

## Vagrant/Docker heavy scans
scripts/run_trivy.sh
scripts/run_dependency_check.sh
scripts/run_gitleaks.sh
scripts/run_sonar_scanner.sh
scripts/run_zap_baseline.sh http://localhost:8000
