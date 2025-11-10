pipeline {
  agent any

  parameters {
    string(name: 'TARGET_URL', defaultValue: '', description: 'Optional app URL for ZAP baseline DAST')
  }

  environment {
    IMAGE_TAG   = "devsecops-lab:ci-${env.BUILD_NUMBER}"
    REPORTS_DIR = "reports"
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Prepare') {
      steps {
        sh '''#!/usr/bin/env bash
        set -euo pipefail
        rm -rf "$REPORTS_DIR" && mkdir -p "$REPORTS_DIR"
        echo "Workspace: $PWD"
        '''
      }
    }

    stage('SonarQube Scan') {
      steps {
        withSonarQubeEnv('SonarLocal') {
          withEnv(["SCANNER_HOME=${tool 'SonarScanner'}"]) {
            sh '''#!/usr/bin/env bash
            set -euo pipefail
            "$SCANNER_HOME/bin/sonar-scanner" \
              -Dsonar.projectKey=devsecops-lab \
              -Dsonar.projectName=devsecops-lab \
              -Dsonar.sources=. \
              -Dsonar.java.binaries=**/target \
              -Dsonar.host.url="$SONAR_HOST_URL"
            '''
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Secrets scan (Gitleaks)') {
      steps {
        sh '''#!/usr/bin/env bash
        set -euo pipefail
        docker run --rm -v "$PWD:/repo" -w /repo \
          ghcr.io/gitleaks/gitleaks:latest detect --no-git -s /repo \
          --report-format json --report-path /repo/$REPORTS_DIR/gitleaks.json || true
        '''
      }
    }

    stage('Dockerfile lint (Hadolint)') {
      when { expression { fileExists('Dockerfile') } }
      steps {
        sh '''#!/usr/bin/env bash
        set -euo pipefail
        docker run --rm -i hadolint/hadolint < Dockerfile | tee "$REPORTS_DIR/hadolint.txt" || true
        '''
      }
    }

    stage('Build container image') {
      when { expression { fileExists('Dockerfile') } }
      steps {
        sh '''#!/usr/bin/env bash
        set -euo pipefail
        docker build --pull -t "${IMAGE_TAG}" .
        '''
      }
    }

    stage('Trivy scan (filesystem)') {
      steps {
        sh '''#!/usr/bin/env bash
        set -euo pipefail
        # Mount reports dir explicitly and write from inside the container
        docker run --rm -v "$PWD:/src" -v "$PWD/$REPORTS_DIR:/report" \
          aquasec/trivy:latest fs /src \
          --scanners vuln,secret,config \
          --severity CRITICAL,HIGH,MEDIUM \
          --format table --output /report/trivy-fs.txt || true

        docker run --rm -v "$PWD:/src" -v "$PWD/$REPORTS_DIR:/report" \
          aquasec/trivy:latest fs /src \
          --format json --output /report/trivy-fs.json || true
        '''
      }
    }

    stage('Trivy scan (image)') {
      when { expression { fileExists('Dockerfile') } }
      steps {
        sh '''#!/usr/bin/env bash
        set -euo pipefail
        docker run --rm \
          -v /var/run/docker.sock:/var/run/docker.sock \
          -v "$PWD/$REPORTS_DIR:/report" \
          aquasec/trivy:latest image "${IMAGE_TAG}" \
          --severity CRITICAL,HIGH \
          --format table --output /report/trivy-image.txt || true

        docker run --rm \
          -v /var/run/docker.sock:/var/run/docker.sock \
          -v "$PWD/$REPORTS_DIR:/report" \
          aquasec/trivy:latest image "${IMAGE_TAG}" \
          --format json --output /report/trivy-image.json || true
        '''
      }
    }

    stage('Dependency-Check (SCA)') {
      steps {
        sh '''#!/usr/bin/env bash
        set -euo pipefail
        mkdir -p "$REPORTS_DIR/dc-data"
        docker run --rm \
          -v "$PWD:/src" \
          -v "$PWD/$REPORTS_DIR/dc-data:/usr/share/dependency-check/data" \
          -v "$PWD/$REPORTS_DIR:/report" \
          owasp/dependency-check:latest \
            --scan /src --format HTML --out /report --disableNodeAudit || true

        # Normalize filename so it’s predictable for archiving
        first=$(ls "$REPORTS_DIR"/dependency-check-report*.html 2>/dev/null | head -n1 || true)
        if [ -n "$first" ] && [ "$first" != "$REPORTS_DIR/dependency-check-report.html" ]; then
          mv "$first" "$REPORTS_DIR/dependency-check-report.html" || true
        fi
        '''
      }
    }

    stage('DAST (OWASP ZAP baseline)') {
      when { expression { return params.TARGET_URL?.trim() } }
      steps {
        sh '''#!/usr/bin/env bash
        set -euo pipefail
        docker run --rm --network host \
          -v "$PWD/$REPORTS_DIR:/zap/wrk" \
          owasp/zap2docker-stable zap-baseline.py \
            -t "${TARGET_URL}" -r zap.html -x zap.xml -a || true
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'reports/**/*, reports/*', fingerprint: true, allowEmptyArchive: true

      // Optional: publish pretty HTML dashboards if plugin installed
      script {
        def htmlFiles = [
          [reportName: 'Dependency-Check', reportFiles: 'reports/dependency-check-report.html', reportDir: '.'],
          [reportName: 'ZAP Baseline',      reportFiles: 'reports/zap.html',                    reportDir: '.']
        ]
        htmlFiles.each { cfg ->
          if (fileExists(cfg.reportFiles)) {
            publishHTML(target: [
              reportDir: cfg.reportDir,
              reportFiles: cfg.reportFiles,
              reportName: cfg.reportName,
              keepAll: true, alwaysLinkToLastBuild: true, allowMissing: true
            ])
          }
        }
      }
    }
  }
}
