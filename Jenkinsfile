pipeline {
  agent any
  environment {
    SONARQUBE_ENV = 'SonarLocal'
    SONAR_SCANNER_HOME = tool 'SonarQube Scanner'
    REPORT_DIR = 'reports'
  }
  options { ansiColor('xterm'); timestamps() }
  stages {
    stage('Checkout') { steps { deleteDir(); checkout scm; sh 'mkdir -p $REPORT_DIR' } }
    stage('Secrets & Hygiene') {
      parallel {
        stage('Gitleaks') { steps { sh 'gitleaks detect --source . --no-log --report-format json --report-path $REPORT_DIR/gitleaks.json || true' } }
        stage('Hadolint') { steps { sh 'if [ -f Dockerfile ]; then hadolint Dockerfile | tee $REPORT_DIR/hadolint.txt || true; fi' } }
      }
    }
    stage('Set up Python') { steps { sh 'python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements-dev.txt' } }
    stage('Unit Tests') { steps { sh '. .venv/bin/activate && pytest -q --disable-warnings --maxfail=1' } }
    stage('SAST') {
      parallel {
        stage('Semgrep') { steps { sh '. .venv/bin/activate && semgrep --config p/owasp-top-ten --json --output $REPORT_DIR/semgrep.json || true' } }
        stage('Bandit') { steps { sh '. .venv/bin/activate && bandit -r app -f json -o $REPORT_DIR/bandit.json || true' } }
      }
    }
    stage('SonarQube') {
      steps {
        withSonarQubeEnv("${env.SONARQUBE_ENV}") {
          sh '''
            ${env.SONAR_SCANNER_HOME}/bin/sonar-scanner \
              -Dsonar.projectKey=devsecops-lab \
              -Dsonar.sources=. \
              -Dsonar.host.url=$SONAR_HOST_URL \
              -Dsonar.login=$SONAR_AUTH_TOKEN \
              -Dsonar.qualitygate.wait=true
          '''
        }
      }
    }
    stage('SCA (Trivy FS)') { steps { sh 'trivy fs --scanners vuln,secret --format json -o $REPORT_DIR/trivy-fs.json --exit-code 1 --severity CRITICAL,HIGH . || true' } }
    stage('Build Docker Image') { steps { sh 'docker build -t devsecops-lab:ci .' } }
    stage('Trivy Image Scan') { steps { sh 'trivy image --format json -o $REPORT_DIR/trivy-image.json --exit-code 1 --severity CRITICAL,HIGH devsecops-lab:ci || true' } }
    stage('Deploy Staging') { steps { sh 'docker compose -f docker-compose.staging.yml down || true; docker compose -f docker-compose.staging.yml up -d --build' } }
    stage('DAST (ZAP Baseline)') {
      steps {
        sh '''
          TARGET_URL=${ZAP_TARGET_URL:-http://localhost:8081}
          docker run --rm -u root -v $(pwd)/reports:/zap/wrk:rw \
            owasp/zap2docker-stable zap-baseline.py \
            -t "$TARGET_URL" -r zap-baseline.html -J zap-baseline.json -m 5 -I || true
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'reports/zap-baseline.*', fingerprint: true
          publishHTML(target: [allowMissing: true, keepAll: true, reportDir: 'reports', reportFiles: 'zap-baseline.html', reportName: 'ZAP Baseline Report'])
        }
      }
    }
  }
  post { always { archiveArtifacts artifacts: 'reports/**', fingerprint: true } }
}
