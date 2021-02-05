//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property link        "https://www.mql5.com"
#property description "CCI (alternative)"
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_label1  "CCI alternative"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrSkyBlue,clrDodgerBlue
#property indicator_width1  2
//--- input parameters
input int inpPeriod=14; // CCI period
//--- buffers and global variables declarations
double val[],valc[],prices[];

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,val,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,prices,INDICATOR_CALCULATIONS);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,"CCI (alternative)("+(string)inpPeriod+")");
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
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

   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,time,close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(close))
      return(0);
   
   int _prev_calculated = customChartIndicator.GetPrevCalculated();
  
   ///  
  
   if(Bars(_Symbol,_Period)<rates_total) return(_prev_calculated);

   int i=(int)MathMax(_prev_calculated-1,1); for(; i<rates_total && !_StopFlag; i++)
     {
      int _start=MathMax(i-inpPeriod+1,0);
      prices[i]=(customChartIndicator.High[ArrayMaximum(customChartIndicator.High,_start,inpPeriod)]+customChartIndicator.Low[ArrayMinimum(customChartIndicator.Low,_start,inpPeriod)]+customChartIndicator.Close[i])/3;
      double avg = 0; for(int k=0; k<inpPeriod && (i-k)>=0; k++) avg +=         prices[i-k];      avg /= inpPeriod;
      double dev = 0; for(int k=0; k<inpPeriod && (i-k)>=0; k++) dev += MathAbs(prices[i-k]-avg); dev /= inpPeriod;

      val[i] = (dev!=0) ? (prices[i]-avg)/(0.015*dev) : 0;
      valc[i]=(i>0) ?(val[i]>val[i-1]) ? 1 :(val[i]<val[i-1]) ? 2 : valc[i-1]: 0;
     }
   return (i);
  }
//+------------------------------------------------------------------+
