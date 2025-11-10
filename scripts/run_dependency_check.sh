
#!/usr/bin/env bash
set -euo pipefail
mkdir -p reports
docker run --rm -e NVD_API_KEY="${NVD_API_KEY:-}" -v $(pwd):/src -v $(pwd)/reports:/report owasp/dependency-check:latest   --scan /src --format "HTML" --format "JSON" --out /report --project "devsecops-lab"
