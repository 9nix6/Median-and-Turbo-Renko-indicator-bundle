# AGENTS.md — Median and Turbo Renko indicator bundle (MT5 SDK + companion code)

**READ THIS FIRST, then the per-directory `AGENTS.md` for whichever area you land in.**
This file is navigational. It does not restate code; it tells you which file and which
function to open.

## The single most important fact

**The Renko indicator itself is NOT in this repository.** This repo is the *open-source
companion SDK* to a closed-source, commercially sold MT5 indicator. The bar-building
engine — the tick-to-bar conversion that turns M1/tick data into Renko bricks — ships
only as a compiled `.ex5` that the customer downloads from MQL5 Market or az-invest.eu.
There is no `.mq5` for it anywhere here.

So: **"the chart isn't building" / "bars are wrong" is almost never a bug in this repo.**
What lives here is everything that *consumes* those bars:

| Layer | Where | What it is |
|---|---|---|
| Bar engine (closed source) | not in this repo | builds the Renko bricks, publishes them as 21 indicator buffers |
| Buffer-reading client library | `Include/AZ-INVEST/SDK/MedianRenko.mqh` | `iCustom()` handle + `CopyBuffer()` wrappers |
| Indicator-porting shim | `Include/AZ-INVEST/SDK/MedianRenkoIndicator.mqh` | makes an ordinary MT5 indicator calculate on Renko OHLC |
| 64 ported indicators | `Indicators/MedianRenko/` | stock/community MT5 indicators patched through that shim |
| Example + production EAs | `Experts/` | robots trading off the Renko bars |

Directory nodes: [`Include/AGENTS.md`](Include/AGENTS.md) ·
[`Indicators/AGENTS.md`](Indicators/AGENTS.md) · [`Experts/AGENTS.md`](Experts/AGENTS.md)

## Product → source-tree map (for support)

There is **one** bar engine with several *presets*, not several source trees. A customer's
purchased product name maps to a preprocessor define and/or a preset enum value, not to a
folder.

**Presets** — `ENUM_CUSTOM_BAR_TYPE` in `Include/AZ-INVEST/SDK/CommonSettings.mqh`
(exposed to the user as the `InpPredefinedSetting` / "Renko mode preset" input):
`cbtCustom`, `cbtRenko`, `cbtMedianRenko`, `cbtPointO`, `cbtTurboRenko075`,
`cbtHybridRenko075`. So **Median Renko and Turbo Renko are two presets of the same
indicator**, and both are served by the same code in this repo. "Turbo Renko is broken but
Median Renko is fine" therefore points at the closed-source engine or at the customer's
input values, not at a distinct source tree.

**Product editions** — selected by `#define` (see `Include/AZ-INVEST/CustomBarConfig.mqh`
and the top of each `.mq5` in `Experts/`):

| Customer bought | Define(s) | Indicator path the code calls via `iCustom()` |
|---|---|---|
| "Median and Turbo renko indicator bundle" (MQL5 Market) | `MQL5_MARKET_VERSION` + `ULTIMATE_RENKO_LICENSE` (the repo default) | `Market\Median and Turbo renko indicator bundle` |
| "Ultimate Renko" (az-invest.eu direct) | `ULTIMATE_RENKO_LICENSE` only | `UltimateRenko` |
| P-Renko BR Ultimate (Brazilian edition) | `P_RENKO_BR_PRO` | `P-RENKO BR Ultimate` |
| P-Renko (all) | `P_RENKO_BR_PRO` + `P_RENKO_ALL` | `P-RENKO` |

That table is resolved in the `#ifdef` ladder at the **top of
`Include/AZ-INVEST/SDK/MedianRenko.mqh`**, which sets `RENKO_INDICATOR_NAME`. See
[`Include/AGENTS.md`](Include/AGENTS.md) for why this is the #1 cause of "won't load".

**Sibling product lines** (Range Bars, Tick Chart, Volume Chart, Seconds Chart, Line Break)
are referenced by `#ifdef` in `CustomBarConfig.mqh`, `Experts/2MA_Cross.mq5` and
`Experts/PriceMA_Cross.mq5`, but **their headers are not in this repo** — they ship with
those separate products. Uncommenting those defines here will not compile.

## Symptom → where to look

| Customer says | Start here |
|---|---|
| "indicator won't load after reinstall", "EA says indicator init failed" | `RENKO_INDICATOR_NAME` ladder at top of `Include/AZ-INVEST/SDK/MedianRenko.mqh`; edition table above. Wrong edition ⇒ `iCustom()` resolves to a path that does not exist on that customer's machine. |
| "EA can't see my Renko settings" / log line `Failed to load indicator settings - Renko indicator not on chart` | `MedianRenko::Init()` (`MedianRenko.mqh`) → `CCustomChartSettingsBase::Load()` (`Include/AZ-INVEST/SDK/CustomChartSettingsBase.mqh`). The settings handshake is a `.set` file, see [`Include/AGENTS.md`](Include/AGENTS.md). |
| "EA works live but not in the Strategy Tester" | `SHOW_INDICATOR_INPUTS` must be `#define`d and the EA recompiled. `Experts/AGENTS.md`. |
| "bars/indicator values are wrong after a reconnect or timeframe change" | `MedianRenkoIndicator::OnCalculate()` and `BufferSynchronizationCheck()` in `Include/AZ-INVEST/SDK/MedianRenkoIndicator.mqh` — the resync/reload state machine. |
| "settings changes don't take effect until I reattach" | `MedianRenko::Reload()` + `MedianRenko::GetRuntimeId()` (buffer `RENKO_RUNTIME_ID`, index 20) and `CCustomChartSettingsBase::Changed()`. |
| "a ported indicator plots nothing / is shifted" | that indicator in `Indicators/MedianRenko/`; check it follows the porting contract in [`Indicators/AGENTS.md`](Indicators/AGENTS.md). |
| "objects/arrows are drawn at the wrong bar" | `MedianRenkoIndicator::TimeToCustomChartTime()` / `CustomChartTimeToCanvasTime()` / `CanvasXYToTimePrice()` (tail of `MedianRenkoIndicator.mqh`) — the Renko-time ↔ canvas-time mapping. |
| "offline chart is empty" | **No offline-chart or custom-symbol code path is active in this repo.** See "Offline charts / custom symbols" below. |
| "activation / licence / ActivationManager" | **Nothing in this repo.** See "Licensing" below. |
| EA trade sizing, SL/TP rejected, trailing stop misbehaving | `Include/AZ-INVEST/SDK/TradeFunctions.mqh`, `TradingChecks.mqh`, `TradeManager.mqh`. |
| Renko_EA entry/exit/filter logic | `Experts/Renko_EA_Logic.mqh` (`CEaLogic`), not `Renko_EA.mq5` (which is only inputs + wiring). |

## Offline charts / custom symbols

MT5 has no MT4-style offline charts; the equivalent in this product line is a **custom
symbol** whose bars the indicator writes. The SDK carries that code path behind
`#ifdef USE_CUSTOM_SYMBOL` (`CUSTOM_SYMBOL_SETTINGS` in `CommonSettings.mqh`; the
`InpCustomChartName` / `InpApplyTemplate` / `InpForBacktester` inputs in
`CustomChartInputs.mqh`; the branches in `CustomChartSettingsBase.mqh`).

`USE_CUSTOM_SYMBOL` is **never defined anywhere in this repository** (verified by grep).
Everything compiled here therefore runs in "indicator-on-a-normal-chart" mode: the Renko
bars live in indicator buffers on a normal symbol/timeframe chart, and consumers read
them through `MedianRenko`. Custom-symbol generation is done by the closed-source
indicator. Treat an empty custom-symbol chart as an engine/product issue, not a repo issue,
and do not claim this repo implements it.

## Licensing / activation

**There is no licensing, activation, `WebRequest`, or account-check code in this
repository** (verified by grep: the only hits for "licence/license" are GPL/MIT headers,
and "activation" hits are MT5 *pending-order activation price* checks in
`TradingChecks.mqh`). `*_LICENSE` defines here are **edition switches**, not licence
enforcement — they only pick which indicator name/ chart name string to use.

Activation lives in the sibling repos, and a support agent should route there:

- `../AzInvestSales_Azure` — serves activation over HTTP (order/seat lookup).
- `../AzInvestProducts_Lock` — the licence-protection side that the closed-source
  products are built against.
- `../installer-builder` — ships the Windows installers and `ActivationManager.exe` that
  the customer actually runs.

So "the indicator won't activate" is an `AzInvestSales_Azure` / `AzInvestProducts_Lock` /
`installer-builder` question; "the indicator activated but the chart is blank" is a
bar-engine question; "my EA can't read the chart's settings" is *this* repo.

## Build & deploy (not obvious)

- **No makefile, no CI-for-release, no script.** `.mq5` is compiled by **MetaEditor**
  (bundled with MT5, Windows only) — F7, or `metaeditor64.exe /compile:...` headless.
  There is no macOS/Linux MQL5 compiler; do not attempt to build from this checkout.
- **Include resolution is by MT5 data folder, not by repo layout.** `<AZ-INVEST/...>`
  resolves against `<MT5 data folder>/MQL5/Include/`. The repo's top-level `Experts/`,
  `Include/`, `Indicators/` mirror `MQL5/Experts`, `MQL5/Include`, `MQL5/Indicators`
  one-to-one — the install step is literally "copy these three folders into `MQL5/`"
  (as `README.md` says). A file compiled outside that layout will fail on `#include`.
- **The repository holds sources only.** `.ex5`/`.ex4` are gitignored and no binary is committed.
  Compiled binaries are produced by CI and attached to each release, so the ones a customer gets
  were built from exactly the sources beside them. Committing binaries is what let a 2021
  `Renko_EA.ex5` ship for five years after its source was fixed.
- **CI compiles everything** — `.github/workflows/mql-build.yml`, see the CI section below.
  It is also the only supported source of binaries.

## Known risk

**The `.set` handshake has no version field.** `Load()` rejects a settings file whose
a settings file whose size does not match the structs this build expects, which catches any layout
change that adds, removes or retypes a field. A *same-size reordering* is still undetectable — that
needs a version field in the file, and the writer is the closed-source indicator, so it cannot be
added from this repository alone. See `Include/AGENTS.md`.

## CI — `MQL Build` (`.github/workflows/mql-build.yml`)

One workflow, three stages, each gating the next.

**1. `Scan`** (hosted, seconds, no platform needed)
- `gitleaks` over the full history.
- `tools/check_includes.py` — resolves every include in all 96 sources, plus `tools/tests/`.
  `<angled>` paths resolve against `Include/`, `"quoted"` ones beside the including file.
  It also enforces the two invariants below — one source encoding, one spelling per include.
  Stdlib-only Python. It knows two things a grep does not:
  **platform headers** (`Trade/`, `Generic/`, `MovingAverages.mqh`, …) come from the terminal;
  **sibling-product headers** (Range Bars, Tick Chart, Volume Chart, Seconds Chart, Line Break)
  are referenced behind `#ifdef` and ship with those products. Both allowlists live at the top of
  the script — when the check fires, fix the include, and add to a list only when the header
  genuinely belongs elsewhere, with the reason.

### Every source is UTF-8 with a BOM

Both halves are load-bearing. **UTF-8**, because `grep`, `git grep` and GitHub code search return
*no match* for text inside a UTF-16 file instead of reporting a skip — a silent false negative, and
the reason a support answer can be confidently wrong ("that setting doesn't exist in this version").
**With a BOM**, because MetaEditor reads a BOM-less file as ANSI, which mangles the Portuguese input
labels in `CustomChartInputsBR.mqh`, the Cyrillic comments in `ATP.mq5` and the `©` in several
copyright headers.

MetaEditor may re-save a file as UTF-16 on its own; the check in stage 1 catches that.

### Includes match the on-disk spelling exactly

MQL on Windows is case-insensitive, so a case-only mismatch resolves there and fails on any
case-sensitive checkout. The spelling on disk wins — it is what customers already have installed —
so `Include/smoothalgorithms.mqh` is included as `<smoothalgorithms.mqh>`, not
`<SmoothAlgorithms.mqh>`. Paths use forward slashes.

**2. `Compile (MetaEditor)`** — `runs-on: [self-hosted, Windows, mql]`
- The Windows 11 UTM VM on the Mac Mini. MetaEditor is Windows-only, so there is nowhere else this
  can run; the VM already hosts the per-repo runners for the sibling repos.
- MT5 is installed into the workspace on first run and kept, then the terminal is run once so the
  standard includes (`Trade/`, `Arrays/`, `Generic/`) exist.
- **The repo is staged into `mt5\MQL5\` before compiling** — `Include\*` into `MQL5\Include`,
  `Indicators\MedianRenko` and `Experts\*` into their counterparts. This is load-bearing:
  MetaEditor resolves `<…>` against the data folder's `Include`, so it is the only arrangement
  where `<AZ-INVEST/SDK/MedianRenko.mqh>` and `<Trade/Trade.mqh>` both resolve in one build.
- Any `.ex5` already in the staging tree is deleted first, and the step throws unless the number of
  staged sources matches the repository. Both guards exist so that an incomplete stage fails loudly
  instead of reading as a clean compile.
- **All 7 sources under `Experts/` and all 64 under `Indicators/MedianRenko/` are compiled.**
- MetaEditor's exit code is the **number of files it compiled**, not an error count — a clean
  directory build exits non-zero. The UTF-16LE log is the authoritative signal, and the job fails
  on any error *or any warning*.
- **Warnings fail the build.** A warning is the compiler naming something it had to guess at: a
  deprecated symbol, a non-boolean condition, a header local shadowing a consumer's global. Fix it
  rather than suppressing it — the reason to keep the count at zero is that a tolerated backlog
  stops being read, and the warning that matters arrives invisible among the rest.

**3. `Release`** — only on a tag push (`3.19.5`) or a `workflow_dispatch` carrying a version.
- A version containing a hyphen (`3.19.5-rc1`) publishes as a **pre-release**, so it does not become
  "Latest" and `/releases/latest` keeps resolving to the last stable version. Plain `3.19.5`
  publishes as a full release.
- Packages the sources with the **freshly compiled** binaries beside them, so the `.ex5` in a
  release always matches the `.mq5` next to it — and fails rather than publishing an archive with
  no binaries in it.
- Release notes = the standard package description every `3.19.x` release carries, plus a
  "What's new" section from the dispatch input.

### If the compile job sits queued

No runner is registered for this repo, or its labels do not include `mql`. Each repo on that VM
needs its own runner registration (a personal account cannot share a runner group) — the sibling
repos each have one under `C:\actions-runner-*`.

## Invariants

- Do not add licence/activation logic here. It belongs in the sibling repos.
- Do not assume a `#include` present in a file means the header exists in this repo —
  several are guarded by `#ifdef` for products shipped separately.
- Never reason about Renko bar geometry from this repo's code. It is not here.
- Any claim about bar construction, wick logic or session handling that cannot be traced
  to a file in this checkout is a claim about the closed-source `.ex5` — say so explicitly
  rather than guessing.
