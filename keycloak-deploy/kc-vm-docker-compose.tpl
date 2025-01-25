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
      - KC_HTTPS_CERTIFICATE_FILE=/usr/local/etc/certs/cert-pub-chain.pem
      - KC_HTTPS_CERTIFICATE_KEY_FILE=/usr/local/etc/certs/cert-priv-key.pem
    volumes:
      - /home/${VM_USER}/cert.pem:/usr/local/etc/certs/cert-pub-chain.pem
      - /home/${VM_USER}/key.pem:/usr/local/etc/certs/cert-priv-key.pem
    command: start-dev