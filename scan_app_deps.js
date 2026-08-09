const fs = require('fs');
const path = require('path');

const appDir = 'D:\\WebApp\\neos-app-96';

const fromRegex = /\.from\(['"]([a-zA-Z0-9_]+)['"]/g;
const rpcRegex = /\.rpc\(['"]([a-zA-Z0-9_]+)['"]/g;
const storageRegex = /storage\.from\(['"]([a-zA-Z0-9_-]+)['"]/g;

const referencedTables = new Set();
const referencedRpcs = new Set();
const referencedBuckets = new Set();
const fileMatches = {};

function scanDir(dir) {
    if (!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (file === 'node_modules' || file === '.next' || file === '.git') continue;
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory()) {
            scanDir(fullPath);
        } else if (/\.(ts|tsx|js|jsx|sql)$/.test(file)) {
            try {
                const content = fs.readFileSync(fullPath, 'utf8');
                const fMatches = [...content.matchAll(fromRegex)].map(m => m[1]);
                const rMatches = [...content.matchAll(rpcRegex)].map(m => m[1]);
                const sMatches = [...content.matchAll(storageRegex)].map(m => m[1]);

                if (fMatches.length || rMatches.length || sMatches.length) {
                    const relPath = path.relative(appDir, fullPath);
                    fileMatches[relPath] = {
                        from: [...new Set(fMatches)],
                        rpc: [...new Set(rMatches)],
                        storage: [...new Set(sMatches)]
                    };
                    fMatches.forEach(t => referencedTables.add(t));
                    rMatches.forEach(r => referencedRpcs.add(r));
                    sMatches.forEach(s => referencedBuckets.add(s));
                }
            } catch (e) {}
        }
    }
}

scanDir(appDir);

const report = {
    summary: {
        total_referenced_tables: referencedTables.size,
        total_referenced_rpcs: referencedRpcs.size,
        total_referenced_buckets: referencedBuckets.size
    },
    referenced_tables: Array.from(referencedTables).sort(),
    referenced_rpcs: Array.from(referencedRpcs).sort(),
    referenced_buckets: Array.from(referencedBuckets).sort(),
    file_matches: fileMatches
};

fs.writeFileSync('D:\\WebApp\\KVM2\\app_deps.json', JSON.stringify(report, null, 2));

console.log(`Scanned codebase: ${Object.keys(fileMatches).length} files matched.`);
console.log(`Referenced Tables/Views (${referencedTables.size}):`, Array.from(referencedTables).sort());
console.log(`Referenced RPCs (${referencedRpcs.size}):`, Array.from(referencedRpcs).sort());
console.log(`Referenced Storage Buckets (${referencedBuckets.size}):`, Array.from(referencedBuckets).sort());
