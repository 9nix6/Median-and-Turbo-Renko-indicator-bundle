# Experts/ — the EAs (mirrors `MQL5/Experts/`)

Parent: [`../AGENTS.md`](../AGENTS.md) · SDK details: [`../Include/AGENTS.md`](../Include/AGENTS.md)

Every file here is an **Expert Advisor** (`OnInit`/`OnTick`/`OnDeinit`), except
`Renko_EA_Logic.mqh`, which is an include. All of them are GPL-3.0 sample/companion code
shipped *alongside* the paid indicator — none of them is itself a purchased product.

## What each file is

| File | Kind | Purpose |
|---|---|---|
| `ExampleEA.mq5` | EA, skeleton | Documented tour of the `MedianRenko` API — `GetMA`, `GetMqlRates`, `GetChannel`, `GetBuySellVolumeBreakdown`. Trades nothing. **Start here to understand the EA-side contract.** |
| `ExampleEA2.mq5` | EA, sample | Same, driven by the SuperTrend channel. |
| `ExampleEA3.mq5` | EA, sample | Shows calling a *ported indicator* from `Indicators/MedianRenko/` via `iCustom`. |
| `2MA_Cross.mq5` | EA, functional | 2-moving-average crossover, SL/TP, trading hours. Reads MA1/MA2 straight off the Renko indicator's buffers — the MAs must be enabled *on the indicator*, not configured in the EA. |
| `PriceMA_Cross.mq5` | EA, functional | Price×MA cross variant of the above. |
| `Renko_EA.mq5` | EA, production | The real robot. **Contains only inputs + wiring** — all logic is in `Renko_EA_Logic.mqh`. |
| `Renko_EA_Logic.mqh` | include | `CEaLogic` — the whole strategy. |

## Entry-point contract (identical in all six EAs)

- **`OnInit()`** — `new MedianRenko(MQLInfoInteger(MQL5_TESTING) ? false : true)` →
  `.Init()` → bail with `INIT_FAILED` if `GetHandle() == INVALID_HANDLE`. That boolean is
  `isUsedByIndicatorOnRenkoChart`; live it is `true` (reuse the chart's own indicator
  instance), in the tester `false` (create a private one). `Renko_EA.mq5` additionally
  packs every input into a `CEaLogicPartameters` struct and calls `eaLogic.Initialize()`.
- **`OnTick()`** — the work. Canonical shape: `if(medianRenko.IsNewBar()) { ... }`, i.e.
  act on completed Renko bricks, not on ticks. `Renko_EA.mq5` delegates to
  `eaLogic.Run()`, guarded by `eaLogic.OkToStartBacktest()` (waits until enough bars exist
  for the configured MA periods — this is why a backtest appears to "do nothing" at first).
- **`OnDeinit()`** — `medianRenko.Deinit()` (releases the `iCustom` handle) then `delete`.
  Skipping it leaks an indicator handle per reattach.

There is no `OnCalculate` here — that is the indicator side.

## `CEaLogic` (`Renko_EA_Logic.mqh`) — where Renko_EA's behaviour actually is

`Run()` is the top of the tree and reads in this order:

- open position? → `TryCloseTradeOnEOD` → `TryCloseTradeOnFilterCondition` →
  `TryCloseTradeOnReversal` → `TryReverseTrade`
- new bar? → `GetRenkoInfo()` (fetches `max(OpenXSignal, CloseXSignal) + 2` bars) →
  `IsReversalCondition()` → `TryOpenTrade()`
- entry/exit gating → `FilterLongOK()` / `FilterShortOK()` / `OkToCloseByFilter()`, which
  evaluate MA1/MA2/MA3/SuperTrend through `CFilters` (`../Include/AZ-INVEST/SDK/Filters.mqh`)

Order placement, stops and sizing are **not** here — they are `CMarketOrder`
(`TradeFunctions.mqh`), `TradingChecks.mqh` and `CTradeManager` (`TradeManager.mqh`).
"Order rejected / invalid stops" questions go there, not here.

Bar index convention throughout: `[0]` is the **current, uncompleted** brick; `[1]` is the
last completed one (see `RenkoPatterns.mqh`'s `CURRENT_UNCOMPLETED_BAR` /
`LAST_COMPLETED_BAR`). Off-by-one bug reports usually come from customers who assumed `[0]`
was closed.

## Compile-time switches at the top of each `.mq5` — the #1 support topic

These are **edit-then-recompile** switches. There is no runtime input for any of them.

- **`SHOW_INDICATOR_INPUTS` — required for the Strategy Tester.** Off (the default), the
  EA reads the chart's `.set` file written by the on-chart indicator; that file is never
  written in the tester, so the EA fails to init. On, the Renko settings appear as EA
  inputs and are used directly. "The EA works live but not in backtest" is this, every
  time. Mechanics: `../Include/AGENTS.md` → *Settings handshake*.
- **`ULTIMATE_RENKO_LICENSE` / `P_RENKO_BR_PRO`** — which edition of the indicator the
  customer owns; decides the `iCustom` name. Wrong value ⇒ `indicator init failed on
  error 4802`-style failure. Table in the root `AGENTS.md`.
- **`DEVELOPER_VERSION`** — internal build paths. Must stay commented out.
- **`EA_ON_RENKO` / `EA_ON_RANGE_BARS` / `EA_ON_TICK_VOLUME_CHART` / `EA_ON_SECONDS_CHART`
  / `EA_ON_LINEBREAK_CHART` / `EA_ON_XTICK_CHART`** (only in `2MA_Cross.mq5` and
  `PriceMA_Cross.mq5`) — exactly one may be defined; it selects which custom-bar SDK class
  the generic `customBars` pointer is. **Only `EA_ON_RENKO` compiles from this repo**; the
  other headers ship with the sibling products. These two EAs are deliberately written
  against the common `Init/GetHandle/IsNewBar/GetMA/GetMqlRates` surface so one source
  serves the whole az-invest product line.

## Ported-indicator paths (if an EA calls one via `iCustom`)

`ExampleEA3.mq5` shows that the ported indicators live under a *different folder name per
edition*, and the EA must match:

| Edition | `iCustom` path |
|---|---|
| MQL5 Market bundle (default) | `MedianRenko\MedianRenko_RSI` |
| Ultimate Renko (az-invest.eu) | `Ultimate Renko\RSI` |
| P-Renko BR Ultimate | `P-RENKO BR Ultimate\RSI` |
| developer build | `CustomChartIndicators\RSI` |

Note the Market edition also *renames* the file (`MedianRenko_` prefix). A "cannot find
indicator" report is usually this mismatch, not a missing file.

Also from `ExampleEA3`: **additional indicator handles must be created in `OnTick()`, not
`OnInit()`**, or they do not work in the backtester; and its header advises backtesting on
the Daily timeframe.

## Gotchas

- Committed `.ex5` files sit next to the sources and **can lag them**. As of this writing
  `Renko_EA.ex5` (2021-10-28) predates the 2026-09-25 SuperTrend-filter fix in
  `Renko_EA.mq5`. Recompile in MetaEditor before handing a customer the binary.
- `.github/workflows/mql-build.yml` compiles every source in this folder on each push and PR, on
  the self-hosted Windows runner. Warnings do not fail the build; errors do.
- `2MA_Cross.mq5` / `PriceMA_Cross.mq5` read MA values **from the indicator's buffers**
  (`GetMA(_MA1, ...)`). If the customer did not enable MA1/MA2 on the Renko indicator, the
  EA gets empty data and silently does nothing. Both EAs' `#property description` say so.
- All files here are ASCII (unlike parts of `../Include/` and `../Indicators/`), so plain
  `grep` works in this directory.
