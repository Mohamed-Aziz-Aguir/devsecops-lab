#!/usr/bin/env bash
set -euxo pipefail

# Ensure time is sane before apt
sudo timedatectl set-ntp true || true
sudo systemctl restart systemd-timesyncd || true
sleep 3 || true

# Base deps
sudo apt-get update -y
sudo apt-get install -y git curl unzip gnupg2 software-properties-common apt-transport-https ca-certificates wget

# Docker CE
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker vagrant || true
sudo usermod -aG docker jenkins || true
sudo systemctl enable --now docker

# Jenkins LTS
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jre jenkins
sudo systemctl enable --now jenkins || true

# Trivy (official installer)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin

# Gitleaks (fixed version)
GL_VER="8.18.4"
curl -sSL -o /tmp/gitleaks.tar.gz "https://github.com/gitleaks/gitleaks/releases/download/v${GL_VER}/gitleaks_${GL_VER}_linux_x64.tar.gz"
sudo tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks
sudo chmod +x /usr/local/bin/gitleaks

# Hadolint
curl -sSL https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o /tmp/hadolint
sudo install -m 0755 /tmp/hadolint /usr/local/bin/hadolint

# OWASP Dependency-Check CLI
ODC_VER="9.2.0"
curl -sSL "https://github.com/jeremylong/DependencyCheck/releases/download/v${ODC_VER}/dependency-check-${ODC_VER}-release.zip" -o /tmp/dependency-check.zip
sudo unzip -q /tmp/dependency-check.zip -d /opt
sudo ln -sf /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check

# SonarQube (Docker)
sudo docker pull sonarqube:lts-community
sudo docker volume create sonarqube_data || true
sudo docker volume create sonarqube_logs || true
sudo docker rm -f sonarqube || true
sudo docker run -d --name sonarqube -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  sonarqube:lts-community

# ZAP image
sudo docker pull owasp/zap2docker-stable

echo "Jenkins => http://localhost:8080"
echo "SonarQube => http://localhost:9000"