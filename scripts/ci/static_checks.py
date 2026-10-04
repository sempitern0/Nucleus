#!/usr/bin/env python3
"""Dependency-free repository checks for Nucleus source conventions."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

TEXT_SUFFIXES = {
	".cfg",
	".gd",
	".gdshader",
	".json",
	".md",
	".py",
	".sh",
	".tscn",
	".tres",
	".yaml",
	".yml",
}
SKIP_DIRS = {".ci", ".git", ".godot", "build", "dist"}
CLASS_NAME_RE = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)\s*$")


def iter_text_files(root: Path):
	for path in root.rglob("*"):
		if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
			continue
		if any(part in SKIP_DIRS for part in path.parts):
			continue
		yield path


def check_file(path: Path, repository_root: Path) -> list[str]:
	errors: list[str] = []
	relative = path.relative_to(repository_root).as_posix()
	raw = path.read_bytes()

	if b"\r\n" in raw or b"\r" in raw:
		errors.append(f"{relative}: use LF line endings")

	if raw and not raw.endswith(b"\n"):
		errors.append(f"{relative}: missing final newline")

	try:
		text = raw.decode("utf-8")
	except UnicodeDecodeError:
		return [f"{relative}: file is not valid UTF-8"]

	lines = text.splitlines()

	for number, line in enumerate(lines, start=1):
		if line.rstrip() != line:
			errors.append(f"{relative}:{number}: trailing whitespace")

		if path.suffix == ".gd" and len(line) > 100:
			errors.append(
				f"{relative}:{number}: GDScript line exceeds 100 columns"
			)

	if path.suffix == ".gd":
		for number, line in enumerate(lines, start=1):
			if line.startswith(" "):
				errors.append(
					f"{relative}:{number}: GDScript indentation must use tabs"
				)

			match = CLASS_NAME_RE.match(line)
			if match and not match.group(1).startswith("Nucleus"):
				errors.append(
					f"{relative}:{number}: public class_name must use Nucleus prefix"
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
	repository_root = args.root.resolve()

	errors: list[str] = []

	for path in iter_text_files(repository_root):
		errors.extend(check_file(path, repository_root))

	if errors:
		print("Nucleus static checks: FAIL")
		for error in errors:
			print(f"  - {error}")
		return 1

	print("Nucleus static checks: PASS")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
