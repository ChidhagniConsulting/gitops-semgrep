#!/bin/bash

# Local Minikube Deployment Script for GitOps Semgrep
# Usage: ./deploy-local.sh [environment] [semgrep-token]
# Example: ./deploy-local.sh dev semgrep_dummy_token_1234567890abcdef1234567890abcdef

set -e

echo "🚀 GitOps Semgrep - Local Minikube Deployment"
echo "=============================================="

# Check if Minikube is running
echo "📋 Checking Minikube status..."
if ! minikube status > /dev/null 2>&1; then
    echo "❌ Minikube is not running. Please start it first:"
    echo "   minikube start"
    exit 1
fi
echo "✅ Minikube is running"

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi
echo "✅ Helm is available"

# Set default values
ENVIRONMENT=${1:-dev}
SEMGREP_TOKEN=${2:-""}

echo ""
echo "📋 Configuration:"
echo "   Environment: $ENVIRONMENT"
if [ -n "$SEMGREP_TOKEN" ]; then
    echo "   Semgrep Token: ***provided***"
else
    echo "   Semgrep Token: not provided (basic scan)"
fi

# Check if environment configuration exists
if [ ! -f "./environments/$ENVIRONMENT/values.yaml" ]; then
    echo "❌ Environment configuration not found: ./environments/$ENVIRONMENT/values.yaml"
    echo "Available environments:"
    ls -la ./environments/
    exit 1
fi

# Create temporary values file with token
TEMP_VALUES="/tmp/semgrep-values-$ENVIRONMENT.yaml"
cp "./environments/$ENVIRONMENT/values.yaml" "$TEMP_VALUES"

# Replace token placeholder if provided
if [ -n "$SEMGREP_TOKEN" ]; then
    echo "🔑 Setting Semgrep token..."
    sed -i "s|\${SEMGREP_APP_TOKEN}|$SEMGREP_TOKEN|g" "$TEMP_VALUES"
else
    echo "⚠️  No Semgrep token provided. Using placeholder (scan may be limited)"
    sed -i "s|\${SEMGREP_APP_TOKEN}|dummy-token-for-basic-scan|g" "$TEMP_VALUES"
fi

echo ""
echo "🚀 Deploying Semgrep job..."
helm upgrade --install semgrep-scan ./k8s-jobs \
    --values "$TEMP_VALUES" \
    --wait \
    --timeout=300s

echo "✅ Deployment completed!"

# Clean up temporary file
rm -f "$TEMP_VALUES"

echo ""
echo "📊 Checking deployment status..."
kubectl get jobs -l app=semgrep
kubectl get pods -l app=semgrep

echo ""
echo "📋 To view logs:"
echo "   kubectl logs -f job/semgrep-scan"
echo ""
echo "📋 To cleanup when done:"
echo "   helm uninstall semgrep-scan"
echo ""
echo "🎉 Deployment complete! Your Semgrep scan is running in Minikube."
