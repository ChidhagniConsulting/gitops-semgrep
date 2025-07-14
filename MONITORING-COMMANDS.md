# 📊 GitOps Semgrep Deployment Monitoring Commands

## 🔍 Check if Deployment is Working

### 1. **Check Namespaces**
```bash
# List all Semgrep namespaces
kubectl get namespaces | grep semgrep

# Expected output:
# semgrep-dev    Active   5m
# semgrep-beta   Active   3m
# semgrep-prod   Active   1m
```

### 2. **Check Jobs in Namespace**
```bash
# Check jobs in dev environment
kubectl get jobs -n semgrep-dev

# Check jobs in all Semgrep namespaces
kubectl get jobs -A | grep semgrep

# Expected output:
# semgrep-dev   semgrep-scan   1/1           30s        2m
```

### 3. **Check Pods Status**
```bash
# Check pods in dev environment
kubectl get pods -n semgrep-dev

# Check pods with more details
kubectl get pods -n semgrep-dev -o wide

# Expected output:
# NAME                    READY   STATUS      RESTARTS   AGE
# semgrep-scan-xxxxx      0/1     Completed   0          2m
```

### 4. **Check Helm Releases**
```bash
# List all Helm releases
helm list -A

# List Semgrep releases specifically
helm list -A | grep semgrep

# Expected output:
# semgrep-scan  semgrep-dev  1  2024-07-14 13:00:00  deployed  semgrep-0.1.0  1.0
```

## 📋 View Deployment Logs

### 1. **Job Logs**
```bash
# View Semgrep scan logs (dev environment)
kubectl logs job/semgrep-scan -n semgrep-dev

# View logs from specific pod
kubectl logs -n semgrep-dev -l app=semgrep

# Follow logs in real-time
kubectl logs job/semgrep-scan -n semgrep-dev -f
```

### 2. **Job Description**
```bash
# Get detailed job information
kubectl describe job/semgrep-scan -n semgrep-dev

# Get pod events
kubectl get events -n semgrep-dev --sort-by='.lastTimestamp'
```

## 🚀 ARC Runner Monitoring

### 1. **Check ARC Runner Status**
```bash
# Check ARC controller
kubectl get pods -n arc-systems

# Check runner scale set
kubectl get autoscalingrunnerset -n arc-runners

# Check active runners
kubectl get pods -n arc-runners
```

### 2. **ARC Runner Logs**
```bash
# Check ARC controller logs
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set-controller

# Check listener logs
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set
```

## 🔧 Troubleshooting Commands

### 1. **If Job is Stuck**
```bash
# Check job status
kubectl get job/semgrep-scan -n semgrep-dev -o yaml

# Check pod status
kubectl describe pod -n semgrep-dev -l app=semgrep

# Check resource usage
kubectl top pods -n semgrep-dev
```

### 2. **If Deployment Failed**
```bash
# Check Helm release status
helm status semgrep-scan -n semgrep-dev

# Check Helm release history
helm history semgrep-scan -n semgrep-dev

# Get Helm values used
helm get values semgrep-scan -n semgrep-dev
```

### 3. **Permission Issues**
```bash
# Check service account permissions
kubectl auth can-i create jobs --as=system:serviceaccount:arc-runners:arc-runner-set-gha-rs-no-permission -n semgrep-dev

# Check ClusterRoleBinding
kubectl describe clusterrolebinding arc-runner-binding
```

## 🧹 Cleanup Commands

### 1. **Remove Specific Deployment**
```bash
# Uninstall Helm release
helm uninstall semgrep-scan -n semgrep-dev

# Delete namespace (removes everything)
kubectl delete namespace semgrep-dev
```

### 2. **Clean All Semgrep Deployments**
```bash
# Remove all Semgrep namespaces
kubectl delete namespace semgrep-dev semgrep-beta semgrep-prod

# Or remove all namespaces with semgrep prefix
kubectl get namespaces -o name | grep semgrep | xargs kubectl delete
```

## 📈 Success Indicators

### ✅ **Deployment Successful When:**
1. **Namespace exists**: `kubectl get ns semgrep-dev`
2. **Job completed**: `kubectl get jobs -n semgrep-dev` shows `1/1` completions
3. **Pod completed**: `kubectl get pods -n semgrep-dev` shows `Completed` status
4. **Helm release deployed**: `helm list -n semgrep-dev` shows `deployed` status
5. **Logs available**: `kubectl logs job/semgrep-scan -n semgrep-dev` shows scan results

### ❌ **Common Failure Signs:**
1. **No namespace**: Namespace creation failed
2. **Job failed**: `kubectl get jobs` shows `0/1` completions
3. **Pod error**: `kubectl get pods` shows `Error` or `CrashLoopBackOff`
4. **Helm failed**: `helm list` shows `failed` status
5. **No logs**: `kubectl logs` returns empty or error

## 🎯 Quick Health Check Script

```bash
#!/bin/bash
echo "🔍 GitOps Semgrep Deployment Health Check"
echo "=========================================="

ENV=${1:-dev}
NAMESPACE="semgrep-${ENV}"

echo "📋 Checking namespace: ${NAMESPACE}"
kubectl get ns ${NAMESPACE} 2>/dev/null && echo "✅ Namespace exists" || echo "❌ Namespace missing"

echo "📋 Checking Helm release:"
helm list -n ${NAMESPACE} 2>/dev/null && echo "✅ Helm release found" || echo "❌ No Helm release"

echo "📋 Checking jobs:"
kubectl get jobs -n ${NAMESPACE} 2>/dev/null && echo "✅ Jobs found" || echo "❌ No jobs found"

echo "📋 Checking pods:"
kubectl get pods -n ${NAMESPACE} 2>/dev/null && echo "✅ Pods found" || echo "❌ No pods found"

echo "📋 Recent events:"
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | tail -5 2>/dev/null || echo "❌ No events"
```

Save this as `health-check.sh` and run: `./health-check.sh dev`
