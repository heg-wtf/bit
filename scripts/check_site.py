"""Static site checker for GitHub Pages output.

Validates every HTML file under a directory:
- local asset references (img src, link href, script src, a href) point to existing files
- in-page anchors (#id) resolve to an element id in the same document
- required <meta> tags are present
- element ids are unique

Usage: python3 scripts/check_site.py docs --require-meta description viewport og:image
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

EXTERNAL_PREFIXES = (
    "http://",
    "https://",
    "mailto:",
    "tel:",
    "data:",
    "//",
    "javascript:",
)
REFERENCE_ATTRIBUTES = {
    "a": "href",
    "img": "src",
    "link": "href",
    "script": "src",
    "iframe": "src",
    "source": "src",
}


@dataclass
class DocumentFacts:
    ids: list[str] = field(default_factory=list)
    references: list[str] = field(default_factory=list)
    meta_keys: set[str] = field(default_factory=set)


class FactCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.facts = DocumentFacts()

    def handle_starttag(
        self, tag: str, attributes: list[tuple[str, str | None]]
    ) -> None:
        attribute_map = {key: value for key, value in attributes if value is not None}
        if "id" in attribute_map:
            self.facts.ids.append(attribute_map["id"])
        if tag == "meta":
            for key in ("name", "property"):
                if key in attribute_map:
                    self.facts.meta_keys.add(attribute_map[key])
        reference_attribute = REFERENCE_ATTRIBUTES.get(tag)
        if reference_attribute and reference_attribute in attribute_map:
            self.facts.references.append(attribute_map[reference_attribute])


def collect_facts(html_text: str) -> DocumentFacts:
    collector = FactCollector()
    collector.feed(html_text)
    return collector.facts


def is_external(reference: str) -> bool:
    return reference.startswith(EXTERNAL_PREFIXES)


def resolve_local_path(site_root: Path, html_path: Path, reference: str) -> Path:
    path_part = unquote(urlsplit(reference).path)
    if path_part.startswith("/"):
        return site_root / path_part.lstrip("/")
    return html_path.parent / path_part


def check_document(
    site_root: Path, html_path: Path, required_meta: list[str]
) -> list[str]:
    problems: list[str] = []
    facts = collect_facts(html_path.read_text(encoding="utf-8"))
    relative_name = html_path.relative_to(site_root)

    duplicate_ids = {value for value in facts.ids if facts.ids.count(value) > 1}
    for duplicate in sorted(duplicate_ids):
        problems.append(f"{relative_name}: duplicate id '{duplicate}'")

    for meta_key in required_meta:
        if meta_key not in facts.meta_keys:
            problems.append(f"{relative_name}: missing meta '{meta_key}'")

    for reference in facts.references:
        if not reference or is_external(reference):
            continue
        if reference.startswith("#"):
            anchor = reference[1:]
            if anchor and anchor not in facts.ids:
                problems.append(f"{relative_name}: anchor '#{anchor}' has no target id")
            continue
        target = resolve_local_path(site_root, html_path, reference)
        if target.is_dir():
            target = target / "index.html"
        if not target.exists():
            problems.append(f"{relative_name}: missing local file '{reference}'")
    return problems


def check_site(site_root: Path, required_meta: list[str]) -> list[str]:
    problems: list[str] = []
    for html_path in sorted(site_root.rglob("*.html")):
        problems.extend(check_document(site_root, html_path, required_meta))
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "site_root", type=Path, help="directory containing the built site"
    )
    parser.add_argument(
        "--require-meta",
        nargs="*",
        default=["description", "viewport"],
        help="meta name/property keys every page must define",
    )
    arguments = parser.parse_args(argv)

    if not arguments.site_root.is_dir():
        print(f"not a directory: {arguments.site_root}", file=sys.stderr)
        return 2

    problems = check_site(arguments.site_root, arguments.require_meta)
    for problem in problems:
        print(problem)
    page_count = len(list(arguments.site_root.rglob("*.html")))
    if problems:
        print(f"{len(problems)} problem(s) in {page_count} page(s)", file=sys.stderr)
        return 1
    print(f"ok: {page_count} page(s) checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
