//+-------------------------------------------------------------------------------------+
//|                                                               Minions.WeisWaves.mq5 |
//| (CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License|
//|                                                          http://www.MinionsLabs.com |
//+-------------------------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Descriptors                                                      |
//+------------------------------------------------------------------+

//--- input parameters
input int      ExtDeviation=5;

//--- indicator buffers

double         deviation;           // deviation in points

#property version     "1.0"
#property description "WeisWaves"
#property description " "

//+------------------------------------------------------------------+
//| Indicator Settings                                               |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1

#property indicator_label1  "WeisWaves"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_width1  4
#property indicator_color1  clrGreen, clrRed


//+------------------------------------------------------------------+
//| Inputs from User Interface                                       |
//+------------------------------------------------------------------+
input ENUM_APPLIED_VOLUME inpVolumeType = VOLUME_TICK;      // Volume Type to use on waves

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//
//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
double bufferWW[];
double bufferColors[];


//+------------------------------------------------------------------+
//| OnInit()                                                         |
//+------------------------------------------------------------------+
int OnInit() {
    SetIndexBuffer( 0, bufferWW, INDICATOR_DATA );
    SetIndexBuffer( 1, bufferColors, INDICATOR_COLOR_INDEX );

    IndicatorSetString( INDICATOR_SHORTNAME, "WeisWaves" );

    customChartIndicator.SetGetVolumesFlag();

    return INIT_SUCCEEDED;
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
                const int &spread[])   {

    int i, barsToProcess, shouldStartIn = 2;
    double vol;

    if (rates_total < shouldStartIn)  { return 0; }   // no enough bars to calculate the waves...

   // Process data through custom indicator indicator
   
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,time,close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(close))
      return(0);

   int _prev_calculated = customChartIndicator.GetPrevCalculated();
   
   //

    // if it is the first start of calculation of the indicator or if the number of values in the indicator changed
    // or if it is necessary to calculate the indicator for two or more bars (it means something has changed in the price history)
    if (_prev_calculated == 0 || rates_total > _prev_calculated+1) {
        bufferWW[0] = ( inpVolumeType==VOLUME_TICK ? (double)customChartIndicator.Tick_volume[0] : (double)customChartIndicator.Real_volume[0] );
        barsToProcess = rates_total;
    } else {
        // it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate()
        // for calculation not more than one bar is added
        barsToProcess = (rates_total-_prev_calculated) + 1;
    }


    // calculates the volume waves...
    for (i=rates_total-MathMax(shouldStartIn,barsToProcess-shouldStartIn);  i<rates_total && !IsStopped();  i++)  {

        vol = ( inpVolumeType==VOLUME_TICK ? (double)customChartIndicator.Tick_volume[i] : (double)customChartIndicator.Real_volume[i] );   // type casts to the correct format of the buffer...

        if (customChartIndicator.Close[i] >= customChartIndicator.Close[i-1]) {      // Closing UP?

            if (customChartIndicator.Close[i-1]>=customChartIndicator.Close[i-2]) {  // continuing closing UP?
                bufferWW[i]     = bufferWW[i-1] + vol;
                bufferColors[i] = 0;
            } else {                       // no? resets the volume...
                bufferWW[i]     = vol;
                bufferColors[i] = 0;
            }

        } else {                           // Closing DOWN ?

            if (customChartIndicator.Close[i-1]<customChartIndicator.Close[i-2]) {   // continuing closing DOWN?
                bufferWW[i]     = bufferWW[i-1] + vol;
                bufferColors[i] = 1;
            } else {                       // no? resets the volume...
                bufferWW[i]     = vol;
                bufferColors[i] = 1;
            }
        }       
    }

    return rates_total;
}

//+------------------------------------------------------------------+
