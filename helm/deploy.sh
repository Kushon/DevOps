#!/bin/bash

set -a
source .env
set +a

# echo "foo: ref+vault://secrets/db#POSTGRES_PASSWORD" | vals eval -f -

helm secrets \
    --backend vals \
    --evaluate-templates \
    upgrade --install my-vault hashicorp/vault \
    --namespace vault \
    --create-namespace \
    -f vault_values.yaml
