#!/usr/bin/env python3
"""Delete all existing screenshots from App Store Connect."""
import jwt, time, requests, os

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
APP_ID = '6767826229'
APP_VERSION = os.environ.get('APP_VERSION', '1.0')

p8 = open('/tmp/asc_key.p8').read()

def make_token():
    return jwt.encode(
        {'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        p8, algorithm='ES256', headers={'kid': KEY_ID}
    )

def api(method, path, **kwargs):
    h = {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json'}
    return requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}', headers=h, **kwargs)

# Find version
r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]={APP_VERSION}&limit=1')
version_id = r.json()['data'][0]['id']
print(f'Version: {version_id}')

# Get all localizations
r = api('GET', f'/appStoreVersions/{version_id}/appStoreVersionLocalizations')
for loc in r.json().get('data', []):
    loc_id = loc['id']
    locale = loc['attributes']['locale']
    print(f'\nLocale: {locale} ({loc_id})')

    # Get all screenshot sets
    r2 = api('GET', f'/appStoreVersionLocalizations/{loc_id}/appScreenshotSets')
    for ss_set in r2.json().get('data', []):
        set_id = ss_set['id']
        display = ss_set['attributes']['screenshotDisplayType']
        print(f'  Set: {display} ({set_id})')

        # Get and delete all screenshots in this set
        r3 = api('GET', f'/appScreenshotSets/{set_id}/appScreenshots')
        for ss in r3.json().get('data', []):
            ss_id = ss['id']
            fname = ss['attributes'].get('fileName', '?')
            dr = api('DELETE', f'/appScreenshots/{ss_id}')
            print(f'    Deleted {fname}: {dr.status_code}')
            time.sleep(0.5)

print('\nDone!')
