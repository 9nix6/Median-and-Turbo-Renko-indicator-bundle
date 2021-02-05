//+------------------------------------------------------------------+
//|                                                         MACD.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Moving Average Convergence/Divergence"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_color1  clrMagenta
#property indicator_color2  clrBlue
#property indicator_width1  2
#property indicator_width2  2
#property indicator_label1  "Main"
#property indicator_label2  "Signal"
//--- input parameters
input int                InpFastEMA=12;               // Fast EMA period
input int                InpSlowEMA=26;               // Slow EMA period
input int                InpSignalSMA=9;              // Signal SMA period
//--- indicator buffers
//double                   ExtMacdBufferUp[];
//double                   ExtMacdBufferDn[];
double                   ExtSignalBuffer[];
double                   ExtFastMaBuffer[];
double                   ExtSlowMaBuffer[];
double                   ExtMacdBuffer[];

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);
   //SetIndexBuffer(2,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);
   //SetIndexBuffer(4,ExtMacdBuffer,INDICATOR_CALCULATIONS);
   
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpSignalSMA-1);
//--- name for Dindicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD("+string(InpFastEMA)+","+string(InpSlowEMA)+","+string(InpSignalSMA)+")");
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
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
   //
   // Precoess data through MedianRenko indicator
   //
   
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,Time,Close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(Close))
      return(0);

   int _prev_calculated = customChartIndicator.GetPrevCalculated();
   
   //
   //
   //    
     
//--- check for data
   if(rates_total<InpSignalSMA)
      return(0);
//--- we can copy not all data
   int to_copy;
   if(_prev_calculated>rates_total || _prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-_prev_calculated;
      if(_prev_calculated>0) to_copy++;
     }
//--- get Fast EMA buffer
   if(IsStopped()) return(0); //Checking for stop flag   
   ExponentialMAOnBuffer(rates_total,_prev_calculated,0,InpFastEMA,customChartIndicator.Close,ExtFastMaBuffer);
//--- get SlowSMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   ExponentialMAOnBuffer(rates_total,_prev_calculated,0,InpSlowEMA,customChartIndicator.Close,ExtSlowMaBuffer);
//---
   int limit;
   if(_prev_calculated==0)
      limit=0;
   else limit=_prev_calculated-1;
//--- calculate MACD
   for(int i=limit;i<rates_total && !IsStopped();i++)
   {
      ExtMacdBuffer[i] = ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];
      /*
      if(ExtMacdBuffer[i] > 0)
      {
         ExtMacdBufferUp[i] = ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];
         ExtMacdBufferDn[i] = 0;
      }
      else if(ExtMacdBuffer[i] < 0)
      {
         ExtMacdBufferDn[i] = ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];
         ExtMacdBufferUp[i] = 0;
      }
      */
   }
//--- calculate Signal
   SimpleMAOnBuffer(rates_total,_prev_calculated,0,InpSignalSMA,ExtMacdBuffer,ExtSignalBuffer);
//--- OnCalculate done. Return new _prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
