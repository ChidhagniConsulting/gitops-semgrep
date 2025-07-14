#!/bin/bash

echo "🔧 Setting up ARC Runner Permissions for GitOps Semgrep"
echo "======================================================="

# Apply the ClusterRole
echo "📋 Creating ClusterRole..."
kubectl apply -f arc-runner-rbac.yaml

# Create the ClusterRoleBinding
echo "📋 Creating ClusterRoleBinding..."
kubectl create clusterrolebinding arc-runner-binding \
  --clusterrole=arc-runner-cluster-role \
  --serviceaccount=arc-runners:arc-runner-set-gha-rs-no-permission \
  --dry-run=client -o yaml | kubectl apply -f -

# Verify permissions
echo "📋 Verifying permissions..."
echo "Can create namespaces:"
kubectl auth can-i create namespaces --as=system:serviceaccount:arc-runners:arc-runner-set-gha-rs-no-permission

echo "Can create jobs:"
kubectl auth can-i create jobs --as=system:serviceaccount:arc-runners:arc-runner-set-gha-rs-no-permission -n default

echo "Can list pods:"
kubectl auth can-i list pods --as=system:serviceaccount:arc-runners:arc-runner-set-gha-rs-no-permission -n default

echo "✅ ARC Runner permissions setup complete!"
echo ""
echo "🚀 You can now create issues to trigger deployments!"
echo "   The ARC runners will have full permissions to:"
echo "   - Create namespaces (semgrep-dev, semgrep-beta, semgrep-prod)"
echo "   - Deploy Helm charts"
echo "   - Manage jobs, pods, and services"
echo "   - Monitor deployment status"
