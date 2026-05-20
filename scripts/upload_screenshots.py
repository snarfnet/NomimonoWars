#!/usr/bin/env python3
"""Upload screenshots to App Store Connect via ASC API."""
import jwt, time, requests, sys, os, argparse, glob

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
    if 'headers_override' in kwargs:
        h = kwargs.pop('headers_override')
        h['Authorization'] = f'Bearer {make_token()}'
    r = requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}', headers=h, **kwargs)
    return r

parser = argparse.ArgumentParser()
parser.add_argument('--display-type', required=True)
parser.add_argument('--screenshots-dir', required=True)
args = parser.parse_args()

# Find the app store version
r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]={APP_VERSION}&limit=1')
data = r.json()
if not data.get('data'):
    print(f'No version {APP_VERSION} found')
    sys.exit(1)

version_id = data['data'][0]['id']
print(f'Version: {version_id}')

# Find or get the localization (ja)
r = api('GET', f'/appStoreVersions/{version_id}/appStoreVersionLocalizations')
loc_id = None
for loc in r.json().get('data', []):
    if loc['attributes']['locale'] == 'ja':
        loc_id = loc['id']
        break

if not loc_id:
    # Try en-US
    for loc in r.json().get('data', []):
        if loc['attributes']['locale'] == 'en-US':
            loc_id = loc['id']
            break

if not loc_id:
    print('No localization found')
    sys.exit(1)

print(f'Localization: {loc_id}')

# Get existing screenshot sets for this display type
print(f'Looking for display type: {args.display_type}')
r = api('GET', f'/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?filter[screenshotDisplayType]={args.display_type}')
set_id = None
if r.json().get('data'):
    set_id = r.json()['data'][0]['id']
    actual_type = r.json()['data'][0]['attributes']['screenshotDisplayType']
    print(f'Found set: {set_id} (type: {actual_type})')
    if actual_type != args.display_type:
        print(f'WARNING: Display type mismatch! Expected {args.display_type}, got {actual_type}')
        set_id = None
    # Delete existing screenshots in the set
    r2 = api('GET', f'/appScreenshotSets/{set_id}/appScreenshots')
    for ss in r2.json().get('data', []):
        api('DELETE', f'/appScreenshots/{ss["id"]}')
        print(f'  Deleted old screenshot: {ss["id"]}')
    time.sleep(2)
else:
    # Create screenshot set
    r = api('POST', '/appScreenshotSets', json={
        'data': {
            'type': 'appScreenshotSets',
            'attributes': {'screenshotDisplayType': args.display_type},
            'relationships': {
                'appStoreVersionLocalization': {
                    'data': {'type': 'appStoreVersionLocalizations', 'id': loc_id}
                }
            }
        }
    })
    if r.status_code not in (200, 201):
        print(f'Failed to create screenshot set: {r.text[:300]}')
        sys.exit(1)
    set_id = r.json()['data']['id']

print(f'Screenshot set: {set_id}')

# Upload each screenshot
png_files = sorted(glob.glob(os.path.join(args.screenshots_dir, '*.png')))
print(f'Found {len(png_files)} screenshots to upload')

for png_path in png_files:
    file_name = os.path.basename(png_path)
    file_size = os.path.getsize(png_path)
    print(f'Uploading {file_name} ({file_size} bytes)...')

    # Reserve upload
    r = api('POST', '/appScreenshots', json={
        'data': {
            'type': 'appScreenshots',
            'attributes': {
                'fileName': file_name,
                'fileSize': file_size
            },
            'relationships': {
                'appScreenshotSet': {
                    'data': {'type': 'appScreenshotSets', 'id': set_id}
                }
            }
        }
    })
    if r.status_code not in (200, 201):
        print(f'  Reserve failed: {r.status_code} {r.text[:200]}')
        continue

    screenshot_data = r.json()['data']
    screenshot_id = screenshot_data['id']
    upload_ops = screenshot_data['attributes'].get('uploadOperations', [])

    # Upload parts
    with open(png_path, 'rb') as f:
        file_bytes = f.read()

    for op in upload_ops:
        offset = op['offset']
        length = op['length']
        chunk = file_bytes[offset:offset + length]
        upload_headers = {h['name']: h['value'] for h in op['requestHeaders']}
        resp = requests.put(op['url'], headers=upload_headers, data=chunk)
        if resp.status_code not in (200, 201):
            print(f'  Upload chunk failed: {resp.status_code}')

    # Commit
    r = api('PATCH', f'/appScreenshots/{screenshot_id}', json={
        'data': {
            'type': 'appScreenshots',
            'id': screenshot_id,
            'attributes': {
                'uploaded': True,
                'sourceFileChecksum': None
            }
        }
    })
    if r.status_code == 200:
        print(f'  Uploaded: {file_name}')
    else:
        print(f'  Commit failed: {r.status_code} {r.text[:200]}')

    time.sleep(1)

print('Done!')
