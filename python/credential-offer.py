#!/usr/bin/python

import requests
import qrcode
import json
from datetime import datetime, UTC
from dateutil.relativedelta import relativedelta

# TODO: get from .env
ISSUER_MGMT_API_URL = "http://localhost:8080/api/v1/credentials"
TOKEN_STATUS_LIST_JWT_URL = "http://status-registry.home.rwpz.net/api/v1/statuslist/6cd90604-00e7-44e1-9933-96da44d95e3c.jwt"

datetime_now = datetime.now(UTC)
CREDENTIAL_VALID_FROM = datetime_now.strftime('%Y-%m-%dT%H:%M:%SZ')
CREDENTIAL_VALID_UNTIL = ((datetime_now + relativedelta(years=3))
                          .strftime('%Y-%m-%dT%H:%M:%SZ'))

# {
#   "id": "927bb392-1455-445f-a705-8d1b38f840e3",
#   "statusRegistryUrl": "http://status-registry.home.rwpz.net/api/v1/statuslist/6cd90604-00e7-44e1-9933-96da44d95e3c.jwt",
#   "type": "TOKEN_STATUS_LIST",
#   "maxListEntries": 800000,
#   "remainingListEntries": 800000,
#   "nextFreeIndex": 0,
#   "version": "1.0",
#   "config": {
#     "bits": 2
#   }
# }

# 'Authorization': 'Bearer YOUR_ACCESS_TOKEN'  # Optional, if needed
headers = {
    'Accept': '*/*',
    'Content-Type': 'application/json',
}

payload = {
    "metadata_credential_supported_id": [
        "university_example_sd_jwt"
    ],
    "credential_subject_data": {
        "degree": "Test",
        "name": "Test", "average_grade": 10
    },
    "offer_validity_seconds": 86400,
    "credential_valid_until": "2010-01-01T19:23:24Z",  # CREDENTIAL_VALID_UNTIL,
    "credential_valid_from": "2010-01-01T19:23:24Z",  # CREDENTIAL_VALID_FROM,
    "status_lists": [TOKEN_STATUS_LIST_JWT_URL]
}

#ex = '{"metadata_credential_supported_id": ["university_example_sd_jwt"],"credential_subject_data": {"degree": "Test","name": "Test", "average_grade": 10},"offer_validity_seconds": 86400,"credential_valid_until": "2010-01-01T19:23:24Z","credential_valid_from": "2010-01-01T18:23:24Z","status_lists": ["http://status-registry.home.rwpz.net/api/v1/statuslist/fce2d18f-f475-4021-b029-e25be9260320.jwt"]}'

# Fetch the string from REST API
response = requests.post(ISSUER_MGMT_API_URL,
                         json=payload,
                         headers=headers)

try:
    response.raise_for_status()
    data = response.json()  # Assuming JSON, adapt as needed

    offer_id = data.get('management_id', None)
    if not offer_id:
        print("malformed response")
        print(data)
        exit(1)

    print(f"offer-id={offer_id}")
    string_to_encode = data.get('offer_deeplink', None)
    print("encoding offer_deeplink:")
    print(string_to_encode)

    # Generate QR Code
    img = qrcode.make(string_to_encode)

    # Show QR Code
    img.show()  # Opens in default image viewer

    # Optionally save to file
    img.save(f"credential_offers/offer_{offer_id}.png")

except requests.exceptions.HTTPError as http_err:
    print(f"HTTP error occurred: {http_err}")
    #print(f"Status Code: {response.status_code}")

    try:
        error_data = response.json()  # If response contains JSON
        print("Error details:", error_data)
    except ValueError:
        # Not a JSON response (plain text or empty)
        print("Raw response:", response.text)
except Exception as err:
    print(f"Other error occurred: {err}")
    print(f"Status Code: {response.status_code}")
    data = response.json()
    print(data)