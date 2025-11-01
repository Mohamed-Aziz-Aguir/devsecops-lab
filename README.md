# devsecops-lab

A small FastAPI app with a **Jenkins DevSecOps pipeline** running:
- Gitleaks (secrets)
- Semgrep + Bandit (SAST)
- Trivy fs & image (SCA + container)
- Hadolint (Dockerfile lint)
- SonarQube (Quality Gate)
- OWASP ZAP Baseline (DAST against staging)

See `infra/` for Vagrant (Jenkins LTS + tools).

## Local quick start (optional)
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
uvicorn app.main:app --reload --port 8080
pytest -q
```

## Staging for DAST
```bash
docker compose -f docker-compose.staging.yml up -d --build
# app → http://localhost:8081/health
```
