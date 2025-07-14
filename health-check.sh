#!/bin/bash

echo "🔍 GitOps Semgrep Deployment Health Check"
echo "=========================================="

ENV=${1:-dev}
NAMESPACE="semgrep-${ENV}"

echo "📋 Checking namespace: ${NAMESPACE}"
if kubectl get ns ${NAMESPACE} >/dev/null 2>&1; then
    echo "✅ Namespace exists"
else
    echo "❌ Namespace missing"
    echo "💡 Create it with: kubectl create namespace ${NAMESPACE}"
    exit 1
fi

echo ""
echo "📋 Checking Helm release:"
if helm list -n ${NAMESPACE} | grep -q semgrep-scan; then
    echo "✅ Helm release found"
    helm list -n ${NAMESPACE}
else
    echo "❌ No Helm release found"
    echo "💡 Deploy with issue creation or manual workflow"
fi

echo ""
echo "📋 Checking jobs:"
if kubectl get jobs -n ${NAMESPACE} >/dev/null 2>&1; then
    echo "✅ Jobs found"
    kubectl get jobs -n ${NAMESPACE}
else
    echo "❌ No jobs found"
fi

echo ""
echo "📋 Checking pods:"
if kubectl get pods -n ${NAMESPACE} >/dev/null 2>&1; then
    echo "✅ Pods found"
    kubectl get pods -n ${NAMESPACE}
else
    echo "❌ No pods found"
fi

echo ""
echo "📋 Recent events:"
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | tail -5 2>/dev/null || echo "❌ No events"

echo ""
echo "📋 ARC Runner Status:"
echo "Controller pods:"
kubectl get pods -n arc-systems | grep arc-gha-rs-controller || echo "❌ No ARC controller"
echo "Active runners:"
kubectl get pods -n arc-runners | grep runner || echo "ℹ️ No active runners (normal when idle)"

echo ""
echo "🎯 Summary for ${NAMESPACE}:"

# Find the actual Semgrep job name
JOB_NAME=$(kubectl get jobs -n ${NAMESPACE} -l app=semgrep -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "$JOB_NAME" ]; then
    echo "📋 Found Semgrep job: $JOB_NAME"

    # Check if job has succeeded
    SUCCEEDED=$(kubectl get job/$JOB_NAME -n ${NAMESPACE} -o jsonpath='{.status.succeeded}' 2>/dev/null || echo "0")
    SPEC_COMPLETIONS=$(kubectl get job/$JOB_NAME -n ${NAMESPACE} -o jsonpath='{.spec.completions}' 2>/dev/null || echo "1")

    if [ "$SUCCEEDED" = "1" ] && [ "$SUCCEEDED" = "$SPEC_COMPLETIONS" ]; then
        echo "🎉 Deployment SUCCESSFUL - Semgrep scan completed!"
        echo "📋 View logs: kubectl logs job/$JOB_NAME -n ${NAMESPACE}"
        echo "📊 Job completed successfully with 1/1 completions"
    else
        # Check for failure conditions
        FAILED=$(kubectl get job/$JOB_NAME -n ${NAMESPACE} -o jsonpath='{.status.failed}' 2>/dev/null || echo "0")
        if [ "$FAILED" -gt "0" ]; then
            echo "❌ Deployment FAILED - Job failed"
            echo "📋 Check status: kubectl describe job/$JOB_NAME -n ${NAMESPACE}"
        else
            echo "⏳ Deployment IN PROGRESS"
            echo "📋 Current status: $SUCCEEDED/$SPEC_COMPLETIONS completions"
            echo "📋 Check status: kubectl describe job/$JOB_NAME -n ${NAMESPACE}"
        fi
    fi
else
    echo "❌ No Semgrep job found - deployment may have failed"
    echo "💡 Try creating a new issue to trigger deployment"
fi
