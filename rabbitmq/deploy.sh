#!/bin/bash

set -e

# Load Vault credentials
set -a
source .env
set +a

echo "Authenticating with Vault..."
# Use provided token or generate one from AppRole
if [ -n "$VAULT_TOKEN" ]; then
  TOKEN=$VAULT_TOKEN
  echo "✓ Using provided VAULT_TOKEN"
else
  # Get token from AppRole
  TOKEN=$(curl -s -X POST \
    -d "role_id=$VAULT_ROLE_ID&secret_id=$VAULT_SECRET_ID" \
    $VAULT_ADDR/v1/auth/approle/login | jq -r '.auth.client_token')
  
  if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "❌ Failed to authenticate with Vault"
    exit 1
  fi
  echo "✓ AppRole authenticated"
fi

# Get credentials from Vault
echo "Fetching RabbitMQ credentials from Vault..."
RABBITMQ_USERNAME=$(curl -s -H "X-Vault-Token: $TOKEN" \
  $VAULT_ADDR/v1/secrets/data/rabbitmq | jq -r '.data.data.username // empty')

RABBITMQ_PASSWORD=$(curl -s -H "X-Vault-Token: $TOKEN" \
  $VAULT_ADDR/v1/secrets/data/rabbitmq | jq -r '.data.data.password // empty')

if [ -z "$RABBITMQ_USERNAME" ] || [ -z "$RABBITMQ_PASSWORD" ]; then
  echo "❌ Failed to retrieve RabbitMQ credentials from Vault"
  echo "   Please ensure the secret exists at: secrets/rabbitmq"
  echo "   With keys: username, password"
  exit 1
fi

echo "✓ Credentials retrieved"

# Create namespace
echo "Creating namespace..."
kubectl create namespace rabbitmq --dry-run=client -o yaml | kubectl apply -f -

# Create secret with credentials
echo "Creating RabbitMQ secret in Kubernetes..."
kubectl create secret generic rabbitmq-secret \
  --from-literal=username="$RABBITMQ_USERNAME" \
  --from-literal=password="$RABBITMQ_PASSWORD" \
  -n rabbitmq \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Secret created"

# Deploy RabbitMQ
echo "Deploying RabbitMQ Helm chart..."
helm upgrade --install \
    rabbitmq oci://registry-1.docker.io/cloudpirates/rabbitmq \
    -n rabbitmq --create-namespace \
    -f values.yaml

echo "✓ RabbitMQ deployment complete"
