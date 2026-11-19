//
// Copyright 2017-2018, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//
// Normalizing functions
//

// installer-builder#131 - the pure core of NormalizeLots / NormalizePrice. No terminal calls, so
// tests/mql/TradePanelTradeMathTest.mq5 pins them offline. The old NormalizeLots rounded to the
// NEAREST step (0.0151 -> 0.02: more volume than asked for, and more risk than a risk-based size
// allows) and derived its digits from log10(step), which is wrong for any step that is not a
// power of ten (0.5 -> 0 digits, so 0.7 lots went out as 1.0; 10 -> 1 digit, so 37.4 went out and
// was rejected) and undefined for a step of 0 (symbol not synchronised yet).

// The number of decimals that represents every multiple of `step` exactly (0.01 -> 2, 0.5 -> 1,
// 0.25 -> 2, 1 -> 0, 10 -> 0). A non-positive step has no grid; 8 keeps whatever precision exists.
int VolumeStepDigits(const double step)
{
   if(step <= 0)
      return 8;
   for(int d = 0; d < 8; d++)
   {
      double scaled = step * MathPow(10, d);
      if(MathAbs(scaled - MathRound(scaled)) < 1e-7 * MathMax(1.0, scaled))
         return d;
   }
   return 8;
}

// Volume ROUNDED DOWN to the step grid (never more than asked for), then limited to [min, max].
// Below the minimum it returns the minimum - callers that must not exceed a computed risk check
// that case themselves (see LotSizeFromSL). A non-positive step means "no grid": clamp only.
double NormalizeLotsToStep(const double lots, const double minLot, const double maxLot, const double step)
{
   double v = lots;
   if(step > 0)
      v = MathFloor(v / step + 1e-7) * step;   // 1e-7: 0.03/0.01 = 2.9999999996 is 3 steps, not 2
   if(maxLot > 0 && v > maxLot)
      v = (step > 0) ? MathFloor(maxLot / step + 1e-7) * step : maxLot;
   if(v < minLot)
      v = minLot;
   return NormalizeDouble(v, VolumeStepDigits(step));
}

// Price rounded to the nearest tick (US500 0.25, DAX 0.5, JP225 5), then to the symbol's digits.
// A non-positive tick rounds to digits only.
double NormalizePriceToTick(const double price, const double tick, const int digits)
{
   if(tick > 0)
      return NormalizeDouble(MathRound(price / tick) * tick, digits);
   return NormalizeDouble(price, digits);
}

double NormalizeLots(string symbol, double InputLots)
{
   return NormalizeLotsToStep(InputLots,
                              SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN),
                              SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX),
                              SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));
}

double VtcNormalizeLots(string symbol, double lotsToNormalize)
{
   double lotsMin    = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double lotsMax    = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   double lotsStep   = SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);

   if (lotsToNormalize == 0)
      return lotsMin;

	int a = (int)(lotsToNormalize / lotsStep);
	double normalizedLots = a * lotsStep;

   if(normalizedLots < lotsMin)
      normalizedLots = lotsMin;
   if(normalizedLots > lotsMax)
      normalizedLots = lotsMax;
	
	return normalizedLots;
}

// `tick` = 0 (the default) rounds to the symbol's own tick size. It used to round to digits only in
// that case, so a stop on an index with a 0.25/0.5/5 tick was sent off-grid and rejected (10015/10016).
double NormalizePrice(string symbol, double price, double tick = 0)
{
   double _tick = tick ? tick : SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   int _digits = (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   return NormalizePriceToTick(price, _tick, _digits);
}
