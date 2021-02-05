//+------------------------------------------------------------------+
//|                                                   Stochastic.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_color2  Red
#property indicator_style2  STYLE_DOT
//--- input parameters
input int InpKPeriod=5;  // K period
input int InpDPeriod=3;  // D period
input int InpSlowing=3;  // Slowing

//--- indicator buffers
double    ExtMainBuffer[];
double    ExtSignalBuffer[];
double    ExtHighesBuffer[];
double    ExtLowesBuffer[];

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMainBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtHighesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtLowesBuffer,INDICATOR_CALCULATIONS);      
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- set levels
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,20);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,80);
//--- set maximum and minimum for subwindow
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,100);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"Stoch("+(string)InpKPeriod+","+(string)InpDPeriod+","+(string)InpSlowing+")");
   PlotIndexSetString(0,PLOT_LABEL,"Main");
   PlotIndexSetString(1,PLOT_LABEL,"Signal");
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpKPeriod+InpSlowing-2);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpKPeriod+InpDPeriod);
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Stochastic Oscillator                                            |
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
   // Process data through MedianRenko indicator
   //
   
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,Time,Close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(Close))
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
       
   int i,k,start;
//--- check for bars count
   if(rates_total<=InpKPeriod+InpDPeriod+InpSlowing)
      return(0);
//---
   start=InpKPeriod-1;
   if(start+1<_prev_calculated) start=_prev_calculated-2;
   else
     {
      for(i=0;i<start;i++)
        {
         ExtLowesBuffer[i]=0.0;
         ExtHighesBuffer[i]=0.0;
        }
        
       
     }
//--- calculate HighesBuffer[] and ExtHighesBuffer[]
   for(i=start;i<rates_total && !IsStopped();i++)
     {
      double dmin=1000000.0;
      double dmax=-1000000.0;
      for(k=i-InpKPeriod+1;k<=i;k++)
        {
         if(dmin>customChartIndicator.Low[k])  dmin=customChartIndicator.Low[k];
         if(dmax<customChartIndicator.High[k]) dmax=customChartIndicator.High[k];
        }
      ExtLowesBuffer[i]=dmin;
      ExtHighesBuffer[i]=dmax;
     }
     
//--- %K
   start=InpKPeriod-1+InpSlowing-1;
   if(start+1<_prev_calculated) start=_prev_calculated-2;
   else
     {
      for(i=0;i<start;i++) ExtMainBuffer[i]=0.0;
     }
//--- main cycle
   for(i=start;i<rates_total && !IsStopped();i++)
     {
      double sumlow=0.0;
      double sumhigh=0.0;
      for(k=(i-InpSlowing+1);k<=i;k++)
        {
         sumlow +=(customChartIndicator.Close[k]-ExtLowesBuffer[k]);
         sumhigh+=(ExtHighesBuffer[k]-ExtLowesBuffer[k]);
        }
      if(sumhigh==0.0) ExtMainBuffer[i]=100.0;
      else             ExtMainBuffer[i]=sumlow/sumhigh*100;
     }
//--- signal
   start=InpDPeriod-1;
   if(start+1<_prev_calculated) start=_prev_calculated-2;
   else
     {
      for(i=0;i<start;i++) ExtSignalBuffer[i]=0.0;
     }
   for(i=start;i<rates_total && !IsStopped();i++)
     {
      double sum=0.0;
      for(k=0;k<InpDPeriod;k++) sum+=ExtMainBuffer[i-k];
      ExtSignalBuffer[i]=sum/InpDPeriod;
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+

