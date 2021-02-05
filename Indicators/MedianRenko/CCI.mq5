

//+------------------------------------------------------------------+
//|                                                          CCI.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Commodity Channel Index"
#include <MovingAverages.mqh>
//---
#property indicator_separate_window
#property indicator_buffers       4
#property indicator_plots         1
#property indicator_type1         DRAW_LINE
#property indicator_color1        LightSeaGreen
#property indicator_level1       -100.0
#property indicator_level2        100.0
#property indicator_applied_price PRICE_TYPICAL
//--- input parametrs
input int  InpCCIPeriod=14; // Period
input ENUM_APPLIED_PRICE InpApplyToPrice= PRICE_CLOSE; // Apply to
//--- global variable
int        ExtCCIPeriod;
//---- indicator buffer
double     ExtSPBuffer[];
double     ExtDBuffer[];
double     ExtMBuffer[];
double     ExtCCIBuffer[];

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
   
   //
   //  Indicator uses Price[] array for calculations so we need to set this in the MedianRenkoIndicator class
   //
  
   customChartIndicator.SetUseAppliedPriceFlag(InpApplyToPrice);
   
   //
   //
   //
  
//--- check for input value of period
   if(InpCCIPeriod<=0)
     {
      ExtCCIPeriod=14;
      printf("Incorrect value for input variable InpCCIPeriod=%d. Indicator will use value=%d for calculations.",InpCCIPeriod,ExtCCIPeriod);
     }
   else ExtCCIPeriod=InpCCIPeriod;
//--- define buffers
   SetIndexBuffer(0,ExtCCIBuffer);
   SetIndexBuffer(1,ExtDBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,ExtMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtSPBuffer,INDICATOR_CALCULATIONS);
//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"CCI("+string(ExtCCIPeriod)+")");
//--- indexes draw begin settings
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtCCIPeriod-1);
//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//---- OnInit done
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   
//--- variables
   int    i,j;
   double dTmp,dMul=0.015/ExtCCIPeriod;
//--- start calculation
   int StartCalcPosition=(ExtCCIPeriod-1);//+begin;
//--- check for bars count
   if(rates_total<StartCalcPosition)
      return(0);
//--- correct draw begin
  // if(begin>0) PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartCalcPosition+(ExtCCIPeriod-1));
//--- calculate position
   int pos=_prev_calculated-1;
   if(pos<StartCalcPosition)
      pos=StartCalcPosition;
//--- main cycle
   for(i=pos;i<rates_total && !IsStopped();i++)
     {
      //--- SMA on price buffer
      ExtSPBuffer[i]=SimpleMA(i,ExtCCIPeriod,customChartIndicator.Price);
      //--- calculate D
      dTmp=0.0;
      for(j=0;j<ExtCCIPeriod;j++) dTmp+=MathAbs(customChartIndicator.Price[i-j]-ExtSPBuffer[i]);
      ExtDBuffer[i]=dTmp*dMul;
      //--- calculate M
      ExtMBuffer[i]=customChartIndicator.Price[i]-ExtSPBuffer[i];
      //--- calculate CCI
      if(ExtDBuffer[i]!=0.0) ExtCCIBuffer[i]=ExtMBuffer[i]/ExtDBuffer[i];
      else                   ExtCCIBuffer[i]=0.0;
      //---
     }
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
