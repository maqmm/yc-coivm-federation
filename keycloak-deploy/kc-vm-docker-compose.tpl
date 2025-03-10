services:
  keycloak:
    image: quay.io/keycloak/keycloak:${VER}
    ports:
      - "${PORT}:8443"
    environment:
      - KEYCLOAK_ADMIN=${KC_USER}
      - KEYCLOAK_ADMIN_PASSWORD=${KC_PASS}
      - KC_HOSTNAME=${KC_FQDN}
      - KC_HOSTNAME_STRICT=true
      - KC_HTTP_ENABLED=false
      - KC_HTTPS_CERTIFICATE_FILE=/usr/local/etc/certs/cert.pem
      - KC_HTTPS_CERTIFICATE_KEY_FILE=/usr/local/etc/certs/key.pem
    volumes:
      - /home/${VM_USER}/certs:/usr/local/etc/certs
    command: start-dev