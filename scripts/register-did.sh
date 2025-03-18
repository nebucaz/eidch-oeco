
#!/bin/bash

# according to https://swiyu-admin-ch.github.io/cookbooks/onboarding-base-and-trust-registry/

PARTNER_ID="7805a775-bac0-4726-ad2f-c68e8fefa05c"
BASE_ROOT="http://base-registry.home.rwpz.net"
BASE_AUTHORING_ROOT="http://authoring-base-registry.home.rwpz.net"
STATUS_ROOT="http://status-registry.home.rwpz.net"
STATUS_AUTHORING_ROOT="http://authoring-status-registry.home.rwpz.net"

# get access token
YOUR_AUTH_TOKEN=$(curl -s -d "client_id=eidch" -d "client_secret=iUsyfcM0MXH8oHLsAMOV1HgVeCHuPjJP" -d "grant_type=client_credentials"  "http://localhost:7080/realms/master/protocol/openid-connect/token" | jq -r '.access_token')

# register did space
HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/response.txt -H "Authorization: Bearer $YOUR_AUTH_TOKEN" -X POST "${BASE_AUTHORING_ROOT}/api/v1/entry/")

if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
  echo "Request failed with status: HTTP $HTTP_CODE"
  exit 1
fi

DID_SPACE=$(< /tmp/response.txt)
ID=$(echo "$DID_SPACE" | jq -r '.id')
echo "ID: ${ID}"

#IDENTIFIER_REGISTRY_URL="${BASE_ROOT}/api/v1/did/${ID}/did.jsonl"
IDENTIFIER_REGISTRY_URL=$(echo "$DID_SPACE" | jq -r '.files.DID_TDW.readUri')

echo "Registry URL: $IDENTIFIER_REGISTRY_URL"

# create DID
YOUR_GENERATED_DIDLOG=$(java -jar didtoolbox.jar create --identifier-registry-url "$IDENTIFIER_REGISTRY_URL")

# move away the keys
mkdir -p "./did"
mv .didtoolbox "./did/${ID}"

DID_LOG="./did/${ID}/did.jsonl"

echo "$YOUR_GENERATED_DIDLOG" > $DID_LOG

# Upload DID log
#   -X PUT "https://identifier-reg-api.trust-infra.swiyu-int.admin.ch/api/v1/identifier/business-entities/$YOUR_BUSINESS_ENTITY_ID/identifier-entries/$ID_FROM_PREVIOUS_STEP"

#IDENTIFIER_PUT_URL="${BASE_AUTHORING_ROOT}/api/v1/did/${ID}/did.jsonl"
IDENTIFIER_PUT_URL="${BASE_AUTHORING_ROOT}/api/v1/identifier/business-entities/swiyu-parner-id/identifier-entries/${ID}"

RESULT=$(curl -s -X PUT "${IDENTIFIER_PUT_URL}" \
    -H "Authorization: Bearer $YOUR_AUTH_TOKEN" \
    -H "Content-Type: application/jsonl+json" \
    -H 'Content-Type: application/json' \
    -d "${YOUR_GENERATED_DIDLOG}")

STATUS=$(echo "$RESULT" | jq -r '.status')
# check, if status active
if [ "$STATUS" != "ACTIVE" ]; then
    echo "Error: The status is not ACTIVE, it is $STATUS."
    exit 1

fi

echo "did ${ID} successfully registered"

# Initialize a status list
# curl -X POST 'http://localhost:8280/api/v1/status/business-entities/{businessEntityId}/status-list-entries/' \
#   -H 'accept: application/json' \
#   -H 'Authorization: Bearer your token' \
#   -d ''
# get status list entry /api/v1/statuslist/{datastoreEntryId}.jwt
#STATUS_SPACE=$(curl -s -X POST "http://localhost:8280/api/v1/entry/" \
#STATUS_SPACE=$(curl -s -X POST "${STATUS_AUTHORING_ROOT}/api/v1/entry/" \
STATUS_SPACE=$(curl -X POST "${STATUS_AUTHORING_ROOT}/api/v1/status/business-entities/swiyu-parner-id/status-list-entries/" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer $YOUR_AUTH_TOKEN" \
    -d "{}")

echo $STATUS_SPACE  #| jq .
exit 0

STATUS_LIST_ID=$(echo "$STATUS_SPACE" | jq -r '.id')
echo "Status List ID=${STATUS_LIST_ID}"


#STATUS_READ_URL="${STATUS_ROOT}/api/v1/statuslist/${STATUS_LIST_ID}.jwt"
STATUS_READ_URL=$(echo "$STATUS_SPACE" | jq -r '.files.TokenStatusListJWT.readUri')
echo "Status read URL=${STATUS_READ_URL}"

# STATUS_ENTRY=$(curl -s -X GET "${STATUS_READ_URL}" \
#     -H 'accept: application/statuslist+jwt' \
#     -H "Authorization: Bearer $YOUR_AUTH_TOKEN")

# echo $STATUS_ENTRY

ISSUER_ID=$ID

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

TOKEN=$(curl -s --url "http://localhost:7080/realms/master/protocol/openid-connect/token" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -d "client_id=${CLIENT}" \
    -d "client_secret=${SECRET}" \
    -d "grant_type=password"  \
    -d "username=issuer_user" \
    -d "password=issuer_user" \
    -d "scope=offline_access")

ACCESS_TOKEN=$(echo $TOKEN | jq -r '.access_token')
REFRESH_TOKEN=$(echo $TOKEN | jq -r '.refresh_token')

# Generate SDJWT_KEY and set it as env variable:
openssl ecparam -genkey -name prime256v1 -noout -out private.pem

# Generate public key
openssl ec -in private.pem -pubout -out ec_public.pem

# Generate .env file
cat > .env <<EOF
ID=$ISSUER_ID
ISSUER_DID=$ISSUER_DID
PARTNER_ID=$PARTNER_ID
STATUS_REGISTRY_CUSTOMER_KEY=$CLIENT
STATUS_REGISTRY_CUSTOMER_SECRET=$SECRET
STATUS_REGISTRY_BOOTSTRAP_REFRESH_TOKEN=$REFRESH_TOKEN
EXTERNAL_URL="http://issuer-oid4vci.home.rwpz.net"
STATUS_REGISTRY_API_URL="http://authoring-status-registry.home.rwpz.net"
STATUS_LIST_ID=$STATUS_LIST_ID
STATUS_JWT_URL=$STATUS_READ_URL
TOKEN_URL="http://keycloak:7080/realms/master/protocol/openid-connect/token"
EOF

# Create docker-compose.override.yml
{
  echo "services:"
  echo "  eidch-issuer-agent-management:"
  echo "    environment:"
  echo "      STATUS_LIST_KEY: |"
  sed 's/^/        /' "$KEY_FILE"
  echo "  eidch-issuer-agent-oid4vci:"
  echo "    environment:"
  echo "      SDJWT_KEY: |"
  sed 's/^/        /' "private.pem"
} > issuer-override.yml


# curl -X POST "http://authoring-status-registry.home.rwpz.net/api/v1/status/business-entities/swiyu-parner-id/status-list-entries/" \
#     -H 'accept: application/json' \
#     -H "Authorization: Bearer $YOUR_AUTH_TOKEN" \
#     -d "{}"