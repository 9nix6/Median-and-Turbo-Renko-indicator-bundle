//+------------------------------------------------------------------+
//|                                                  MACDClassic.mqh |
//|                                                      Paul Csapak |
//|                 https://github.com/paulcpk/mql5-MT5-MACD-Classic |
//+------------------------------------------------------------------+

#property copyright "Paul Csapak"
#property link "https://github.com/paulcpk/mql5-MT5-MACD-Classic"
#property description "Moving Average Convergence/Divergence (Classic)"

/*
MIT License
Copyright (c) 2020 Paul Csapak
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <AZ-INVEST/CustomBarConfig.mqh>
#include <MovingAverages.mqh>

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots 3

#property indicator_label1 "MACD"
#property indicator_type1 DRAW_LINE
#property indicator_color1 Blue
#property indicator_style1  STYLE_SOLID
#property indicator_width1 1

#property indicator_label2 "Signal"
#property indicator_type2 DRAW_LINE
#property indicator_color2 Red
#property indicator_style2  STYLE_SOLID
#property indicator_width2 1

#property indicator_label3  "Histogram"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  Green
#property indicator_style3  STYLE_SOLID
#property indicator_width3  4

//--- input parameters
input int InpFastEMA = 12;                              // Fast EMA period
input int InpSlowEMA = 26;                              // Slow EMA period
input int InpSignalSMA = 9;                             // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Applied price
//--- indicator buffers
double ExtMacdBuffer[];
double ExtSignalBuffer[];
double ExtFastMaBuffer[];
double ExtSlowMaBuffer[];
double ExtHistogBuffer[];
//--- MA handles
//int ExtFastMaHandle;
//int ExtSlowMaHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
    //--- indicator buffers mapping
    SetIndexBuffer(0, ExtMacdBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, ExtSignalBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, ExtHistogBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, ExtFastMaBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(4, ExtSlowMaBuffer, INDICATOR_CALCULATIONS);
    //--- sets first bar from what index will be drawn
    PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, InpSignalSMA - 1);
    //--- name for indicator subwindow label
    IndicatorSetString(INDICATOR_SHORTNAME, "MACDClassic(" + string(InpFastEMA) + "," + string(InpSlowEMA) + "," + string(InpSignalSMA) + ")");
    //--- initialization done
}
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(const int __rates_total,
                const int __prev_calculated,
                const datetime &_time[],
                const double &_open[],
                const double &_high[],
                const double &_low[],
                const double &_close[],
                const long &_tick_volume[],
                const long &_volume[],
                const int &_spread[])
{
       
    // process through custom charting indicator
    
      if(!customChartIndicator.OnCalculate(__rates_total,__prev_calculated,_time,_close))
         return(0);
         
      if(!customChartIndicator.BufferSynchronizationCheck(_close))
         return(0);
      
      int _prev_calculated = customChartIndicator.GetPrevCalculated();
      int _rates_total = ArraySize(customChartIndicator.Close);
    //        

    //--- check for data
    if (_rates_total < InpSignalSMA)
        return (0);
        
//--- get Fast EMA buffer
    if(IsStopped()) return(0); //Checking for stop flag   
    ExponentialMAOnBuffer(_rates_total,_prev_calculated,0,InpFastEMA, customChartIndicator.Close, ExtFastMaBuffer);

//--- get SlowSMA buffer
    if(IsStopped()) return(0); //Checking for stop flag
    ExponentialMAOnBuffer(_rates_total,_prev_calculated,0,InpSlowEMA, customChartIndicator.Close, ExtSlowMaBuffer);
        
    //---
    int limit;
    if (_prev_calculated == 0)
        limit = 0;
    else
        limit = _prev_calculated - 1;
    //--- calculate MACD
    for(int i=limit;i<_rates_total && !IsStopped();i++)
        ExtMacdBuffer[i] = ExtFastMaBuffer[i] - ExtSlowMaBuffer[i];
    //--- calculate Signal

    ExponentialMAOnBuffer(_rates_total, _prev_calculated, 0, InpSignalSMA, ExtMacdBuffer, ExtSignalBuffer);

    //--- calculate Histogram
    for(int i=limit;i<_rates_total && !IsStopped();i++)
      ExtHistogBuffer[i]=ExtMacdBuffer[i]-ExtSignalBuffer[i];

    //--- OnCalculate done. Return new prev_calculated.
    return (_rates_total);
}
//+------------------------------------------------------------------+
