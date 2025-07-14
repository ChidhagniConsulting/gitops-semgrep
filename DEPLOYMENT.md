# GitOps Semgrep - Local Minikube Deployment Guide

## 🚀 Quick Start

### Prerequisites
- ✅ Minikube running locally
- ✅ kubectl configured for Minikube
- ✅ Helm installed

### Deploy with Your Semgrep Token

```bash
# Deploy to dev environment with your token
./deploy-local.sh dev semgrep_dummy_token_1234567890abcdef1234567890abcdef

# Or deploy to other environments
./deploy-local.sh beta your-token-here
./deploy-local.sh prod your-token-here
```

### Deploy without Token (Basic Scan)

```bash
# Deploy with basic scanning (no token required)
./deploy-local.sh dev
```

## 📋 Manual Deployment

If you prefer manual commands:

```bash
# 1. Set your token as environment variable
export SEMGREP_TOKEN="your-actual-token-here"

# 2. Create temporary values file
cp environments/dev/values.yaml /tmp/custom-values.yaml
sed -i "s|\${SEMGREP_APP_TOKEN}|$SEMGREP_TOKEN|g" /tmp/custom-values.yaml

# 3. Deploy with Helm
helm upgrade --install semgrep-scan ./k8s-jobs \
  --values /tmp/custom-values.yaml \
  --wait

# 4. Check status
kubectl get jobs,pods -l app=semgrep

# 5. View logs
kubectl logs -f job/semgrep-scan
```

## 🔧 Configuration Options

### Environment Files
- `environments/dev/values.yaml` - Development configuration
- `environments/beta/values.yaml` - Beta configuration  
- `environments/prod/values.yaml` - Production configuration

### Customization
You can modify the values files to:
- Change resource limits (CPU/Memory)
- Update scan rules path
- Modify job restart policy
- Set custom job names

## 📊 Monitoring

### Check Deployment Status
```bash
kubectl get jobs -l app=semgrep
kubectl get pods -l app=semgrep
```

### View Real-time Logs
```bash
kubectl logs -f job/semgrep-scan
```

### Get Detailed Information
```bash
kubectl describe job semgrep-scan
kubectl describe pod -l app=semgrep
```

## 🧹 Cleanup

### Remove Deployment
```bash
helm uninstall semgrep-scan
```

### Clean All Resources
```bash
kubectl delete jobs,pods -l app=semgrep
```

## 🎯 Using GitHub Issue Templates

1. Go to GitHub Issues → New Issue
2. Select "Deploy Semgrep to Local Minikube"
3. Fill out the form with your preferences
4. Create the issue
5. Download the generated deployment package
6. Run the provided scripts locally

## 🔒 Security Notes

- ✅ Tokens are handled via environment variables
- ✅ No secrets stored in Git repository
- ✅ Temporary files are cleaned up automatically
- ✅ GitHub push protection prevents accidental token commits

## 🆘 Troubleshooting

### Minikube Not Running
```bash
minikube start
minikube status
```

### Helm Issues
```bash
helm version
helm list
```

### Pod Issues
```bash
kubectl describe pod -l app=semgrep
kubectl logs pod-name
```

### Job Stuck
```bash
kubectl delete job semgrep-scan
# Then redeploy
```

## 📝 Example Usage

```bash
# Quick deployment with your token
./deploy-local.sh dev semgrep_dummy_token_1234567890abcdef1234567890abcdef

# Monitor the deployment
kubectl logs -f job/semgrep-scan

# Clean up when done
helm uninstall semgrep-scan
```
