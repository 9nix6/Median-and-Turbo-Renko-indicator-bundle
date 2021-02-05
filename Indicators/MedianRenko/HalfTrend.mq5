//+------------------------------------------------------------------+
//|                                                    HalfTrend.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   6
//--- plot
#property indicator_label1 "UP"
#property indicator_color1 MediumOrchid  // up[] DodgerBlue
#property indicator_type1  DRAW_LINE
#property indicator_width1 2

#property indicator_label2 "DN"
#property indicator_color2 Red       // down[]
#property indicator_type2  DRAW_LINE
#property indicator_width2 2

#property indicator_label3 "ATR-LOW"
#property indicator_color3 Red  // atrlo[],atrhi[]
#property indicator_type3  DRAW_LINE   //
#property indicator_width3 1

#property indicator_label4 "ATR-HIGH"
#property indicator_color4 MediumOrchid  // atrlo[],atrhi[]
#property indicator_type4  DRAW_LINE   //From Histogram
#property indicator_width4 1

#property indicator_label5 "ARR-UP"
#property indicator_color5 MediumOrchid  // arrdwn[]
#property indicator_type5  DRAW_ARROW
#property indicator_width5 1

#property indicator_label6 "ARR-DN"
#property indicator_color6 Red  // arrup[]
#property indicator_type6  DRAW_ARROW
#property indicator_width6 1

input int    Diamond        = 2;
input int    ChannelDeviation        = 2;
input bool   ShowChannels     = true;
input bool   ShowArrows       = true;
input bool   alertsOn         = false;
input bool   alertsOnCurrent  = false;
input bool   alertsMessage    = true;
input bool   alertsSound      = true;
input bool   alertsEmail      = false;
input int    lookback         = 256;         // Maximum lookback period

bool nexttrend;
double minhighprice, maxlowprice;
double up[], down[], atrlo[], atrhi[],  trend[];
double arrup[], arrdwn[];
//int ind_mahi, ind_malo, ind_atr;
//double iMAHigh[], iMALow[], iATRx[];

#include <AZ-INVEST/CustomBarConfig.mqh>
#include <AZ-INVEST/SDK/IndicatorAccess.mqh>
#include <IncOnRingBuffer\CATROnRingBuffer.mqh>
#include <IncOnRingBuffer\CMAOnRingBuffer.mqh>

CIndicatorAccess iAccess;
CATROnRingBuffer atr;
CMAOnRingBuffer maHigh;
CMAOnRingBuffer maLow;

//iMAHigh, iMALow, iATRx

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, up, INDICATOR_DATA);
   SetIndexBuffer(1, down, INDICATOR_DATA);
   
   SetIndexBuffer(2, atrlo, INDICATOR_DATA);
   SetIndexBuffer(3, atrhi, INDICATOR_DATA);
   
   SetIndexBuffer(4, arrup, INDICATOR_DATA);
   SetIndexBuffer(5, arrdwn, INDICATOR_DATA);
   
   SetIndexBuffer(6, trend, INDICATOR_CALCULATIONS);
//   SetIndexBuffer(7, iMAHigh, INDICATOR_CALCULATIONS);
//   SetIndexBuffer(8, iMALow, INDICATOR_CALCULATIONS);
//   SetIndexBuffer(9, iATRx, INDICATOR_CALCULATIONS);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   ArraySetAsSeries(up, true);
   ArraySetAsSeries(down, true);
   ArraySetAsSeries(atrlo, true);
   ArraySetAsSeries(atrhi, true);
   ArraySetAsSeries(arrup, true);
   ArraySetAsSeries(arrdwn, true);
   ArraySetAsSeries(trend, true);
//   ArraySetAsSeries(iMAHigh, true);
//   ArraySetAsSeries(iMALow, true);
//   ArraySetAsSeries(iATRx, true);
   if(ShowChannels)
   {
       
      PlotIndexSetInteger(2,PLOT_LINE_COLOR,0,clrDodgerBlue); 
      PlotIndexSetInteger(3,PLOT_LINE_COLOR,0,clrRed); 
      PlotIndexSetInteger(2,PLOT_LINE_STYLE,STYLE_DOT);
      PlotIndexSetInteger(3,PLOT_LINE_STYLE,STYLE_DOT);
   }
   else
   {
       PlotIndexSetInteger(2,PLOT_LINE_COLOR,0,clrNONE); 
      PlotIndexSetInteger(3,PLOT_LINE_COLOR,0,clrNONE);
      
   }
   
   
   if(ShowArrows)
   {
 
      bool rep5= PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_ARROW);  
      bool rep6=PlotIndexSetInteger(5, PLOT_DRAW_TYPE, DRAW_ARROW);
      PlotIndexSetInteger(4, PLOT_ARROW, 233);     //233
      PlotIndexSetInteger(5, PLOT_ARROW, 234);     //234
      //Comment(ShowArrows +"\n"+rep5 +"\n"+ rep6);
   
   }
   else
   {  PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(5, PLOT_DRAW_TYPE, DRAW_NONE);   
   }
   
   
   //ind_mahi = iMA(NULL, 0, Diamond, 0, MODE_SMA, PRICE_HIGH);
   //ind_malo = iMA(NULL, 0, Diamond, 0, MODE_SMA, PRICE_LOW);
   //ind_atr = iATR(NULL, 0, 100);
   //if(ind_mahi == INVALID_HANDLE || ind_mahi == INVALID_HANDLE || ind_atr == INVALID_HANDLE)
  // {
   //   PrintFormat("Failed to create handle of the indicators, error code %d", GetLastError());
   //   return(INIT_FAILED);
   //}
   
   customChartIndicator.SetGetTimeFlag();
   
   if(!atr.Init(100,MODE_SMA,lookback))
   {
      PrintFormat("Failed to create ATR on ring buffer");
      return(INIT_FAILED);
   }
   
   if(!maHigh.Init(Diamond, MODE_SMA, lookback))
   {
      PrintFormat("Failed to create maHigh on ring buffer");
      return(INIT_FAILED);
   }

   if(!maLow.Init(Diamond, MODE_SMA, lookback))
   {
      PrintFormat("Failed to create maLow on ring buffer");
      return(INIT_FAILED);
   }
   
   
   nexttrend = 0;
   minhighprice = iHigh(NULL, 0, Bars(NULL, 0) - 1); // ?
   maxlowprice = iLow(NULL, 0, Bars(NULL, 0) - 1); // ?
   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |`
//+------------------------------------------------------------------+
int  OnCalculate(
   const int        rates_total,       // size of input time series
   const int        prev_calculated,   // number of handled bars at the previous call
   const datetime&  time[],            // Time array
   const double&    open[],            // Open array
   const double&    high[],            // High array
   const double&    low[],             // Low array
   const double&    close[],           // Close array
   const long&      tick_volume[],     // Tick Volume array
   const long&      volume[],          // Real Volume array
   const int&       spread[]           // Spread array
)
{
   //
   // Process data through custom chart indicator
   //
   
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,time,close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(close))
      return(0);
      
   int _prev_calculated = customChartIndicator.GetPrevCalculated();      
   int _rates_total = ArraySize(customChartIndicator.Close);
   
   //
   
   int i, limit, to_copy;
   double _atr, lowprice_i, highprice_i, lowma, highma;
   
   ArraySetAsSeries(customChartIndicator.Time, true);
   ArraySetAsSeries(customChartIndicator.High, true);
   ArraySetAsSeries(customChartIndicator.Low, true);
   ArraySetAsSeries(customChartIndicator.Close, true);
   
   if(_prev_calculated > _rates_total || _prev_calculated < 0) to_copy = _rates_total;
   else
   {
      to_copy = _rates_total - _prev_calculated;
      if(_prev_calculated > 0)
         to_copy += 10;
   }
   
//   if(!RefreshBuffers(iMAHigh, iMALow, iATRx, ind_mahi, ind_malo, ind_atr, to_copy))
//      return(0);

   atr.MainOnArray(_rates_total,_prev_calculated,customChartIndicator.High,customChartIndicator.Low,customChartIndicator.Close);
   maHigh.MainOnArray(_rates_total, _prev_calculated, customChartIndicator.High);
   maLow.MainOnArray(_rates_total, _prev_calculated, customChartIndicator.Low);
//  
      
   if(_prev_calculated == 0)
      limit = _rates_total - 2;
   else
      limit = _rates_total - _prev_calculated + 1;

   for(i = limit; i >= 0; i--)
   {
      //lowprice_i = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, Diamond, i));
      //highprice_i = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, Diamond, i));
      //lowma = NormalizeDouble(iMALow[i], _Digits);
      //highma = NormalizeDouble(iMAHigh[i], _Digits);
      
      lowprice_i = customChartIndicator.Low[iAccess.Lowest(customChartIndicator.Low, Diamond, i)];
      highprice_i = customChartIndicator.High[iAccess.Highest(customChartIndicator.High, Diamond, i)];
      lowma = NormalizeDouble(maLow[i], _Digits);
      highma = NormalizeDouble(maHigh[i], _Digits);
      
      //
      
      trend[i] = trend[i + 1];
      
      //atr = iATRx[i] / 2;
      _atr = atr[i] / 2;
      
      arrup[i]  = EMPTY_VALUE;
      arrdwn[i] = EMPTY_VALUE;
      
      if(trend[i + 1] != 1.0)
      {
         maxlowprice = MathMax(lowprice_i, maxlowprice);
         if(highma < maxlowprice && customChartIndicator.Close[i] < customChartIndicator.Low[i + 1])
         {
            trend[i] = 1.0;
            nexttrend = 0;
            minhighprice = highprice_i;
         }
      }
      else
      {
         minhighprice = MathMin(highprice_i, minhighprice);
         if(lowma > minhighprice && customChartIndicator.Close[i] > customChartIndicator.High[i + 1])
         {
            trend[i] = 0.0;
            nexttrend = 1;
            maxlowprice = lowprice_i;
         }
      }
      //---
      if(trend[i] == 0.0)
      {
         if(trend[i + 1] != 0.0)
         {
            up[i] = down[i + 1];
            up[i + 1] = up[i];
            arrup[i] = up[i] - 2 * _atr;
         }
         else
         {
            up[i] = MathMax(maxlowprice, up[i + 1]);
         }

        
         atrhi[i] = up[i] + ChannelDeviation*_atr;
         atrlo[i] = up[i] - ChannelDeviation*_atr;
         down[i] = 0.0;
      }
      else
      {
         if(trend[i + 1] != 1.0)
         {
            down[i] = up[i + 1];
            down[i + 1] = down[i];
            arrdwn[i] = down[i] + 2 * _atr;
         }
         else
         {
            down[i] = MathMin(minhighprice, down[i + 1]);
         }
         
         
         atrhi[i] = down[i] + ChannelDeviation*_atr;
         atrlo[i] = down[i] - ChannelDeviation*_atr;
         up[i] = 0.0;
      }
   }
   manageAlerts();
   return (rates_total);
}

/*
//+------------------------------------------------------------------+
//| Filling indicator buffers from the indicators                    |
//+------------------------------------------------------------------+
bool RefreshBuffers(double &hi_buffer[],
                    double &lo_buffer[],
                    double &atr_buffer[],
                    int hi_handle,
                    int lo_handle,
                    int atr_handle,
                    int amount
                   )
{
//--- reset error code
   ResetLastError();
//--- fill a part of the iMACDBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(hi_handle, 0, 0, amount, hi_buffer) < 0)
   {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the MaHigh indicator, error code %d", GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
   }
//--- fill a part of the SignalBuffer array with values from the indicator buffer that has index 1
   if(CopyBuffer(lo_handle, 0, 0, amount, lo_buffer) < 0)
   {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the MaLow indicator, error code %d", GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
   }
//--- fill a part of the StdDevBuffer array with values from the indicator buffer
   if(CopyBuffer(atr_handle, 0, 0, amount, atr_buffer) < 0)
   {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the ATR indicator, error code %d", GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
   }
//--- everything is fine
   return(true);
}
*/
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void manageAlerts()
{
   int whichBar;
   if (alertsOn)
   {
      if (alertsOnCurrent)
         whichBar = 0;
      else
         whichBar = 1;
      if (arrup[whichBar]  != EMPTY_VALUE) doAlert(whichBar, "up");
      if (arrdwn[whichBar] != EMPTY_VALUE) doAlert(whichBar, "down");
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void doAlert(int forBar, string doWhat)
{
   static string   previousAlert = "nothing";
   static datetime previousTime;
   string message;
   if (previousAlert != doWhat || previousTime != iTime(NULL, 0, forBar))
   {
      previousAlert  = doWhat;
      previousTime   = iTime(NULL, 0, forBar);
      message = StringFormat("%s at %s", Symbol(), TimeToString(TimeLocal(), TIME_SECONDS), " HalfTrend signal ", doWhat);
      if (alertsMessage) Alert(message);
      if (alertsEmail)   SendMail(Symbol(), StringFormat("HalfTrend %s", message));
      if (alertsSound)   PlaySound("alert2.wav");
   }
}

//+------------------------------------------------------------------+
