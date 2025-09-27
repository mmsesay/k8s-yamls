#!/bin/bash

# Test script for pgAdmin deployment
# This script helps verify that pgAdmin deploys without postfix and pkg_resources warnings

echo "🚀 Testing pgAdmin Deployment Configuration"
echo "============================================"

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed or not in PATH"
        exit 1
    fi
    echo "✅ kubectl is available"
}

# Function to deploy pgAdmin for testing
deploy_pgadmin() {
    local namespace=${1:-default}
    echo "📦 Deploying pgAdmin to namespace: $namespace"
    
    # Apply the kustomization
    if kubectl apply -k infrastructure/kustomization/base/; then
        echo "✅ pgAdmin base configuration applied successfully"
    else
        echo "❌ Failed to apply pgAdmin configuration"
        return 1
    fi
}

# Function to check pod status
check_pod_status() {
    local namespace=${1:-default}
    echo "🔍 Checking pod status..."
    
    # Wait for pod to be ready
    echo "⏳ Waiting for pgAdmin pod to be ready (timeout: 5 minutes)..."
    if kubectl wait --for=condition=ready pod -l app=pgadmin --timeout=300s -n $namespace; then
        echo "✅ pgAdmin pod is ready"
    else
        echo "❌ pgAdmin pod failed to become ready"
        return 1
    fi
}

# Function to check logs for warnings
check_logs() {
    local namespace=${1:-default}
    echo "📋 Checking pgAdmin logs for warnings..."
    
    # Get the pod name
    POD_NAME=$(kubectl get pods -l app=pgadmin -n $namespace -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$POD_NAME" ]; then
        echo "❌ Could not find pgAdmin pod"
        return 1
    fi
    
    echo "📄 Logs from pod: $POD_NAME"
    echo "================================="
    
    # Show recent logs
    kubectl logs $POD_NAME -n $namespace --tail=50
    
    echo "================================="
    echo "🔍 Checking for specific warnings..."
    
    # Check for postfix warnings
    if kubectl logs $POD_NAME -n $namespace 2>&1 | grep -i "postfix" > /dev/null; then
        echo "⚠️  WARNING: Postfix-related messages found in logs"
    else
        echo "✅ No postfix warnings found"
    fi
    
    # Check for pkg_resources warnings
    if kubectl logs $POD_NAME -n $namespace 2>&1 | grep -i "pkg_resources" > /dev/null; then
        echo "⚠️  WARNING: pkg_resources deprecation warnings found in logs"
    else
        echo "✅ No pkg_resources warnings found"
    fi
    
    # Check for crash/error messages
    if kubectl logs $POD_NAME -n $namespace 2>&1 | grep -i "error\|crash\|failed" > /dev/null; then
        echo "⚠️  WARNING: Error messages found in logs"
        kubectl logs $POD_NAME -n $namespace 2>&1 | grep -i "error\|crash\|failed"
    else
        echo "✅ No error messages found in logs"
    fi
}

# Function to clean up test deployment
cleanup() {
    local namespace=${1:-default}
    echo "🧹 Cleaning up test deployment..."
    
    if kubectl delete -k infrastructure/kustomization/base/; then
        echo "✅ Cleanup completed"
    else
        echo "⚠️  Cleanup had issues (this is normal if resources don't exist)"
    fi
}

# Main execution
main() {
    local namespace=${1:-default}
    
    echo "Starting pgAdmin deployment test..."
    echo "Namespace: $namespace"
    echo ""
    
    # Run checks
    check_kubectl
    
    echo ""
    deploy_pgadmin $namespace
    
    echo ""
    check_pod_status $namespace
    
    echo ""
    check_logs $namespace
    
    echo ""
    echo "🎉 Test completed!"
    echo ""
    echo "If you see ✅ for all checks above, your pgAdmin deployment is stable!"
    echo "If you see ⚠️  warnings, the configuration needs further adjustment."
    echo ""
    echo "To clean up the test deployment, run:"
    echo "  kubectl delete -k infrastructure/kustomization/base/"
}

# Help function
show_help() {
    echo "Usage: $0 [namespace]"
    echo ""
    echo "Arguments:"
    echo "  namespace    Kubernetes namespace to deploy to (default: default)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy to default namespace"
    echo "  $0 dev                # Deploy to dev namespace"
    echo "  $0 staging            # Deploy to staging namespace"
}

# Parse arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
