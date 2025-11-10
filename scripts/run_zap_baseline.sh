
#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:-http://localhost:8000}"
mkdir -p reports
docker run --rm --network host -v $(pwd)/reports:/zap/wrk ghcr.io/zaproxy/zaproxy:stable zap-baseline.py   -t "${TARGET}/" -r zap-baseline.html -w zap-baseline.md -J zap-baseline.json -I
