#!/usr/bin/env bash
set -e
sudo apt-get update -y
sudo apt-get install -y git curl unzip gnupg2 software-properties-common apt-transport-https ca-certificates wget
# Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker vagrant
# Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jre jenkins
sudo usermod -aG docker jenkins
sudo systemctl enable --now jenkins
# Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb stable main | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y && sudo apt-get install -y trivy
# Gitleaks
curl -sSL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_amd64.deb -o /tmp/gitleaks.deb
sudo dpkg -i /tmp/gitleaks.deb || sudo apt-get -f install -y
# Semgrep
curl -sL https://semgrep.dev/install.sh | sudo bash
# Hadolint
curl -sL https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint
sudo chmod +x /usr/local/bin/hadolint
# OWASP Dependency-Check
ODC_VER=9.2.0
curl -sL https://github.com/jeremylong/DependencyCheck/releases/download/v${ODC_VER}/dependency-check-${ODC_VER}-release.zip -o /tmp/dependency-check.zip
sudo unzip -q /tmp/dependency-check.zip -d /opt
sudo ln -sf /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
# SonarQube in Docker
sudo docker pull sonarqube:lts-community
sudo docker volume create sonarqube_data
sudo docker volume create sonarqube_logs
sudo docker run -d --name sonarqube -p 9000:9000 -v sonarqube_data:/opt/sonarqube/data -v sonarqube_logs:/opt/sonarqube/logs sonarqube:lts-community
# ZAP image
sudo docker pull owasp/zap2docker-stable
echo "Jenkins => http://localhost:8080"
echo "SonarQube => http://localhost:9000"
