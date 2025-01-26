#!/bin/bash

# default settings
HTTPS_PORT=8443
MAX_RETRIES=120
RETRY_INTERVAL=1

# parse kc_fqdn & kc_port from main.tf
KC_FQDN=$(grep 'kc_fqdn *= *"' main.tf | sed -E 's/.*"([^"]+)".*/\1/')
HTTPS_PORT=$(grep 'kc_port *= *"' main.tf | sed -E 's/.*"([^"]+)".*/\1/')

# validate values
if [[ -z "$KC_FQDN" ]]; then
    echo "ERROR: could not find variable kc_fqdn in main.tf"
    exit 1
fi
if [[ -z "$HTTPS_PORT" ]]; then
    echo "ERROR: could not find variable kc_port in main.tf"
    exit 1
fi

echo "Waiting for Keycloak to be available: $KC_FQDN:$HTTPS_PORT"

check_health() {
    # ignore stderr (HTTP/2 header) and check code only
    curl --head -k -fsS "https://${KC_FQDN}:${HTTPS_PORT}" 2>/dev/null | grep -q "HTTP/2 200"
    return $?
}

wait_for_health() {
    local attempts=0
    while [ $attempts -lt $MAX_RETRIES ]; do
        if check_health; then
            echo "Keycloak is available and responds to HTTPS requests!"
            return 0
        fi
        attempts=$((attempts + 1))
        echo "Try $attempts/$MAX_RETRIES: Wait Keycloak..."
        sleep $RETRY_INTERVAL
    done
    echo "ERROR: Keycloak did not start after $MAX_RETRIES attempts"
    return 1
}

wait_for_health
exit $?
