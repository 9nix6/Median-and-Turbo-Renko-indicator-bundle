//+------------------------------------------------------------------+
//|                                                 ParabolicSAR.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_type1   DRAW_ARROW
#property indicator_color1  DodgerBlue
//--- External parametrs
input double         InpSARStep=0.02;    // Step
input double         InpSARMaximum=0.2;  // Maximum
//---- buffers
double               ExtSARBuffer[];
double               ExtEPBuffer[];
double               ExtAFBuffer[];
//--- global variables
int                  ExtLastRevPos;
bool                 ExtDirectionLong;
double               ExtSarStep;
double               ExtSarMaximum;

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- checking input data
   if(InpSARStep<0.0)
     {
      ExtSarStep=0.02;
      Print("Input parametr InpSARStep has incorrect value. Indicator will use value",
            ExtSarStep,"for calculations.");
     }
   else ExtSarStep=InpSARStep;
   if(InpSARMaximum<0.0)
     {
      ExtSarMaximum=0.2;
      Print("Input parametr InpSARMaximum has incorrect value. Indicator will use value",
            ExtSarMaximum,"for calculations.");
     }
   else ExtSarMaximum=InpSARMaximum;
//---- indicator buffers
   SetIndexBuffer(0,ExtSARBuffer);
   SetIndexBuffer(1,ExtEPBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,ExtAFBuffer,INDICATOR_CALCULATIONS);
//--- set arrow symbol
   PlotIndexSetInteger(0,PLOT_ARROW,159);
//--- set indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- set label name
   PlotIndexSetString(0,PLOT_LABEL,"SAR("+
                      DoubleToString(ExtSarStep,2)+","+
                      DoubleToString(ExtSarMaximum,2)+")");
//--- set global variables
   ExtLastRevPos=0;
   ExtDirectionLong=false;
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//--- check for minimum rates count
   if(rates_total<3)
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
      
//--- detect current position 
   int pos=_prev_calculated-1;
//--- correct position
   if(pos<1)
     {
      //--- first pass, set as SHORT
      pos=1;
      ExtAFBuffer[0]=ExtSarStep;
      ExtAFBuffer[1]=ExtSarStep;
      ExtSARBuffer[0]=customChartIndicator.High[0];
      ExtLastRevPos=0;
      ExtDirectionLong=false;
      ExtSARBuffer[1]=GetHigh(pos,ExtLastRevPos,customChartIndicator.High);
      ExtEPBuffer[0]=customChartIndicator.Low[pos];
      ExtEPBuffer[1]=customChartIndicator.Low[pos];
     }
//---main cycle
   for(int i=pos;i<rates_total-1 && !IsStopped();i++)
     {
      //--- check for reverse
      if(ExtDirectionLong)
        {
         if(ExtSARBuffer[i]>customChartIndicator.Low[i])
           {
            //--- switch to SHORT
            ExtDirectionLong=false;
            ExtSARBuffer[i]=GetHigh(i,ExtLastRevPos,customChartIndicator.High);
            ExtEPBuffer[i]=customChartIndicator.Low[i];
            ExtLastRevPos=i;
            ExtAFBuffer[i]=ExtSarStep;
           }
        }
      else
        {
         if(ExtSARBuffer[i]<customChartIndicator.High[i])
           {
            //--- switch to LONG
            ExtDirectionLong=true;
            ExtSARBuffer[i]=GetLow(i,ExtLastRevPos,customChartIndicator.Low);
            ExtEPBuffer[i]=customChartIndicator.High[i];
            ExtLastRevPos=i;
            ExtAFBuffer[i]=ExtSarStep;
           }
        }
      //--- continue calculations
      if(ExtDirectionLong)
        {
         //--- check for new High
         if(customChartIndicator.High[i]>ExtEPBuffer[i-1] && i!=ExtLastRevPos)
           {
            ExtEPBuffer[i]=customChartIndicator.High[i];
            ExtAFBuffer[i]=ExtAFBuffer[i-1]+ExtSarStep;
            if(ExtAFBuffer[i]>ExtSarMaximum)
               ExtAFBuffer[i]=ExtSarMaximum;
           }
         else
           {
            //--- when we haven't reversed
            if(i!=ExtLastRevPos)
              {
               ExtAFBuffer[i]=ExtAFBuffer[i-1];
               ExtEPBuffer[i]=ExtEPBuffer[i-1];
              }
           }
         //--- calculate SAR for tomorrow
         ExtSARBuffer[i+1]=ExtSARBuffer[i]+ExtAFBuffer[i]*(ExtEPBuffer[i]-ExtSARBuffer[i]);
         //--- check for SAR
         if(ExtSARBuffer[i+1]>customChartIndicator.Low[i] || ExtSARBuffer[i+1]>customChartIndicator.Low[i-1])
            ExtSARBuffer[i+1]=MathMin(customChartIndicator.Low[i],customChartIndicator.Low[i-1]);
        }
      else
        {
         //--- check for new Low
         if(customChartIndicator.Low[i]<ExtEPBuffer[i-1] && i!=ExtLastRevPos)
           {
            ExtEPBuffer[i]=customChartIndicator.Low[i];
            ExtAFBuffer[i]=ExtAFBuffer[i-1]+ExtSarStep;
            if(ExtAFBuffer[i]>ExtSarMaximum)
               ExtAFBuffer[i]=ExtSarMaximum;
           }
         else
           {
            //--- when we haven't reversed
            if(i!=ExtLastRevPos)
              {
               ExtAFBuffer[i]=ExtAFBuffer[i-1];
               ExtEPBuffer[i]=ExtEPBuffer[i-1];
              }
           }
         //--- calculate SAR for tomorrow
         ExtSARBuffer[i+1]=ExtSARBuffer[i]+ExtAFBuffer[i]*(ExtEPBuffer[i]-ExtSARBuffer[i]);
         //--- check for SAR
         if(ExtSARBuffer[i+1]<customChartIndicator.High[i] || ExtSARBuffer[i+1]<customChartIndicator.High[i-1])
            ExtSARBuffer[i+1]=MathMax(customChartIndicator.High[i],customChartIndicator.High[i-1]);
        }
     }
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Find highest price from start to current position                |
//+------------------------------------------------------------------+
double GetHigh(int nPosition,int nStartPeriod,const double &HiData[])
  {
//--- calculate
   double result=HiData[nStartPeriod];
   for(int i=nStartPeriod;i<=nPosition;i++) if(result<HiData[i]) result=HiData[i];
   return(result);
  }
//+------------------------------------------------------------------+
//| Find lowest price from start to current position                 |
//+------------------------------------------------------------------+
double GetLow(int nPosition,int nStartPeriod,const double &LoData[])
  {
//--- calculate
   double result=LoData[nStartPeriod];
   for(int i=nStartPeriod;i<=nPosition;i++) if(result>LoData[i]) result=LoData[i];
   return(result);
  }
//+------------------------------------------------------------------+
