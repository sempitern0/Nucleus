#!/usr/bin/env python3
"""Verify every top-level Nucleus subsystem is mapped to documentation."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def discover_directories(root: Path, relative: str) -> set[str]:
	base = root / relative
	if not base.is_dir():
		return set()
	return {
		path.relative_to(root).as_posix()
		for path in base.iterdir()
		if path.is_dir()
	}


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--root", type=Path, default=Path.cwd())
	args = parser.parse_args()
	root = args.root.resolve()

	manifest_path = root / "docs" / "documentation_coverage.json"
	if not manifest_path.is_file():
		print("Documentation audit: FAIL")
		print("  - missing docs/documentation_coverage.json")
		return 1

	manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
	coverage: dict[str, list[str]] = manifest.get("coverage", {})

	discovered: set[str] = set()
	discovered |= discover_directories(root, "core")
	discovered |= discover_directories(root, "modules")
	discovered |= discover_directories(root, "components/gameplay")
	discovered |= discover_directories(root, "components/ui")
	discovered |= discover_directories(root, "components/world")

	errors: list[str] = []
	mapped = set(coverage)

	for subsystem in sorted(discovered - mapped):
		errors.append(f"unmapped subsystem: {subsystem}")

	for subsystem in sorted(mapped - discovered):
		errors.append(f"manifest references missing subsystem: {subsystem}")

	for subsystem, documents in sorted(coverage.items()):
		if not documents:
			errors.append(f"{subsystem}: no documentation targets")
			continue

		for document in documents:
			if not (root / document).is_file():
				errors.append(f"{subsystem}: missing documentation file {document}")

	if errors:
		print("Documentation audit: FAIL")
		for error in errors:
			print(f"  - {error}")
		return 1

	print(
		"Documentation audit: PASS "
		f"({len(discovered)} top-level subsystems covered)"
	)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
