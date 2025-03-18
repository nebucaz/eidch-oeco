#!/bin/bash

# Check if ID (directory name) is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <ID directory name>"

  echo "chosse one from './did':"
  # List directories inside ./keys
  #find ./did -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
  #exit 1
  PS3="Enter the number of the directory to select: "
  select ISSUER_ID in $(find ./did -mindepth 1 -maxdepth 1 -type d -exec basename {} \;); do
    if [ -z "$ISSUER_ID" ]; then
      echo "Invalid selection. Please select a valid directory."
    else
      break
    fi
  done
else
  # Use the provided ID if it's passed as a parameter
  ISSUER_ID="$1"
fi

# Assign directory name
#ISSUER_ID="$1"

# Path to private key
KEY_FILE="./did/${ISSUER_ID}/assert-key-01"

# Path to did-log key
DID_LOG="./did/${ISSUER_ID}/did.jsonl"

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
  echo "Private key file not found: $KEY_FILE"
  exit 1
fi

# Check JSONL file
if [ ! -f "$DID_LOG" ]; then
  echo "JSONL file not found: $DID_LOG"
  exit 1
fi

# Read and escape private key content
PRIVATE_KEY=$(awk '{printf "%s\\n", $0}' "$KEY_FILE")
ISSUER_DID=$(jq -r '.[3].value.id' "$DID_LOG")
if [ -z "$ISSUER_DID" ]; then
  echo "Failed to extract ID from $DID_LOG"
  exit 1
fi

CLIENT="ISSUER_MGMT"
SECRET=kW94KAL0D9Bwd3vrqvdHoJwMQRS0twWt

TOKEN=$(curl --url "http://localhost:7080/realms/master/protocol/openid-connect/token" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -d "client_id=${CLIENT}" \
    -d "client_secret=${SECRET}" \
    -d "grant_type=password"  \
    -d "username=issuer_user" \
    -d "password=issuer_user" \
    -d "scope=offline_access")

echo $TOKEN
ACCESS_TOKEN=$(echo $TOKEN | jq -r '.access_token')
REFRESH_TOKEN=$(echo $TOKEN | jq -r '.refresh_token')

# Generate SDJWT_KEY and set it as env variable:
#openssl ecparam -genkey -name prime256v1 -noout -out private.pem

# Generate public key
#openssl ec -in private.pem -pubout -out ec_public.pem
# SDJWT_KEY=$(awk '{printf "%s\\n", $0}' "private.pem")

# Generate .env file
cat > .env <<EOF
POSTGRES_USER="issuer_mgmt_user"
POSTGRES_PASS="secret"
POSTGRES_DB="issuer_db"
ID=$ISSUER_ID
ISSUER_DID=$ISSUER_DID
PARTNER_ID="7805a775-bac0-4726-ad2f-c68e8fefa05c"
STATUS_REGISTRY_CUSTOMER_KEY=$CLIENT
STATUS_REGISTRY_CUSTOMER_SECRET=$SECRET
STATUS_REGISTRY_BOOTSTRAP_REFRESH_TOKEN=$REFRESH_TOKEN
EXTERNAL_URL="http://issuer-oid4vci.home.rwpz.net"
STATUS_REGISTRY_API_URL="http://status-registry.home.rwpz.net"
EOF

echo ".env file generated successfully for ID=$ISSUER_ID"

