# GitOps-Based Semgrep On-Demand Scan

🧩 **GOAL**: Automate Semgrep scans across dev, beta, and prod environments using GitOps principles with GitHub Actions, Minikube, and Helm.

## ✅ Features

- ✅ GitOps folder structure
- ✅ Dynamic rules from Git repo (rules/)
- ✅ values.yaml-based token/config injection
- ✅ GitHub Actions for trigger automation
- ✅ GitHub Secrets for secure token management (prod/beta)
- ✅ Self-hosted runner for Minikube (dev)
- ✅ Pure YAML (no bash scripts)
- ✅ No SealedSecrets used

## 📁 Folder Structure

```
gitops-semgrep/
├── rules/                      # Dynamic scan rules per project
│   ├── frontend/
│   │   └── javascript-security.yml
│   ├── backend/
│   │   └── java-security.yml
│   └── shared/
│       └── common-security.yml
├── environments/
│   ├── dev/
│   │   └── values.yaml         # hardcoded token for Minikube dev
│   ├── beta/
│   │   └── values.yaml         # token injected from GitHub Secrets
│   └── prod/
│       └── values.yaml
├── k8s-jobs/
│   └── semgrep-job.yaml        # Helm-templated Kubernetes Job
├── .github/
│   └── workflows/
│       └── scan-semgrep.yml    # CI/CD pipeline trigger
└── README.md
```

## 🚀 Quick Start

### Prerequisites

1. **Self-hosted GitHub Runner** with:
   - Docker installed
   - Minikube installed
   - kubectl installed
   - Helm installed

2. **GitHub Secrets** (for beta/prod):
   - `SEMGREP_TOKEN_BETA`
   - `SEMGREP_TOKEN_PROD`

### Manual Commands for Minikube Dev Testing

```bash
# Start Minikube
minikube start --cpus=4 --memory=8192

# Create namespace
kubectl create ns semgrep-dev

# Deploy Semgrep job
helm upgrade --install semgrep-job ./k8s-jobs \
  -f environments/dev/values.yaml \
  -n semgrep-dev

# View logs
kubectl logs job/semgrep-scan-once -n semgrep-dev
```

## 🔧 Configuration

### Environment-Specific Values

Each environment has its own `values.yaml` file:

- **dev/values.yaml**: Uses hardcoded token for local development
- **beta/values.yaml**: Token injected from `SEMGREP_TOKEN_BETA` secret
- **prod/values.yaml**: Token injected from `SEMGREP_TOKEN_PROD` secret

### Rule Configuration

Rules are organized by project type:
- `rules/frontend/`: JavaScript/TypeScript security rules
- `rules/backend/`: Java/Python/Go security rules  
- `rules/shared/`: Common security rules across all languages

## 🎯 Usage

### Automatic Triggers

- **Push to dev branch**: Automatically runs dev environment scan
- **Push to main branch**: Automatically runs dev environment scan

### Manual Triggers

1. Go to **Actions** tab in GitHub
2. Select **Semgrep On-Demand Scan** workflow
3. Click **Run workflow**
4. Choose environment: `dev`, `beta`, or `prod`
5. Click **Run workflow**

## 🔐 Security

### GitHub Secrets Setup

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:
   - `SEMGREP_TOKEN_BETA`: Your Semgrep token for beta environment
   - `SEMGREP_TOKEN_PROD`: Your Semgrep token for production environment

### Token Management

- **Dev**: Uses dummy token from values.yaml (safe for local testing)
- **Beta/Prod**: Uses secure tokens from GitHub Secrets
- Tokens are never exposed in logs or configuration files

## 📊 Monitoring

### Job Status

```bash
# Check job status
kubectl get jobs -n semgrep-{env}

# View detailed logs
kubectl logs job/semgrep-scan-once -n semgrep-{env} --all-containers=true

# Check pod status
kubectl get pods -n semgrep-{env}
```

### Results

Semgrep results are output in JSON format and displayed in the GitHub Actions logs.

## 🛠️ Customization

### Adding New Rules

1. Create new rule files in appropriate `rules/` subdirectory
2. Follow Semgrep rule syntax
3. Commit and push changes
4. Rules will be automatically pulled during next scan

### Environment Configuration

Modify `environments/{env}/values.yaml` to:
- Change resource limits
- Update rule paths
- Modify job configuration

### Workflow Customization

Edit `.github/workflows/scan-semgrep.yml` to:
- Add new environments
- Modify trigger conditions
- Change notification settings

## 🔍 Troubleshooting

### Common Issues

1. **Minikube not starting**: Check Docker daemon and system resources
2. **Job fails**: Check namespace creation and Helm chart syntax
3. **No logs**: Wait for job completion or check pod status
4. **Token errors**: Verify GitHub Secrets are properly configured

### Debug Commands

```bash
# Check Minikube status
minikube status

# Verify kubectl context
kubectl config current-context

# Check Helm releases
helm list -n semgrep-{env}

# Describe job for detailed info
kubectl describe job semgrep-scan-once -n semgrep-{env}
```

## 📈 Summary Table

| Feature | Status |
|---------|--------|
| GitOps folder structure | ✅ |
| Dynamic rules via Git initContainer | ✅ |
| Secure token (GitHub Secrets) | ✅ |
| Dev/local support (Minikube) | ✅ |
| Self-hosted runner integration | ✅ |
| Pure YAML (no bash scripts) | ✅ |
| No SealedSecrets used | ✅ |

# GitHub Repository Setup Guide

## Required GitHub Secrets

To use this GitOps Semgrep setup, you need to configure the following secrets in your GitHub repository:

### 1. Navigate to Repository Settings
1. Go to your repository on GitHub
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**

### 2. Add Required Secrets

Click **New repository secret** and add:

#### For Beta Environment
- **Name**: `SEMGREP_TOKEN_BETA`
- **Value**: Your Semgrep API token for beta environment

#### For Production Environment  
- **Name**: `SEMGREP_TOKEN_PROD`
- **Value**: Your Semgrep API token for production environment

### 3. Self-Hosted Runner Setup

This workflow requires a self-hosted runner with the following tools installed:

#### Required Tools
- **Docker**: For running Minikube and containers
- **Minikube**: For local Kubernetes cluster (dev environment)
- **kubectl**: For Kubernetes cluster management
- **Helm**: For deploying Kubernetes applications

#### Runner Setup Commands
```bash
# Install Docker (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install docker.io
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### 4. Repository Configuration

#### Branch Protection (Optional)
Consider setting up branch protection rules for:
- `main` branch: Require PR reviews
- `dev` branch: Allow direct pushes for development

#### Workflow Permissions
Ensure the workflow has necessary permissions:
- **Actions**: Read
- **Contents**: Read
- **Secrets**: Read

### 5. Semgrep Token Generation

1. Go to [Semgrep Dashboard](https://semgrep.dev/manage/settings)
2. Navigate to **Settings** → **Tokens**
3. Click **Create New Token**
4. Give it a descriptive name (e.g., "GitOps Beta" or "GitOps Prod")
5. Copy the token and add it to GitHub Secrets

### 6. Testing the Setup

#### Test Dev Environment (Local)
```bash
# Trigger manually via GitHub Actions UI
# Or push to dev branch to auto-trigger
```

#### Test Beta/Prod Environment
```bash
# Use GitHub Actions UI with workflow_dispatch
# Select environment: beta or prod
```

### 7. Monitoring and Logs

#### GitHub Actions Logs
- Go to **Actions** tab in your repository
- Click on the workflow run
- Expand each step to see detailed logs

#### Kubernetes Logs (if you have cluster access)
```bash
# Check job status
kubectl get jobs -n semgrep-{env}

# View logs
kubectl logs job/semgrep-scan-once -n semgrep-{env}
```

## Troubleshooting

### Common Issues

1. **Secret not found**: Verify secret names match exactly (`SEMGREP_TOKEN_BETA`, `SEMGREP_TOKEN_PROD`)
2. **Runner offline**: Check self-hosted runner status in repository settings
3. **Minikube fails**: Ensure Docker is running and user has proper permissions
4. **Helm deployment fails**: Check Chart.yaml and values.yaml syntax

### Support

For issues with this setup:
1. Check the GitHub Actions logs first
2. Verify all prerequisites are installed on the runner
3. Test individual components (kubectl, helm, minikube) manually
4. Review the README.md for additional troubleshooting steps
