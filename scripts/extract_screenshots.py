#!/usr/bin/env python3
"""Extract screenshot attachments from xcresult bundle."""
import subprocess, json, sys, os

xcresult = sys.argv[1]
output_dir = sys.argv[2]
os.makedirs(output_dir, exist_ok=True)

def try_xcresulttool():
    """Try new API first, then legacy."""
    # Try legacy format (required in Xcode 26+)
    for extra_args in [
        ['get', '--path', xcresult, '--format', 'json', '--legacy'],
        ['get', '--legacy', '--format', 'json', '--path', xcresult],
        ['get', '--format', 'json', '--path', xcresult],
    ]:
        result = subprocess.run(
            ['xcrun', 'xcresulttool'] + extra_args,
            capture_output=True, text=True
        )
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout)
        print(f"Tried: xcresulttool {' '.join(extra_args)} -> rc={result.returncode}")
        if result.stderr:
            print(f"  stderr: {result.stderr[:200]}")
    return None

root = try_xcresulttool()
if not root:
    print("All xcresulttool attempts failed. Trying direct attachment export...")
    # Fallback: use xcresulttool to export attachments directly
    result = subprocess.run(
        ['xcrun', 'xcresulttool', 'export', '--type', 'file',
         '--path', xcresult, '--output-path', output_dir],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print("Exported via xcresulttool export")
        # Rename any png files found
        for i, f in enumerate(sorted(os.listdir(output_dir))):
            if f.lower().endswith('.png'):
                print(f"  Found: {f}")
    else:
        print(f"Export also failed: {result.stderr[:300]}")
        sys.exit(1)
    sys.exit(0)

def find_attachments(obj):
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

if not attachments:
    print("No attachments found in xcresult. Dumping top-level keys for debug:")
    if isinstance(root, dict):
        for k in list(root.keys())[:20]:
            print(f"  {k}")
    sys.exit(1)

for name, ref_id in attachments:
    safe_name = name.replace(' ', '_').replace('/', '_')
    out_path = os.path.join(output_dir, f"{safe_name}.png")
    # Try legacy export
    for extra in [['--legacy'], []]:
        r = subprocess.run(
            ['xcrun', 'xcresulttool', 'get'] + extra +
            ['--path', xcresult, '--id', ref_id, '--output-path', out_path],
            capture_output=True, text=True
        )
        if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
            break
    if os.path.exists(out_path):
        size = os.path.getsize(out_path)
        print(f"  Extracted: {safe_name}.png ({size} bytes)")
    else:
        print(f"  FAILED: {safe_name}.png")
