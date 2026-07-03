#!/usr/bin/env bash
set -euo pipefail

usage() {
	printf 'Usage: %s <commit-sha> [arch ...]\n' "$0" >&2
}

case "$#" in
	0) usage; exit 64 ;;
esac

commit_sha="$1"
shift

case "$commit_sha" in
	*[!A-Za-z0-9._-]*|'') printf 'Unsafe commit/artifact id: %s\n' "$commit_sha" >&2; exit 65 ;;
esac

if [ "$#" -gt 0 ]; then
	arches=("$@")
else
	arches=(aarch64 arm i686 x86_64)
fi

for arch in "${arches[@]}"; do
	case "$arch" in
		aarch64|arm|i686|x86_64) ;;
		*) printf 'Unsupported architecture: %s\n' "$arch" >&2; exit 65 ;;
	esac

	artifact_dir="debs-${arch}-${commit_sha}"
	archive="${artifact_dir}/debs-${arch}-${commit_sha}.tar"
	manifest="${artifact_dir}/debs-${arch}-${commit_sha}.manifest"
	checksum_dir="checksum-${arch}-${commit_sha}"
	checksum="${checksum_dir}/checksum-${arch}-${commit_sha}.txt"

	for required_file in "$archive" "$manifest" "$checksum"; do
		if [ ! -f "$required_file" ]; then
			printf 'Missing required downloaded artifact file: %s\n' "$required_file" >&2
			exit 66
		fi
	done

	if ! grep -qx "arch=${arch}" "$manifest"; then
		printf 'Manifest %s does not declare arch=%s\n' "$manifest" "$arch" >&2
		exit 67
	fi
	if ! grep -qx "commit=${commit_sha}" "$manifest"; then
		printf 'Manifest %s does not declare commit=%s\n' "$manifest" "$commit_sha" >&2
		exit 67
	fi
	if ! grep -qx "checksum_file=checksum-${arch}-${commit_sha}.txt" "$manifest"; then
		printf 'Manifest %s does not match checksum artifact name\n' "$manifest" >&2
		exit 67
	fi
	if ! grep -qx "archive_file=artifacts/debs-${arch}-${commit_sha}.tar" "$manifest"; then
		printf 'Manifest %s does not match archive artifact name\n' "$manifest" >&2
		exit 67
	fi

	deb_count="$(sed -n 's/^deb_count=//p' "$manifest")"
	case "$deb_count" in
		''|*[!0-9]*) printf 'Manifest %s has invalid deb_count=%s\n' "$manifest" "$deb_count" >&2; exit 67 ;;
	esac
	checksum_count="$(wc -l < "$checksum")"
	if [ "$checksum_count" -ne "$deb_count" ]; then
		printf 'Checksum count mismatch for %s: manifest=%s checksum_lines=%s\n' "$arch" "$deb_count" "$checksum_count" >&2
		exit 68
	fi

	tar tf "$archive" >/dev/null
	printf 'Validated package artifacts for %s at %s (%s debs)\n' "$arch" "$commit_sha" "$deb_count"
done
