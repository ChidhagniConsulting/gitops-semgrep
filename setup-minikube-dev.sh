#!/bin/bash

# Minikube Development Setup Script
# This script helps set up and test the Semgrep GitOps pipeline locally

set -e

echo "🚀 Setting up Minikube for Semgrep GitOps Development"

# Check if Minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube is not installed. Please install it first:"
    echo "   https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first:"
    echo "   https://kubernetes.io/docs/tasks/tools/install-kubectl/"
    exit 1
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install it first:"
    echo "   https://helm.sh/docs/intro/install/"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Start Minikube
echo "🚀 Starting Minikube cluster..."
minikube start --cpus=4 --memory=8192 --driver=docker || echo "Minikube already running"

# Check Minikube status
echo "📊 Minikube status:"
minikube status

# Configure kubectl context
echo "🔧 Configuring kubectl context..."
kubectl config use-context minikube
kubectl cluster-info

# Create namespace
NAMESPACE="semgrep-dev"
echo "📦 Creating namespace: $NAMESPACE"
kubectl get ns $NAMESPACE || kubectl create ns $NAMESPACE

# Deploy Semgrep job
echo "🚀 Deploying Semgrep job to Minikube..."
helm upgrade --install semgrep-job ./k8s-jobs \
  -f environments/dev/values.yaml \
  --set environment=dev \
  --set github.repository=ChidhagniConsulting/gitops-semgrep \
  -n $NAMESPACE \
  --wait --timeout=10m

# Verify deployment
echo "🔍 Verifying deployment..."
kubectl get all -n $NAMESPACE
kubectl get jobs -n $NAMESPACE

# Wait for job completion
echo "⏳ Waiting for Semgrep job to complete..."
kubectl wait --for=condition=complete job/semgrep-scan-once \
  -n $NAMESPACE \
  --timeout=600s || echo "Job may still be running"

# View logs
echo "📋 === SEMGREP LOGS ==="
kubectl logs job/semgrep-scan-once -n $NAMESPACE --all-containers=true || echo "No logs available yet"

# Health check
echo "🏥 Performing health check..."
kubectl get pods -n $NAMESPACE -o wide

echo "✅ Minikube setup and deployment completed!"
echo ""
echo "📋 Useful commands:"
echo "  kubectl get jobs -n $NAMESPACE"
echo "  kubectl logs job/semgrep-scan-once -n $NAMESPACE --all-containers=true"
echo "  kubectl describe job semgrep-scan-once -n $NAMESPACE"
echo "  minikube status"
echo "  helm list -n $NAMESPACE" 