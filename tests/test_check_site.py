import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from check_site import check_site, main

REQUIRED_META = ["description", "viewport"]
BASE_HEAD = (
    '<meta name="description" content="d" /><meta name="viewport" content="v" />'
)


def write(site_root: Path, name: str, body: str) -> None:
    target = site_root / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        f"<!doctype html><html><head>{BASE_HEAD}</head><body>{body}</body></html>",
        encoding="utf-8",
    )


class CheckSiteTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.site_root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_existing_local_asset_passes(self) -> None:
        (self.site_root / "logo.png").write_bytes(b"png")
        write(self.site_root, "index.html", '<img src="./logo.png" alt="" />')
        self.assertEqual(check_site(self.site_root, REQUIRED_META), [])

    def test_missing_local_asset_fails(self) -> None:
        write(self.site_root, "index.html", '<img src="./missing.png" alt="" />')
        problems = check_site(self.site_root, REQUIRED_META)
        self.assertEqual(len(problems), 1)
        self.assertIn("missing local file './missing.png'", problems[0])

    def test_root_relative_asset_resolves_from_site_root(self) -> None:
        (self.site_root / "assets").mkdir()
        (self.site_root / "assets" / "style.css").write_text("body{}")
        write(
            self.site_root,
            "2026/09/02/post/index.html",
            '<link rel="stylesheet" href="/assets/style.css" />',
        )
        self.assertEqual(check_site(self.site_root, REQUIRED_META), [])

    def test_directory_link_resolves_to_index(self) -> None:
        write(self.site_root, "2026/09/02/post/index.html", "<p>post</p>")
        write(self.site_root, "index.html", '<a href="/2026/09/02/post/">post</a>')
        self.assertEqual(check_site(self.site_root, REQUIRED_META), [])

    def test_anchor_with_target_passes_and_without_fails(self) -> None:
        write(
            self.site_root,
            "index.html",
            '<a href="#projects">x</a><section id="projects"></section><a href="#nope">y</a>',
        )
        problems = check_site(self.site_root, REQUIRED_META)
        self.assertEqual(problems, ["index.html: anchor '#nope' has no target id"])

    def test_missing_required_meta_fails(self) -> None:
        (self.site_root / "index.html").write_text(
            '<!doctype html><html><head><meta name="viewport" content="v" /></head><body></body></html>'
        )
        problems = check_site(self.site_root, ["description", "viewport", "og:image"])
        self.assertEqual(
            problems,
            [
                "index.html: missing meta 'description'",
                "index.html: missing meta 'og:image'",
            ],
        )

    def test_external_references_are_ignored(self) -> None:
        write(
            self.site_root,
            "index.html",
            '<a href="https://heg.wtf">a</a><a href="mailto:me@heg.wtf">b</a>'
            '<script src="//cdn.example/x.js"></script><img src="data:image/png;base64,AA" alt="" />',
        )
        self.assertEqual(check_site(self.site_root, REQUIRED_META), [])

    def test_duplicate_ids_fail(self) -> None:
        write(self.site_root, "index.html", '<div id="top"></div><div id="top"></div>')
        problems = check_site(self.site_root, REQUIRED_META)
        self.assertEqual(problems, ["index.html: duplicate id 'top'"])

    def test_encoded_path_and_query_are_normalized(self) -> None:
        (self.site_root / "약봉투.png").write_bytes(b"png")
        write(
            self.site_root,
            "index.html",
            '<img src="./%EC%95%BD%EB%B4%89%ED%88%AC.png?v=2" alt="" />',
        )
        self.assertEqual(check_site(self.site_root, REQUIRED_META), [])

    def test_main_exit_codes(self) -> None:
        write(self.site_root, "index.html", "<p>ok</p>")
        with (
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            self.assertEqual(main([str(self.site_root)]), 0)
            write(self.site_root, "broken.html", '<img src="nope.png" alt="" />')
            self.assertEqual(main([str(self.site_root)]), 1)
            self.assertEqual(main([str(self.site_root / "does-not-exist")]), 2)


if __name__ == "__main__":
    unittest.main()
