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
// Initialize MedianRenko indicator for data processing 
// according to settings of the MedianRenko indicator already on chart
//

#include <AZ-INVEST/SDK/MedianRenkoIndicator.mqh>
MedianRenkoIndicator medianRenkoIndicator;

//
//
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
   
   if(!medianRenkoIndicator.OnCalculate(rates_total,prev_calculated,time))
      return(0);
   
   //
   // Make the following modifications in the code below:
   //
   // medianRenkoIndicator.GetPrevCalculated() should be used instead of prev_calculated
   //
   // medianRenkoIndicator.Open[] should be used instead of open[]
   // medianRenkoIndicator.Low[] should be used instead of low[]
   // medianRenkoIndicator.High[] should be used instead of high[]
   // medianRenkoIndicator.Close[] should be used instead of close[]
   //
   // medianRenkoIndicator.IsNewBar (true/false) informs you if a renko brick completed
   //
   // medianRenkoIndicator.Time[] shold be used instead of Time[] for checking the renko bar time.
   // (!) medianRenkoIndicator.SetGetTimeFlag() must be called in OnInit() for medianRenkoIndicator.Time[] to be used
   //
   // medianRenkoIndicator.Tick_volume[] should be used instead of TickVolume[]
   // medianRenkoIndicator.Real_volume[] should be used instead of Volume[]
   // (!) medianRenkoIndicator.SetGetVolumesFlag() must be called in OnInit() for Tick_volume[] & Real_volume[] to be used
   //
   // medianRenkoIndicator.Price[] should be used instead of Price[]
   // (!) medianRenkoIndicator.SetUseAppliedPriceFlag(ENUM_APPLIED_PRICE _applied_price) must be called in OnInit() for medianRenkoIndicator.Price[] to be used
   //
   
   int _prev_calculated = medianRenkoIndicator.GetPrevCalculated();
   
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
      ExtSARBuffer[0]=medianRenkoIndicator.High[0];
      ExtLastRevPos=0;
      ExtDirectionLong=false;
      ExtSARBuffer[1]=GetHigh(pos,ExtLastRevPos,medianRenkoIndicator.High);
      ExtEPBuffer[0]=medianRenkoIndicator.Low[pos];
      ExtEPBuffer[1]=medianRenkoIndicator.Low[pos];
     }
//---main cycle
   for(int i=pos;i<rates_total-1 && !IsStopped();i++)
     {
      //--- check for reverse
      if(ExtDirectionLong)
        {
         if(ExtSARBuffer[i]>medianRenkoIndicator.Low[i])
           {
            //--- switch to SHORT
            ExtDirectionLong=false;
            ExtSARBuffer[i]=GetHigh(i,ExtLastRevPos,medianRenkoIndicator.High);
            ExtEPBuffer[i]=medianRenkoIndicator.Low[i];
            ExtLastRevPos=i;
            ExtAFBuffer[i]=ExtSarStep;
           }
        }
      else
        {
         if(ExtSARBuffer[i]<medianRenkoIndicator.High[i])
           {
            //--- switch to LONG
            ExtDirectionLong=true;
            ExtSARBuffer[i]=GetLow(i,ExtLastRevPos,medianRenkoIndicator.Low);
            ExtEPBuffer[i]=medianRenkoIndicator.High[i];
            ExtLastRevPos=i;
            ExtAFBuffer[i]=ExtSarStep;
           }
        }
      //--- continue calculations
      if(ExtDirectionLong)
        {
         //--- check for new High
         if(medianRenkoIndicator.High[i]>ExtEPBuffer[i-1] && i!=ExtLastRevPos)
           {
            ExtEPBuffer[i]=medianRenkoIndicator.High[i];
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
         if(ExtSARBuffer[i+1]>medianRenkoIndicator.Low[i] || ExtSARBuffer[i+1]>medianRenkoIndicator.Low[i-1])
            ExtSARBuffer[i+1]=MathMin(medianRenkoIndicator.Low[i],medianRenkoIndicator.Low[i-1]);
        }
      else
        {
         //--- check for new Low
         if(medianRenkoIndicator.Low[i]<ExtEPBuffer[i-1] && i!=ExtLastRevPos)
           {
            ExtEPBuffer[i]=medianRenkoIndicator.Low[i];
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
         if(ExtSARBuffer[i+1]<medianRenkoIndicator.High[i] || ExtSARBuffer[i+1]<medianRenkoIndicator.High[i-1])
            ExtSARBuffer[i+1]=MathMax(medianRenkoIndicator.High[i],medianRenkoIndicator.High[i-1]);
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
