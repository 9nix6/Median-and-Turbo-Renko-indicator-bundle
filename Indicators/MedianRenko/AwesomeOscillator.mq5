//+------------------------------------------------------------------+
//|                                           Awesome_Oscillator.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

//---- indicator settings
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Green,Red
#property indicator_width1  1
#property indicator_label1  "AO"
//--- indicator buffers
double ExtAOBuffer[];
double ExtColorBuffer[];
double ExtFastBuffer[];
double ExtSlowBuffer[];
//--- bars minimum for calculation
#define DATA_LIMIT 33

//
//

#include <MovingAverages.mqh>
#include <AZ-INVEST/CustomBarConfig.mqh>

//
//

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- indicator buffers mapping
   SetIndexBuffer(0,ExtAOBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,ExtFastBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtSlowBuffer,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,33);
//--- name for DataWindow 
   IndicatorSetString(INDICATOR_SHORTNAME,"AO");
//--- get handles
   //ExtFastSMAHandle=iMA(NULL,0,5,0,MODE_SMA,PRICE_MEDIAN);
   //ExtSlowSMAHandle=iMA(NULL,0,34,0,MODE_SMA,PRICE_MEDIAN);
// -- Set applied price to MEDIAN as required by AO indicator
   customChartIndicator.SetUseAppliedPriceFlag(PRICE_MEDIAN);
//---- initialization done
  }
//+------------------------------------------------------------------+
//|  Awesome Oscillator                                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
 
//--- check for rates total
   if(rates_total<=DATA_LIMIT)
      return(0);// not enough bars for calculation

   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,time,close))
      return(0);
   
   if(!customChartIndicator.BufferSynchronizationCheck(close))
      return(0);
  
   int _prev_calculated = customChartIndicator.GetPrevCalculated();

//--- get Fast MA buffer
   if(IsStopped()) return(0); //Checking for stop flag   
   SimpleMAOnBuffer(rates_total,_prev_calculated,0,5,customChartIndicator.Price,ExtFastBuffer);
//--- get Slow MA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   SimpleMAOnBuffer(rates_total,_prev_calculated,0,35,customChartIndicator.Price,ExtSlowBuffer);

//--- first calculation or number of bars was changed
   int i,limit;
   if(_prev_calculated<=DATA_LIMIT)
     {
      for(i=0;i<DATA_LIMIT;i++)
         ExtAOBuffer[i]=0.0;
      limit=DATA_LIMIT;
     }
   else limit=_prev_calculated-1;
//--- main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      ExtAOBuffer[i]=ExtFastBuffer[i]-ExtSlowBuffer[i];
      if(ExtAOBuffer[i]>ExtAOBuffer[i-1])ExtColorBuffer[i]=0.0; // set color Green
      else                               ExtColorBuffer[i]=1.0; // set color Red
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
