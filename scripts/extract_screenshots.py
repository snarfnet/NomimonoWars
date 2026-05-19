#!/usr/bin/env python3
"""Extract screenshot attachments from xcresult bundle."""
import subprocess, json, sys, os

xcresult = sys.argv[1]
output_dir = sys.argv[2]
os.makedirs(output_dir, exist_ok=True)

# Get test results
result = subprocess.run(
    ['xcrun', 'xcresulttool', 'get', '--format', 'json', '--path', xcresult],
    capture_output=True, text=True
)
if result.returncode != 0 or not result.stdout.strip():
    print(f"xcresulttool failed (rc={result.returncode})")
    print(f"stderr: {result.stderr[:500]}")
    # Try legacy format
    result = subprocess.run(
        ['xcrun', 'xcresulttool', 'get', '--path', xcresult, '--format', 'json'],
        capture_output=True, text=True
    )
    if not result.stdout.strip():
        print("No xcresult data available")
        sys.exit(1)

root = json.loads(result.stdout)

def find_attachments(obj, path=""):
    """Recursively find screenshot attachments in xcresult JSON."""
    attachments = []
    if isinstance(obj, dict):
        if obj.get('_type', {}).get('_name') == 'ActionTestAttachment':
            name = obj.get('name', {}).get('_value', '')
            payload_ref = obj.get('payloadRef', {}).get('id', {}).get('_value', '')
            if payload_ref and name:
                attachments.append((name, payload_ref))
        for v in obj.values():
            attachments.extend(find_attachments(v))
    elif isinstance(obj, list):
        for item in obj:
            attachments.extend(find_attachments(item))
    return attachments

attachments = find_attachments(root)
print(f"Found {len(attachments)} attachments")

for name, ref_id in attachments:
    safe_name = name.replace(' ', '_').replace('/', '_')
    out_path = os.path.join(output_dir, f"{safe_name}.png")
    subprocess.run([
        'xcrun', 'xcresulttool', 'get',
        '--path', xcresult,
        '--id', ref_id,
        '--output-path', out_path
    ])
    if os.path.exists(out_path):
        size = os.path.getsize(out_path)
        print(f"  Extracted: {safe_name}.png ({size} bytes)")
    else:
        print(f"  FAILED: {safe_name}.png")
