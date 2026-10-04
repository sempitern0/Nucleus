#!/usr/bin/env python3
"""Validate Nucleus productization contracts using only the standard library."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

SEMVER_RE = re.compile(
	r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
	r"(?:-"
	r"(?:0|[1-9]\d*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)"
	r"(?:\.(?:0|[1-9]\d*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*"
	r")?"
	r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"
)

REQUIRED_FILES = (
	"README.md",
	"LICENSE",
	"CHANGELOG.md",
	"VERSION",
	"docs/policies/versioning.md",
	"docs/policies/godot_compatibility.md",
	"docs/policies/deprecation.md",
	"docs/policies/api_stability.md",
	"docs/guides/installation.md",
	"docs/guides/releasing.md",
	"scripts/release/package_release.py",
	".github/workflows/nucleus-package.yml",
)

README_TOKENS = (
	"docs/guides/installation.md",
	"docs/policies/versioning.md",
	"docs/policies/godot_compatibility.md",
	"docs/policies/deprecation.md",
	"docs/policies/api_stability.md",
	"CHANGELOG.md",
	"LICENSE",
)

TEXT_FILES = REQUIRED_FILES + ("project.godot",)


def read_text(
	path: Path,
	relative: str,
	errors: list[str],
) -> str:
	try:
		raw = path.read_bytes()
	except OSError as exc:
		errors.append(f"{relative}: unable to read ({exc})")
		return ""

	if b"\r" in raw:
		errors.append(f"{relative}: use LF line endings")

	if raw and not raw.endswith(b"\n"):
		errors.append(f"{relative}: missing final newline")

	try:
		return raw.decode("utf-8")
	except UnicodeDecodeError:
		errors.append(f"{relative}: file is not valid UTF-8")
		return ""


def audit(root: Path) -> list[str]:
	errors: list[str] = []

	for relative in REQUIRED_FILES:
		if not (root / relative).is_file():
			errors.append(f"{relative}: required productization file is missing")

	text_by_path: dict[str, str] = {}

	for relative in TEXT_FILES:
		path = root / relative
		if path.is_file():
			text_by_path[relative] = read_text(
				path,
				relative,
				errors,
			)

	version = text_by_path.get("VERSION", "").strip()

	if version and not SEMVER_RE.fullmatch(version):
		errors.append(f"VERSION: '{version}' is not valid Semantic Versioning")

	license_text = text_by_path.get("LICENSE", "")

	if license_text and "MIT License" not in license_text:
		errors.append("LICENSE: expected an MIT License declaration")

	if (
		license_text
		and "Permission is hereby granted, free of charge"
		not in license_text
	):
		errors.append("LICENSE: MIT grant text is incomplete")

	changelog = text_by_path.get("CHANGELOG.md", "")

	if changelog and "## [Unreleased]" not in changelog:
		errors.append("CHANGELOG.md: missing [Unreleased] section")

	readme = text_by_path.get("README.md", "")

	for token in README_TOKENS:
		if readme and token not in readme:
			errors.append(f"README.md: missing product contract link '{token}'")

	project = text_by_path.get("project.godot", "")

	if project and '"4.7"' not in project:
		errors.append(
			"project.godot: expected the declared Godot 4.7 feature line"
		)

	compatibility = text_by_path.get(
		"docs/policies/godot_compatibility.md",
		"",
	)

	if compatibility and "4.7.2-stable" not in compatibility:
		errors.append(
			"Godot compatibility policy: missing CI reference 4.7.2-stable"
		)

	return errors


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument(
		"--root",
		type=Path,
		default=Path.cwd(),
		help="Repository root; defaults to the current working directory.",
	)
	args = parser.parse_args()
	root = args.root.resolve()
	errors = audit(root)

	if errors:
		print("Nucleus productization audit: FAIL")
		for error in errors:
			print(f"  - {error}")
		return 1

	print("Nucleus productization audit: PASS")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
