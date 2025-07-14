# Local Minikube Deployment Script (PowerShell)
# This script replicates the GitHub Actions deploy-minikube job locally

param(
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"

# Configuration
$NAMESPACE = "semgrep-$Environment"
$CHART_PATH = "./k8s-jobs"
$VALUES_FILE = "environments/$Environment/values.yaml"

Write-Host "🚀 Starting Local Minikube Deployment..." -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Namespace: $NAMESPACE" -ForegroundColor Cyan
Write-Host "Values file: $VALUES_FILE" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

# Check if Minikube is installed
try {
    $null = Get-Command minikube -ErrorAction Stop
    Write-Host "✅ Minikube found" -ForegroundColor Green
} catch {
    Write-Host "❌ Minikube is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   Windows: choco install minikube" -ForegroundColor Yellow
    Write-Host "   Or download from: https://minikube.sigs.k8s.io/docs/start/" -ForegroundColor Yellow
    exit 1
}

# Check if kubectl is installed
try {
    $null = Get-Command kubectl -ErrorAction Stop
    Write-Host "✅ kubectl found" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   Windows: choco install kubernetes-cli" -ForegroundColor Yellow
    exit 1
}

# Check if Helm is installed
try {
    $null = Get-Command helm -ErrorAction Stop
    Write-Host "✅ Helm found" -ForegroundColor Green
} catch {
    Write-Host "❌ Helm is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   Windows: choco install kubernetes-helm" -ForegroundColor Yellow
    exit 1
}

# Check if values file exists
if (-not (Test-Path $VALUES_FILE)) {
    Write-Host "❌ Values file not found: $VALUES_FILE" -ForegroundColor Red
    Write-Host "Available environments:" -ForegroundColor Yellow
    if (Test-Path "environments") {
        Get-ChildItem "environments" | ForEach-Object { Write-Host "   $($_.Name)" }
    } else {
        Write-Host "   No environments directory found" -ForegroundColor Red
    }
    exit 1
}

Write-Host "✅ All prerequisites met" -ForegroundColor Green
Write-Host ""

# Start Minikube
Write-Host "🚀 Starting Minikube cluster..." -ForegroundColor Green
try {
    minikube start --cpus=4 --memory=8192 --driver=docker
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️ Minikube start failed, trying with different settings..." -ForegroundColor Yellow
        minikube start --cpus=2 --memory=4096 --driver=docker
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start Minikube"
        }
    }
} catch {
    Write-Host "❌ Failed to start Minikube. Please check your Docker installation." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Minikube started successfully" -ForegroundColor Green
minikube status
Write-Host ""

# Configure kubectl context
Write-Host "🔧 Configuring kubectl context..." -ForegroundColor Yellow
kubectl config use-context minikube
kubectl cluster-info
Write-Host ""

# Create namespace
Write-Host "📦 Creating namespace: $NAMESPACE" -ForegroundColor Yellow
kubectl get ns $NAMESPACE 2>$null
if ($LASTEXITCODE -ne 0) {
    kubectl create ns $NAMESPACE
}
Write-Host "✅ Namespace ready" -ForegroundColor Green
Write-Host ""

# Set Semgrep Token
Write-Host "🔑 Setting up Semgrep configuration..." -ForegroundColor Yellow
$TOKEN_OVERRIDE = ""
if ($Environment -eq "dev") {
    Write-Host "Using dev token from values.yaml" -ForegroundColor Cyan
} else {
    Write-Host "⚠️ For $Environment environment, you may need to set SEMGREP_TOKEN environment variable" -ForegroundColor Yellow
    $SEMGREP_TOKEN = $env:SEMGREP_TOKEN
    if ($SEMGREP_TOKEN) {
        $TOKEN_OVERRIDE = "--set semgrep.token=$SEMGREP_TOKEN"
        Write-Host "✅ Using SEMGREP_TOKEN environment variable" -ForegroundColor Green
    } else {
        Write-Host "❌ SEMGREP_TOKEN environment variable not set for $Environment" -ForegroundColor Red
        Write-Host "Please set it: `$env:SEMGREP_TOKEN='your_token_here'" -ForegroundColor Yellow
        exit 1
    }
}
Write-Host ""

# Deploy to Minikube
Write-Host "🚀 Deploying to Minikube ($Environment environment)..." -ForegroundColor Green
$helmArgs = @(
    "upgrade", "--install", "semgrep-job", $CHART_PATH,
    "-f", $VALUES_FILE,
    "--set", "environment=$Environment",
    "--set", "github.repository=local/gitops-semgrep",
    "-n", $NAMESPACE,
    "--wait", "--timeout=10m"
)

if ($TOKEN_OVERRIDE) {
    $helmArgs += $TOKEN_OVERRIDE.Split(' ')
}

& helm @helmArgs

Write-Host "✅ Deployment completed" -ForegroundColor Green
Write-Host ""

# Verify deployment
Write-Host "🔍 Verifying deployment..." -ForegroundColor Yellow
kubectl get all -n $NAMESPACE
Write-Host ""
kubectl get jobs -n $NAMESPACE
Write-Host ""

# Wait for Job Completion
Write-Host "⏳ Waiting for Semgrep job to complete..." -ForegroundColor Yellow
kubectl wait --for=condition=complete job/semgrep-scan-once -n $NAMESPACE --timeout=600s
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ Job may still be running or failed" -ForegroundColor Yellow
}
Write-Host ""

# View deployment logs
Write-Host "📋 === DEPLOYMENT STATUS ===" -ForegroundColor Cyan
kubectl get jobs -n $NAMESPACE
Write-Host ""
Write-Host "📋 === SEMGREP LOGS ===" -ForegroundColor Cyan
kubectl logs job/semgrep-scan-once -n $NAMESPACE --all-containers=true
if ($LASTEXITCODE -ne 0) {
    Write-Host "No logs available yet" -ForegroundColor Yellow
}
Write-Host ""

# Health check
Write-Host "🏥 Performing health check..." -ForegroundColor Yellow
Write-Host "=== CLUSTER INFO ===" -ForegroundColor Cyan
kubectl cluster-info
Write-Host ""
Write-Host "=== NAMESPACE STATUS ===" -ForegroundColor Cyan
kubectl get ns $NAMESPACE -o wide
Write-Host ""
Write-Host "=== PODS STATUS ===" -ForegroundColor Cyan
kubectl get pods -n $NAMESPACE -o wide
Write-Host ""
Write-Host "=== JOBS STATUS ===" -ForegroundColor Cyan
kubectl get jobs -n $NAMESPACE -o wide
Write-Host ""
Write-Host "=== EVENTS ===" -ForegroundColor Cyan
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | Select-Object -Last 10
Write-Host ""

# Deployment validation summary
Write-Host "📋 === DEPLOYMENT VALIDATION SUMMARY ===" -ForegroundColor Green
$minikubeStatus = (minikube status | Select-String "host:").ToString().Split()[1]
Write-Host "✅ Minikube cluster: $minikubeStatus" -ForegroundColor Green
$currentContext = kubectl config current-context
Write-Host "✅ Kubernetes context: $currentContext" -ForegroundColor Green
Write-Host "✅ Namespace: $NAMESPACE" -ForegroundColor Green
Write-Host "✅ Environment: $Environment" -ForegroundColor Green

# Check job status
$JOB_STATUS = kubectl get job semgrep-scan-once -n $NAMESPACE -o jsonpath='{.status.conditions[0].type}' 2>$null
if ($LASTEXITCODE -ne 0) { $JOB_STATUS = "NotFound" }
Write-Host "✅ Job status: $JOB_STATUS" -ForegroundColor Green

# Count pods
$POD_COUNT = (kubectl get pods -n $NAMESPACE --no-headers 2>$null | Measure-Object).Count
Write-Host "✅ Pods created: $POD_COUNT" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Local deployment to Minikube completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📖 Useful commands:" -ForegroundColor Cyan
Write-Host "   View logs: kubectl logs job/semgrep-scan-once -n $NAMESPACE" -ForegroundColor Yellow
Write-Host "   Check status: kubectl get all -n $NAMESPACE" -ForegroundColor Yellow
Write-Host "   Delete deployment: helm uninstall semgrep-job -n $NAMESPACE" -ForegroundColor Yellow
Write-Host "   Stop Minikube: minikube stop" -ForegroundColor Yellow
Write-Host "   Delete cluster: minikube delete" -ForegroundColor Yellow
