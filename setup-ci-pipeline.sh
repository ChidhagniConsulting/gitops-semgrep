#!/bin/bash

# CI Pipeline Setup Script
# This script helps set up the environment for the CI pipeline

set -e

echo "🚀 Setting up CI Pipeline for Minikube Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_status "✅ Docker is installed"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    print_status "✅ kubectl is installed"
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm first."
        exit 1
    fi
    print_status "✅ Helm is installed"
    
    # Check Minikube
    if ! command -v minikube &> /dev/null; then
        print_error "Minikube is not installed. Please install Minikube first."
        exit 1
    fi
    print_status "✅ Minikube is installed"
}

# Validate file structure
validate_structure() {
    print_status "Validating project structure..."
    
    required_files=(
        ".github/workflows/ci-pipeline.yml"
        "k8s-jobs/Chart.yaml"
        "k8s-jobs/templates/semgrep-job.yaml"
        "environments/dev/values.yaml"
        "environments/staging/values.yaml"
        "environments/prod/values.yaml"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Required file missing: $file"
            exit 1
        fi
    done
    
    print_status "✅ All required files present"
}

# Test Minikube setup
test_minikube() {
    print_status "Testing Minikube setup..."
    
    # Stop any existing minikube
    minikube stop 2>/dev/null || true
    
    # Start minikube
    print_status "Starting Minikube cluster..."
    minikube start --cpus=4 --memory=8192 --driver=docker
    
    # Wait for cluster to be ready
    print_status "Waiting for cluster to be ready..."
    kubectl wait --for=condition=ready node --all --timeout=300s
    
    print_status "✅ Minikube cluster is ready"
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Create namespace
    kubectl create ns semgrep-dev --dry-run=client -o yaml | kubectl apply -f -
    
    # Test Helm chart
    print_status "Testing Helm chart..."
    helm lint ./k8s-jobs
    
    # Test template rendering
    print_status "Testing template rendering..."
    helm template ./k8s-jobs -f environments/dev/values.yaml | kubectl apply --dry-run=client -f -
    
    print_status "✅ Deployment test passed"
}

# Cleanup test resources
cleanup_test() {
    print_status "Cleaning up test resources..."
    
    # Delete test namespace
    kubectl delete ns semgrep-dev --ignore-not-found=true
    
    # Stop minikube
    minikube stop
    
    print_status "✅ Cleanup completed"
}

# Main execution
main() {
    echo "=========================================="
    echo "CI Pipeline Setup for Minikube Deployment"
    echo "=========================================="
    
    check_prerequisites
    validate_structure
    
    echo ""
    print_status "Starting Minikube test..."
    test_minikube
    test_deployment
    
    echo ""
    print_warning "Do you want to clean up test resources? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cleanup_test
    fi
    
    echo ""
    echo "=========================================="
    print_status "Setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Configure GitHub Secrets:"
    echo "   - SEMGREP_TOKEN_STAGING"
    echo "   - SEMGREP_TOKEN_PROD"
    echo ""
    echo "2. Push your code to trigger the CI pipeline"
    echo ""
    echo "3. Monitor the pipeline in GitHub Actions"
    echo "=========================================="
}

# Run main function
main "$@" 