//
// Copyright 2017-2018, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//
// Normalizing functions
//

double NormalizeLots(string symbol, double InputLots)
{
   double lotsMin    = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double lotsMax    = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
//   int lotsDigits  = (int) - MathLog10(SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));
   int lotsDigits  =  (int)MathAbs(MathLog10(SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP)));

   if(InputLots < lotsMin)
      InputLots = lotsMin;
   if(InputLots > lotsMax)
      InputLots = lotsMax;

   return NormalizeDouble(InputLots, lotsDigits);
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

double NormalizePrice(string symbol, double price, double tick = 0)
{
   double _tick = tick ? tick : SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   int _digits = (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   
   if (tick) 
      return NormalizeDouble(MathRound(price/_tick)*_tick,_digits);
   else 
      return NormalizeDouble(price,_digits);
}