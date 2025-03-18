# get access token
TOKEN=$(curl -s --url "http://localhost:7080/realms/master/protocol/openid-connect/token" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    -d "client_id=ISSUER_MGMT" \
    -d "client_secret=kW94KAL0D9Bwd3vrqvdHoJwMQRS0twWt" \
    -d "grant_type=password"  \
    -d "username=issuer_user" \
    -d "password=issuer_user" \
    -d "scope=offline_access")

ACCESS_TOKEN=$(echo $TOKEN | jq -r '.access_token')
REFRESH_TOKEN=$(echo $TOKEN | jq -r '.refresh_token')

#echo $ACCESS_TOKEN
echo $REFRESH_TOKEN

#export YOUR_AUTH_TOKEN
#echo $YOUR_AUTH_TOKEN