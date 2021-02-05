//+------------------------------------------------------------------+
//|                                                       ZigZag.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
//---- plot Zigzag
#property indicator_label1  "Zigzag"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      ExtDepth=12;
input int      ExtDeviation=5;
input int      ExtBackstep=3;
//--- indicator buffers
double         ZigzagBuffer[];      // main buffer
double         HighMapBuffer[];     // highs
double         LowMapBuffer[];      // lows
int            level=3;             // recounting depth
double         deviation;           // deviation in points

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ZigzagBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighMapBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,LowMapBuffer,INDICATOR_CALCULATIONS);

//--- set short name and digits   
   PlotIndexSetString(0,PLOT_LABEL,"ZigZag("+(string)ExtDepth+","+(string)ExtDeviation+","+(string)ExtBackstep+")");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- set empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- to use in cycle
   deviation=ExtDeviation*_Point;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|  searching index of the highest bar                              |
//+------------------------------------------------------------------+
int iHighest(const double &array[],
             int depth,
             int startPos)
  {
   int index=startPos;
//--- start index validation
   if(startPos<0)
     {
      Print("Invalid parameter in the function iHighest, startPos =",startPos);
      return 0;
     }
   int size=ArraySize(array);
//--- depth correction if need
   if(startPos-depth<0) depth=startPos;
   double max=array[startPos];
//--- start searching
   for(int i=startPos;i>startPos-depth;i--)
     {
      if(array[i]>max)
        {
         index=i;
         max=array[i];
        }
     }
//--- return index of the highest bar
   return(index);
  }
//+------------------------------------------------------------------+
//|  searching index of the lowest bar                               |
//+------------------------------------------------------------------+
int iLowest(const double &array[],
            int depth,
            int startPos)
  {
   int index=startPos;
//--- start index validation
   if(startPos<0)
     {
      Print("Invalid parameter in the function iLowest, startPos =",startPos);
      return 0;
     }
   int size=ArraySize(array);
//--- depth correction if need
   if(startPos-depth<0) depth=startPos;
   double min=array[startPos];
//--- start searching
   for(int i=startPos;i>startPos-depth;i--)
     {
      if(array[i]<min)
        {
         index=i;
         min=array[i];
        }
     }
//--- return index of the lowest bar
   return(index);
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
   int i=0;
   int limit=0,counterZ=0,whatlookfor=0;
   int shift=0,back=0,lasthighpos=0,lastlowpos=0;
   double val=0,res=0;
   double curlow=0,curhigh=0,lasthigh=0,lastlow=0;
//--- auxiliary enumeration
   enum looling_for
     {
      Pike=1,  // searching for next high
      Sill=-1  // searching for next low
     };
//--- initializing
   if(_prev_calculated==0)
     {
      ArrayInitialize(ZigzagBuffer,0.0);
      ArrayInitialize(HighMapBuffer,0.0);
      ArrayInitialize(LowMapBuffer,0.0);
     }
//--- 
   if(rates_total<100) return(0);
//--- set start position for calculations
   if(_prev_calculated==0) limit=ExtDepth;

//--- ZigZag was already counted before
   if(_prev_calculated>0)
     {
      i=rates_total-1;
      //--- searching third extremum from the last uncompleted bar
      while(counterZ<level && i>rates_total-100)
        {
         res=ZigzagBuffer[i];
         if(res!=0) counterZ++;
         i--;
        }
      i++;
      limit=i;

      //--- what type of exremum we are going to find
      if(LowMapBuffer[i]!=0)
        {
         curlow=LowMapBuffer[i];
         whatlookfor=Pike;
        }
      else
        {
         curhigh=HighMapBuffer[i];
         whatlookfor=Sill;
        }
      //--- chipping
      for(i=limit+1;i<rates_total && !IsStopped();i++)
        {
         ZigzagBuffer[i]=0.0;
         LowMapBuffer[i]=0.0;
         HighMapBuffer[i]=0.0;
        }
     }

//--- searching High and Low
   for(shift=limit;shift<rates_total && !IsStopped();shift++)
     {
      val=customChartIndicator.Low[iLowest(customChartIndicator.Low,ExtDepth,shift)];
      if(val==lastlow) val=0.0;
      else
        {
         lastlow=val;
         if((customChartIndicator.Low[shift]-val)>deviation) val=0.0;
         else
           {
            for(back=1;back<=ExtBackstep;back++)
              {
               res=LowMapBuffer[shift-back];
               if((res!=0) && (res>val)) LowMapBuffer[shift-back]=0.0;
              }
           }
        }
      if(customChartIndicator.Low[shift]==val) LowMapBuffer[shift]=val; else LowMapBuffer[shift]=0.0;
      //--- high
      val=customChartIndicator.High[iHighest(customChartIndicator.High,ExtDepth,shift)];
      if(val==lasthigh) val=0.0;
      else
        {
         lasthigh=val;
         if((val-customChartIndicator.High[shift])>deviation) val=0.0;
         else
           {
            for(back=1;back<=ExtBackstep;back++)
              {
               res=HighMapBuffer[shift-back];
               if((res!=0) && (res<val)) HighMapBuffer[shift-back]=0.0;
              }
           }
        }
      if(customChartIndicator.High[shift]==val) HighMapBuffer[shift]=val; else HighMapBuffer[shift]=0.0;
     }

//--- last preparation
   if(whatlookfor==0)// uncertain quantity
     {
      lastlow=0;
      lasthigh=0;
     }
   else
     {
      lastlow=curlow;
      lasthigh=curhigh;
     }

//--- final rejection
   for(shift=limit;shift<rates_total && !IsStopped();shift++)
     {
      res=0.0;
      switch(whatlookfor)
        {
         case 0: // search for peak or lawn
            if(lastlow==0 && lasthigh==0)
              {
               if(HighMapBuffer[shift]!=0)
                 {
                  lasthigh=customChartIndicator.High[shift];
                  lasthighpos=shift;
                  whatlookfor=Sill;
                  ZigzagBuffer[shift]=lasthigh;
                  res=1;
                 }
               if(LowMapBuffer[shift]!=0)
                 {
                  lastlow=customChartIndicator.Low[shift];
                  lastlowpos=shift;
                  whatlookfor=Pike;
                  ZigzagBuffer[shift]=lastlow;
                  res=1;
                 }
              }
            break;
         case Pike: // search for peak
            if(LowMapBuffer[shift]!=0.0 && LowMapBuffer[shift]<lastlow && HighMapBuffer[shift]==0.0)
              {
               ZigzagBuffer[lastlowpos]=0.0;
               lastlowpos=shift;
               lastlow=LowMapBuffer[shift];
               ZigzagBuffer[shift]=lastlow;
               res=1;
              }
            if(HighMapBuffer[shift]!=0.0 && LowMapBuffer[shift]==0.0)
              {
               lasthigh=HighMapBuffer[shift];
               lasthighpos=shift;
               ZigzagBuffer[shift]=lasthigh;
               whatlookfor=Sill;
               res=1;
              }
            break;
         case Sill: // search for lawn
            if(HighMapBuffer[shift]!=0.0 && HighMapBuffer[shift]>lasthigh && LowMapBuffer[shift]==0.0)
              {
               ZigzagBuffer[lasthighpos]=0.0;
               lasthighpos=shift;
               lasthigh=HighMapBuffer[shift];
               ZigzagBuffer[shift]=lasthigh;
              }
            if(LowMapBuffer[shift]!=0.0 && HighMapBuffer[shift]==0.0)
              {
               lastlow=LowMapBuffer[shift];
               lastlowpos=shift;
               ZigzagBuffer[shift]=lastlow;
               whatlookfor=Pike;
              }
            break;
         default: return(rates_total);
        }
     }

//--- return value of _prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
