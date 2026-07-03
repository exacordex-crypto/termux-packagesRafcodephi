# RAFCODEPHI Package Namespace Boundary

## Status

`namespace_boundary / integration_audit / claim_boundary`

## Purpose

This repository builds Termux package archives. It does not build or sign the Android APK.

The companion app fork uses the Android package identity:

```text
com.termux.rafacodephi
```

This package repository still preserves upstream Termux package defaults unless a specific build path overrides them.

## Observed boundary

The package build properties define the app package default as:

```text
TERMUX_APP__PACKAGE_NAME=com.termux
TERMUX_APP__DATA_DIR=/data/data/$TERMUX_APP__PACKAGE_NAME
```

That is not automatically equivalent to the companion app package identity:

```text
com.termux.rafacodephi
```

## Claim allowed

This repository may claim package-build infrastructure and package artifact collection when the corresponding CI or local build evidence exists.

## Claim blocked

This repository must not claim, from package-build evidence alone:

- a published independent RAFCODEPHI apt repository;
- full runtime integration with `com.termux.rafacodephi`;
- physical device install success;
- bootstrap runtime success;
- package mirror readiness;
- app APK signing or release readiness.

## Safe integration rule

A RAFCODEPHI-specific package build must explicitly record which namespace is used:

```text
TERMUX_APP__PACKAGE_NAME=com.termux.rafacodephi
TERMUX_APP__DATA_DIR=/data/data/com.termux.rafacodephi
```

or must state that it intentionally remains upstream-compatible:

```text
TERMUX_APP__PACKAGE_NAME=com.termux
```

## Next safe step

Add a small validator that checks whether the package namespace is upstream-compatible or RAFCODEPHI-specific and reports the state without changing the build defaults.

## Non-goal

This document does not change package build behavior. It only records the namespace boundary so future package artifacts are not mistaken for complete app/runtime integration.
