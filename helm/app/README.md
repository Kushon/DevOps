# Cat API Helm Charts

Umbrella Helm chart для развёртывания cat-api приложения с PostgreSQL на Kubernetes.

## Структура проекта

```
helm/app/                          # Основной umbrella чарт
├── Chart.yaml                     # Метаданные чарта и зависимости
├── values.yaml                    # Глобальные значения (global, ingress, back, postgres)
├── templates/
│   ├── _helpers.tpl              # Хелпер-функции для имён и лейблов
│   ├── ingress.yaml              # Ingress для доступа к приложению
│   └── tests/
│       └── test-connection.yaml   # Helm test для проверки связности
│
├── charts/
│   ├── back/                      # Subchart для backend API
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── _helpers.tpl
│   │       ├── deployment.yaml   # FastAPI приложение
│   │       └── service.yaml      # ClusterIP сервис
│   │
│   └── postgres/                  # Subchart для PostgreSQL
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── pg_configmap.yaml
│           ├── pg_pvc.yaml
│           ├── pg_secret.yaml
│           ├── pg_service.yaml
│           └── pg_statefulset.yaml
```

## Быстрый старт

### 1. Установка зависимостей

```bash
cd helm/app
helm dependency update
```

### 2. Просмотр сгенерированных шаблонов

```bash
helm template app . --values values.yaml
```

### 3. Сухой запуск (dry-run)

```bash
helm install app . --dry-run=client
```

### 4. Развёртывание

```bash
helm install app . \
  --namespace cat-api-ns \
  --create-namespace
```

### 5. Обновление развёртывания

```bash
helm upgrade app . \
  --namespace cat-api-ns
```

### 6. Запуск тестов

```bash
helm test app --namespace cat-api-ns
```

## Значения (Values)

### Глобальные значения (`helm/app/values.yaml`)

#### `global`

```yaml
global:
  namespace: "cat-api-ns"           # Namespace для всех ресурсов
  image:
    registry: ""                     # Реестр образов (опционально)
    pullPolicy: "IfNotPresent"
  secret:
    externalSecret: false            # Использовать external secrets
    vaultPath: ""                    # Путь в Vault для helm-secrets
```

#### `ingress`

```yaml
ingress:
  enabled: true
  ingressClassName: "nginx"
  hosts:
    - host: "192.168.49.2"
      paths:
        - path: "/"
          pathType: "Prefix"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: "/"
```

#### `back` (Backend API)

```yaml
back:
  enabled: true
  replicas: 1
  image:
    repository: "cat-api"
    tag: "latest"
    pullPolicy: "Never"
  service:
    type: "ClusterIP"
    port: 8000
    targetPort: 8000
  database:
    protocol: "postgresql+asyncpg"
    host: "postgres-release-service.cat-api-ns.svc.cluster.local"
    port: "5432"
    name: "postgres"
    secretRef:
      name: "postgres-release-secrets"
      userKey: "POSTGRES_USER"
      passwordKey: "POSTGRES_PASSWORD"
```

#### `postgres` (Database)

```yaml
postgres:
  enabled: true
  image:
    repository: "postgres"
    tag: "15"
    pullPolicy: "IfNotPresent"
  secret:
    POSTGRES_PASSWORD: "postgres"
    POSTGRES_USER: "postgres"
  config:
    POSTGRES_DB: "postgres"
  statefulset:
    replicas: 1
    pvc:
      storage: "5Gi"
      accessModes: ["ReadWriteOnce"]
```

## Best Practices

### Структурирование Helm чартов

1. **Helpers** — используются для генерации имён и лейблов
2. **Quoted strings** — все строковые значения в values.yaml заключены в кавычки
3. **Standard labels** — используются `app.kubernetes.io/*` метки
4. **nindent для helpers** — корректное выравнивание при включении многострочных хелперов
5. **No hardcoded values** — все значения в values.yaml
6. **Namespace management** — использование глобального namespace или значения по умолчанию

### Структура Subcharts

- **back** — зависит от secret, созданного postgres чартом
- **postgres** — независимый чарт, создаёт Secret и ConfigMap
- **Зависимости** — явно описаны в Chart.yaml

## Интеграция с Vault и helm-secrets

### Подготовка к использованию helm-secrets

Для шифрования секретов используйте `helm-secrets`:

```bash
# Шифрование values файла
helm secrets enc helm/app/values.yaml

# Развёртывание с расшифровкой
helm secrets install app helm/app -f helm/app/values.yaml
```

Установите `vals` для интеграции с Vault:

```bash
brew install vals
```

В `values.yaml` используйте refs для Vault:

```yaml
secret:
  POSTGRES_PASSWORD: !vault "secret/data/postgres/password"
```

## Переменные окружения в deployment

Backend контейнер получает следующие переменные окружения:

- `DB_USER` — из Secret (postgres)
- `DB_PASS` — из Secret (postgres)
- `DB_HOST` — адрес PostgreSQL сервиса
- `DB_PORT` — порт PostgreSQL
- `DB_NAME` — имя базы данных
- `DATABASE_URL` — полная строка подключения (автоматически построена)

## Отладка

### Просмотр логов

```bash
# Backend
kubectl logs -n cat-api-ns deployment/app-back-deployment

# PostgreSQL
kubectl logs -n cat-api-ns statefulset/app-postgres-statefulset
```

### Port-forward

```bash
# Доступ к приложению
kubectl port-forward -n cat-api-ns svc/app-back-service 8000:8000

# Доступ к PostgreSQL
kubectl port-forward -n cat-api-ns svc/app-postgres-service 5432:5432
```

### Проверка ресурсов

```bash
# Все ресурсы в namespace
kubectl get all -n cat-api-ns

# Описание release
helm status app -n cat-api-ns
helm history app -n cat-api-ns
```

## Удаление

```bash
helm uninstall app -n cat-api-ns
kubectl delete namespace cat-api-ns
```

## Дополнительные ресурсы

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [helm-secrets](https://github.com/jkroepke/helm-secrets)
- [vals](https://github.com/variantdev/vals)
