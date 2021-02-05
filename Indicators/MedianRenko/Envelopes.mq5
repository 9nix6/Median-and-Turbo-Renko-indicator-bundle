

//+------------------------------------------------------------------+
//|                                                    Envelopes.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_color1  Blue
#property indicator_color2  Red
#property indicator_label1  "Upper band"
#property indicator_label2  "Lower band"
//--- input parameters
input int                InpMAPeriod=14;              // Period
input int                InpMAShift=0;                // Shift
input ENUM_MA_METHOD     InpMAMethod=MODE_SMA;        // Method
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price
input double             InpDeviation=0.1;            // Deviation
//--- indicator buffers
double                   ExtUpBuffer[];
double                   ExtDownBuffer[];
double                   ExtMABuffer[];
int                      weightSum;

//--- MA handle
//int                      ExtMAHandle;

#include <MovingAverages.mqh>
#include <AZ-INVEST/CustomBarConfig.mqh>

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtUpBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtDownBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtMABuffer,INDICATOR_CALCULATIONS);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod-1);
//--- name for DataWindow
   IndicatorSetString(INDICATOR_SHORTNAME,"Env("+string(InpMAPeriod)+")");
   PlotIndexSetString(0,PLOT_LABEL,"Env("+string(InpMAPeriod)+")Upper");
   PlotIndexSetString(1,PLOT_LABEL,"Env("+string(InpMAPeriod)+")Lower");
//---- line shifts when drawing
   PlotIndexSetInteger(0,PLOT_SHIFT,InpMAShift);
   PlotIndexSetInteger(1,PLOT_SHIFT,InpMAShift);
//---
   
   customChartIndicator.SetUseAppliedPriceFlag(InpAppliedPrice);
   
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Envelopes                                                        |
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
   int    i,limit;
//--- check for bars count
   if(rates_total<InpMAPeriod)
      return(0);
//--
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,Time,Close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(Close))
      return(0);
  
   int _prev_calculated = customChartIndicator.GetPrevCalculated();     
     
//--- we can copy not all data
   int to_copy;
   if(_prev_calculated>rates_total || _prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-_prev_calculated;
      if(_prev_calculated>0) to_copy++;
     }
//---- get ma buffer
   if(IsStopped()) return(0); //Checking for stop flag
   
   switch(InpMAMethod)
   {
      case MODE_SMA:
         SimpleMAOnBuffer(rates_total,_prev_calculated,0,InpMAPeriod,customChartIndicator.Price,ExtMABuffer);
      break;
      
      case MODE_EMA:
         ExponentialMAOnBuffer(rates_total,_prev_calculated,0,InpMAPeriod,customChartIndicator.Price,ExtMABuffer);
      break;
      
      case MODE_SMMA:
         SmoothedMAOnBuffer(rates_total,_prev_calculated,0,InpMAPeriod,customChartIndicator.Price,ExtMABuffer);
      break;
      
      case MODE_LWMA:
         LinearWeightedMAOnBuffer(rates_total,_prev_calculated,0,InpMAPeriod,customChartIndicator.Price,ExtMABuffer,weightSum);
      break;
   }
      
//--- preliminary calculations
   limit=_prev_calculated-1;
   if(limit<InpMAPeriod)
      limit=InpMAPeriod;
//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      ExtUpBuffer[i]=(1+InpDeviation/100.0)*ExtMABuffer[i];
      ExtDownBuffer[i]=(1-InpDeviation/100.0)*ExtMABuffer[i];
     }
//--- done
   return(rates_total);
  }
//+------------------------------------------------------------------+
