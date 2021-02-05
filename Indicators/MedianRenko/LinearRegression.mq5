#property description "Linear Regression"
#property description "https://www.mql5.com/en/articles/270"
#property copyright   "ds2"
#property version     "1.0"
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  Cyan
//+------------------------------------------------------------------+
input int       LRPeriod  = 20;        // Bars in regression
//+------------------------------------------------------------------+
// The main buffer - drawing a line on a chart
double ExtLRBuffer[];

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
void OnInit()
  {
   SetIndexBuffer(0, ExtLRBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, LRPeriod-1);
   
   IndicatorSetString (INDICATOR_SHORTNAME,"Linear Regression");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);   
   
   customChartIndicator.SetUseAppliedPriceFlag(PRICE_CLOSE);
   
  }
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {

   ////////////////////////////////////////////////////////////////////////

   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,Time,Close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(Close))
      return(0);

   int _prev_calculated = customChartIndicator.GetPrevCalculated();    
   
   ////////////////////////////////////////////////////////////////////////

   if (rates_total < LRPeriod)
      return(0);

   int limit = _prev_calculated ? _prev_calculated-1 : LRPeriod-1;
 
   // The cycle along the calculated bars
   for (int bar = limit; bar < rates_total; bar++)
   {
      double lrvalue = 0; // the linear regression value in this bar
      double Sx=0, Sy=0, Sxy=0, Sxx=0;
      
      // Finding intermediate values-sums
      Sx  = 0;
      Sy  = 0;
      Sxx = 0;
      Sxy = 0;
      for (int x = 1; x <= LRPeriod; x++)
      {
         double y = customChartIndicator.GetPrice(bar-LRPeriod+x);
         Sx  += x;
         Sy  += y;
         Sxx += x*x;
         Sxy += x*y;
      }

      // Regression ratios
      double a = (LRPeriod * Sxy - Sx * Sy) / (LRPeriod * Sxx - Sx * Sx);
      double b = (Sy - a * Sx) / LRPeriod;

      lrvalue = a*LRPeriod + b;

      // Saving regression results
      ExtLRBuffer[bar] = lrvalue;
   }

   return(rates_total);
  }
//+------------------------------------------------------------------+