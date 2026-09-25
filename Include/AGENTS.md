# Include/ — the SDK (mirrors `MQL5/Include/`)

Parent: [`../AGENTS.md`](../AGENTS.md). Everything here is a header (`.mqh`); nothing here
compiles on its own. Paths are resolved by MT5 against `MQL5/Include/`, so
`<AZ-INVEST/SDK/MedianRenko.mqh>` == `Include/AZ-INVEST/SDK/MedianRenko.mqh`.

## Layout

```
Include/
  AZ-INVEST/
    CustomBarConfig.mqh      <- the ONE file indicators include; picks the product edition
    SDK/                     <- the actual library (see below)
  IncOnRingBuffer/           <- 3rd-party ring-buffer MA/ATR/ADX helpers (unmodified)
  Double.mqh                 <- 3rd-party CDouble/CDoubleVector helper
```

The three non-`AZ-INVEST` items are vendored dependencies of a handful of ported
indicators. Treat them as read-only; they are not az-invest code.

## The two entry points into the SDK

Which one a file uses tells you what kind of file it is.

**`AZ-INVEST/SDK/MedianRenko.mqh` — the raw client. Used by EAs.**
Wraps the closed-source indicator: `Init()` calls `iCustom(symbol, period,
RENKO_INDICATOR_NAME, <~60 settings>)` and keeps the handle; `GetMqlRates()`,
`GetMA()`, `GetChannel()`, `GetBuySellVolumeBreakdown()` are `CopyBuffer()` wrappers over
the 21 named buffer offsets `RENKO_OPEN`(0) … `RENKO_RUNTIME_ID`(20) defined at the top of
the file. `IsNewBar()` compares bar-0 time against the previously seen one.

**`AZ-INVEST/SDK/MedianRenkoIndicator.mqh` — the porting shim. Used by indicators.**
Wraps a `MedianRenko` instance and republishes the Renko series as plain arrays
(`Open[] High[] Low[] Close[] Time[] Price[] Tick_volume[] …`) that a stock MT5
indicator's `OnCalculate()` body can consume with minimal edits. Its own `OnCalculate()`
is the resync state machine (below). Indicators never include it directly — they include
`AZ-INVEST/CustomBarConfig.mqh`, which `#define`s the edition, includes this header and
declares the single global `customChartIndicator`.

## Settings handshake — read this before debugging "EA can't see my settings"

The Renko indicator and the EA are two separate MT5 programs. They share settings through
a **binary file**, not through inputs:

1. The indicator (closed source, same `CCustomChartSettingsBase` code) calls `Save()`,
   which `FileWriteStruct`s the settings into
   `<MT5 data folder>/MQL5/Files/<CUSTOM_CHART_NAME><ChartID()>.set`.
   `CUSTOM_CHART_NAME` is `"Ultimate Renko"` for every edition except P-Renko BR
   (`RenkoCustomChartSettings.mqh`), so the file is typically
   `Ultimate Renko132750984093478.set`. Filename comes from
   `CRenkoCustomChartSettigns::GetSettingsFileName()`.
2. The EA calls `MedianRenko::Init()` → `medianRenkoSettings.Load()` →
   `CCustomChartSettingsBase::Load()`, which reads that same file back with
   `FileReadStruct`, then passes every field into `iCustom()`.

Consequences a support agent needs:

- **The indicator must be on the chart, and must have been there when the EA started.**
  No file ⇒ `Load()` returns false ⇒ the EA logs
  `Failed to load indicator settings - Renko indicator not on chart` and `OnInit` fails.
- **`Save()` and `Delete()` are no-ops when `IS_TESTING` or when
  `chartIndicatorSettings.UsedInEA` is true** (`CustomChartSettingsBase.mqh`). That is
  why the Strategy Tester needs the `SHOW_INDICATOR_INPUTS` route instead
  (see [`../Experts/AGENTS.md`](../Experts/AGENTS.md)).
- **The file is `FileWriteStruct` of a C struct.** Any change to `RENKO_SETTINGS`,
  `CHART_INDICATOR_SETTINGS` or `ALERT_INFO_SETTINGS` in `CommonSettings.mqh` /
  `RenkoCustomChartSettings.mqh` silently changes the on-disk layout. A mismatched
  indicator `.ex5` and SDK version reads garbage — this is a real class of "settings are
  wrong / EA trades nonsense after an update". There is no version field.
- **Live settings changes are detected out-of-band**, not by re-reading the file:
  `MedianRenko::Reload()` compares `GetRuntimeId()` (buffer `RENKO_RUNTIME_ID`, index 20 —
  the indicator bumps it whenever it reinitialises) via
  `CCustomChartSettingsBase::Changed()`, and also re-resolves the `iCustom` handle. If a
  customer says "changes don't take effect", look here.

## Resync / reload state machine (bars wrong after reconnect, timeframe change, history fill)

All in `MedianRenkoIndicator::OnCalculate()`, in this order:

1. `CheckStatus()` — handle invalid ⇒ destroy and recreate the whole `MedianRenko`
   object, log `CheckStatus block failed`, return false (indicator draws nothing this tick).
2. `NeedsReload()` ⇒ `GetOLHC(0, rates_total)`, reset `prev_calculated`, and
   **`ChartSetSymbolPeriod(ChartID(), _Symbol, _Period)` — a deliberate forced chart
   reload.** Logged as `Chart settings changed - reloading indicator with new settings`.
   A customer reporting "the chart flickers/reloads by itself" is seeing this.
3. `Canvas_RatesTotalChangedBy()` — the *underlying* chart grew. By 1 ⇒ `OLHCResize()`
   (append + shift); by more ⇒ refetch everything. This is the path that history
   backfill and reconnects take.
4. `Canvas_IsNewBar()` ⇒ `OLHCShiftRight()`.
5. Renko `IsNewBar()` ⇒ full refetch.
6. Otherwise only bar 0 is refreshed (`GetOLHC(0,0)`).

`BufferSynchronizationCheck(buffer)` is the guard every ported indicator must call after
`OnCalculate()`: it compares the indicator's own buffer length against `Close[]`. Skipping
it is what produces "values shifted by one bar" / array-out-of-range reports.

`GetOLHCForIndicatorCalc()` handles the **partial-data** case: when `CopyBuffer` returns
fewer bars than requested it zero-fills the *left* of the arrays and offsets the copy, so
early bars read 0.0 rather than garbage. `ERR_INDICATOR_DATA_NOT_FOUND` returns `-2` and
logs `Waiting for buffers ready flag` — normal during startup, not an error to escalate.

## Renko-time ↔ canvas-time mapping

`TimeToCustomChartTime()`, `CustomChartTimeToCanvasTime()`, `CanvasXYToTimePrice()` at the
tail of `MedianRenkoIndicator.mqh`. A Renko bar's timestamp is not the chart's timestamp;
anything that draws objects or reads mouse coordinates must go through these. Wrongly
placed arrows/lines on a Renko chart start here (`Indicators/MedianRenko/TradeHistory.mq5`
is the live consumer).

## The rest of `SDK/`

| File | Role |
|---|---|
| `CommonSettings.mqh` | All shared enums + the three settings structs. `ENUM_CUSTOM_BAR_TYPE` here is the Median/Turbo/Hybrid/PointO preset list. `IS_TESTING` global. |
| `CustomChartInputs.mqh` / `CustomChartInputsBR.mqh` | The `input` declarations, only compiled under `SHOW_INDICATOR_INPUTS`. `BR` is the Portuguese-language P-Renko BR variant — **a near-duplicate kept in parallel**; a new input must be added to both. |
| `CustomChartSettingsBase.mqh` + `ICustomChartSettings.mqh` + `RenkoCustomChartSettings.mqh` | The `.set` load/save machinery described above. Base class is generic across the product line; the Renko subclass supplies `RENKO_SETTINGS` and the filename. |
| `TradeFunctions.mqh` (1093 ln) | `CMarketOrder` — order send/close/modify with retry, requote and busy handling. The biggest EA-side file. |
| `TradingChecks.mqh` (931 ln) | Broker-constraint validation (freeze level, stop level, volume, margin). Where "invalid stops" / "order rejected" answers live. |
| `TradeManager.mqh` | Break-even, trailing stop, partial close. |
| `TimeControl.mqh` | Trading-hours window parsing (`"9:00"`–`"16:00"`) and EOD logic. |
| `Filters.mqh` | MA/SuperTrend entry-exit filter predicates used by `Renko_EA_Logic.mqh`. |
| `RenkoPatterns.mqh` | Bull/bear reversal detection over an `MqlRates[]`. Note the index convention: `[0]` is the **uncompleted** bar, `[1]` the last completed one. |
| `HistoryHandler.mqh` | Deal-history diffing for the TradeHistory indicator. |
| `RSI.mqh`, `Normailze.mqh` (sic), `IndicatorAccess.mqh` | Small helpers. |

## Gotchas

- **Encoding is mixed.** `CommonSettings.mqh`, `CustomChartInputs.mqh`,
  `CustomChartInputsBR.mqh`, `CustomChartSettingsBase.mqh`, `ICustomChartSettings.mqh`,
  everything else is ASCII. Plain `grep` finds nothing in them. Use
  **Do not "normalise" these to UTF-8**: MetaEditor wrote them and round-trips them.
- **Include paths are inconsistently cased** (`<az-invest/sdk/...>` vs
  `<AZ-INVEST/SDK/...>`, `<SmoothAlgorithms.mqh>` vs the on-disk `smoothalgorithms.mqh`).
  Fine on Windows, not elsewhere.
- **`CustomBarConfig.mqh` references headers that are not in this repo**
  (`TickChartIndicator.mqh`, `RangeBarIndicator.mqh`, `SecondsChartIndicator.mqh`,
  `VolumeChartIndicator.mqh`). They ship with the Tick Chart / Range Bar / Seconds Chart /
  Volume Chart products. Only the `ULTIMATE_RENKO_LICENSE` and `P_RENKO_BR_PRO` branches
  build from this checkout.
- **`ULTIMATE_RENKO_LICENSE` etc. are edition switches, not licence checks.** No
  activation code exists here — see the root `AGENTS.md`.
- `DEVELOPER_VERSION`, `IS_DEBUG`, `SHOW_DEBUG`, `DISPLAY_DEBUG_MSG` gate `Print()`
  diagnostics. `DEVELOPER_VERSION` also swaps `RENKO_INDICATOR_NAME` to an internal build
  (`MedianRenko\MedianRenkoOverlay319`) — it must stay commented out in anything shipped.
