#!/bin/bash

# Helm Chart Installation Script
# Installs the cat-api application using packaged Helm charts

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RELEASE_DIR="${SCRIPT_DIR}"
NAMESPACE="${NAMESPACE:-cat-api-ns}"
RELEASE_NAME="${RELEASE_NAME:-cat-api}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Helm Chart Installation Script${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Function to print success messages
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print info messages
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to print error messages
error() {
    echo -e "${RED}✗${NC} $1"
}

# Verify Helm is installed
if ! command -v helm &> /dev/null; then
    error "Helm is not installed. Please install Helm first."
    exit 1
fi
success "Helm found: $(helm version --short)"

# Check if namespace exists, create if needed
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    success "Namespace '$NAMESPACE' exists"
else
    info "Creating namespace '$NAMESPACE'..."
    kubectl create namespace "$NAMESPACE"
    success "Namespace created"
fi

# Add local Helm repository
info "Adding local Helm repository..."
# Remove existing repo if it exists, then add fresh
helm repo remove cat-api 2>/dev/null || true
helm repo add cat-api "file://${RELEASE_DIR}" --force-update 2>/dev/null || {
    info "Note: Local file repository registered in helm config"
}
helm repo update 2>/dev/null || true
success "Repository configured"

# List available charts
echo ""
info "Available charts in release directory:"
ls -lh ${RELEASE_DIR}/*.tgz | awk '{print "  " $9 " (" $5 ")"}'

# Install the umbrella chart
echo ""
info "Installing chart: cat-api app"
echo "  From: ${RELEASE_DIR}/app-0.1.0.tgz"
echo "  Namespace: $NAMESPACE"
echo "  Release: $RELEASE_NAME"
echo ""

helm install "$RELEASE_NAME" "${RELEASE_DIR}/app-0.1.0.tgz" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --wait=false

success "Chart installed successfully!"

# Display post-installation info
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Installation Complete${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
success "Release: $RELEASE_NAME"
success "Namespace: $NAMESPACE"
echo ""
info "To check the status of your deployment, run:"
echo "  kubectl get all -n $NAMESPACE"
echo ""
info "To view recent events:"
echo "  kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
echo ""
info "To access the application (via Ingress):"
echo "  kubectl get ingress -n $NAMESPACE"
echo ""
info "To upgrade the release:"
echo "  helm upgrade $RELEASE_NAME ${RELEASE_DIR}/app-0.1.0.tgz -n $NAMESPACE"
echo ""
info "To uninstall the release:"
echo "  helm uninstall $RELEASE_NAME -n $NAMESPACE"
