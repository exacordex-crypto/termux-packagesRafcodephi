#!/usr/bin/env python3
"""Validate Rafcodephi package-fork alignment boundaries without changing builds."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ABI_SET = {"aarch64", "arm", "i686", "x86_64"}
WATCH_PATTERNS = (
    'TERMUX_APP__PACKAGE_NAME="com.termux"',
    "/data/data/com.termux",
    "packages-cf.termux.dev",
)
WATCH_FILES = (
    "README.md",
    "repo.json",
    "scripts/properties.sh",
    "scripts/generate-bootstraps.sh",
    ".github/workflows/packages.yml",
    "scripts/ci/collect-package-artifacts.sh",
    "scripts/ci/collect-package-artifacts-test.sh",
)


def read_text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def line_hits(relative: str, needle: str) -> list[int]:
    return [
        index
        for index, line in enumerate(read_text(relative).splitlines(), start=1)
        if needle in line
    ]


def require(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        print(f"UPSTREAM_COMPATIBLE: {message}")
    else:
        print(f"CLAIM_BLOCKED: {message}")
        failures.append(message)


def workflow_abis() -> set[str]:
    text = read_text(".github/workflows/packages.yml")
    match = re.search(r"target_arch:\s*\[([^\]]+)\]", text)
    if not match:
        return set()
    return {item.strip() for item in match.group(1).split(",")}


def collector_abis() -> set[str]:
    text = read_text("scripts/ci/collect-package-artifacts.sh")
    match = re.search(r"\n\s*(aarch64\|arm\|i686\|x86_64)\)\s*;;", text)
    if not match:
        return set()
    return set(match.group(1).split("|"))


def main() -> int:
    failures: list[str] = []
    readme = read_text("README.md").lower()

    require(
        "does not build" in readme and "apk" in readme,
        "README.md declares that this package repository does not build an APK.",
        failures,
    )
    require(
        workflow_abis() == ABI_SET,
        "Packages workflow keeps ABI matrix: aarch64, arm, i686, x86_64.",
        failures,
    )
    require(
        collector_abis() == ABI_SET,
        "Artifact collector accepts only package ABIs: aarch64, arm, i686, x86_64.",
        failures,
    )

    print("RAF_ALIGNMENT_PENDING: identity and repository drift markers are reported below without failing by default.")
    for needle in WATCH_PATTERNS:
        found = False
        for relative in WATCH_FILES:
            if not (ROOT / relative).exists():
                continue
            hits = line_hits(relative, needle)
            if hits:
                found = True
                lines = ",".join(str(line) for line in hits)
                print(f"RAF_ALIGNMENT_PENDING: {needle} in {relative}:{lines}")
        if not found:
            print(f"UPSTREAM_COMPATIBLE: no occurrence found for {needle}")

    print("CLAIM_BLOCKED: no runtime, device, performance, root, mirror, or APK validation claim is made by this validator.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
