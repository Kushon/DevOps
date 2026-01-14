#!/bin/bash

set -e

echo "Deploying Redis Helm chart..."

helm upgrade --install \
    redis . \
    -n redis --create-namespace

echo "✓ Redis deployment complete"
echo ""
echo "Services:"
echo "  - Master: redis-master (headless)"
echo "  - Replicas: redis-replicas (ClusterIP)"
echo ""
echo "Check status:"
echo "  kubectl get pods -n redis"
echo "  kubectl get svc -n redis"
echo ""
echo "Connect to Redis:"
echo "  kubectl run -it --rm redis-cli --image=redis:7 --restart=Never -- redis-cli -h redis-master.redis.svc.cluster.local -p 6379"
