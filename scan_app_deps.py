import os, re, json

app_dir = r"D:\WebApp\neos-app-96"

from_regex = re.compile(r"\.from\(['\"]([a-zA-Z0-9_]+)['\"]")
rpc_regex = re.compile(r"\.rpc\(['\"]([a-zA-Z0-9_]+)['\"]")
storage_regex = re.compile(r"storage\.from\(['\"]([a-zA-Z0-9_-]+)['\"]")

referenced_tables = set()
referenced_rpcs = set()
referenced_buckets = set()

file_matches = {}

for root, dirs, files in os.walk(app_dir):
    if 'node_modules' in root or '.next' in root or '.git' in root:
        continue
    for file in files:
        if file.endswith(('.ts', '.tsx', '.js', '.jsx', '.sql')):
            filepath = os.path.join(root, file)
            rel_path = os.path.relpath(filepath, app_dir)
            try:
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                
                f_matches = from_regex.findall(content)
                r_matches = rpc_regex.findall(content)
                s_matches = storage_regex.findall(content)
                
                if f_matches or r_matches or s_matches:
                    file_matches[rel_path] = {
                        'from': list(set(f_matches)),
                        'rpc': list(set(r_matches)),
                        'storage': list(set(s_matches))
                    }
                    referenced_tables.update(f_matches)
                    referenced_rpcs.update(r_matches)
                    referenced_buckets.update(s_matches)
            except Exception as e:
                pass

report = {
    'summary': {
        'total_referenced_tables': len(referenced_tables),
        'total_referenced_rpcs': len(referenced_rpcs),
        'total_referenced_buckets': len(referenced_buckets),
    },
    'referenced_tables': sorted(list(referenced_tables)),
    'referenced_rpcs': sorted(list(referenced_rpcs)),
    'referenced_buckets': sorted(list(referenced_buckets)),
    'file_matches': file_matches
}

with open(r"D:\WebApp\KVM2\app_deps.json", "w") as f:
    json.dump(report, f, indent=2)

print(f"Scanned application codebase: {len(file_matches)} files matched.")
print(f"Referenced Tables/Views ({len(referenced_tables)}):", sorted(list(referenced_tables))[:15])
print(f"Referenced RPCs ({len(referenced_rpcs)}):", sorted(list(referenced_rpcs)))
print(f"Referenced Storage Buckets ({len(referenced_buckets)}):", sorted(list(referenced_buckets)))
