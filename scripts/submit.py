import jwt, time, requests, sys, os

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
APP_ID = '6767826229'
BUILD_NUMBER = sys.argv[1]
APP_VERSION = os.environ.get('APP_VERSION', '1.0')

p8 = open('/tmp/asc_key.p8').read()

def make_token():
    return jwt.encode(
        {'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        p8, algorithm='ES256', headers={'kid': KEY_ID}
    )

def headers():
    return {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json'}

def api(method, path, **kwargs):
    r = requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}',
        headers=headers(), **kwargs)
    return r

print(f'Waiting for build {BUILD_NUMBER} to be processed...')
build_id = None
for i in range(80):
    r = api('GET', f'/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1')
    data = r.json()
    if data.get('data'):
        build_id = data['data'][0]['id']
        print(f'Build ready: {build_id}')
        break
    print(f'  Waiting... ({i+1}/80)')
    time.sleep(30)

if not build_id:
    print('ERROR: Build not found after 40 minutes. Check ASC manually.')
    sys.exit(1)

# Set export compliance
r = api('PATCH', f'/builds/{build_id}',
    json={'data': {'type': 'builds', 'id': build_id, 'attributes': {'usesNonExemptEncryption': False}}})
print(f'Export compliance: {r.status_code}')

# Find version
version_id = None
version_state = None
r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]={APP_VERSION}&limit=1')
data = r.json()
if data.get('data'):
    version_id = data['data'][0]['id']
    version_state = data['data'][0]['attributes']['appStoreState']
    print(f'Found version {APP_VERSION}: {version_id} state={version_state}')

if version_state in ('WAITING_FOR_REVIEW', 'IN_REVIEW'):
    print(f'Already in review ({version_state}). Nothing to do.')
    sys.exit(0)

if not version_id or version_state in ('READY_FOR_DISTRIBUTION',):
    print('Creating new version...')
    r = api('POST', '/appStoreVersions', json={
        'data': {
            'type': 'appStoreVersions',
            'attributes': {'platform': 'IOS', 'versionString': APP_VERSION},
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}
        }
    })
    if r.status_code not in (200, 201):
        print(f'Failed to create version: {r.text[:300]}')
        sys.exit(1)
    version_id = r.json()['data']['id']
    version_state = 'PREPARE_FOR_SUBMISSION'

print(f'Version ID: {version_id} state={version_state}')

# Set App Review Notes
review_notes = """This build addresses the iPad Air 11-inch layout and metadata issues reported under Guideline 4 and Guideline 2.3. The bottom navigation now directly shows the three tabs named in the metadata: 新商品, ランキング, and ニュース. Saved articles are opened from the bookmark button in the header, so the main tab structure matches the app metadata. The layout now uses a safe-area bottom inset for the tab bar and adaptive AdMob banner, wider iPad content, safer article-card padding, and non-truncated article titles so the top and bottom of articles remain visible.

1. Screen recording: The app launches and immediately displays beverage news articles fetched from Google News RSS. Users can switch between 新商品, ランキング, and ニュース using the bottom navigation. Tap an article card to read the full article in Safari. Tap the bookmark button on an article, then tap the bookmark icon in the header to see saved articles. There are no accounts, logins, or paid features. ATT prompt appears for AdMob ad personalization.

2. Layout verified for: iPad Air 11-inch screen size, iPhone 17 Pro Max screen size, and compact iPhone screen sizes.

3. Purpose: A Japanese beverage news aggregator. Users can quickly browse the latest drink product releases, sales rankings, and industry news in one place. It solves the problem of scattered beverage information across multiple sites.

4. Setup: No login required. Launch the app and news articles load automatically. Use the bottom navigation to switch between 新商品, ランキング, and ニュース. Saved articles are available from the bookmark icon in the header.

5. External services:
- Google News RSS (news.google.com): Public RSS feeds for beverage-related news articles
- Google AdMob: Banner and interstitial advertisements

6. Regional differences: None. The app functions consistently across all regions. Content is in Japanese as it aggregates Japanese beverage news.

7. Not applicable. The app does not operate in a regulated industry and does not include protected third-party material."""

review_contact = {
    'contactFirstName': 'Tokyo',
    'contactLastName': 'Nasu',
    'contactEmail': 'tokyonasu@yahoo.co.jp',
    'contactPhone': '+818023689194',
    'demoAccountRequired': False,
    'demoAccountName': '',
    'demoAccountPassword': '',
    'notes': review_notes,
}

# Check/create appStoreReviewDetail
r = api('GET', f'/appStoreVersions/{version_id}/appStoreReviewDetail')
if r.status_code == 200 and r.json().get('data'):
    detail_id = r.json()['data']['id']
    r = api('PATCH', f'/appStoreReviewDetails/{detail_id}', json={
        'data': {'type': 'appStoreReviewDetails', 'id': detail_id,
                 'attributes': review_contact}
    })
    print(f'Review notes updated: {r.status_code}')
else:
    r = api('POST', '/appStoreReviewDetails', json={
        'data': {
            'type': 'appStoreReviewDetails',
            'attributes': review_contact,
            'relationships': {
                'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version_id}}
            }
        }
    })
    print(f'Review notes created: {r.status_code}')

# Assign build
r = api('PATCH', f'/appStoreVersions/{version_id}/relationships/build',
    json={'data': {'type': 'builds', 'id': build_id}})
print(f'Build assigned: {r.status_code}')

# Cancel any blocking reviewSubmissions
canceled_any = False
for state_filter in ['UNRESOLVED_ISSUES', 'READY_FOR_REVIEW']:
    r = api('GET', f'/apps/{APP_ID}/reviewSubmissions?filter[state]={state_filter}')
    if r.status_code == 200:
        for sub in r.json().get('data', []):
            sid = sub['id']
            st = sub['attributes']['state']
            cr = api('PATCH', f'/reviewSubmissions/{sid}', json={
                'data': {'type': 'reviewSubmissions', 'id': sid, 'attributes': {'canceled': True}}
            })
            print(f'Cancel {sid} state={st}: {cr.status_code}')
            canceled_any = True

if canceled_any:
    print('Waiting 30s for cancellations to propagate...')
    time.sleep(30)
    r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]={APP_VERSION}&limit=1')
    data = r.json()
    if data.get('data'):
        version_id = data['data'][0]['id']
        version_state = data['data'][0]['attributes']['appStoreState']
        print(f'Version after cancel: {version_id} state={version_state}')
    r = api('PATCH', f'/appStoreVersions/{version_id}/relationships/build',
        json={'data': {'type': 'builds', 'id': build_id}})
    print(f'Build re-assigned: {r.status_code}')

# Submit via reviewSubmissions API
submission_id = None
for attempt in range(5):
    r = api('POST', '/reviewSubmissions', json={
        'data': {
            'type': 'reviewSubmissions',
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}
        }
    })
    if r.status_code == 201:
        submission_id = r.json()['data']['id']
        print(f'ReviewSubmission created: {submission_id}')
        break
    print(f'Create reviewSubmission attempt {attempt+1}/5 failed: {r.status_code} {r.text[:200]}')
    if attempt < 4:
        time.sleep(15)

if not submission_id:
    print('Could not create reviewSubmission after 5 attempts.')
    sys.exit(1)

# Add item
item_added = False
for attempt in range(5):
    r = api('POST', '/reviewSubmissionItems', json={
        'data': {
            'type': 'reviewSubmissionItems',
            'relationships': {
                'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': submission_id}},
                'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version_id}}
            }
        }
    })
    print(f'Add item attempt {attempt+1}/5: {r.status_code}')
    if r.status_code == 201:
        item_added = True
        break
    if attempt < 4:
        time.sleep(15)

if not item_added:
    print(f'Failed to add item: {r.text[:300]}')
    sys.exit(1)

r = api('PATCH', f'/reviewSubmissions/{submission_id}', json={
    'data': {
        'type': 'reviewSubmissions',
        'id': submission_id,
        'attributes': {'submitted': True}
    }
})
if r.status_code == 200:
    state = r.json()['data']['attributes']['state']
    print(f'Submitted! State: {state}')
else:
    print(f'Submit failed: {r.status_code} {r.text[:300]}')
    sys.exit(1)
