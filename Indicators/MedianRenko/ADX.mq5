

//+------------------------------------------------------------------+
//|                                                          ADX.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Average Directional Movement Index"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   3
#property indicator_type1   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_type2   DRAW_LINE
#property indicator_color2  YellowGreen
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
#property indicator_type3   DRAW_LINE
#property indicator_color3  Wheat
#property indicator_style3  STYLE_DOT
#property indicator_width3  1
#property indicator_label1  "ADX"
#property indicator_label2  "+DI"
#property indicator_label3  "-DI"
//--- input parameters
input int InpPeriodADX=14; // Period
//---- buffers
double    ExtADXBuffer[];
double    ExtPDIBuffer[];
double    ExtNDIBuffer[];
double    ExtPDBuffer[];
double    ExtNDBuffer[];
double    ExtTmpBuffer[];
//--- global variables
int       ExtADXPeriod;

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  { 
//--- check for input parameters
   if(InpPeriodADX>=100 || InpPeriodADX<=0)
     {
      ExtADXPeriod=14;
      printf("Incorrect value for input variable Period_ADX=%d. Indicator will use value=%d for calculations.",InpPeriodADX,ExtADXPeriod);
     }
   else ExtADXPeriod=InpPeriodADX;
//---- indicator buffers
   SetIndexBuffer(0,ExtADXBuffer);
   SetIndexBuffer(1,ExtPDIBuffer);
   SetIndexBuffer(2,ExtNDIBuffer);
   SetIndexBuffer(3,ExtPDBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtNDBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtTmpBuffer,INDICATOR_CALCULATIONS);
//--- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- set draw begin
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtADXPeriod<<1);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtADXPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtADXPeriod);
//--- indicator short name
   string short_name="ADX("+string(ExtADXPeriod)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- change 1-st index label
   PlotIndexSetString(0,PLOT_LABEL,short_name);
//---- end of initialization function
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
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
    
//--- checking for bars count
   if(rates_total<ExtADXPeriod)
      return(0);
//--- detect start position
   int start;
   if(_prev_calculated>1) start=_prev_calculated-1;
   else
     {
      start=1;
      ExtPDIBuffer[0]=0.0;
      ExtNDIBuffer[0]=0.0;
      ExtADXBuffer[0]=0.0;
     }
//--- main cycle
   for(int i=start;i<rates_total && !IsStopped();i++)
     {
      //--- get some data
      double Hi    =customChartIndicator.High[i];
      double prevHi=customChartIndicator.High[i-1];
      double Lo    =customChartIndicator.Low[i];
      double prevLo=customChartIndicator.Low[i-1];
      double prevCl=customChartIndicator.Close[i-1];
      //--- fill main positive and main negative buffers
      double dTmpP=Hi-prevHi;
      double dTmpN=prevLo-Lo;
      if(dTmpP<0.0)   dTmpP=0.0;
      if(dTmpN<0.0)   dTmpN=0.0;
      if(dTmpP>dTmpN) dTmpN=0.0;
      else
        {
         if(dTmpP<dTmpN) dTmpP=0.0;
         else
           {
            dTmpP=0.0;
            dTmpN=0.0;
           }
        }
      //--- define TR
      double tr=MathMax(MathMax(MathAbs(Hi-Lo),MathAbs(Hi-prevCl)),MathAbs(Lo-prevCl));
      //---
      if(tr!=0.0)
        {
         ExtPDBuffer[i]=100.0*dTmpP/tr;
         ExtNDBuffer[i]=100.0*dTmpN/tr;
        }
      else
        {
         ExtPDBuffer[i]=0.0;
         ExtNDBuffer[i]=0.0;
        }
      //--- fill smoothed positive and negative buffers
      ExtPDIBuffer[i]=ExponentialMA(i,ExtADXPeriod,ExtPDIBuffer[i-1],ExtPDBuffer);
      ExtNDIBuffer[i]=ExponentialMA(i,ExtADXPeriod,ExtNDIBuffer[i-1],ExtNDBuffer);
      //--- fill ADXTmp buffer
      double dTmp=ExtPDIBuffer[i]+ExtNDIBuffer[i];
      if(dTmp!=0.0)
         dTmp=100.0*MathAbs((ExtPDIBuffer[i]-ExtNDIBuffer[i])/dTmp);
      else
         dTmp=0.0;
      ExtTmpBuffer[i]=dTmp;
      //--- fill smoothed ADX buffer
      ExtADXBuffer[i]=ExponentialMA(i,ExtADXPeriod,ExtADXBuffer[i-1],ExtTmpBuffer);
     }
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
