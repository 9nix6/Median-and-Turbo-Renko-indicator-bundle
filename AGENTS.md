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
- **`.ex5` artifacts sit next to their `.mq5` and are committed to git** (70 of them, no
  `.gitignore`). They are the build output *and* part of what customers get. This means
  a committed `.ex5` can be stale relative to a source fix — check before telling a
  customer to just copy the file (see "Known risks" below).
- **CI** (`.github/workflows/2macrossea.yml`) compiles the `Experts/` folder on
  `windows-latest` via `fx31337/mql-compile-action`, warnings ignored, on push/PR to
  `master`. It is a compile smoke test only: no tests, no artifact upload, and it does
  **not** cover `Indicators/` or refresh the committed `.ex5` files.

## Known risks / things that looked wrong while surveying

Flagged, unverified fixes — do not "fix" these as a side effect of another task.

1. **`Experts/Renko_EA.ex5` is stale.** `Renko_EA.mq5` was last changed 2026-09-25
   (commit `48dbfb6`, the SuperTrend-filter input wiring fix); the committed
   `Renko_EA.ex5` dates from 2021-10-28. A customer who copies the `.ex5` still gets the
   bug. Recompile before shipping.
2. ~~`Indicators/MedianRenko/TradeHistory.mq5` includes `<AZ-INVEST/Double.mqh>` but the repo
   ships `Include/Double.mqh`.~~ **Fixed 2026-09-26** (issue #19): no installer relocates the
   file, and every other consumer in both this repo and `installer-builder` includes it as
   `<Double.mqh>`, so the include was the outlier. `tools/check_includes.py` now resolves every
   `#include <…>` in the tree and runs in CI (`static-checks.yml`), so this class of breakage
   cannot come back silently — see "Checks that actually run" below.
3. **Case-sensitivity.** Sources are `#include`d as `<SmoothAlgorithms.mqh>` and
   `<IncOnRingBuffer\CMAOnRingBuffer.mqh>` but stored lowercase
   (`Include/smoothalgorithms.mqh`, `Include/IncOnRingBuffer/cmaonringbuffer.mqh`).
   Harmless on Windows/MT5; breaks any case-sensitive tooling or checkout.
4. **Mixed file encodings.** Several `.mqh`/`.mq5` files are UTF-16LE with BOM, the rest
   ASCII. See [`Include/AGENTS.md`](Include/AGENTS.md) — grep silently misses the UTF-16
   ones, which is how "that setting doesn't exist anywhere" happens.

## Checks that actually run

The `EA compiler` workflow **compiles nothing**: the runner has no MetaTrader, so every run
since it was added has ended in `Platform cannot be found in "."!`. Do not read a green or red
badge there as evidence about the code.

`static-checks.yml` is what currently gates a push: `tools/check_includes.py` resolves every
`#include <…>` in all 96 sources against what the repo ships, plus `tools/tests/`. It is
stdlib-only Python and needs no platform. It knows three things a grep does not:

- **UTF-16LE sources** (29 of the 96) are decoded properly, so their includes are visible at all.
- **Platform headers** (`Trade/`, `Generic/`, `MovingAverages.mqh`, …) come from the terminal and
  are expected to be absent here.
- **Sibling-product headers** (Range Bars, Tick Chart, Volume Chart, Seconds Chart, Line Break)
  are referenced behind `#ifdef` and ship with those products, not this repo.

Both lists live at the top of the script. If a check fires, fix the include or the file — add to
those lists only when the header genuinely belongs elsewhere, with the reason.

## Invariants

- Do not add licence/activation logic here. It belongs in the sibling repos.
- Do not assume a `#include` present in a file means the header exists in this repo —
  several are guarded by `#ifdef` for products shipped separately.
- Never reason about Renko bar geometry from this repo's code. It is not here.
- Any claim about bar construction, wick logic or session handling that cannot be traced
  to a file in this checkout is a claim about the closed-source `.ex5` — say so explicitly
  rather than guessing.
