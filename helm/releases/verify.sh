#!/bin/bash

# Helm Chart Release Verification Script
# Validates packaged charts and repository integrity

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RELEASE_DIR="${SCRIPT_DIR}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Helm Release Verification${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Function to print success messages
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print info messages
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to print warning messages
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print error messages
error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if charts exist
echo -e "${BLUE}1. Checking packaged charts...${NC}"
CHARTS=("app-0.1.0.tgz" "back-0.1.0.tgz" "postgres-0.1.0.tgz")
for chart in "${CHARTS[@]}"; do
    if [ -f "$RELEASE_DIR/$chart" ]; then
        SIZE=$(du -h "$RELEASE_DIR/$chart" | cut -f1)
        success "$chart ($SIZE)"
    else
        error "$chart - NOT FOUND"
        exit 1
    fi
done

# Check if index.yaml exists
echo -e "\n${BLUE}2. Checking repository index...${NC}"
if [ -f "$RELEASE_DIR/index.yaml" ]; then
    success "index.yaml exists"
    # Parse the index
    ENTRIES=$(grep "^  [a-z]*:" "$RELEASE_DIR/index.yaml" | wc -l)
    success "Found $ENTRIES chart entries"
else
    error "index.yaml - NOT FOUND"
    exit 1
fi

# Verify chart contents using helm template
echo -e "\n${BLUE}3. Verifying chart contents...${NC}"

# Extract and test app chart
info "Testing app chart..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
tar -xzf "$RELEASE_DIR/app-0.1.0.tgz" > /dev/null 2>&1
if helm template app ./app > /dev/null 2>&1; then
    success "app chart templates are valid"
else
    error "app chart template validation failed"
    exit 1
fi
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Verify chart signatures (if signed)
echo -e "\n${BLUE}4. Checking file integrity...${NC}"
for chart in "${CHARTS[@]}"; do
    if tar -tzf "$RELEASE_DIR/$chart" > /dev/null 2>&1; then
        success "$chart is valid tar archive"
    else
        error "$chart is corrupted"
        exit 1
    fi
done

# Display release summary
echo -e "\n${BLUE}======================================${NC}"
echo -e "${BLUE}  Release Summary${NC}"
echo -e "${BLUE}======================================${NC}\n"

success "All checks passed!"
echo ""
info "Release directory: $RELEASE_DIR"
info "Release date: $(date)"
echo ""
info "Charts available:"
helm search repo --defs="file://$RELEASE_DIR" 2>/dev/null || {
    cd "$RELEASE_DIR"
    echo "  - app-0.1.0"
    echo "  - back-0.1.0"
    echo "  - postgres-0.1.0"
}
echo ""
info "Installation command:"
echo "  bash $RELEASE_DIR/install.sh"
echo ""

# Calculate total size
TOTAL_SIZE=$(du -sh "$RELEASE_DIR" | cut -f1)
success "Total release size: $TOTAL_SIZE"
