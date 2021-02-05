//+------------------------------------------------------------------+
//|                                                      Volumes.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//---- indicator settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Green,Red
#property indicator_style1  0
#property indicator_width1  1
#property indicator_minimum 0.0
//--- input data
input ENUM_APPLIED_VOLUME InpVolumeType=VOLUME_TICK; // Volumes
//---- indicator buffers
double                    ExtVolumesBuffer[];
double                    ExtColorsBuffer[];

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- buffers   
   SetIndexBuffer(0,ExtVolumesBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorsBuffer,INDICATOR_COLOR_INDEX);
//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"Volumes");
//---- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,0);
   
   customChartIndicator.SetGetVolumesFlag();
//----
  }
//+------------------------------------------------------------------+
//|  Volumes                                                         |
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
//---check for rates total
   if(rates_total<2)
      return(0);

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

//--- starting work
   int start=_prev_calculated-1;
//--- correct position
   if(start<1) start=1;
//--- main cycle
   if(InpVolumeType==VOLUME_TICK)
      CalculateVolume(start,rates_total,customChartIndicator.Tick_volume);
   else
      CalculateVolume(start,rates_total,customChartIndicator.Real_volume);
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateVolume(const int nPosition,
                     const int nRatesCount,
                     const long &SrcBuffer[])
  {
   ExtVolumesBuffer[0]=(double)SrcBuffer[0];
   ExtColorsBuffer[0]=0.0;
//---
   for(int i=nPosition;i<nRatesCount && !IsStopped();i++)
     {
      //--- get some data from src buffer
      double dCurrVolume=(double)SrcBuffer[i];
      double dPrevVolume=(double)SrcBuffer[i-1];
      //--- calculate indicator
      ExtVolumesBuffer[i]=dCurrVolume;
      if(dCurrVolume>dPrevVolume)
         ExtColorsBuffer[i]=0.0;
      else
         ExtColorsBuffer[i]=1.0;
     }
//---
  }
//+------------------------------------------------------------------+
