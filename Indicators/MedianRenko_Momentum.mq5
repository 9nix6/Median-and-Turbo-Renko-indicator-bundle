

//+------------------------------------------------------------------+
//|                                                     Momentum.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//---- indicator settings
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  DodgerBlue
//---- input parameters
input int InpMomentumPeriod=14; // Period
input ENUM_APPLIED_PRICE InpApplyToPrice= PRICE_CLOSE; // Apply to
//---- indicator buffers
double    ExtMomentumBuffer[];
//--- global variable
int       ExtMomentumPeriod;

//
// Initialize MedianRenko indicator for data processing 
// according to settings of the MedianRenko indicator already on chart
//

#include <MedianRenkoIndicator.mqh>
MedianRenkoIndicator medianRenkoIndicator;

//
//
//

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
   //
   //  Indicator uses Price[] array for calculations so we need to set this in the MedianRenkoIndicator class
   //
  
   medianRenkoIndicator.SetUseAppliedPriceFlag(InpApplyToPrice);
   
   //
   //
   //  
  
//--- check for input value
   if(InpMomentumPeriod<0)
     {
      ExtMomentumPeriod=14;
      Print("Input parameter InpMomentumPeriod has wrong value. Indicator will use value ",ExtMomentumPeriod);
     }
   else ExtMomentumPeriod=InpMomentumPeriod;
//---- buffers  
   SetIndexBuffer(0,ExtMomentumBuffer,INDICATOR_DATA);
//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"Momentum"+"("+string(ExtMomentumPeriod)+")");
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtMomentumPeriod-1);
//--- sets drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- digits
   IndicatorSetInteger(INDICATOR_DIGITS,2);
  }
//+------------------------------------------------------------------+
//|  Momentum                                                        |
//+------------------------------------------------------------------+
/*
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
*/
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
   
   //
   // Precoess data through MedianRenko indicator
   //
   
   static int begin = 0;
   
   if(!medianRenkoIndicator.OnCalculate(rates_total,prev_calculated,Time))
      return(rates_total);
   
   //
   // Make the following modifications in the code below:
   //
   // medianRenkoIndicator.GetPrevCalculated() should be used instead of prev_calculated
   // medianRenkoIndicator.Open[] should be used instead of open[]
   // medianRenkoIndicator.Low[] should be used instead of low[]
   // medianRenkoIndicator.High[] should be used instead of high[]
   // medianRenkoIndicator.Close[] should be used instead of close[]
   // if applied_price is used
   // medianRenkoIndicator.Price[] should be used instead of price[]
   //

   int _prev_calculated = medianRenkoIndicator.GetPrevCalculated();
   
   //
   //
   //   
   
//--- start calculation
   int StartCalcPosition=(ExtMomentumPeriod-1)+begin;
//---- insufficient data
   if(rates_total<StartCalcPosition)
      return(0);
//--- correct draw begin
   if(begin>0) PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartCalcPosition+(ExtMomentumPeriod-1));
//--- start working, detect position
   int pos=_prev_calculated-1;
   if(pos<StartCalcPosition)
      pos=begin+ExtMomentumPeriod;
//--- main cycle
   for(int i=pos;i<rates_total && !IsStopped();i++)
     {
      if(medianRenkoIndicator.Price[i-ExtMomentumPeriod] > 0)
         ExtMomentumBuffer[i]=medianRenkoIndicator.Price[i]*100/medianRenkoIndicator.Price[i-ExtMomentumPeriod];
      
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
