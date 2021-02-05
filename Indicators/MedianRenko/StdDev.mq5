//+------------------------------------------------------------------+
//|                                                       StdDev.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2017, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Standard Deviation"
#property description "Adapted for use with TickChart by Artur Zas."

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  MediumSeaGreen
#property indicator_style1  STYLE_SOLID
//--- input parametrs
input int            InpStdDevPeriod=20;   // Period
input int            InpStdDevShift=0;     // Shift
input ENUM_MA_METHOD InpMAMethod=MODE_SMA; // Method
input ENUM_APPLIED_PRICE InpPrice=PRICE_CLOSE; // Apply to
//---- buffers
double               ExtStdDevBuffer[];
double               ExtMABuffer[];
//--- global variables
int                  ExtStdDevPeriod,ExtStdDevShift;

#include <MovingAverages.mqh>
#include <AZ-INVEST/CustomBarConfig.mqh>

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   if(InpStdDevPeriod<=1)
     {
      ExtStdDevPeriod=20;
      printf("Incorrect value for input variable InpStdDevPeriod=%d. Indicator will use value=%d for calculations.",InpStdDevPeriod,ExtStdDevPeriod);
     }
   else ExtStdDevPeriod=InpStdDevPeriod;
   if(InpStdDevShift<0)
     {
      ExtStdDevShift=0;
      printf("Incorrect value for input variable InpStdDevShift=%d. Indicator will use value=%d for calculations.",InpStdDevShift,ExtStdDevShift);
     }
   else ExtStdDevShift=InpStdDevShift;
//--- set indicator short name
   IndicatorSetString(INDICATOR_SHORTNAME,"StdDev("+string(ExtStdDevPeriod)+")");
//---- define indicator buffers as indexes
   SetIndexBuffer(0,ExtStdDevBuffer);
   SetIndexBuffer(1,ExtMABuffer,INDICATOR_CALCULATIONS);
//--- set index label
   PlotIndexSetString(0,PLOT_LABEL,"StdDev("+string(ExtStdDevPeriod)+")");
//--- set index shift
   PlotIndexSetInteger(0,PLOT_SHIFT,ExtStdDevShift);
//----

   customChartIndicator.SetUseAppliedPriceFlag(InpPrice);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//--- variables of indicator
   int               pos;
//--- set draw begin
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtStdDevPeriod-1);//+begin);
//--- check for rates count
   if(rates_total<ExtStdDevPeriod)
      return(0);
      
      
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,Time,Close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(Close))
      return(0);
      

   int _prev_calculated = customChartIndicator.GetPrevCalculated();
   int _rates_total = customChartIndicator.GetRatesTotal();      
         
//--- starting work
   pos=_prev_calculated-1;
//--- correct position for first iteration
   if(pos<ExtStdDevPeriod)
     {
      pos=ExtStdDevPeriod-1;
      ArrayInitialize(ExtStdDevBuffer,0.0);
      ArrayInitialize(ExtMABuffer,0.0);
     }
//--- main cycle
   switch(InpMAMethod)
     {
      case  MODE_EMA :
         for(int i=pos;i<_rates_total && !IsStopped();i++)
           {
            if(i==InpStdDevPeriod-1)
               ExtMABuffer[i]=SimpleMA(i,InpStdDevPeriod, customChartIndicator.Price);
            else
               ExtMABuffer[i]=ExponentialMA(i,InpStdDevPeriod,ExtMABuffer[i-1], customChartIndicator.Price);
            //--- Calculate StdDev
            ExtStdDevBuffer[i]=StdDevFunc(customChartIndicator.Price, ExtMABuffer,i);
           }
         break;
      case MODE_SMMA :
         for(int i=pos;i<_rates_total && !IsStopped();i++)
           {
            if(i==InpStdDevPeriod-1)
               ExtMABuffer[i]=SimpleMA(i,InpStdDevPeriod,customChartIndicator.Price);
            else
               ExtMABuffer[i]=SmoothedMA(i,InpStdDevPeriod,ExtMABuffer[i-1],customChartIndicator.Price);
            //--- Calculate StdDev
            ExtStdDevBuffer[i]=StdDevFunc(customChartIndicator.Price,ExtMABuffer,i);
           }
         break;
      case MODE_LWMA :
         for(int i=pos;i<_rates_total && !IsStopped();i++)
           {
            ExtMABuffer[i]=LinearWeightedMA(i,InpStdDevPeriod,customChartIndicator.Price);
            ExtStdDevBuffer[i]=StdDevFunc(customChartIndicator.Price,ExtMABuffer,i);
           }
         break;
      default   :
         for(int i=pos;i<_rates_total && !IsStopped();i++)
           {
            ExtMABuffer[i]=SimpleMA(i,InpStdDevPeriod,customChartIndicator.Price);
            //--- Calculate StdDev
            ExtStdDevBuffer[i]=StdDevFunc(customChartIndicator.Price,ExtMABuffer,i);
           }
     }
//---- OnCalculate done. Return new prev_calculated.
   return(_rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDevFunc(const double &price[],const double &MAprice[],int position)
  {
   double dTmp=0.0;
   for(int i=0;i<ExtStdDevPeriod;i++) dTmp+=MathPow(price[position-i]-MAprice[position],2);
   dTmp=MathSqrt(dTmp/ExtStdDevPeriod);
   return(dTmp);
  }
//+------------------------------------------------------------------+
