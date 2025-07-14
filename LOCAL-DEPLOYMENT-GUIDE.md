# Local Minikube Deployment Guide

This guide shows you how to run the Semgrep GitOps deployment locally on your laptop instead of in GitHub Actions.

## 🏠 Prerequisites

### Required Software

1. **Docker Desktop** (Required for Minikube)
   - Windows: Download from [docker.com](https://www.docker.com/products/docker-desktop)
   - macOS: `brew install --cask docker`
   - Linux: Follow [Docker installation guide](https://docs.docker.com/engine/install/)

2. **Minikube**
   - Windows: `choco install minikube` or download from [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/docs/start/)
   - macOS: `brew install minikube`
   - Linux: `curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube`

3. **kubectl**
   - Windows: `choco install kubernetes-cli`
   - macOS: `brew install kubectl`
   - Linux: `curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && sudo install kubectl /usr/local/bin/`

4. **Helm**
   - Windows: `choco install kubernetes-helm`
   - macOS: `brew install helm`
   - Linux: `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`

### System Requirements

- **CPU**: 2+ cores (4 recommended)
- **Memory**: 4GB+ RAM (8GB recommended)
- **Disk**: 10GB+ free space
- **Docker**: Must be running

## 🚀 Quick Start

### Option 1: Using the Deployment Script (Recommended)

#### For Linux/macOS:
```bash
# Make script executable
chmod +x deploy-local.sh

# Deploy to dev environment
./deploy-local.sh dev

# Deploy to staging environment (requires SEMGREP_TOKEN)
export SEMGREP_TOKEN="your_staging_token_here"
./deploy-local.sh staging
```

#### For Windows (PowerShell):
```powershell
# Deploy to dev environment
.\deploy-local.ps1 -Environment dev

# Deploy to staging environment (requires SEMGREP_TOKEN)
$env:SEMGREP_TOKEN = "your_staging_token_here"
.\deploy-local.ps1 -Environment staging
```

### Option 2: Manual Step-by-Step

```bash
# 1. Start Minikube
minikube start --cpus=4 --memory=8192 --driver=docker

# 2. Configure kubectl
kubectl config use-context minikube

# 3. Create namespace
kubectl create namespace semgrep-dev

# 4. Deploy with Helm
helm upgrade --install semgrep-job ./k8s-jobs \
  -f environments/dev/values.yaml \
  --set environment=dev \
  --set github.repository=local/gitops-semgrep \
  -n semgrep-dev \
  --wait --timeout=10m

# 5. Check deployment
kubectl get all -n semgrep-dev

# 6. View logs
kubectl logs job/semgrep-scan-once -n semgrep-dev
```

## 🔍 Validation & Monitoring

### Check Deployment Status
```bash
# View all resources
kubectl get all -n semgrep-dev

# Check job status
kubectl get jobs -n semgrep-dev

# View job details
kubectl describe job semgrep-scan-once -n semgrep-dev

# Check pod status
kubectl get pods -n semgrep-dev

# View events
kubectl get events -n semgrep-dev --sort-by='.lastTimestamp'
```

### View Semgrep Results
```bash
# View complete logs
kubectl logs job/semgrep-scan-once -n semgrep-dev

# Filter for findings
kubectl logs job/semgrep-scan-once -n semgrep-dev | grep -E "(ERROR|WARNING|Found)"

# Follow logs in real-time (if job is running)
kubectl logs -f job/semgrep-scan-once -n semgrep-dev
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Minikube Won't Start
```bash
# Check Docker is running
docker ps

# Try different driver
minikube start --driver=virtualbox  # or hyperv on Windows

# Reset Minikube
minikube delete
minikube start
```

#### 2. Insufficient Resources
```bash
# Start with lower resources
minikube start --cpus=2 --memory=4096

# Check available resources
minikube status
```

#### 3. Job Fails to Complete
```bash
# Check pod logs
kubectl logs -l job-name=semgrep-scan-once -n semgrep-dev

# Check pod events
kubectl describe pod -l job-name=semgrep-scan-once -n semgrep-dev

# Check if image can be pulled
kubectl get pods -n semgrep-dev -o wide
```

#### 4. Permission Issues (Linux/macOS)
```bash
# Make sure Docker daemon is running
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
# Then logout and login again
```

### Debug Commands
```bash
# Check Minikube logs
minikube logs

# Check cluster info
kubectl cluster-info

# Check node status
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Access Minikube dashboard
minikube dashboard
```

## 🧹 Cleanup

### Remove Deployment
```bash
# Uninstall Helm release
helm uninstall semgrep-job -n semgrep-dev

# Delete namespace
kubectl delete namespace semgrep-dev
```

### Stop/Delete Minikube
```bash
# Stop Minikube (preserves cluster)
minikube stop

# Delete Minikube cluster
minikube delete

# Delete all Minikube profiles
minikube delete --all
```

## 🔧 Configuration

### Environment Variables

For non-dev environments, set the Semgrep token:

```bash
# Linux/macOS
export SEMGREP_TOKEN="your_token_here"

# Windows PowerShell
$env:SEMGREP_TOKEN = "your_token_here"

# Windows Command Prompt
set SEMGREP_TOKEN=your_token_here
```

### Custom Values

You can override values by editing the environment-specific files:
- `environments/dev/values.yaml`
- `environments/staging/values.yaml`
- `environments/prod/values.yaml`

Or pass custom values:
```bash
helm upgrade --install semgrep-job ./k8s-jobs \
  -f environments/dev/values.yaml \
  --set semgrep.configPath=/custom/path \
  --set resources.limits.memory=4Gi \
  -n semgrep-dev
```

## 📊 Monitoring

### Real-time Monitoring
```bash
# Watch job status
watch kubectl get jobs -n semgrep-dev

# Watch pod status
watch kubectl get pods -n semgrep-dev

# Follow logs
kubectl logs -f job/semgrep-scan-once -n semgrep-dev
```

### Access Minikube Dashboard
```bash
# Open Kubernetes dashboard
minikube dashboard

# Get dashboard URL
minikube dashboard --url
```

## 🎯 Success Indicators

Your local deployment is successful when you see:

- ✅ Minikube status shows "Running"
- ✅ kubectl context is "minikube"
- ✅ Namespace "semgrep-dev" exists
- ✅ Job "semgrep-scan-once" is created
- ✅ Job status shows "Complete"
- ✅ Pod logs show Semgrep scan results
- ✅ No error events in the namespace

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Minikube logs: `minikube logs`
3. Check pod events: `kubectl describe pod -n semgrep-dev`
4. Verify all prerequisites are installed and running
5. Try with a fresh Minikube cluster: `minikube delete && minikube start`
