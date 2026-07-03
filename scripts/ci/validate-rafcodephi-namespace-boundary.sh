#!/usr/bin/env bash
set -euo pipefail

properties_file="scripts/properties.sh"
boundary_doc="docs/audits/RAFCODEPHI_PACKAGE_NAMESPACE_BOUNDARY.md"

if [ ! -f "$properties_file" ]; then
	printf 'namespace_boundary=FAIL\n' >&2
	printf 'missing %s\n' "$properties_file" >&2
	exit 1
fi

if [ ! -f "$boundary_doc" ]; then
	printf 'namespace_boundary=FAIL\n' >&2
	printf 'missing %s\n' "$boundary_doc" >&2
	exit 1
fi

if grep -q 'TERMUX_APP__PACKAGE_NAME="com.termux.rafacodephi"' "$properties_file"; then
	state="rafcodephi_specific"
elif grep -q 'TERMUX_APP__PACKAGE_NAME="com.termux"' "$properties_file"; then
	state="upstream_compatible_default"
else
	printf 'namespace_boundary=FAIL\n' >&2
	printf 'TERMUX_APP__PACKAGE_NAME is neither com.termux nor com.termux.rafacodephi\n' >&2
	exit 1
fi

for token in \
	'com.termux.rafacodephi' \
	'TERMUX_APP__PACKAGE_NAME=com.termux' \
	'TERMUX_APP__PACKAGE_NAME=com.termux.rafacodephi' \
	'full runtime integration' \
	'This document does not change package build behavior'
do
	if ! grep -q "$token" "$boundary_doc"; then
		printf 'namespace_boundary=FAIL\n' >&2
		printf 'boundary doc missing token: %s\n' "$token" >&2
		exit 1
	fi
done

printf 'namespace_boundary=PASS\n'
printf 'namespace_state=%s\n' "$state"
printf 'claim_boundary=package_build_evidence_does_not_equal_app_runtime_integration\n'
