# Test-Driven Container Development: Getting Started

Welcome! This template enables you to develop Docker containers using **test-driven development (TDD)** with **Bats** (Bash Automated Testing Framework).

## What is This?

This workflow separates concerns into a **multi-branch strategy**:

- **test-development** → Write tests that define features
- **container-development** → Build the Dockerfile that passes tests
- **security-review** → Scan for vulnerabilities, propose security tests
- **main** → Production-ready, auto-deployed to Docker Hub

## Initial Setup (Do This First)

1. **Click "Use this template"** on GitHub to create your own repo

2. **Clone your new repo:**
   ```bash
   git clone https://github.com/<your-username>/<your-repo>.git
   cd <your-repo>

### Security Scanning & SARIF

When you create a PR to `security-review`:

1. **Trivy automatically scans** your Docker image for vulnerabilities
2. **Results upload to GitHub's code scanning** (SARIF format)
3. **View in:** Settings → Security → Code scanning alerts
4. **Address vulnerabilities** before merging to `main`

GitHub will block merges if critical vulnerabilities exist (if branch protection is enforced).
