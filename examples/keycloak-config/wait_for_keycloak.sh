
#!/bin/bash

# Настройки по умолчанию
HTTPS_PORT=8443
MAX_RETRIES=60
RETRY_INTERVAL=1

# Получаем kc_fqdn из main.tf
KC_FQDN=$(grep 'kc_fqdn *= *"' main.tf | sed -E 's/.*"([^"]+)".*/\1/')

# Проверяем, нашли ли переменную
if [[ -z "$KC_FQDN" ]]; then
    echo "Ошибка: не удалось найти переменную kc_fqdn в main.tf"
    exit 1
fi

echo "Ожидание доступности Keycloak на $KC_FQDN:$HTTPS_PORT"

check_health() {
    # Игнорируем stderr (где появляется ошибка HTTP/2 header) и проверяем только статус
    curl --head -k -fsS "https://${KC_FQDN}:${HTTPS_PORT}" 2>/dev/null | grep -q "HTTP/2 200"
    return $?
}

wait_for_health() {
    local attempts=0
    while [ $attempts -lt $MAX_RETRIES ]; do
        if check_health; then
            echo "Keycloak доступен и отвечает на HTTPS запросы!"
            return 0
        fi
        attempts=$((attempts + 1))
        echo "Попытка $attempts/$MAX_RETRIES: Ожидание Keycloak..."
        sleep $RETRY_INTERVAL
    done
    echo "Ошибка: Keycloak не запустился за $MAX_RETRIES попыток"
    return 1
}

wait_for_health
exit $?
