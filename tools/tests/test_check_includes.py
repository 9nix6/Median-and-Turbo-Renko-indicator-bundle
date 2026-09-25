"""Tests for tools/check_includes.py (issue #19)."""

import importlib.util
import tempfile
import unittest
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = TOOLS_DIR.parent


def load():
    path = TOOLS_DIR / "check_includes.py"
    spec = importlib.util.spec_from_file_location("_uut_check_includes", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ReadSource(unittest.TestCase):
    """~a third of this tree is UTF-16LE; read it as UTF-8 and every #include
    line becomes invisible, which is how the TradeHistory bug survived."""

    def setUp(self):
        self.m = load()

    def read(self, data):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "Sample.mq5"
            path.write_bytes(data)
            return self.m.read_source(path)

    def test_utf16le_with_bom(self):
        text = '#include <Double.mqh>\r\n'
        self.assertIn("#include <Double.mqh>", self.read(b"\xff\xfe" + text.encode("utf-16-le")))

    def test_utf16be_with_bom(self):
        text = '#include <Double.mqh>\r\n'
        self.assertIn("#include <Double.mqh>", self.read(b"\xfe\xff" + text.encode("utf-16-be")))

    def test_plain_utf8(self):
        self.assertIn("#include <Double.mqh>", self.read(b"#include <Double.mqh>\r\n"))


class Normalise(unittest.TestCase):
    def setUp(self):
        self.m = load()

    def test_either_slash_and_any_case_are_the_same_include(self):
        """MQL is a Windows language: both separators, case-insensitive."""
        self.assertEqual(self.m.normalise(r"Trade\Trade.mqh"), self.m.normalise("trade/TRADE.mqh"))

    def test_platform_headers_are_not_expected_in_this_repo(self):
        for include in (r"Trade\Trade.mqh", "Generic/ArrayList.mqh", "MovingAverages.mqh"):
            with self.subTest(include=include):
                self.assertTrue(self.m.is_expected_elsewhere(include))

    def test_sibling_product_headers_are_not_expected_in_this_repo(self):
        """Range Bars / Tick Chart / etc. ship with those products; root
        AGENTS.md says uncommenting their defines will not compile here."""
        self.assertTrue(self.m.is_expected_elsewhere("AZ-INVEST/SDK/RangeBars.mqh"))

    def test_a_header_this_repo_owns_is_expected_here(self):
        self.assertFalse(self.m.is_expected_elsewhere("AZ-INVEST/SDK/MedianRenko.mqh"))
        self.assertFalse(self.m.is_expected_elsewhere("Double.mqh"))


class LineNumbers(unittest.TestCase):
    def setUp(self):
        self.m = load()

    def test_a_blank_line_before_the_include_does_not_shift_the_report(self):
        text = "#property version \"1.0\"\r\n\r\n#include <Nope.mqh>\r\n"
        match = self.m.INCLUDE_RE.search(text)
        self.assertEqual(text.count("\n", 0, match.start(1)) + 1, 3)


class TheRepositoryItself(unittest.TestCase):
    def setUp(self):
        self.m = load()

    def test_every_include_resolves(self):
        problems = self.m.unresolved_includes()
        self.assertEqual(
            problems,
            [],
            "\n".join(f"{s}:{ln}: #include <{i}>" for s, i, ln in problems),
        )

    def test_the_tree_is_actually_being_scanned(self):
        """A guard against the check silently passing because it found nothing."""
        self.assertGreater(len(self.m.source_files()), 90)
        self.assertGreater(len(self.m.shipped_headers()), 20)

    def test_tradehistory_includes_double_at_the_root(self):
        """The specific regression: the header ships at Include/Double.mqh, and
        every other consumer in both repos includes it without a prefix."""
        source = REPO_ROOT / "Indicators" / "MedianRenko" / "TradeHistory.mq5"
        text = self.m.read_source(source)
        self.assertIn("#include <Double.mqh>", text)
        self.assertNotIn("AZ-INVEST/Double.mqh", text)


if __name__ == "__main__":
    unittest.main()
