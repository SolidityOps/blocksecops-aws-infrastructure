#!/bin/bash

# CRD Installation Script for Local Development Environment
# This script installs all required CRDs for local overlays

set -e

echo "🚀 Installing CRDs for Local Development Environment"
echo "=================================================="

# Cert-Manager CRDs
echo "📦 Installing Cert-Manager CRDs..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.crds.yaml
echo "✅ Cert-Manager CRDs installed"

# External Secrets CRDs
echo "📦 Installing External Secrets CRDs..."
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
echo "✅ External Secrets CRDs installed"

echo ""
echo "🔍 Verifying CRD Installation..."
echo "Cert-Manager CRDs:"
kubectl get crd | grep cert-manager | wc -l | xargs echo "  Found CRDs:"

echo "External Secrets CRDs:"
kubectl get crd | grep external-secrets | wc -l | xargs echo "  Found CRDs:"

echo ""
echo "✅ All CRDs installed successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Deploy overlays: kubectl apply -k k8s/overlays/local/<overlay-name>/"
echo "   2. Verify deployments: kubectl get pods -A"