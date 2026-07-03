from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_validator_reports_pending_alignment_without_promoting_claims() -> None:
    result = subprocess.run(
        [sys.executable, "tools/validate_raf_package_fork_alignment.py"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )

    assert result.returncode == 0, result.stderr + result.stdout
    assert "UPSTREAM_COMPATIBLE" in result.stdout
    assert "RAF_ALIGNMENT_PENDING" in result.stdout
    assert "CLAIM_BLOCKED" in result.stdout
    assert "TERMUX_APP__PACKAGE_NAME=\"com.termux\"" in result.stdout
    assert "/data/data/com.termux" in result.stdout
    assert "packages-cf.termux.dev" in result.stdout
    assert "no runtime, device, performance, root, mirror, or APK validation claim" in result.stdout
