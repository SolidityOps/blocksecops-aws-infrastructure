#!/bin/bash

# Deploy Solidity Security Infrastructure to Local Environment (Minikube)

set -e

echo "🚀 Deploying Solidity Security Infrastructure to Local Environment..."
echo "================================================================"

# Check if minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo "❌ Minikube is not running. Please start minikube first."
    echo "   Run: minikube start --memory=16384 --cpus=6"
    exit 1
fi

echo "✅ Minikube is running"

# Check if kubectl is configured
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ kubectl is not configured properly"
    exit 1
fi

echo "✅ kubectl is configured"

# Install CRDs first
echo "📦 Installing CRDs via Helm..."
helm upgrade --install infrastructure-crds ./helm/crds --create-namespace || {
    echo "❌ Failed to install CRDs"
    exit 1
}

echo "✅ CRDs installed successfully"

# Wait for CRDs to be available
echo "⏳ Waiting for CRDs to be ready..."
sleep 30

# Deploy all services
echo "🏗️  Deploying all infrastructure services..."
kubectl apply -k k8s/overlays/local || {
    echo "❌ Failed to deploy infrastructure"
    exit 1
}

echo "✅ Infrastructure deployed successfully"

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n postgresql-local || true
kubectl wait --for=condition=available --timeout=300s deployment --all -n redis-local || true
kubectl wait --for=condition=available --timeout=300s deployment --all -n ingress-nginx || true
kubectl wait --for=condition=available --timeout=300s deployment --all -n cert-manager-local || true
kubectl wait --for=condition=available --timeout=300s deployment --all -n prometheus-local || true
kubectl wait --for=condition=available --timeout=300s deployment --all -n grafana-local || true
kubectl wait --for=condition=available --timeout=300s deployment --all -n argocd-local || true

echo "📊 Deployment Status:"
echo "=================="
echo "PostgreSQL: $(kubectl get pods -n postgresql-local --no-headers 2>/dev/null | wc -l) pods"
echo "Redis: $(kubectl get pods -n redis-local --no-headers 2>/dev/null | wc -l) pods"
echo "NGINX Ingress: $(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | wc -l) pods"
echo "cert-manager: $(kubectl get pods -n cert-manager-local --no-headers 2>/dev/null | wc -l) pods"
echo "Prometheus: $(kubectl get pods -n prometheus-local --no-headers 2>/dev/null | wc -l) pods"
echo "Grafana: $(kubectl get pods -n grafana-local --no-headers 2>/dev/null | wc -l) pods"
echo "ArgoCD: $(kubectl get pods -n argocd-local --no-headers 2>/dev/null | wc -l) pods"

echo ""
echo "🎉 Local deployment completed successfully!"
echo "📝 Access URLs:"
echo "   Grafana: https://grafana-local.minikube.local (admin/admin)"
echo "   ArgoCD: kubectl port-forward -n argocd-local svc/argocd-server 8080:80"
echo "   Prometheus: kubectl port-forward -n prometheus-local svc/prometheus 9090:9090"
echo ""
echo "💡 To add minikube.local entries to /etc/hosts:"
echo "   echo \"$(minikube ip) grafana-local.minikube.local\" | sudo tee -a /etc/hosts"
echo ""
echo "🧹 To cleanup: ./cleanup-local.sh"