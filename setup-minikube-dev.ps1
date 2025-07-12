# Minikube Development Setup Script for Windows
# This script helps set up and test the Semgrep GitOps pipeline locally

Write-Host "🚀 Setting up Minikube for Semgrep GitOps Development" -ForegroundColor Green

# Check if Minikube is installed
if (!(Get-Command minikube -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Minikube is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   https://minikube.sigs.k8s.io/docs/start/" -ForegroundColor Yellow
    exit 1
}

# Check if kubectl is installed
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   https://kubernetes.io/docs/tasks/tools/install-kubectl/" -ForegroundColor Yellow
    exit 1
}

# Check if Helm is installed
if (!(Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Helm is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Prerequisites check passed" -ForegroundColor Green

# Start Minikube
Write-Host "🚀 Starting Minikube cluster..." -ForegroundColor Green
minikube start --cpus=4 --memory=8192 --driver=docker
if ($LASTEXITCODE -ne 0) {
    Write-Host "Minikube already running" -ForegroundColor Yellow
}

# Check Minikube status
Write-Host "📊 Minikube status:" -ForegroundColor Green
minikube status

# Configure kubectl context
Write-Host "🔧 Configuring kubectl context..." -ForegroundColor Green
kubectl config use-context minikube
kubectl cluster-info

# Create namespace
$NAMESPACE = "semgrep-dev"
Write-Host "📦 Creating namespace: $NAMESPACE" -ForegroundColor Green
kubectl get ns $NAMESPACE 2>$null || kubectl create ns $NAMESPACE

# Deploy Semgrep job
Write-Host "🚀 Deploying Semgrep job to Minikube..." -ForegroundColor Green
helm upgrade --install semgrep-job ./k8s-jobs `
  -f environments/dev/values.yaml `
  --set environment=dev `
  --set github.repository=ChidhagniConsulting/gitops-semgrep `
  -n $NAMESPACE `
  --wait --timeout=10m

# Verify deployment
Write-Host "🔍 Verifying deployment..." -ForegroundColor Green
kubectl get all -n $NAMESPACE
kubectl get jobs -n $NAMESPACE

# Wait for job completion
Write-Host "⏳ Waiting for Semgrep job to complete..." -ForegroundColor Green
kubectl wait --for=condition=complete job/semgrep-scan-once `
  -n $NAMESPACE `
  --timeout=600s
if ($LASTEXITCODE -ne 0) {
    Write-Host "Job may still be running" -ForegroundColor Yellow
}

# View logs
Write-Host "📋 === SEMGREP LOGS ===" -ForegroundColor Green
kubectl logs job/semgrep-scan-once -n $NAMESPACE --all-containers=true
if ($LASTEXITCODE -ne 0) {
    Write-Host "No logs available yet" -ForegroundColor Yellow
}

# Health check
Write-Host "🏥 Performing health check..." -ForegroundColor Green
kubectl get pods -n $NAMESPACE -o wide

Write-Host "✅ Minikube setup and deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Useful commands:" -ForegroundColor Cyan
Write-Host "  kubectl get jobs -n $NAMESPACE" -ForegroundColor White
Write-Host "  kubectl logs job/semgrep-scan-once -n $NAMESPACE --all-containers=true" -ForegroundColor White
Write-Host "  kubectl describe job semgrep-scan-once -n $NAMESPACE" -ForegroundColor White
Write-Host "  minikube status" -ForegroundColor White
Write-Host "  helm list -n $NAMESPACE" -ForegroundColor White 