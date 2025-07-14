#!/bin/bash

# Local Minikube Deployment Script
# This script replicates the GitHub Actions deploy-minikube job locally

set -e  # Exit on any error

# Configuration
ENVIRONMENT=${1:-dev}  # Default to dev if no argument provided
NAMESPACE="semgrep-${ENVIRONMENT}"
CHART_PATH="./k8s-jobs"
VALUES_FILE="environments/${ENVIRONMENT}/values.yaml"

echo "🚀 Starting Local Minikube Deployment..."
echo "Environment: ${ENVIRONMENT}"
echo "Namespace: ${NAMESPACE}"
echo "Values file: ${VALUES_FILE}"
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check if Minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube is not installed. Please install it first:"
    echo "   - macOS: brew install minikube"
    echo "   - Windows: choco install minikube"
    echo "   - Linux: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first:"
    echo "   - macOS: brew install kubectl"
    echo "   - Windows: choco install kubernetes-cli"
    echo "   - Linux: curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && sudo install kubectl /usr/local/bin/"
    exit 1
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install it first:"
    echo "   - macOS: brew install helm"
    echo "   - Windows: choco install kubernetes-helm"
    echo "   - Linux: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi

# Check if values file exists
if [ ! -f "${VALUES_FILE}" ]; then
    echo "❌ Values file not found: ${VALUES_FILE}"
    echo "Available environments:"
    ls -la environments/ 2>/dev/null || echo "No environments directory found"
    exit 1
fi

echo "✅ All prerequisites met"
echo ""

# Start Minikube
echo "🚀 Starting Minikube cluster..."
minikube start --cpus=4 --memory=8192 --driver=docker || {
    echo "⚠️ Minikube start failed, trying with different settings..."
    minikube start --cpus=2 --memory=4096 --driver=docker || {
        echo "❌ Failed to start Minikube. Please check your Docker installation."
        exit 1
    }
}

echo "✅ Minikube started successfully"
minikube status
echo ""

# Configure kubectl context
echo "🔧 Configuring kubectl context..."
kubectl config use-context minikube
kubectl cluster-info
echo ""

# Create namespace
echo "📦 Creating namespace: ${NAMESPACE}"
kubectl get ns ${NAMESPACE} 2>/dev/null || kubectl create ns ${NAMESPACE}
echo "✅ Namespace ready"
echo ""

# Set Semgrep Token (for local dev, we use the token from values.yaml)
echo "🔑 Setting up Semgrep configuration..."
if [ "${ENVIRONMENT}" == "dev" ]; then
    echo "Using dev token from values.yaml"
    TOKEN_OVERRIDE=""
else
    echo "⚠️ For ${ENVIRONMENT} environment, you may need to set SEMGREP_TOKEN environment variable"
    if [ -n "${SEMGREP_TOKEN}" ]; then
        TOKEN_OVERRIDE="--set semgrep.token=${SEMGREP_TOKEN}"
        echo "✅ Using SEMGREP_TOKEN environment variable"
    else
        echo "❌ SEMGREP_TOKEN environment variable not set for ${ENVIRONMENT}"
        echo "Please set it: export SEMGREP_TOKEN=your_token_here"
        exit 1
    fi
fi
echo ""

# Deploy to Minikube
echo "🚀 Deploying to Minikube (${ENVIRONMENT} environment)..."
helm upgrade --install semgrep-job ${CHART_PATH} \
    -f ${VALUES_FILE} \
    ${TOKEN_OVERRIDE} \
    --set environment=${ENVIRONMENT} \
    --set github.repository="local/gitops-semgrep" \
    -n ${NAMESPACE} \
    --wait --timeout=10m

echo "✅ Deployment completed"
echo ""

# Verify deployment
echo "🔍 Verifying deployment..."
kubectl get all -n ${NAMESPACE}
echo ""
kubectl get jobs -n ${NAMESPACE}
echo ""

# Wait for Job Completion
echo "⏳ Waiting for Semgrep job to complete..."
kubectl wait --for=condition=complete job/semgrep-scan-once \
    -n ${NAMESPACE} \
    --timeout=600s || echo "⚠️ Job may still be running or failed"
echo ""

# View deployment logs
echo "📋 === DEPLOYMENT STATUS ==="
kubectl get jobs -n ${NAMESPACE}
echo ""
echo "📋 === SEMGREP LOGS ==="
kubectl logs job/semgrep-scan-once -n ${NAMESPACE} --all-containers=true || echo "No logs available yet"
echo ""

# Health check
echo "🏥 Performing health check..."
echo "=== CLUSTER INFO ==="
kubectl cluster-info
echo ""
echo "=== NAMESPACE STATUS ==="
kubectl get ns ${NAMESPACE} -o wide
echo ""
echo "=== PODS STATUS ==="
kubectl get pods -n ${NAMESPACE} -o wide
echo ""
echo "=== JOBS STATUS ==="
kubectl get jobs -n ${NAMESPACE} -o wide
echo ""
echo "=== EVENTS ==="
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | tail -10
echo ""

# Deployment validation summary
echo "📋 === DEPLOYMENT VALIDATION SUMMARY ==="
echo "✅ Minikube cluster: $(minikube status | grep 'host:' | awk '{print $2}' || echo 'Running')"
echo "✅ Kubernetes context: $(kubectl config current-context)"
echo "✅ Namespace: ${NAMESPACE}"
echo "✅ Environment: ${ENVIRONMENT}"

# Check if job exists and get status
JOB_STATUS=$(kubectl get job semgrep-scan-once -n ${NAMESPACE} -o jsonpath='{.status.conditions[0].type}' 2>/dev/null || echo "NotFound")
echo "✅ Job status: ${JOB_STATUS}"

# Count pods
POD_COUNT=$(kubectl get pods -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
echo "✅ Pods created: ${POD_COUNT}"

echo ""
echo "🎉 Local deployment to Minikube completed successfully!"
echo ""
echo "📖 Useful commands:"
echo "   View logs: kubectl logs job/semgrep-scan-once -n ${NAMESPACE}"
echo "   Check status: kubectl get all -n ${NAMESPACE}"
echo "   Delete deployment: helm uninstall semgrep-job -n ${NAMESPACE}"
echo "   Stop Minikube: minikube stop"
echo "   Delete cluster: minikube delete"
