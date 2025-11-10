
#!/usr/bin/env bash
set -euo pipefail
APP_IMAGE="${1:-devsecops-lab:latest}"
mkdir -p reports
docker run --rm -v $PWD:/src aquasec/trivy fs --scanners vuln,secret --format sarif -o /src/reports/trivy-fs.sarif /src
docker build -t "$APP_IMAGE" .
docker run --rm -v $PWD:/src aquasec/trivy image --format sarif -o /src/reports/trivy-image.sarif "$APP_IMAGE"
