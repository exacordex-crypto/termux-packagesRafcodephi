#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CORE_LIST="${ROOT_DIR}/scripts/ci/rafcodephi-core-packages.txt"
OUT_DIR="${ROOT_DIR}/artifacts/rafcodephi-core-plan"
ARCHES=(aarch64 arm i686 x86_64)

mkdir -p "$OUT_DIR"

[[ -f "$CORE_LIST" ]] || { echo "missing core package list: $CORE_LIST" >&2; exit 1; }

while IFS= read -r pkg; do
  [[ -n "$pkg" ]] || continue
  [[ -f "${ROOT_DIR}/packages/${pkg}/build.sh" ]] || { echo "missing package recipe: packages/${pkg}/build.sh" >&2; exit 1; }
  grep -q 'TERMUX_PKG_VERSION' "${ROOT_DIR}/packages/${pkg}/build.sh" || { echo "recipe missing TERMUX_PKG_VERSION: ${pkg}" >&2; exit 1; }
done < "$CORE_LIST"

printf '%s ' $(cat "$CORE_LIST") > "${OUT_DIR}/workflow-dispatch-packages.txt"
printf '\n' >> "${OUT_DIR}/workflow-dispatch-packages.txt"
printf '%s\n' "${ARCHES[@]}" > "${OUT_DIR}/arches.txt"
git -C "$ROOT_DIR" rev-parse HEAD > "${OUT_DIR}/packages-repo-head.txt"

echo "rafcodephi_core_packages=PASS"
echo "packages=$(cat "$CORE_LIST" | xargs)"
echo "arches=${ARCHES[*]}"
echo "dispatch_input_packages=$(cat "$OUT_DIR/workflow-dispatch-packages.txt" | xargs)"
