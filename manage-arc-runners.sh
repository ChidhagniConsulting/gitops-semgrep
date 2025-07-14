#!/bin/bash

echo "🏃 ARC Runner Management Script"
echo "==============================="

# Load configuration from file if it exists
if [ -f "arc-config.env" ]; then
    source arc-config.env
    echo "✅ Loaded configuration from arc-config.env"
fi

# Configuration - Update these values for your setup
GITHUB_TOKEN="${GITHUB_TOKEN:-YOUR_GITHUB_TOKEN_HERE}"
GITHUB_URL="${GITHUB_URL:-https://github.com/ChidhagniConsulting/gitops-semgrep}"

if [ "$GITHUB_TOKEN" = "YOUR_GITHUB_TOKEN_HERE" ]; then
    echo "❌ Error: Please configure GitHub token"
    echo "💡 Option 1: Set environment variable: GITHUB_TOKEN=your_token_here ./manage-arc-runners.sh status"
    echo "💡 Option 2: Create config file: cp arc-config.env.example arc-config.env (then edit with your token)"
    exit 1
fi

show_status() {
    echo "📊 Current ARC Runner Status:"
    echo "=============================="
    
    echo "🎛️ AutoScaling Runner Set:"
    kubectl get autoscalingrunnerset -n arc-runners
    
    echo ""
    echo "🏃 Runner Pods:"
    kubectl get pods -n arc-runners
    
    echo ""
    echo "📋 Runner Events:"
    kubectl get events -n arc-runners --sort-by='.lastTimestamp' | tail -5
}

set_ephemeral() {
    echo "🔄 Setting ARC runners to EPHEMERAL mode..."
    echo "Runners will start only when jobs are triggered and terminate after completion."
    
    helm upgrade arc-runner-set --namespace arc-runners \
        --set githubConfigUrl=$GITHUB_URL \
        --set githubConfigSecret.github_token=$GITHUB_TOKEN \
        --set minRunners=0 \
        --set maxRunners=5 \
        --set scaleDownDelaySecondsAfterScaleOut=30 \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
    
    echo "✅ ARC runners set to ephemeral mode"
    echo "💡 Runners will scale from 0 to 5 based on demand"
}

set_persistent() {
    echo "🔄 Setting ARC runners to PERSISTENT mode..."
    echo "At least 1 runner will always be running, scaling up to 3 as needed."
    
    helm upgrade arc-runner-set --namespace arc-runners \
        --set githubConfigUrl=$GITHUB_URL \
        --set githubConfigSecret.github_token=$GITHUB_TOKEN \
        --set minRunners=1 \
        --set maxRunners=3 \
        --set scaleDownDelaySecondsAfterScaleOut=600 \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
    
    echo "✅ ARC runners set to persistent mode"
    echo "💡 1 runner will always be running, scaling up to 3 as needed"
}

set_high_persistent() {
    echo "🔄 Setting ARC runners to HIGH PERSISTENT mode..."
    echo "2 runners will always be running, scaling up to 5 as needed."
    
    helm upgrade arc-runner-set --namespace arc-runners \
        --set githubConfigUrl=$GITHUB_URL \
        --set githubConfigSecret.github_token=$GITHUB_TOKEN \
        --set minRunners=2 \
        --set maxRunners=5 \
        --set scaleDownDelaySecondsAfterScaleOut=900 \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
    
    echo "✅ ARC runners set to high persistent mode"
    echo "💡 2 runners will always be running, scaling up to 5 as needed"
}

case "$1" in
    "status")
        show_status
        ;;
    "ephemeral")
        set_ephemeral
        echo ""
        echo "⏳ Waiting for changes to take effect..."
        sleep 10
        show_status
        ;;
    "persistent")
        set_persistent
        echo ""
        echo "⏳ Waiting for changes to take effect..."
        sleep 10
        show_status
        ;;
    "high-persistent")
        set_high_persistent
        echo ""
        echo "⏳ Waiting for changes to take effect..."
        sleep 10
        show_status
        ;;
    *)
        echo "Usage: $0 {status|ephemeral|persistent|high-persistent}"
        echo ""
        echo "Commands:"
        echo "  status          - Show current runner status"
        echo "  ephemeral       - Set runners to ephemeral (0 min, 5 max)"
        echo "  persistent      - Set runners to persistent (1 min, 3 max)"
        echo "  high-persistent - Set runners to high persistent (2 min, 5 max)"
        echo ""
        echo "Current status:"
        show_status
        ;;
esac
