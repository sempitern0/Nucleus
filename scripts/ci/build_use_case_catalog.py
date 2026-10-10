#!/usr/bin/env python3
"""Generate the human-readable catalog from the single JSON routing registry."""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path


def render(registry: dict) -> str:
    grouped: dict[str, list[dict]] = defaultdict(list)
    for item in registry["cases"]:
        grouped[item["domain"]].append(item)
    lines = [
        "# Game development use cases / Casos de uso", "",
        "This is the **problem-first navigation layer** for humans and coding agents. Start with",
        "a behavior you want to build, follow the linked contract, and keep the final",
        "gameplay/content/art policy in the consuming game. This catalog is also stored",
        "in machine-readable form in [`../use_case_registry.json`](../use_case_registry.json).", "",
        "## Choose a route", "",
        "1. Find the closest player/developer problem below.",
        "2. Open the linked canonical document and inspect the actual source owner.",
        "3. Read the relevant quickstart or tutorial for a minimum working scene.",
        "4. Author game-specific behavior next to its owning scene, not as a Nucleus Autoload.",
        "5. Validate headless + a real gameplay/editor scene where the change is observable.", "",
        "If none fits, prefer native Godot APIs and a game-local implementation. Extract",
        "a Nucleus feature only after independent reuse is demonstrated. See",
        "[`ai_composition_workflow.md`](ai_composition_workflow.md) for the coding workflow.", "",
    ]
    for domain, cases in grouped.items():
        lines.extend([
            f"## {domain}: use cases / casos de uso", "",
            "| You want to... | Start with Nucleus | The game still owns... |",
            "| --- | --- | --- |",
        ])
        for item in cases:
            mechanism = item["nucleus_role"].replace("|", "/")
            route = "../" + item["guide"].removeprefix("docs/")
            lines.append(
                f"| {item['need']} | [{mechanism}]({route}) | {item['game_owns']} |"
            )
        lines.append("")
    lines.extend([
        "## What the catalog does not promise", "",
        "- A component is not a finished RPG/MMO/survival/puzzle mechanic; the game wires inputs, state and feedback.",
        "- A valid API call is not a trust decision; authoritative worlds validate requests and visibility.",
        "- A smoke/headless test is not proof of feel, visuals, latency or frame budget on real hardware.",
        "- Generic tools should not replace Godot physics, animation, navigation or UndoRedo.",
        "- Do not add a global manager merely to make a generated mechanic easier to access.", "",
    ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    registry = json.loads((root / "docs/use_case_registry.json").read_text(encoding="utf-8"))
    output = root / "docs/guides/use_case_catalog.md"
    expected = render(registry)
    if args.check:
        if not output.is_file() or output.read_text(encoding="utf-8") != expected:
            print("Use-case catalog: OUT OF DATE; run build_use_case_catalog.py")
            return 1
        print("Use-case catalog: current")
        return 0
    output.write_text(expected, encoding="utf-8")
    print(f"Generated {output} from {len(registry['cases'])} use cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
