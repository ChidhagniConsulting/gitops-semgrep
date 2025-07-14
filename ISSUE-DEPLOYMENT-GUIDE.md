# 🚀 Issue-Based Deployment Guide

## How to Deploy Using GitHub Issues

When you click **"New Issue"** in your repository, you can trigger automated deployments to your local Minikube cluster using your existing issue templates.

## 📋 Available Issue Templates

### 1. **"Deploy Semgrep to Local Minikube"** 
**Use this for:** Deploying Semgrep scans to your local cluster

**Required Information:**
- ✅ **Environment**: Choose `dev`, `beta`, or `prod`
- ✅ **What to Scan**: Choose scan target (Frontend, Backend, Shared, or All rules)

**Optional Information:**
- 🔑 **Semgrep Token**: Your Semgrep App Token for enhanced scanning
- ⚙️ **Custom Configuration**: Any Helm values overrides
- 📝 **Additional Notes**: Context or special requirements

### 2. **"Semgrep Input Types Required"**
**Use this for:** Configuring detailed Semgrep scanning parameters

**Required Information:**
- ✅ **Input Category**: Type of configuration needed
- ✅ **Target Environment**: `dev`, `beta`, `prod`, or `all`
- ✅ **Programming Languages**: Select languages to scan
- ✅ **Minimum Severity Level**: `INFO`, `WARNING`, `ERROR`, or `ALL`
- ✅ **Rule Sets**: Which rule sets to use (backend, frontend, shared)
- ✅ **Output Format**: Preferred output format

**Optional Information:**
- 📁 **Target Paths**: Specific files/directories to scan
- 🚫 **Exclude Paths**: Paths to exclude from scanning
- 🔧 **Custom Patterns**: Custom Semgrep rules in YAML
- 🌍 **Environment Variables**: Additional env vars needed
- ⏱️ **Timeout**: Maximum scan time in seconds
- ⚙️ **Scan Options**: Additional scanning preferences

## 🎯 Quick Start Examples

### Example 1: Simple Development Deployment
**When creating a new issue, fill in:**
```
Template: "Deploy Semgrep to Local Minikube"
Environment: dev
What to Scan: All rules (Frontend + Backend + Shared)
Semgrep Token: (leave empty for basic scan)
```

### Example 2: Production Deployment with Token
**When creating a new issue, fill in:**
```
Template: "Deploy Semgrep to Local Minikube"
Environment: prod
What to Scan: All rules (Frontend + Backend + Shared)
Semgrep Token: semgrep_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Custom Configuration:
  resources:
    limits:
      cpu: "2"
      memory: "4Gi"
```

### Example 3: Frontend-Only Scan
**When creating a new issue, fill in:**
```
Template: "Deploy Semgrep to Local Minikube"
Environment: dev
What to Scan: Frontend rules (JavaScript/TypeScript)
Additional Notes: Testing new frontend security rules
```

## 🔄 What Happens After You Create the Issue

1. **🤖 Automatic Detection**: GitHub Actions detects your new issue
2. **🏃 ARC Runner Starts**: A self-hosted runner pod starts in your local Minikube
3. **📝 Comment Added**: Bot adds a comment showing deployment progress
4. **🚀 Deployment Runs**: Your Semgrep application deploys to local Minikube
5. **📊 Status Updates**: Bot updates the issue with deployment status and logs
6. **✅ Auto-Close**: Issue closes automatically on successful deployment

## 📊 Monitoring Your Deployment

### In GitHub:
- **Issue Comments**: Real-time updates on deployment progress
- **Actions Tab**: Detailed workflow execution logs
- **Issue Status**: Automatically closed on success

### In Your Local Terminal:
```bash
# Check deployment status
kubectl get jobs -l app=semgrep
kubectl get pods -l app=semgrep

# View deployment logs
kubectl logs job/semgrep-scan

# Check ARC runner activity
kubectl get pods -n arc-runners
kubectl get pods -n arc-systems

# Cleanup when done
helm uninstall semgrep-scan
```

## 🔧 Advanced Configuration

### Custom Helm Values
In the **"Custom Configuration"** field, you can provide YAML overrides:
```yaml
resources:
  limits:
    cpu: "2"
    memory: "4Gi"
  requests:
    cpu: "1"
    memory: "2Gi"

semgrep:
  configPath: "/repo/rules/backend/"
  
job:
  restartPolicy: "Never"
```

### Environment Variables
In the **"Environment Variables"** field:
```
SEMGREP_APP_TOKEN=your_token_here
SEMGREP_BASELINE_REF=main
SEMGREP_TIMEOUT=600
```

## 🚨 Troubleshooting

### Issue Not Triggering Deployment
- ✅ Ensure issue has `deployment` or `minikube` label
- ✅ Check that ARC runners are healthy: `kubectl get pods -n arc-systems`
- ✅ Verify Minikube is running: `minikube status`

### Deployment Fails
- 📋 Check issue comments for error details
- 📋 View workflow logs in Actions tab
- 📋 Check runner logs: `kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set-controller`

### Cleanup Stuck Deployments
```bash
# Manual cleanup
helm uninstall semgrep-scan
kubectl delete jobs -l app=semgrep
kubectl delete pods -l app=semgrep
```

## 🎉 Benefits of Issue-Based Deployment

✅ **User-Friendly**: No need to remember complex commands  
✅ **Documented**: Each deployment is tracked as an issue  
✅ **Automated**: Fully automated from issue creation to deployment  
✅ **Flexible**: Support for different environments and configurations  
✅ **Transparent**: Real-time updates and logs in issue comments  
✅ **Local**: Everything runs on your local Minikube cluster
