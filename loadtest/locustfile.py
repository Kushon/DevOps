"""
Locust load test for the cat-api backend.

Targets read endpoints (получение ресурсов):
  - GET /                       — список всех котов (основной)
  - GET /cats?cat_name=<name>   — поиск по имени

Запуск через ingress Traefik. Чтобы обойти 5-секундную задержку
mDNS-резолва домена `.local` на macOS, бьём в http://localhost:8080
и подменяем заголовок Host на cat-api.local (Traefik роутит по Host).

Пример (headless):
  locust -f loadtest/locustfile.py --host http://localhost:8080 \
      --headless -u 200 -r 20 --run-time 2m --csv loadtest/results_200
"""
from locust import HttpUser, task, between


class CatApiUser(HttpUser):
    # Пауза между запросами одного пользователя
    wait_time = between(0.1, 0.5)

    def on_start(self):
        # Host-заголовок для роутинга через Traefik ingress.
        # Можно переопределить переменной окружения TARGET_HOST.
        self.client.headers.update({"Host": "cat-api.local"})

    @task(3)
    def list_cats(self):
        # Основной эндпоинт «получение ресурсов»
        self.client.get("/", name="GET /")

    @task(1)
    def search_cat(self):
        self.client.get("/cats?cat_name=alpha", name="GET /cats?cat_name")
