# 🧪 Test Issue-Based Deployment

## ✅ Your Setup is Ready!

Your ARC runners are configured and ready to respond to GitHub issues. Here's how to test it:

## 🚀 Step-by-Step Test

### 1. **Commit and Push the Workflows**
First, make sure all the workflow files are committed:

```bash
git add .github/workflows/issue-triggered-deployment.yml
git add ISSUE-DEPLOYMENT-GUIDE.md
git add TEST-ISSUE-DEPLOYMENT.md
git commit -m "Add issue-triggered deployment workflow"
git push origin main
```

### 2. **Create a Test Issue**
1. Go to your repository: https://github.com/ChidhagniConsulting/gitops-semgrep
2. Click **"Issues"** tab
3. Click **"New Issue"**
4. Select **"Deploy Semgrep to Local Minikube"** template
5. Fill in the form:
   ```
   Environment: dev
   What to Scan: All rules (Frontend + Backend + Shared)
   Semgrep Token: (leave empty)
   Additional Notes: Testing ARC runner deployment
   ```
6. Click **"Submit new issue"**

### 3. **Watch the Magic Happen**
After creating the issue, you should see:

**In GitHub (within 30 seconds):**
- ✅ A bot comment appears on your issue saying "🚀 Deployment Started"
- ✅ A new workflow run appears in the Actions tab
- ✅ The workflow shows "Running" status

**In Your Local Terminal (within 1-2 minutes):**
```bash
# Watch ARC runner scale up
kubectl get pods -n arc-runners -w

# You should see a new runner pod starting:
# NAME                                    READY   STATUS    RESTARTS   AGE
# arc-runner-set-xxxxx-runner-xxxxx       0/1     Pending   0          5s
# arc-runner-set-xxxxx-runner-xxxxx       1/1     Running   0          30s
```

**In GitHub (after 3-5 minutes):**
- ✅ Bot updates the issue with deployment logs
- ✅ Issue automatically closes on successful deployment
- ✅ Workflow shows "Completed" status

### 4. **Verify Deployment in Minikube**
```bash
# Check if Semgrep job was created
kubectl get jobs -l app=semgrep

# Check Semgrep pods
kubectl get pods -l app=semgrep

# View Semgrep logs
kubectl logs job/semgrep-scan

# Check Helm release
helm list
```

## 🔍 Current ARC Status

Your ARC setup is healthy:
```
✅ ARC Controller: Running (arc-gha-rs-controller-9cc8c9544-7vjzg)
✅ Runner Scale Set: Configured (arc-runner-set)
✅ Current Runners: 0 (will scale up when needed)
✅ GitHub Integration: Connected with admin permissions
```

## 🎯 Expected Behavior

### When You Create an Issue:
1. **GitHub detects** the new issue with `minikube` or `deployment` label
2. **Workflow triggers** the `issue-triggered-deployment.yml` workflow
3. **ARC scales up** a new runner pod in your local Minikube
4. **Runner executes** the deployment steps:
   - Parses issue content
   - Checks Minikube connectivity
   - Deploys Semgrep using your `deploy-local.sh` script
   - Reports back to the issue
5. **Runner scales down** after completion

### Timeline:
- **0-30 seconds**: Issue created → Workflow triggered
- **30-60 seconds**: Runner pod starts → Begins deployment
- **2-5 minutes**: Deployment completes → Issue updated
- **5+ minutes**: Runner pod terminates → Resources cleaned up

## 🚨 Troubleshooting

### If No Runner Starts:
```bash
# Check ARC controller logs
kubectl logs -n arc-systems arc-gha-rs-controller-9cc8c9544-7vjzg

# Check if workflow triggered
# Go to: https://github.com/ChidhagniConsulting/gitops-semgrep/actions
```

### If Deployment Fails:
- Check the issue comments for error details
- View the workflow logs in GitHub Actions
- Verify Minikube is running: `minikube status`

## 🎉 Ready to Test!

Your setup is complete and ready for testing. Create an issue using the template and watch your ARC runners automatically deploy Semgrep to your local Minikube cluster!

**Next Steps:**
1. Commit and push the workflow files
2. Create a test issue
3. Watch the automated deployment happen
4. Enjoy your GitOps automation! 🚀
