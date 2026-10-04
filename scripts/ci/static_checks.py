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

TEST_ROOT = Path("tests/headless")
TEST_CASE_PATH = TEST_ROOT / "test_case.gd"
TEST_MANIFEST_PATH = TEST_ROOT / "test_manifest.gd"
TEST_CASE_EXTENDS = 'extends "res://tests/headless/test_case.gd"'
TEST_RUN_RE = re.compile(r"(?m)^func run\(\) -> Dictionary:\s*$")
TEST_FUNC_RE = re.compile(r"(?m)^func ([A-Za-z_][A-Za-z0-9_]*)\s*\(")
EXPECT_CALL_RE = re.compile(r"(?<![\w.])(expect_[A-Za-z0-9_]+)\s*\(")
LEGACY_TEST_HELPER_RE = re.compile(r"(?<![\w.])(check|result)\s*\(")
MANIFEST_SUITE_RE = re.compile(
	r'preload\("(res://tests/headless/[^"]+_test\.gd)"\)'
)


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


def check_test_contract(repository_root: Path) -> list[str]:
	errors: list[str] = []
	test_root = repository_root / TEST_ROOT
	test_case_path = repository_root / TEST_CASE_PATH
	manifest_path = repository_root / TEST_MANIFEST_PATH

	if not test_case_path.is_file():
		return [f"{TEST_CASE_PATH.as_posix()}: missing test base"]

	if not manifest_path.is_file():
		return [f"{TEST_MANIFEST_PATH.as_posix()}: missing suite manifest"]

	test_case_text = test_case_path.read_text(encoding="utf-8")
	available_helpers = set(TEST_FUNC_RE.findall(test_case_text))

	if "finish" not in available_helpers:
		errors.append(
			f"{TEST_CASE_PATH.as_posix()}: test base must define finish()"
		)

	manifest_text = manifest_path.read_text(encoding="utf-8")
	manifest_suites = set(MANIFEST_SUITE_RE.findall(manifest_text))
	discovered_suites: set[str] = set()

	for suite_path in sorted(test_root.glob("*_test.gd")):
		relative = suite_path.relative_to(repository_root).as_posix()
		resource_path = "res://" + relative
		discovered_suites.add(resource_path)
		text = suite_path.read_text(encoding="utf-8")

		if TEST_CASE_EXTENDS not in text:
			errors.append(
				f"{relative}: test suite must extend tests/headless/test_case.gd"
			)

		if not TEST_RUN_RE.search(text):
			errors.append(
				f"{relative}: test suite must define run() -> Dictionary"
			)

		if "return finish()" not in text:
			errors.append(
				f"{relative}: test suite must return finish()"
			)

		for helper in sorted(set(EXPECT_CALL_RE.findall(text))):
			if helper not in available_helpers:
				errors.append(
					f"{relative}: unknown test helper {helper}()"
				)

		for legacy_helper in sorted(set(LEGACY_TEST_HELPER_RE.findall(text))):
			errors.append(
				f"{relative}: unsupported test helper {legacy_helper}(); "
				"use expect_*() and finish()"
			)

	for resource_path in sorted(discovered_suites - manifest_suites):
		errors.append(
			f"{TEST_MANIFEST_PATH.as_posix()}: missing suite {resource_path}"
		)

	for resource_path in sorted(manifest_suites - discovered_suites):
		errors.append(
			f"{TEST_MANIFEST_PATH.as_posix()}: references missing suite "
			f"{resource_path}"
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

	errors.extend(check_test_contract(repository_root))

	if errors:
		print("Nucleus static checks: FAIL")
		for error in errors:
			print(f"  - {error}")
		return 1

	print("Nucleus static checks: PASS")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
