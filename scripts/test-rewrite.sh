#!/bin/bash

BASE_ROOT="http://base-registry.home.rwpz.net"
BASE_AUTHORING_ROOT="http://authoring-base-registry.home.rwpz.net"
STATUS_ROOT="http://status-registry.home.rwpz.net"
STATUS_AUTHORING_ROOT="http://authoring-status-registry.home.rwpz.net"

# get access-token

# get access token
YOUR_AUTH_TOKEN=$(curl -s -d "client_id=eidch" -d "client_secret=iUsyfcM0MXH8oHLsAMOV1HgVeCHuPjJP" -d "grant_type=client_credentials"  "http://localhost:7080/realms/master/protocol/openid-connect/token" | jq -r '.access_token')

# register did space
HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/response.txt -H "Authorization: Bearer $YOUR_AUTH_TOKEN" -X POST "${BASE_AUTHORING_ROOT}/api/v1/identifier/business-entities/swiyu-parner-id/identifier-entries/")

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

# test get status space

STATUS_SPACE=$(curl -s -X POST "${STATUS_AUTHORING_ROOT}/api/v1/status/business-entities/swiyu-parner-id/status-list-entries/" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer $YOUR_AUTH_TOKEN" \
    -d "{}")

STATUS_LIST_ID=$(echo "$STATUS_SPACE" | jq -r '.id')
echo "Status List ID=${STATUS_LIST_ID}"