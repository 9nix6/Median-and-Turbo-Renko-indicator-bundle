//+------------------------------------------------------------------+
//|                                        Custom Moving Average.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
//--- input parameters
input int            InpMAPeriod=13;         // Period
input int            InpMAShift=0;           // Shift
input ENUM_MA_METHOD InpMAMethod=MODE_SMMA;  // Method
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE;

//--- indicator buffers
double               ExtLineBuffer[];

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
//|   simple moving average                                          |
//+------------------------------------------------------------------+
void CalculateSimpleMA(int rates_total,int prev_calculated,int begin,const double &price[])
  {
   int i,limit;
//--- first calculation or number of bars was changed
   if(prev_calculated==0)// first calculation
     {
      limit=InpMAPeriod+begin;
      //--- set empty value for first limit bars
      for(i=0;i<limit-1;i++) ExtLineBuffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
         firstValue+=price[i];
      firstValue/=InpMAPeriod;
      ExtLineBuffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   for(i=limit;i<rates_total && !IsStopped();i++)
      ExtLineBuffer[i]=ExtLineBuffer[i-1]+(price[i]-price[i-InpMAPeriod])/InpMAPeriod;
//---
  }
//+------------------------------------------------------------------+
//|  exponential moving average                                      |
//+------------------------------------------------------------------+
void CalculateEMA(int rates_total,int prev_calculated,int begin,const double &price[])
  {
   int    i,limit;
   double SmoothFactor=2.0/(1.0+InpMAPeriod);
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
     {
      limit=InpMAPeriod+begin;
      ExtLineBuffer[begin]=price[begin];
      for(i=begin+1;i<limit;i++)
         ExtLineBuffer[i]=price[i]*SmoothFactor+ExtLineBuffer[i-1]*(1.0-SmoothFactor);
     }
   else limit=prev_calculated-1;
//--- main loop
   for(i=limit;i<rates_total && !IsStopped();i++)
      ExtLineBuffer[i]=price[i]*SmoothFactor+ExtLineBuffer[i-1]*(1.0-SmoothFactor);
//---
  }
//+------------------------------------------------------------------+
//|  linear weighted moving average                                  |
//+------------------------------------------------------------------+
void CalculateLWMA(int rates_total,int prev_calculated,int begin,const double &price[])
  {
   int        i,limit;
   static int weightsum;
   double     sum;
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
     {
      weightsum=0;
      limit=InpMAPeriod+begin;
      //--- set empty value for first limit bars
      for(i=0;i<limit;i++) ExtLineBuffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
        {
         int k=i-begin+1;
         weightsum+=k;
         firstValue+=k*price[i];
        }
      firstValue/=(double)weightsum;
      ExtLineBuffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      sum=0;
      for(int j=0;j<InpMAPeriod;j++) sum+=(InpMAPeriod-j)*price[i-j];
      ExtLineBuffer[i]=sum/weightsum;
     }
//---
  }
//+------------------------------------------------------------------+
//|  smoothed moving average                                         |
//+------------------------------------------------------------------+
void CalculateSmoothedMA(int rates_total,int prev_calculated,int begin,const double &price[])
  {
   int i,limit;
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
     {
      limit=InpMAPeriod+begin;
      //--- set empty value for first limit bars
      for(i=0;i<limit-1;i++) ExtLineBuffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
         firstValue+=price[i];
      firstValue/=InpMAPeriod;
      ExtLineBuffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   for(i=limit;i<rates_total && !IsStopped();i++)
      ExtLineBuffer[i]=(ExtLineBuffer[i-1]*(InpMAPeriod-1)+price[i])/InpMAPeriod;
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod);
//---- line shifts when drawing
   PlotIndexSetInteger(0,PLOT_SHIFT,InpMAShift);
//--- name for DataWindow
   string short_name="unknown ma";
   switch(InpMAMethod)
     {
      case MODE_EMA :  short_name="EMA";  break;
      case MODE_LWMA : short_name="LWMA"; break;
      case MODE_SMA :  short_name="SMA";  break;
      case MODE_SMMA : short_name="SMMA"; break;
     }
   IndicatorSetString(INDICATOR_SHORTNAME,short_name+"("+string(InpMAPeriod)+")");
//---- sets drawing line empty value--
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   
   //
   //  Indicator uses Price[] array for calculations so we need to set this in the MedianRenkoIndicator class
   //
  
   customChartIndicator.SetUseAppliedPriceFlag(InpAppliedPrice);
   
   //
   //
   //
   
//---- initialization done
  }
//+------------------------------------------------------------------+
//|  Moving Average                                                  |
//+------------------------------------------------------------------+
/*int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {*/
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
   int _begin = 0;

   //
   //
   //    
  
//--- check for bars count
   if(rates_total<InpMAPeriod-1+_begin)
      return(0);// not enough bars for calculation
         
//--- first calculation or number of bars was changed
   if(_prev_calculated==0)
      ArrayInitialize(ExtLineBuffer,0);
//--- sets first bar from what index will be draw
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod-1+_begin);

//--- calculation
   switch(InpMAMethod)
     {
      case MODE_EMA:  CalculateEMA(rates_total,_prev_calculated,_begin,customChartIndicator.Price);        break;
      case MODE_LWMA: CalculateLWMA(rates_total,_prev_calculated,_begin,customChartIndicator.Price);       break;
      case MODE_SMMA: CalculateSmoothedMA(rates_total,_prev_calculated,_begin,customChartIndicator.Price); break;
      case MODE_SMA:  CalculateSimpleMA(rates_total,_prev_calculated,_begin,customChartIndicator.Price);   break;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
