# Indicators/ — ported indicators (mirrors `MQL5/Indicators/`)

Parent: [`../AGENTS.md`](../AGENTS.md) · shim internals: [`../Include/AGENTS.md`](../Include/AGENTS.md)

One subfolder, `MedianRenko/`, holding **64 `.mq5` indicators plus their committed `.ex5`**.
These are stock MetaQuotes and community MT5 indicators that have been *patched* to read
Renko bricks instead of the chart's own bars. They are not original work and not the
product — they are a convenience bundle shipped with it.

**None of them builds Renko bars.** They all consume bars produced by the closed-source
indicator. A wrong *value* is usually a porting bug (here); a wrong *bar* is not (root
`AGENTS.md`).

## The porting contract — the one pattern to know

Every file in `MedianRenko/` follows it, and all 64 were verified to do so. To port a new
indicator, or to judge whether an existing one is correct, check these five points:

1. `#include <AZ-INVEST/CustomBarConfig.mqh>` near the inputs. That single include picks
   the product edition and declares the global `customChartIndicator`. Nothing here
   includes `MedianRenkoIndicator.mqh` or `MedianRenko.mqh` directly.
2. First two statements of `OnCalculate()`, before any of the original body:
   ```
   if(!customChartIndicator.OnCalculate(rates_total, prev_calculated, Time, Close)) return(0);
   if(!customChartIndicator.BufferSynchronizationCheck(Close))                      return(0);
   ```
   Both early-returns are mandatory. Dropping the second is what produces "values shifted
   by one bar" and array-out-of-range reports after a reconnect or history fill.
3. Substitute the data source throughout the original body:
   `prev_calculated` → `customChartIndicator.GetPrevCalculated()`;
   `open/high/low/close[]` → `customChartIndicator.Open/High/Low/Close[]`;
   `time[]` → `.Time[]`; `tick_volume[]`/`volume[]` → `.Tick_volume[]`/`.Real_volume[]`;
   applied price → `.Price[]`. `customChartIndicator.IsNewBar` reports brick completion.
4. **Opt in, in `OnInit()`, to anything beyond OHLC** — the shim only fetches what was
   requested: `SetGetTimeFlag()` (37 of 64 use it), `SetUseAppliedPriceFlag(price)` (36),
   `SetGetVolumesFlag()` (31), `SetGetVolumeBreakdownFlag()` (1: `ProVolume`). Forgetting
   the flag leaves the corresponding array empty — reads return 0/false, not an error.
   This is the most common porting mistake and it fails *silently*.
5. `ArraySetAsSeries(..., false)` on both the indicator's own buffers and
   `customChartIndicator.Close` — the shim works in non-series (left-to-right) order.

`Indicators/MedianRenko/RSI.mq5` is the reference implementation and carries the contract
as a comment block inside `OnCalculate()`. Read it before touching any other file here.

## Structure of a file (they are near-duplicates by design)

Each `.mq5` is the upstream indicator's source with the five edits above applied — the
original `#property`, inputs, buffers and maths are untouched, including their original
copyright headers (MetaQuotes, MIT, CC-BY-NC-SA on `WeisWaves`). This is **duplicated
per-indicator code, not generated code**: a fix to the shared shim propagates for free,
but a fix to the *pattern* (e.g. a missing `SetGetTimeFlag`) has to be applied file by
file. There is no template or codegen step.

A few pull in extra vendored helpers rather than only the shim:
`../Include/smoothalgorithms.mqh` (ColorHMA, GMMA, HA_Smoothed, KeltnerChannel, T3),
`../Include/IncOnRingBuffer/` (ADX Cross Alerts, DidiIndex, HalfTrend, Ozymandias,
SuperTrend), `../Include/AZ-INVEST/SDK/RSI.mqh` (TDI),
`../Include/AZ-INVEST/SDK/IndicatorAccess.mqh` (HalfTrend),
`../Include/Double.mqh` + `HistoryHandler.mqh` (TradeHistory).

## Notable individual files

| File | Why it stands out |
|---|---|
| `RSI.mq5` | The canonical port; the porting contract is documented inline. |
| `TradeHistory.mq5` | Not a study — draws executed trades on the Renko chart. Only consumer of `CHistoryHandler` and of the Renko-time↔canvas-time mapping. Its include of `Double.mqh` was wrong until 2026-09-26 (issue #19) — it asked for `<AZ-INVEST/Double.mqh>`, which the repo does not ship, so this indicator alone would not compile from a clean checkout. `tools/check_includes.py` guards that now. |
| `ProVolume.mq5` | Only user of `SetGetVolumeBreakdownFlag()` (buy/sell volume split), so the only one that needs real-volume instruments. |
| `SuperTrend.mq5` | Mirrors the SuperTrend channel the Renko indicator can draw itself; `Renko_EA` filters on the indicator's own channel buffers, not on this file. Do not confuse the two when tracing a SuperTrend complaint. |
| `Heiken_Ashi.mq5`, `OscillatorCandles.mq5` | Draw candles *on top of* Renko bricks — most sensitive to the series/shift conventions in point 5. |

## Install path — matters for "indicator not found"

These files install under a **folder whose name depends on the edition the customer
bought**, and the Market edition additionally prefixes the filename:

| Edition | Installed as |
|---|---|
| MQL5 Market bundle | `MQL5/Indicators/MedianRenko/MedianRenko_<Name>.ex5` |
| Ultimate Renko (az-invest.eu) | `MQL5/Indicators/Ultimate Renko/<Name>.ex5` |
| P-Renko BR Ultimate | `MQL5/Indicators/P-RENKO BR Ultimate/<Name>.ex5` |

(Source: the `#ifdef` ladder in `../Experts/ExampleEA3.mq5`.) The repo folder is named
`MedianRenko/` after the Market layout. An EA or a customer calling `iCustom` with the
wrong path gets "cannot load indicator" even though the file is installed.

## Gotchas

- **22 of the 64 sources are UTF-16LE with BOM** (ATP, AroonOscillator, BB_MACD,
  BollingerBandsMacd, ColorHMA, DidiIndex, DonchianChannel, GMMA, HA_Smoothed,
  KeltnerChannel, LRMA, `Ozymandias System Alert MT5 Indicator`, RangeDetector,
  SchaffTrendCycle, SuperTrend, T3, TDI,
  TradeHistory, Volatility, Volume_Average_percent, WPR, ZigZag_NK_Channel — plus any
  added since). **Plain `grep` finds nothing in them**; pipe through
  `iconv -f UTF-16LE -t UTF-8` first. Do not re-encode them.
- Two filenames contain spaces (`ADX Cross Alerts.mq5`,
  `Ozymandias System Alert MT5 Indicator.mq5`) and one contains parentheses
  (`CCI(alternative).mq5`) — quote paths in any script.
- The committed `.ex5` here are **not** rebuilt by CI (`.github/workflows/2macrossea.yml`
  compiles `Experts/` only). Assume an `.ex5` in this folder may lag its `.mq5`.
- These are third-party sources under several licences. Carrying a fix upstream, or
  relicensing, is not automatic — check each file's own header.
