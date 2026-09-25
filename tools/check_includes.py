"""Resolve every #include <...> in this repository against what it ships.

Why this exists: nothing here compiles in CI (the runner has no MetaTrader), so
a wrong include path can sit in the tree indefinitely --
Indicators/MedianRenko/TradeHistory.mq5 asked for <AZ-INVEST/Double.mqh> while
the repo ships Include/Double.mqh, and no clean checkout of that indicator had
compiled since. Resolving includes needs no compiler, so it can gate every push.

Two traps this deliberately handles, because a naive grep gets both wrong:

  * ~a third of the sources are UTF-16LE, so plain grep/git grep never sees
    their #include lines at all.
  * MQL is a Windows language: include paths use either slash, and the platform
    treats them case-insensitively. Comparisons here are normalised the same way.

Run:  python3 tools/check_includes.py
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
INCLUDE_ROOT = REPO_ROOT / "Include"
SOURCE_SUFFIXES = {".mq4", ".mq5", ".mqh"}
INCLUDE_RE = re.compile(r"^\s*#include\s+<([^>]+)>", re.MULTILINE)
# `#include "x.mqh"` resolves relative to the including file, not the include
# root -- a different lookup, so it gets its own pattern and its own check.
LOCAL_INCLUDE_RE = re.compile(r'^\s*#include\s+"([^"]+)"', re.MULTILINE)

# Headers the MetaTrader platform itself provides (MQL5/Include of any terminal).
# Not shipped here and not expected to be.
PLATFORM_PREFIXES = (
    "arrays/",
    "canvas/",
    "charts/",
    "controls/",
    "expert/",
    "files/",
    "generic/",
    "indicators/",
    "math/",
    "objects/",
    "strings/",
    "tools/",
    "trade/",
)
PLATFORM_HEADERS = {
    "movingaverages.mqh",
    "errordescription.mqh",
    "stdliberr.mqh",
    "stderror.mqh",
}

# Headers that ship with the *sibling* products (Range Bars, Tick Chart, Volume
# Chart, Seconds Chart, Line Break), referenced here behind #ifdef so a customer
# who owns one of those can build against it. Root AGENTS.md says plainly that
# uncommenting those defines will not compile in this repo. Absent on purpose.
SIBLING_PRODUCT_HEADERS = {
    "az-invest/sdk/linebreakchart.mqh",
    "az-invest/sdk/rangebarindicator.mqh",
    "az-invest/sdk/rangebars.mqh",
    "az-invest/sdk/secondschart.mqh",
    "az-invest/sdk/secondschartindicator.mqh",
    "az-invest/sdk/tickchart.mqh",
    "az-invest/sdk/tickchartindicator.mqh",
    "az-invest/sdk/volumebarchart.mqh",
    "az-invest/sdk/volumechartindicator.mqh",
}


def read_source(path):
    """Decode an MQL source whatever encoding it was saved in.

    MetaEditor writes UTF-16LE by default; parts of this tree are UTF-8. A
    UTF-16 file read as UTF-8 yields NUL-separated bytes and matches nothing.
    """
    raw = path.read_bytes()
    if raw[:2] == b"\xff\xfe":
        return raw.decode("utf-16-le", errors="replace")
    if raw[:2] == b"\xfe\xff":
        return raw.decode("utf-16-be", errors="replace")
    return raw.decode("utf-8", errors="replace")


def normalise(include_path):
    """MQL accepts either slash and is case-insensitive about include paths."""
    return include_path.replace("\\", "/").lower()


def shipped_headers():
    """Every header under Include/, keyed the way an #include would name it.

    The value keeps the real on-disk spelling, so a report can quote it exactly.
    """
    return {
        normalise(str(p.relative_to(INCLUDE_ROOT))): p
        for p in INCLUDE_ROOT.rglob("*")
        if p.is_file() and p.suffix.lower() == ".mqh"
    }


def source_files():
    return sorted(
        p
        for p in REPO_ROOT.rglob("*")
        if p.suffix.lower() in SOURCE_SUFFIXES and ".git" not in p.parts
    )


def is_expected_elsewhere(include_path):
    key = normalise(include_path)
    if key in SIBLING_PRODUCT_HEADERS or key in PLATFORM_HEADERS:
        return True
    return key.startswith(PLATFORM_PREFIXES)


def unresolved_includes():
    """[(source, include, line)] for every include this repo should ship but doesn't."""
    shipped = shipped_headers()
    problems = []
    for source in source_files():
        text = read_source(source)
        for match in INCLUDE_RE.finditer(text):
            include_path = match.group(1).strip()
            if is_expected_elsewhere(include_path) or normalise(include_path) in shipped:
                continue
            # count to the group, not the match: the leading `^\s*` can swallow
            # the newline of a preceding blank line and report the line before.
            line = text.count("\n", 0, match.start(1)) + 1
            problems.append((source.relative_to(REPO_ROOT), include_path, line))
    return problems


def unresolved_local_includes():
    """[(source, include, line)] for every `#include "..."` with no file beside it."""
    problems = []
    for source in source_files():
        text = read_source(source)
        for match in LOCAL_INCLUDE_RE.finditer(text):
            include_path = match.group(1).strip()
            target = source.parent / include_path.replace("\\", "/")
            if target.exists():
                continue
            line = text.count("\n", 0, match.start(1)) + 1
            problems.append((source.relative_to(REPO_ROOT), include_path, line))
    return problems


def main():
    sources = source_files()
    problems = unresolved_includes()
    local_problems = unresolved_local_includes()

    for source, include_path, line in local_problems:
        print(f'{source}:{line}: #include "{include_path}" -- no such file beside it')
    if local_problems and not problems:
        return 1

    if not problems:
        print(f"All includes resolve across {len(sources)} sources.")
        return 0

    print(f"{len(problems)} unresolved include(s) across {len(sources)} sources:\n")
    shipped = shipped_headers()
    for source, include_path, line in problems:
        print(f"{source}:{line}: #include <{include_path}>")
        basename = normalise(Path(include_path).name)
        elsewhere = [k for k in shipped if normalise(Path(k).name) == basename]
        if elsewhere:
            actual = shipped[elsewhere[0]].relative_to(REPO_ROOT)
            print(f"    this repo ships it as: {actual}")
    print(
        "\nEither correct the include path or add the header. If it belongs to a "
        "sibling product or the platform, add it to the lists in this script with "
        "the reason."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
