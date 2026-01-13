# Helm Chart Releases

This directory contains packaged Helm charts for the cat-api application.

## Charts

- **app-0.1.0.tgz** - Umbrella chart for the complete cat-api application
  - Includes backend (FastAPI) and PostgreSQL database subcharts
  - Manages ingress, networking, and cross-service communication
  
- **back-0.1.0.tgz** - Backend application chart (FastAPI)
  - Handles deployment of the cat-api backend service
  - Configures database connections and environment variables
  
- **postgres-0.1.0.tgz** - PostgreSQL database chart
  - StatefulSet with persistent storage
  - Includes ConfigMap, Secret, Service, and PVC resources

## Repository Index

The `index.yaml` file provides Helm repository metadata for all packaged charts. 

### Adding as a Local Repository

```bash
helm repo add cat-api file:///Users/mariakochenkova/Documents/PROJECTS/DevOps/helm/releases
helm repo update cat-api
```

### Installing Charts

#### Install the complete umbrella chart:
```bash
helm install cat-api cat-api/app --namespace cat-api-ns
```

#### Install only the backend:
```bash
helm install cat-api-backend cat-api/back --namespace cat-api-ns
```

#### Install only PostgreSQL:
```bash
helm install cat-api-postgres cat-api/postgres --namespace cat-api-ns
```

## Customization

Each chart can be customized using `values.yaml` files:

```bash
helm install cat-api cat-api/app \
  --namespace cat-api-ns \
  --values custom-values.yaml
```

## Chart Dependencies

The `app` chart automatically manages its subcharts:
- `back` (condition: `back.enabled`)
- `postgres` (condition: `postgres.enabled`)

Conditionally disable subcharts:

```bash
helm install cat-api cat-api/app \
  --set back.enabled=true \
  --set postgres.enabled=false \
  --namespace cat-api-ns
```

## Release Notes

### Version 0.1.0
- Initial release
- Umbrella chart with backend and database subcharts
- Full Helm best practices implementation
- Externalized configuration via values.yaml
- Ingress support with configurable hosts and paths

---

**Generated**: 2026-01-12
**Location**: `/Users/mariakochenkova/Documents/PROJECTS/DevOps/helm/releases/`
