

//+------------------------------------------------------------------+
//|                                                DT oscillator.mq5 |
//+------------------------------------------------------------------+
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3
#property indicator_level1  70
#property indicator_level2  30

//
//
//
//
//

#property indicator_type1   DRAW_FILLING
#property indicator_color1  PowderBlue,MistyRose
#property indicator_label1  "DT oscillator filling"
#property indicator_type2   DRAW_LINE
#property indicator_color2  DeepSkyBlue
#property indicator_width2  2
#property indicator_label2  "DT oscillator"
#property indicator_type3   DRAW_LINE
#property indicator_color3  PaleVioletRed
#property indicator_width3  1
#property indicator_label3  "DT oscillator signal"

//
//
//
//
//

input int  RsiPeriod     = 13;   // Rsi period
input int  StochPeriod   =  8;   // Stochastic period
input int  SlowingPeriod =  5;   // Slowing
input int  SignalPeriod  =  3;   // Signal period
input bool TapeVisible   = true; // Tape visibility

//
//
//
//
//
//

double dtosc[];
double dtoss[];
double dtosf1[];
double dtosf2[];

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer( 0,dtosf1,INDICATOR_DATA);
   SetIndexBuffer( 1,dtosf2,INDICATOR_DATA);
   SetIndexBuffer( 2,dtosc ,INDICATOR_DATA);
   SetIndexBuffer( 3,dtoss ,INDICATOR_DATA);
      return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double rsibuf[];
double stobuf[];

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
   //
   //
  
   if (ArraySize(rsibuf)!=rates_total) ArrayResize(rsibuf,rates_total);
   if (ArraySize(stobuf)!=rates_total) ArrayResize(stobuf,rates_total);
  
   //
   //
   //
   //
   //
  
   for (int i=(int)MathMax(_prev_calculated-1,0); i<rates_total; i++)
   {
      rsibuf[i] = iRsi(customChartIndicator.Close[i],RsiPeriod,i,rates_total);
      
         double min = rsibuf[i];
         double max = rsibuf[i];
         for (int k=1; k<StochPeriod && (i-k)>=0; k++)
         {
            min = MathMin(rsibuf[i-k],min);
            max = MathMax(rsibuf[i-k],max);
         }
         if (max!=min)
               stobuf[i] = 100*(rsibuf[i]-min)/(max-min);
         else  stobuf[i] = 0;
      
      //
      //
      //
      //
      //
      
      dtosc[i]  = 0; for (int k=0; k<SlowingPeriod && (i-k)>=0; k++) dtosc[i] += stobuf[i-k]; dtosc[i] /= SlowingPeriod;
      dtoss[i]  = 0; for (int k=0; k<SignalPeriod  && (i-k)>=0; k++) dtoss[i] +=  dtosc[i-k]; dtoss[i] /= SignalPeriod;
      if (TapeVisible)
            { dtosf1[i] = dtosc[i];    dtosf2[i] = dtoss[i];    }
      else  { dtosf1[i] = EMPTY_VALUE; dtosf2[i] = EMPTY_VALUE; }        
   }
  
   //
   //
   //
   //
   //
  
   return(rates_total);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double rsiWork[][3];
#define _price  0
#define _chgAvg 1
#define _totChg 2

//
//
//
//
//

double iRsi(double price, double period, int i, int bars)
{
   if (ArrayRange(rsiWork,0)!=bars) ArrayResize(rsiWork,bars);
      
   //
   //
   //
   //
   //
   //

   rsiWork[i][_price] = price;
   if (i==0)
   {
         rsiWork[i][_chgAvg] = 0;
         rsiWork[i][_totChg] = 0;
         return(50);
   }        

   //
   //
   //
   //
   //
      
   double sf     = 1.0 / period;      
   double change = rsiWork[i][_price]-rsiWork[i-1][_price];
        
      rsiWork[i][_chgAvg] = rsiWork[i-1][_chgAvg] + sf*(        change -rsiWork[i-1][_chgAvg]);
      rsiWork[i][_totChg] = rsiWork[i-1][_totChg] + sf*(MathAbs(change)-rsiWork[i-1][_totChg]);

   double changeRatio = (rsiWork[i][_totChg]!=0 ? rsiWork[i][_chgAvg]/rsiWork[i][_totChg] : 0 );
   return(50.0*(changeRatio+1.0));
}
