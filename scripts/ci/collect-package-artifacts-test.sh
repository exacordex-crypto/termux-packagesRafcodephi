#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

cd "$workdir"
mkdir -p output termux-packages/output
cat > repo.json <<'JSON'
{
  "pkg_format": "debian",
  "packages": {
    "name": "main"
  }
}
JSON

printf 'foo\n' > built_main_packages.txt
printf 'gone\n' > deleted_main_packages.txt
printf 'foo package\n' > output/foo_1_aarch64.deb
printf 'foo static package\n' > output/foo-static_1_aarch64.deb
printf 'other package\n' > output/foobar_1_aarch64.deb
printf 'other package\n' > output/bar_1_aarch64.deb

"$repo_root/scripts/ci/collect-package-artifacts.sh" aarch64 testsha

test -f artifacts/debs-aarch64-testsha.tar
test -f checksum-aarch64-testsha.txt
test -f artifacts/debs-aarch64-testsha.manifest
test -f debs/built_main_packages.txt
test -f debs/deleted_main_packages.txt
test -f debs/foo_1_aarch64.deb
test -f debs/foo-static_1_aarch64.deb
test -f output/foobar_1_aarch64.deb
test -f output/bar_1_aarch64.deb

checksum_count="$(wc -l < checksum-aarch64-testsha.txt)"
if ! grep -qx "arch=aarch64" artifacts/debs-aarch64-testsha.manifest; then
	printf "Missing arch manifest entry\n" >&2
	exit 1
fi
if ! grep -qx "deb_count=2" artifacts/debs-aarch64-testsha.manifest; then
	printf "Missing deb_count manifest entry\n" >&2
	exit 1
fi

if "$repo_root/scripts/ci/collect-package-artifacts.sh" sparc testsha >/tmp/collect-invalid.out 2>/tmp/collect-invalid.err; then
	printf "Expected invalid architecture to fail\n" >&2
	exit 1
fi

if [ "$checksum_count" -ne 2 ]; then
	printf 'Expected 2 checksums, got %s\n' "$checksum_count" >&2
	exit 1
fi
