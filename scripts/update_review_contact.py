import os
import sys
import time

import jwt
import requests


KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
APP_ID = os.environ.get("APP_ID", "6767826229")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")

CONTACT = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+818023689194",
    "demoAccountRequired": False,
    "demoAccountName": "",
    "demoAccountPassword": "",
}

p8 = open(P8_PATH, encoding="utf-8").read()


def make_token():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        p8,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def api(method, path, **kwargs):
    response = requests.request(
        method,
        f"https://api.appstoreconnect.apple.com/v1{path}",
        headers={"Authorization": f"Bearer {make_token()}", "Content-Type": "application/json"},
        timeout=60,
        **kwargs,
    )
    if response.status_code >= 400:
        print(f"{method} {path} -> {response.status_code}")
        print(response.text[:1200])
    return response


def main():
    states = (
        "PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED,"
        "READY_FOR_REVIEW,WAITING_FOR_REVIEW,IN_REVIEW"
    )
    response = api(
        "GET",
        f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]={APP_VERSION}&filter[appStoreState]={states}&limit=10",
    )
    versions = response.json().get("data", [])
    if not versions:
        print(f"No App Store version found for {APP_VERSION}.")
        sys.exit(1)

    version = versions[0]
    version_id = version["id"]
    print(f"Version {APP_VERSION}: {version_id} state={version['attributes'].get('appStoreState')}")

    attrs = {
        **CONTACT,
        "notes": (
            "No login required. This app is a Japanese beverage news aggregator. "
            "If a call is needed, please use the updated contact phone number."
        ),
    }

    response = api("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    if response.status_code == 200 and response.json().get("data"):
        detail_id = response.json()["data"]["id"]
        payload = {"data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}}
        response = api("PATCH", f"/appStoreReviewDetails/{detail_id}", json=payload)
        if response.status_code >= 400:
            sys.exit(1)
        print("Review contact updated.")
        return

    payload = {
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": attrs,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
        }
    }
    response = api("POST", "/appStoreReviewDetails", json=payload)
    if response.status_code not in (200, 201):
        sys.exit(1)
    print("Review contact created.")


if __name__ == "__main__":
    main()
