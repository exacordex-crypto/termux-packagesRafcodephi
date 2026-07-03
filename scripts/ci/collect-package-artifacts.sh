#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
	printf 'Usage: %s <arch> <commit-sha>\n' "$0" >&2
	exit 64
fi

arch="$1"
commit_sha="$2"

mkdir -p artifacts debs output

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
		mv "./built_${repo_name}_packages.txt" ./debs/
	fi
	if [ -f "./built_${repo_name}_subpackages.txt" ]; then
		cat "./built_${repo_name}_subpackages.txt" >> "./debs/built_${repo_name}_packages.txt"
		rm "./built_${repo_name}_subpackages.txt"
	fi
	if [ -f "./deleted_${repo_name}_packages.txt" ]; then
		mv "./deleted_${repo_name}_packages.txt" ./debs/
	fi

	if [ -f "./debs/built_${repo_name}_packages.txt" ] && [ -d output ]; then
		while IFS= read -r pkg; do
			[ -n "$pkg" ] || continue
			find output \( -name "${pkg}_*.deb" -o -name "${pkg}-static_*.deb" \) -type f -print0 |
				while IFS= read -r -d '' deb_file; do
					mv "$deb_file" debs/
				done
		done < "./debs/built_${repo_name}_packages.txt"
	fi
done < <(jq --raw-output 'del(.pkg_format) | .[].name' repo.json)

tar cf "artifacts/debs-${arch}-${commit_sha}.tar" debs
find debs -type f -name "*.deb" -exec sha256sum "{}" \; | sort -k2 > "checksum-${arch}-${commit_sha}.txt"
