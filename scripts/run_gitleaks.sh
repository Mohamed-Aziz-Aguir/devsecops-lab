
#!/usr/bin/env bash
set -euo pipefail
mkdir -p reports
docker run --rm -v $PWD:/repo zricethezav/gitleaks:latest detect   --source="/repo" --report-format sarif --report-path "/repo/reports/gitleaks.sarif"
