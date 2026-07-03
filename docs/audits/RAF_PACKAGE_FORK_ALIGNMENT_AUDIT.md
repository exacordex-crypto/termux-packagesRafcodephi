# Rafcodephi package fork alignment audit

## Scope and claim boundary

This repository builds Termux `.deb` package infrastructure and bootstrap inputs. It does **not** build, sign, or validate an Android APK.

The separate `termux-app-rafacodephi` repository is the Android APK/bootstrap consumer. Any runtime, APK signing, APK validation, or device compatibility claim belongs there, after explicit evidence from that app repository and its release pipeline.

## Facts observed

- The `Packages` workflow keeps the package ABI matrix at `aarch64`, `arm`, `i686`, and `x86_64`.
- `scripts/ci/collect-package-artifacts.sh` accepts only `aarch64`, `arm`, `i686`, and `x86_64` for package artifact collection.
- Upstream Termux repository URLs are still used where package/bootstrap tooling needs a real published repository, including `https://packages-cf.termux.dev`.
- Upstream Termux identity values are still present in package/build properties, including `TERMUX_APP__PACKAGE_NAME="com.termux"` and derived `/data/data/com.termux` paths.

## RAF_ALIGNMENT_PENDING

Rafcodephi identity alignment remains pending until it is validated end-to-end against all of these contracts:

- `TERMUX_APP__PACKAGE_NAME`
- `TERMUX__ROOTFS`
- `TERMUX__PREFIX`
- generated bootstrap contents
- the consuming `termux-app-rafacodephi` APK/bootstrap integration

These values are build/package contracts, not cosmetic strings. Changing them without bootstrap and APK compatibility proof could produce packages that install into paths the consuming app does not own or initialize correctly.

## UPSTREAM_COMPATIBLE

Keeping upstream Termux names, package paths, and `packages-cf.termux.dev` URLs is currently the conservative, upstream-compatible behavior for this package fork. This preserves compatibility with existing Termux package assumptions and avoids inventing an unpublished Rafcodephi package mirror.

## CLAIM_BLOCKED

The following claims are blocked in this repository until explicit evidence is added from the correct pipeline:

- Rafcodephi package mirror is published and authoritative.
- Runtime has been validated on a device.
- Android APK has been built, signed, or validated here.
- Performance has improved.
- Root behavior is supported or validated.
- Final compatibility with Moto E7 Power is proven.

## Safe changes now

Safe changes are structural and documentary: audits, validators, CI checks, and reports that expose upstream compatibility and pending Rafcodephi alignment without changing build behavior.

## Changes blocked until explicit decision

The following changes should stay blocked until there is an explicit compatibility decision and validation plan:

- Replacing `com.termux` with a Rafcodephi package name.
- Replacing `/data/data/com.termux` paths.
- Replacing `packages-cf.termux.dev` with a Rafcodephi URL.
- Changing `repo.json` to point to an unpublished mirror.
- Changing bootstrap generation in a way that alters install paths or package source trust.

## Compatibility risks

Changing upstream identity or repository values can break package installation paths, bootstrap generation, artifact consumers, existing package scripts, and compatibility with upstream Termux tooling. Any such change should be reviewed as a package/bootstrap contract migration, not as a branding-only edit.
