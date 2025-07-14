# GitOps Semgrep - CI/CD with ARC Self-Hosted Runners

This repository is configured with **Actions Runner Controller (ARC)** self-hosted runners that automatically deploy your Semgrep application to your local Minikube cluster.

## 🏗️ Architecture

```
GitHub Repository (Push/PR) 
    ↓
GitHub Actions Workflow
    ↓
ARC Self-Hosted Runner (in local Minikube)
    ↓
Deploy Semgrep Job (to same Minikube cluster)
```

## 🚀 Automated Deployment Workflows

### 1. **Main Deployment Workflow** (`deploy-semgrep.yml`)

**Triggers:**
- ✅ **Push to `main` branch** → Deploys to `prod` environment
- ✅ **Push to `develop` branch** → Deploys to `beta` environment  
- ✅ **Push to other branches** → Deploys to `dev` environment
- ✅ **Pull Requests to `main`** → Deploys to `dev` environment
- ✅ **Manual trigger** → Choose environment and optional Semgrep token

**What it does:**
1. Runs on your local ARC self-hosted runner
2. Checks Minikube connectivity
3. Deploys Semgrep application using Helm
4. Waits for job completion
5. Shows deployment logs
6. Cleans up on failure

### 2. **Test Runner Workflow** (`test-runner.yml`)

**Trigger:** Manual only
**Purpose:** Test that ARC runners are working correctly

### 3. **Cleanup Workflow** (`cleanup-semgrep.yml`)

**Trigger:** Manual only  
**Purpose:** Clean up all Semgrep deployments from Minikube

## 🔄 How It Works

### When you commit and push code:

1. **Code Push** → GitHub detects the push
2. **Workflow Triggers** → GitHub Actions starts the deployment workflow
3. **ARC Runner Scales** → A new runner pod starts in your local Minikube
4. **Deployment Runs** → The runner executes your `deploy-local.sh` script
5. **Semgrep Deploys** → Your application deploys to the same Minikube cluster
6. **Runner Scales Down** → After completion, the runner pod terminates

## 📋 Prerequisites

✅ **Already Configured:**
- Minikube cluster running locally
- ARC (Actions Runner Controller) installed
- Self-hosted runners registered with GitHub
- kubectl and Helm available in runners

## 🎯 Usage Examples

### Automatic Deployment (on push):
```bash
# Deploy to dev environment
git checkout feature-branch
git add .
git commit -m "Add new Semgrep rules"
git push origin feature-branch

# Deploy to prod environment  
git checkout main
git add .
git commit -m "Release new version"
git push origin main
```

### Manual Deployment:
1. Go to **Actions** tab in GitHub
2. Select **"Deploy Semgrep to Local Minikube"**
3. Click **"Run workflow"**
4. Choose environment and optionally provide Semgrep token
5. Click **"Run workflow"**

### Testing Runners:
1. Go to **Actions** tab in GitHub
2. Select **"Test ARC Runner"**  
3. Click **"Run workflow"**

### Cleanup:
1. Go to **Actions** tab in GitHub
2. Select **"Cleanup Semgrep Deployments"**
3. Click **"Run workflow"**

## 🔧 Environment Configuration

| Branch | Environment | Config File |
|--------|-------------|-------------|
| `main` | `prod` | `environments/prod/values.yaml` |
| `develop` | `beta` | `environments/beta/values.yaml` |
| Others | `dev` | `environments/dev/values.yaml` |

## 📊 Monitoring Deployments

### From GitHub:
- Check **Actions** tab for workflow status
- View logs in real-time during execution

### From Local Machine:
```bash
# Check runner status
kubectl get pods -n arc-systems
kubectl get pods -n arc-runners

# Check Semgrep deployments
kubectl get jobs -l app=semgrep
kubectl get pods -l app=semgrep

# View Semgrep logs
kubectl logs job/semgrep-scan

# Check Helm releases
helm list
```

## 🔐 Secrets Configuration

If you need to use a real Semgrep token:

1. Go to **Repository Settings** → **Secrets and variables** → **Actions**
2. Add secret: `SEMGREP_APP_TOKEN`
3. Update workflow to use: `${{ secrets.SEMGREP_APP_TOKEN }}`

## 🚨 Troubleshooting

### Runner Issues:
```bash
# Check ARC controller logs
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set-controller

# Check listener logs  
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set
```

### Deployment Issues:
```bash
# Check job status
kubectl describe job semgrep-scan

# Check pod logs
kubectl logs -l app=semgrep

# Manual cleanup
helm uninstall semgrep-scan
```

## 🎉 Benefits

✅ **Local Development** - Everything runs on your local Minikube  
✅ **No External Dependencies** - No need for cloud runners  
✅ **Fast Execution** - Direct access to local cluster  
✅ **Cost Effective** - No GitHub Actions minutes consumed  
✅ **Full Control** - Complete control over runner environment  
✅ **Automatic Scaling** - Runners scale up/down as needed
