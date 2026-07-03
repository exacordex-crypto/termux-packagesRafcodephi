#!/usr/bin/env bash
set -euo pipefail

usage() {
	printf 'Usage: %s <arch> <commit-sha>\n' "$0" >&2
}

case "$#" in
	2) ;;
	*) usage; exit 64 ;;
esac

arch="$1"
commit_sha="$2"

case "$arch" in
	aarch64|arm|i686|x86_64) ;;
	*) printf 'Unsupported architecture: %s\n' "$arch" >&2; exit 65 ;;
esac

case "$commit_sha" in
	*[!A-Za-z0-9._-]*|'') printf 'Unsafe commit/artifact id: %s\n' "$commit_sha" >&2; exit 65 ;;
esac

mkdir -p artifacts debs output

manifest="artifacts/debs-${arch}-${commit_sha}.manifest"
checksum="checksum-${arch}-${commit_sha}.txt"
archive="artifacts/debs-${arch}-${commit_sha}.tar"
tmp_debs="debs/.collect-${arch}-${commit_sha}"
rm -rf "$tmp_debs"
mkdir -p "$tmp_debs"

cleanup() {
	rm -rf "$tmp_debs"
}
trap cleanup EXIT

if [ -d termux-packages/output ]; then
	shopt -s nullglob
	built_outputs=(termux-packages/output/*)
	if [ "${#built_outputs[@]}" -gt 0 ]; then
		mv "${built_outputs[@]}" output/
	fi
	shopt -u nullglob
fi

while IFS= read -r repo_name; do
	[ -n "$repo_name" ] || continue

	if [ -f "./built_${repo_name}_packages.txt" ]; then
		mv "./built_${repo_name}_packages.txt" "$tmp_debs/"
	fi
	if [ -f "./built_${repo_name}_subpackages.txt" ]; then
		cat "./built_${repo_name}_subpackages.txt" >> "$tmp_debs/built_${repo_name}_packages.txt"
		rm "./built_${repo_name}_subpackages.txt"
	fi
	if [ -f "./deleted_${repo_name}_packages.txt" ]; then
		mv "./deleted_${repo_name}_packages.txt" "$tmp_debs/"
	fi

	if [ -f "$tmp_debs/built_${repo_name}_packages.txt" ] && [ -d output ]; then
		while IFS= read -r pkg; do
			[ -n "$pkg" ] || continue
			find output \( -name "${pkg}_*.deb" -o -name "${pkg}-static_*.deb" \) -type f -print0 |
				while IFS= read -r -d '' deb_file; do
					mv "$deb_file" "$tmp_debs/"
				done
		done < "$tmp_debs/built_${repo_name}_packages.txt"
	fi
done < <(jq --raw-output 'del(.pkg_format) | .[].name' repo.json)

find "$tmp_debs" -mindepth 1 -maxdepth 1 -exec mv -t debs/ -- {} + 2>/dev/null || true

find debs -type f -name "*.deb" -exec sha256sum "{}" \; | LC_ALL=C sort -k2 > "$checksum"

deb_count="$(find debs -type f -name '*.deb' | wc -l)"
{
	printf 'arch=%s\n' "$arch"
	printf 'commit=%s\n' "$commit_sha"
	printf 'deb_count=%s\n' "$deb_count"
	printf 'checksum_file=%s\n' "$checksum"
	printf 'archive_file=%s\n' "$archive"
} > "$manifest"

tar cf "$archive" debs
