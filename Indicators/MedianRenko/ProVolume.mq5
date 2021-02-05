#property copyright "2017-2020, Artur Zas"
#property link      "http://www.az-invest.eu"
//---- indicator settings
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   5

#property indicator_label1  "Volume"
#property indicator_type1   DRAW_HISTOGRAM // volume
#property indicator_color1  Gray
#property indicator_style1  0
#property indicator_width1  2

#property indicator_label2  "Buy volume"
#property indicator_type2   DRAW_HISTOGRAM // buy volume
#property indicator_color2  clrDarkGreen
#property indicator_style2  0
#property indicator_width2  2

#property indicator_label3  "Sell volume"
#property indicator_type3   DRAW_HISTOGRAM // sell volume
#property indicator_color3  clrFireBrick
#property indicator_style3  0
#property indicator_width3  2

#property indicator_label4  "Bar volume delta"
#property indicator_type4   DRAW_COLOR_HISTOGRAM // bar delta
#property indicator_color4  Lime,Red,clrNONE
#property indicator_style4  0
#property indicator_width4  5

#property indicator_label5  "Cumulative volume delta"
#property indicator_type5   DRAW_COLOR_LINE // cumulative delta
#property indicator_color5  Green, Red, clrNONE
#property indicator_style5  STYLE_DOT
#property indicator_width5  1


//--- input data
static ENUM_APPLIED_VOLUME InpVolumeType= (SymbolInfoInteger(_Symbol,SYMBOL_VOLUME) <= 0) ? VOLUME_TICK : VOLUME_REAL; // Volumes

input bool InpShowVolume = true;             // Show volume histogram
input bool InpShowBuySellVolume = true;      // Show bar's buy/sell volume breakdown
input bool InpShowBarDelta = true;           // Show bar's buy/sell volume delta 
input bool InpShowCumulativeDelta = false;   // Show cumulative volume delta
input int  InpCumulativeDeltaScale = 1;      // Scale down cumulative volume 1:x

//---- indicator buffers
double                    ExtBarDeltaBuffer[];
double                    ExtBarDeltaColorsBuffer[];

double                    ExtBuyVolumeBuffer[];

double                    ExtSellVolumeBuffer[];

double                    ExtVolumeBuffer[];

double                    ExtCumulativeVolumeBuffer[];
double                    ExtCumulativeVolumeColorBuffer[];

double  cumulativeDelta = 0;

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- buffers   
   SetIndexBuffer(0,ExtVolumeBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtBuyVolumeBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtSellVolumeBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtBarDeltaBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtBarDeltaColorsBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,ExtCumulativeVolumeBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,ExtCumulativeVolumeColorBuffer,INDICATOR_COLOR_INDEX);

//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"Pro Volume");
//---- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,0);
   
   customChartIndicator.SetGetTimeFlag();
   customChartIndicator.SetGetVolumesFlag();
   customChartIndicator.SetGetVolumeBreakdownFlag();
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
//   if(start<1) start=1;
   if(start<0) start=0;
//--- main cycle
   CalculateData(start,rates_total);
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateData(const int nPosition,
                     const int nRatesCount)
  {
   double volume,buyVolume,sellVolume,barDelta;
   
   for(int i=nPosition;i<nRatesCount && !IsStopped();i++)
     {
      //--- calculate indicator
      volume = (InpVolumeType == VOLUME_TICK) ? (double)customChartIndicator.Tick_volume[i] : (double)customChartIndicator.Real_volume[i];
      buyVolume = customChartIndicator.Buy_volume[i];
      sellVolume = customChartIndicator.Sell_volume[i];
      barDelta = buyVolume - sellVolume;
      //
      
      if(InpShowVolume)
         ExtVolumeBuffer[i] = volume;
      else
         ExtVolumeBuffer[i] = 0;
      
      if(InpShowBuySellVolume)
      {
         ExtBuyVolumeBuffer[i] = buyVolume;
         ExtSellVolumeBuffer[i] = sellVolume * (-1);
      }
      else
      {
         ExtBuyVolumeBuffer[i] = 0;
         ExtSellVolumeBuffer[i] = 0;
      }
      
      if(InpShowBarDelta)
      {
         ExtBarDeltaBuffer[i] = barDelta;       
         ExtBarDeltaColorsBuffer[i] = ( ExtBarDeltaBuffer[i] < 0 ) ? 1 : (( ExtBarDeltaBuffer[i] == 0 ) ? 2 : 0 );
      }
      else
      {
         ExtBarDeltaBuffer[i] = 0;       
         ExtBarDeltaColorsBuffer[i] = 2;      
      }
      
      if(InpShowCumulativeDelta)
      {      
         if((i != (nRatesCount-1)) && (i>0))
         {          
            if(IsNewDay(customChartIndicator.Time[i-1], customChartIndicator.Time[i]))
               cumulativeDelta = 0; // reset cumulative volme
   
            cumulativeDelta += barDelta;
            
            ExtCumulativeVolumeBuffer[i] = cumulativeDelta / InpCumulativeDeltaScale;
            ExtCumulativeVolumeColorBuffer[i] = ( ExtCumulativeVolumeBuffer[i] < 0 ) ? 1 : (( ExtCumulativeVolumeBuffer[i] == 0 ) ? 2 : 0 ); 
         }
         else
         {
            ExtCumulativeVolumeBuffer[i] = (cumulativeDelta + barDelta) / InpCumulativeDeltaScale;
            ExtCumulativeVolumeColorBuffer[i] = ( ExtCumulativeVolumeBuffer[i] < 0 ) ? 1 : (( ExtCumulativeVolumeBuffer[i] == 0 ) ? 2 : 0 );       
         }
      }
      else
      {
         ExtCumulativeVolumeBuffer[i] = 0;
         ExtCumulativeVolumeColorBuffer[i] = 2;
      }
      
     }
  }
//+------------------------------------------------------------------+

bool IsNewDay(datetime prevTime,datetime currTime)
{
   MqlDateTime prev;
   MqlDateTime curr;
   
   TimeToStruct(prevTime,prev);
   TimeToStruct(currTime,curr);
   
   if(prev.day_of_week != curr.day_of_week)
      return true;
   else
      return false;

}