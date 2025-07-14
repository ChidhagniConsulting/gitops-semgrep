# Deploy GitOps-Semgrep to Your Local Minikube

This guide shows you how to deploy your gitops-semgrep project to your existing local Minikube cluster.

## 🚀 Quick Start

### Prerequisites
- ✅ Minikube running locally
- ✅ kubectl configured
- ✅ Helm installed
- ✅ Docker running

### Deploy Commands

#### Linux/macOS:
```bash
# Make script executable (first time only)
chmod +x deploy-local.sh

# Deploy to dev environment
./deploy-local.sh dev
```

#### Windows PowerShell:
```powershell
# Deploy to dev environment
.\deploy-local.ps1 -Environment dev
```

#### Manual Deployment:
```bash
# 1. Ensure correct context
kubectl config use-context minikube

# 2. Create namespace
kubectl create namespace semgrep-dev

# 3. Deploy with Helm
helm upgrade --install semgrep-job ./k8s-jobs \
  -f environments/dev/values.yaml \
  --set environment=dev \
  --set github.repository=local/gitops-semgrep \
  -n semgrep-dev \
  --wait --timeout=10m
```

## 🔍 Verify Deployment

```bash
# Check deployment status
kubectl get all -n semgrep-dev

# View job status
kubectl get jobs -n semgrep-dev

# Check pod logs
kubectl logs job/semgrep-scan-once -n semgrep-dev

# Follow logs in real-time
kubectl logs -f job/semgrep-scan-once -n semgrep-dev

# View in dashboard
minikube dashboard
```

## 📋 Expected Results

### Successful Deployment:
```
✅ Minikube cluster: Running
✅ Kubernetes context: minikube
✅ Namespace: semgrep-dev
✅ Job status: Complete
✅ Pods created: 1
```

### Semgrep Scan Results:
```
📋 === SEMGREP LOGS ===
[Semgrep scan output showing findings or "No issues found"]
```

## 🧹 Cleanup

```bash
# Remove deployment
helm uninstall semgrep-job -n semgrep-dev

# Delete namespace
kubectl delete namespace semgrep-dev
```

## 🔧 Troubleshooting

### Check Minikube Status:
```bash
minikube status
kubectl cluster-info
```

### View Events:
```bash
kubectl get events -n semgrep-dev --sort-by='.lastTimestamp'
```

### Debug Pod Issues:
```bash
kubectl describe pod -l job-name=semgrep-scan-once -n semgrep-dev
```

## 🎯 Environments

- **dev**: Uses token from values.yaml (for local testing)
- **staging**: Requires `SEMGREP_TOKEN` environment variable
- **prod**: Requires `SEMGREP_TOKEN` environment variable

### For staging/prod:
```bash
# Set token
export SEMGREP_TOKEN="your_token_here"

# Deploy
./deploy-local.sh staging
```

## 📖 What Gets Deployed

1. **Namespace**: `semgrep-{environment}`
2. **Job**: `semgrep-scan-once` 
3. **Pod**: Runs Semgrep scan with your rules
4. **ConfigMaps**: Contains scan configuration
5. **Secrets**: Environment-specific tokens (if provided)

The deployment will scan your codebase using the rules in the `rules/` directory and report any security findings.
