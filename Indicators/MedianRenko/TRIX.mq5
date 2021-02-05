//+------------------------------------------------------------------+
//|                                                         TRIX.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2017, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Triple Exponential Average"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
#property indicator_width1  1
#property indicator_label1  "TRIX"
#property indicator_applied_price PRICE_CLOSE
//--- input parameters
input int                InpPeriodEMA=14;               // EMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE;   // Applied price
//--- indicator buffers
double                  TRIX_Buffer[];
double                  EMA[];
double                  SecondEMA[];
double                  ThirdEMA[];

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,TRIX_Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,EMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,SecondEMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ThirdEMA,INDICATOR_CALCULATIONS);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,3*InpPeriodEMA-3);
//--- name for index label
   PlotIndexSetString(0,PLOT_LABEL,"TRIX("+string(InpPeriodEMA)+")");
//--- name for indicator label
   IndicatorSetString(INDICATOR_SHORTNAME,"TRIX("+string(InpPeriodEMA)+")");
//--- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,5);
//--- initialization done

   customChartIndicator.SetUseAppliedPriceFlag(InpAppliedPrice);
  }
//+------------------------------------------------------------------+
//| Triple Exponential Average                                       |
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
//--- check for data
   if(rates_total<3*InpPeriodEMA-3)
      return(0);
//---

   //
   // Process data through MedianRenko indicator
   //
   
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,time,close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(close))
      return(0);
   
   //
   // Make the following modifications in the code below:
   //
   // customChartIndicator.GetPrevCalculated() should be used instead of prev_calculated
   //
   // customChartIndicator.Open[] should be used instead of open[]
   // customChartIndicator.Low[] should be used instead of low[]
   // customChartIndicator.High[] should be used instead of high[]
   // customChartIndicator.Close[] should be used instead of close[]
   //
   // customChartIndicator.IsNewBar (true/false) informs you if a renko brick completed
   //
   // customChartIndicator.Time[] shold be used instead of Time[] for checking the renko bar time.
   // (!) customChartIndicator.SetGetTimeFlag() must be called in OnInit() for customChartIndicator.Time[] to be used
   //
   // customChartIndicator.Tick_volume[] should be used instead of TickVolume[]
   // customChartIndicator.Real_volume[] should be used instead of Volume[]
   // (!) customChartIndicator.SetGetVolumesFlag() must be called in OnInit() for Tick_volume[] & Real_volume[] to be used
   //
   // customChartIndicator.Price[] should be used instead of Price[]
   // (!) customChartIndicator.SetUseAppliedPriceFlag(ENUM_APPLIED_PRICE _applied_price) must be called in OnInit() for customChartIndicator.Price[] to be used
   //
   
   int _prev_calculated = customChartIndicator.GetPrevCalculated();
   
   //
   //
   //  

   int limit;
   if(_prev_calculated==0)
     {
      limit=3*(InpPeriodEMA-1);
      for(int i=0;i<limit;i++)
         TRIX_Buffer[i]=EMPTY_VALUE;
     }
   else limit=_prev_calculated-1;
//--- calculate EMA
   ExponentialMAOnBuffer(rates_total,_prev_calculated,0,InpPeriodEMA,customChartIndicator.Price,EMA);
//--- calculate EMA on EMA array
   ExponentialMAOnBuffer(rates_total,_prev_calculated,InpPeriodEMA-1,InpPeriodEMA,EMA,SecondEMA);
//--- calculate EMA on EMA array on EMA array
   ExponentialMAOnBuffer(rates_total,_prev_calculated,2*InpPeriodEMA-2,InpPeriodEMA,SecondEMA,ThirdEMA);
//--- calculate TRIX
   for(int i=limit;i<rates_total && !IsStopped();i++)
     {
      if(ThirdEMA[i-1]!=0.0)
         TRIX_Buffer[i]=(ThirdEMA[i]-ThirdEMA[i-1])/ThirdEMA[i-1];
      else
         TRIX_Buffer[i]=0.0;
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
