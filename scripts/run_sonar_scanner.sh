
#!/usr/bin/env bash
set -euo pipefail
: "${SONAR_HOST_URL:?Set SONAR_HOST_URL}"
: "${SONAR_TOKEN:?Set SONAR_TOKEN}"
docker run --rm -e SONAR_HOST_URL -e SONAR_TOKEN -v $PWD:/usr/src sonarsource/sonar-scanner-cli:latest
