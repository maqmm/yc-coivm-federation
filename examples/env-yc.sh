#!/bin/bash

# Get absolute path of the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Profile settings (change if needed)
YC_PROFILE=""

# If profile is set, use it directly in commands
export YC_TOKEN=$(yc iam create-token --profile "$YC_PROFILE")
export TF_VAR_YC_CLOUD_ID=$(yc config get cloud-id --profile "$YC_PROFILE")
export TF_VAR_YC_FOLDER_ID=$(yc config get folder-id --profile "$YC_PROFILE")
export TF_VAR_YC_ORGANIZATION_ID=$(yc resource-manager cloud get "$TF_VAR_YC_CLOUD_ID" --profile "$YC_PROFILE" --format=json | jq -r .organization_id)

# Debug output
echo "Script directory: $SCRIPT_DIR"

# Function to generate random password
generate_password() {
    LC_ALL=C tr -dc 'A-Za-z0-9!#$%&*()-_=+' </dev/urandom | head -c 16
}

# Function to update password in file
update_password_in_file() {
    local file=$1
    local password=$2
    if [ -f "$file" ]; then
        sed -i.bak '/kc_adm_pass[[:space:]]*=[[:space:]]*""/s/""/"'"$password"'"/' "$file"
        return 0
    else
        echo "Warning: File not found: $file"
        return 1
    fi
}

# Look for main.tf in parent directories
find_main_tf() {
    local current_dir="$1"
    local search_dir
    
    # First, try direct paths relative to script location
    DEPLOY_MAIN_TF="$current_dir/keycloak-deploy/main.tf"
    CONFIG_MAIN_TF="$current_dir/keycloak-config/main.tf"
    
    # If not found, try parent directory
    if [ ! -f "$DEPLOY_MAIN_TF" ] && [ ! -f "$CONFIG_MAIN_TF" ]; then
        search_dir="$(dirname "$current_dir")"
        DEPLOY_MAIN_TF="$search_dir/keycloak-deploy/main.tf"
        CONFIG_MAIN_TF="$search_dir/keycloak-config/main.tf"
    fi
    
    echo "Looking for main.tf in:"
    echo "  $DEPLOY_MAIN_TF"
    echo "  $CONFIG_MAIN_TF"
}

# Find main.tf files
find_main_tf "$SCRIPT_DIR"

# Check if files exist
if [ ! -f "$DEPLOY_MAIN_TF" ] && [ ! -f "$CONFIG_MAIN_TF" ]; then
    echo "Error: Cannot find main.tf file in keycloak-deploy or keycloak-config"
    echo "Script directory: $SCRIPT_DIR"
    exit 1
fi

# Check if files exist and need password
DEPLOY_NEEDS_PASSWORD=0
CONFIG_NEEDS_PASSWORD=0

if [ -f "$DEPLOY_MAIN_TF" ]; then
    if grep -q '^[[:space:]]*kc_adm_pass[[:space:]]*=[[:space:]]*""' "$DEPLOY_MAIN_TF"; then
        DEPLOY_NEEDS_PASSWORD=1
    fi
    MAIN_TF="$DEPLOY_MAIN_TF"
fi

if [ -f "$CONFIG_MAIN_TF" ]; then
    if grep -q '^[[:space:]]*kc_adm_pass[[:space:]]*=[[:space:]]*""' "$CONFIG_MAIN_TF"; then
        CONFIG_NEEDS_PASSWORD=1
    fi
    MAIN_TF="${MAIN_TF:-$CONFIG_MAIN_TF}"
fi

# Generate and update password if needed
if [ $DEPLOY_NEEDS_PASSWORD -eq 1 ] || [ $CONFIG_NEEDS_PASSWORD -eq 1 ]; then
    NEW_PASSWORD=$(generate_password)
    echo "Generated new password for Keycloak admin"
    
    if [ $DEPLOY_NEEDS_PASSWORD -eq 1 ]; then
        update_password_in_file "$DEPLOY_MAIN_TF" "$NEW_PASSWORD"
        echo "Updated password in keycloak-deploy/main.tf"
    fi
    
    if [ $CONFIG_NEEDS_PASSWORD -eq 1 ]; then
        update_password_in_file "$CONFIG_MAIN_TF" "$NEW_PASSWORD"
        echo "Updated password in keycloak-config/main.tf"
    fi
fi

# Get zone name from terraform file
if [ -f "$MAIN_TF" ]; then
    ZONE_NAME=$(grep "dns_zone_name" "$MAIN_TF" | awk -F'"' '{print $2}')
    if [ -n "$ZONE_NAME" ]; then
        DNS_ZONE=$(yc dns zone get "$ZONE_NAME" --profile "$YC_PROFILE" | grep 'zone:' | awk '{print $2}' | sed 's/\.$//')
        HOSTNAME=$(grep "kc_hostname" "$MAIN_TF" | awk -F'"' '{print $2}')

        if [ -n "$DNS_ZONE" ] && [ -n "$HOSTNAME" ]; then
            DOMAIN="${HOSTNAME}.${DNS_ZONE}"
            CERT_ID=$(yc cm certificates list --profile "$YC_PROFILE" \
                --format="json" | \
                jq -r '.[] | select(.status == "ISSUED" and (.domains | any(. == "'$DOMAIN'"))) | .id' \
                | head -n1)

            if [ -n "$CERT_ID" ]; then
                export TF_VAR_CERTIFICATE_ID="$CERT_ID"
            fi
        fi
    fi
fi

# Print configuration
echo "CLI profile:     ${YC_PROFILE:-current}"
echo "Organization ID: $TF_VAR_YC_ORGANIZATION_ID"
echo "Cloud ID:        $TF_VAR_YC_CLOUD_ID"
echo "Folder ID:       $TF_VAR_YC_FOLDER_ID"
echo "Cert ID:         ${CERT_ID:-not found}"