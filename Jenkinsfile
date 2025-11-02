pipeline {
  agent any

  options { timestamps() }

  environment {
    // Path to the scanner tool configured under Manage Jenkins → Tools
    SONAR_SCANNER_HOME = tool 'SonarScanner'
  }

  stages {
    stage('Prepare') {
      steps {
        sh 'echo "Workspace: $PWD"'
      }
    }

    stage('SonarQube Scan') {
      steps {
        withSonarQubeEnv('SonarLocal') {
          sh """
            ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
              -Dsonar.projectKey=devsecops-lab \
              -Dsonar.projectName=devsecops-lab \
              -Dsonar.sources=. \
              -Dsonar.java.binaries=**/target \
              -Dsonar.host.url=$SONAR_HOST_URL
          """
        }
      }
    }

    stage('Quality Gate') {
      steps {
        // Requires the Sonar webhook to Jenkins to be configured
        timeout(time: 10, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }
  }

  post {
    always {
      // Archive anything useful; won't fail if nothing matches
      archiveArtifacts artifacts: '**/dependency-check-report.*', allowEmptyArchive: true
    }
  }
}
