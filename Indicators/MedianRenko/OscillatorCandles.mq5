//+------------------------------------------------------------------+
//|                                           Oscillator Candles.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright  "Copyright 2015, MetaQuotes Software Corp."
#property link       "https://www.mql5.com"
#property description"Oscillator Candles by pipPod"
#property version    "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   1
//---
#property indicator_type1  DRAW_COLOR_CANDLES
#property indicator_color1  clrLimeGreen,clrFireBrick
//---
#property indicator_levelcolor clrLightSlateGray
//---
double indicator_level1=   0;
double indicator_level2=  20;
double indicator_level3=  30;
double indicator_level4=  50;
double indicator_level5=  70;
double indicator_level6=  80;
double indicator_level7= 100;
double indicator_level8=-100;
//---
#include <MovingAverages.mqh>
#include <AZ-INVEST/CustomBarConfig.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum indicators
  {
   INDICATOR_MACD,         //Moving Average Convergence/Divergence
   INDICATOR_STOCHASTIC,   //Stochastic Oscillator
   INDICATOR_RSI,          //Relative Strength Index
   INDICATOR_CCI,          //Commodity Channel Index
   INDICATOR_MOMENTUM,     //Momentum Index
  };
//--- indicator to show
input indicators  Indicator=INDICATOR_MACD;
//--- indicator parameters
input string MACD;
input ushort FastEMA=12;   //Fast EMA Period
input ushort SlowEMA=26;   //Slow EMA Period
//---
input string Stochastic;
input ushort Kperiod=7;    //K Period
input ushort Slowing=3;
input ENUM_STO_PRICE PriceField=STO_LOWHIGH; //Price Field
//---
input string RSI;
input ushort RSIPeriod=14; //RSI Period
//---
input string CCI;
input ushort CCIPeriod=14; //CCI Period
//---
input string Momentum;
input ushort MomPeriod=14; //Momentum Period
//---
input string _;            //---
input bool PriceLine=true; //Horizontal Value Line
#define priceLine "priceLine"
input bool AutoColor=false;//Auto Color Candles
//---index buffers for drawing candles
double OpenBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];
double ColorBuffer[];
//---Stochastic buffers
double HighesBuffer[];
double LowestBuffer[];
//---CCI buffers
double PriceBuffer[];
double MovAvBuffer[];
//---
long chartID=ChartID();
short window;
#define OBJ_NONE -1
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   string shortName;
   switch(Indicator)
     {
      case INDICATOR_MACD:
         shortName=StringFormat("MACD(%d,%d)",FastEMA,SlowEMA);
         IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
         IndicatorSetInteger(INDICATOR_LEVELS,1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         PlotIndexSetString(0,PLOT_LABEL,"MACD Open;MACD High;MACD Low;MACD Close");
         for(int i=0;i<5;i++)
            PlotIndexSetInteger(i,PLOT_DRAW_BEGIN,SlowEMA-1);
         break;
      case INDICATOR_STOCHASTIC:
         shortName=StringFormat("Stochastic(%d,%d)",Kperiod,Slowing);
         SetIndexBuffer(5,HighesBuffer,INDICATOR_CALCULATIONS);
         SetIndexBuffer(6,LowestBuffer,INDICATOR_CALCULATIONS);
         IndicatorSetInteger(INDICATOR_DIGITS,0);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level2);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1,indicator_level4);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,indicator_level6);
         PlotIndexSetString(0,PLOT_LABEL,"Stoch Open;Stoch High;Stoch Low;Stoch Close");
         for(int i=0;i<5;i++)
            PlotIndexSetInteger(i,PLOT_DRAW_BEGIN,Kperiod-1+Slowing-1);
         break;
      case INDICATOR_RSI:
         shortName=StringFormat("RSI(%d)",RSIPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,0);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1,indicator_level4);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,indicator_level5);
         PlotIndexSetString(0,PLOT_LABEL,"RSI Open;RSI High;RSI Low;RSI Close");
         for(int i=0;i<5;i++)
            PlotIndexSetInteger(i,PLOT_DRAW_BEGIN,RSIPeriod-1);
         break;
      case INDICATOR_CCI:
         shortName=StringFormat("CCI(%d)",CCIPeriod);
         SetIndexBuffer(5,PriceBuffer,INDICATOR_CALCULATIONS);
         SetIndexBuffer(6,MovAvBuffer,INDICATOR_CALCULATIONS);
         IndicatorSetInteger(INDICATOR_DIGITS,0);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1,indicator_level7);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,indicator_level8);
         PlotIndexSetString(0,PLOT_LABEL,"CCI Open;CCI High;CCI Low;CCI Close");
         for(int i=0;i<5;i++)
            PlotIndexSetInteger(i,PLOT_DRAW_BEGIN,CCIPeriod-1);
         break;
      case INDICATOR_MOMENTUM:
         shortName=StringFormat("Momentum(%d)",MomPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,2);
         IndicatorSetInteger(INDICATOR_LEVELS,1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level7);
         PlotIndexSetString(0,PLOT_LABEL,"Mom Open;Mom High;Mom Low;Mom Close");
         for(int i=0;i<5;i++)
            PlotIndexSetInteger(i,PLOT_DRAW_BEGIN,MomPeriod-1);
     }
//---set name, get window
   IndicatorSetString(INDICATOR_SHORTNAME,shortName);
   window=(short)ChartWindowFind(chartID,shortName);
//---index buffers
   SetIndexBuffer(0,OpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,CloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ColorBuffer,INDICATOR_COLOR_INDEX);
//---color bars
   if(AutoColor)
      SetColors();
//---delete price line
   if(!PriceLine && ObjectFind(chartID,priceLine)!=OBJ_NONE)
      ObjectDelete(chartID,priceLine);
//---
   return(INIT_SUCCEEDED);
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
   
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,time,close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(close))
      return(0);
   
   int _prev_calculated = customChartIndicator.GetPrevCalculated();
   
   //  


//---bars to count
   int toFill=rates_total-_prev_calculated;
   if(_prev_calculated>0)
      toFill++;
//---fill OHLC buffers
   switch(Indicator)
     {
      case INDICATOR_MACD:
         if(MACD(customChartIndicator.GetRatesTotal(),_prev_calculated,customChartIndicator.High,customChartIndicator.Low,customChartIndicator.Close)!=toFill)
         return(0);
         break;
      case INDICATOR_STOCHASTIC:
         if(Stochastic(customChartIndicator.GetRatesTotal(),_prev_calculated,customChartIndicator.High,customChartIndicator.Low,customChartIndicator.Close)!=toFill)
         return(0);
         break;
      case INDICATOR_RSI:
         if(RSI(customChartIndicator.GetRatesTotal(),_prev_calculated,customChartIndicator.High,customChartIndicator.Low,customChartIndicator.Close)!=toFill)
         return(0);
         break;
      case INDICATOR_CCI:
         if(CCI(customChartIndicator.GetRatesTotal(),_prev_calculated,customChartIndicator.High,customChartIndicator.Low,customChartIndicator.Close)!=toFill)
         return(0);
         break;
      case INDICATOR_MOMENTUM:
         if(Momentum(customChartIndicator.GetRatesTotal(),_prev_calculated,customChartIndicator.High,customChartIndicator.Low,customChartIndicator.Close)!=toFill)
         return(0);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Moving Average Convergence/Divergence                            |
//+------------------------------------------------------------------+
int MACD(const int rates_total,
         const int prev_calculated,
         const double &high[],
         const double &low[],
         const double &close[])
  {
//---check bars and input vars
   if(rates_total<=SlowEMA || FastEMA<=1 || SlowEMA<FastEMA)
      return(0);
//---declare vars
   int begin,count=0;
   double highFast,highSlow,
   lowFast,lowSlow,
   closeFast,closeSlow;
   static double prevCloseFast,prevCloseSlow;
//--- initial zero
   if(prev_calculated==0)
     {
      for(int i=0;i<SlowEMA && !IsStopped();i++)
        {
         OpenBuffer[i]=HighBuffer[i]=LowBuffer[i]=CloseBuffer[i]=0.0;
         count++;
        }
      begin=SlowEMA;
     }
   else
      begin=prev_calculated-1;
//--- calculate MACD
   for(int i=begin;i<rates_total && !IsStopped();i++)
     {
      highFast = ExponentialMA(i,FastEMA,prevCloseFast,high);
      highSlow = ExponentialMA(i,SlowEMA,prevCloseSlow,high);
      lowFast = ExponentialMA(i,FastEMA,prevCloseFast,low);
      lowSlow = ExponentialMA(i,SlowEMA,prevCloseSlow,low);
      closeFast = ExponentialMA(i,FastEMA,prevCloseFast,close);
      closeSlow = ExponentialMA(i,SlowEMA,prevCloseSlow,close);
      //---fill OHLC buffers
      HighBuffer[i]= highFast-highSlow;
      LowBuffer[i] = lowFast-lowSlow;
      CloseBuffer[i]=closeFast-closeSlow;
      //---check for new bar
      static int k;
      if(k!=i)
        {
         prevCloseFast = closeFast;
         prevCloseSlow = closeSlow;
         OpenBuffer[i] = CloseBuffer[i-1];
         k=i;
        }
      //---set candle color
      ColorBuffer[i]=(CloseBuffer[i]>OpenBuffer[i])?0:1;
      //---horizontal value line
      if(PriceLine)
         PriceLine(CloseBuffer[i]);
      count++;
     }
//--- macd done. return count.
   return(count);
  }
//+------------------------------------------------------------------+
//| Stochastic Oscillator                                            |
//+------------------------------------------------------------------+
int Stochastic(const int rates_total,
               const int prev_calculated,
               const double &high[],
               const double &low[],
               const double &close[])
  {
//--- check for bars count
   if(rates_total<=Kperiod+Slowing || Kperiod<=1)
      return(0);
//--- declare variables
   int begin,count=0;
   double sumLowH,sumLowL,sumLowC,sumHigh;
   double min,max;
//---
   begin=Kperiod-1;
   if(begin<prev_calculated)
      begin=prev_calculated-1;
   else
   for(int i=0;i<begin && !IsStopped();i++)
             LowestBuffer[i]=HighesBuffer[i]=0.0;
//--- calculate HighesBuffer[] and LowestBuffer[]
   for(int i=begin;i<rates_total && !IsStopped();i++)
     {
      min = 1000000.0;
      max =-1000000.0;
      for(int k=(i-Kperiod+1);k<=i;k++)
        {
         switch(PriceField)
           {
            case STO_LOWHIGH:
               if(min>low[k])
               min=low[k];
               if(max<high[k])
                  max=high[k];
               break;
            case STO_CLOSECLOSE:
               if(min>close[k])
               min=close[k];
               if(max<close[k])
                  max=close[k];
           }
        }
      LowestBuffer[i] = min;
      HighesBuffer[i] = max;
     }
//--- %K
   begin=Kperiod-1;
   if(begin<prev_calculated)
      begin=prev_calculated-1;
   else
   for(int i=0;i<begin && !IsStopped();i++)
     {
      OpenBuffer[i]=HighBuffer[i]=LowBuffer[i]=CloseBuffer[i]=0.0;
      count++;
     }
//--- main cycle
   for(int i=begin;i<rates_total && !IsStopped();i++)
     {
      sumLowH=sumLowL=sumLowC=sumHigh=0.0;
      for(int k=(i-Slowing+1);k<=i;k++)
        {
         sumLowH += (high[i]-LowestBuffer[k]);
         sumLowL += (low[i]-LowestBuffer[k]);
         sumLowC += (close[k]-LowestBuffer[k]);
         sumHigh += (HighesBuffer[k]-LowestBuffer[k]);
        }
      //---check for new bar
      static int k;
      if(k!=i)
        {
         OpenBuffer[i]=CloseBuffer[i-1];
         k=i;
        }
      //---check zero divide and fill candle buffers
      if(sumHigh==0.0)
         HighBuffer[i]=LowBuffer[i]=CloseBuffer[i]=50.0;
      else
        {
         HighBuffer[i]= OpenBuffer[i]+(sumLowH/sumHigh*100-OpenBuffer[i])/Slowing;
         LowBuffer[i] = OpenBuffer[i]+(sumLowL/sumHigh*100-OpenBuffer[i])/Slowing;
         CloseBuffer[i]=sumLowC/sumHigh*100;
        }
      //---set candle color
      ColorBuffer[i]=(CloseBuffer[i]>OpenBuffer[i])?0:1;
      //---horizontal value line
      if(PriceLine)
         PriceLine(CloseBuffer[i]);
      count++;
     }
//--- stochastic done. return count.
   return(count);
  }
//+------------------------------------------------------------------+
//| Relative Strength index                                          |
//+------------------------------------------------------------------+
int RSI(const int rates_total,
        const int prev_calculated,
        const double &high[],
        const double &low[],
        const double &close[])
  {
//--- check bars and input vars
   if(rates_total<=RSIPeriod || RSIPeriod<=1)
      return(0);
   int begin,count=0;
//--- declare vars
   double diffC,
   diffH,
   diffL;
   double currPositive = 0.0,
   currNegative = 0.0;
   static double prevPositive = 0.0,
   prevNegative = 0.0;
//--- preliminary calculations
   begin=prev_calculated-1;
   if(begin<=RSIPeriod)
     {
      //--- first RSIPeriod values of the indicator are not calculated
      OpenBuffer[0]=HighBuffer[0]=LowBuffer[0]=CloseBuffer[0]=0.0;
      double sumPositive = 0.0,
      sumNegative = 0.0;
      count++;
      for(int i=1;i<=RSIPeriod && !IsStopped();i++)
        {
         OpenBuffer[i]=HighBuffer[i]=LowBuffer[i]=CloseBuffer[i]=0.0;
         diffC=close[i]-close[i-1];
         sumPositive += (diffC>0.0? diffC:0.0);
         sumNegative += (diffC<0.0?-diffC:0.0);
         count++;
        }
      //--- calculate first visible value
      currPositive = sumPositive/RSIPeriod;
      currNegative = sumNegative/RSIPeriod;
      //--- check zero divide, calculate first rsi and fill candle buffers
      if(currNegative!=0.0)
         OpenBuffer[RSIPeriod]=HighBuffer[RSIPeriod]=LowBuffer[RSIPeriod]=
                               CloseBuffer[RSIPeriod]=100.0-100.0/(1.0+currPositive/currNegative);
      else
      if(currPositive!=0.0)
                       OpenBuffer[RSIPeriod]=HighBuffer[RSIPeriod]=LowBuffer[RSIPeriod]=
                       CloseBuffer[RSIPeriod]=100.0;
      else
      OpenBuffer[RSIPeriod]=HighBuffer[RSIPeriod]=LowBuffer[RSIPeriod]=
                            CloseBuffer[RSIPeriod]=50.0;
      prevPositive = currPositive;
      prevNegative = currNegative;
      //--- prepare the position value for main calculation
      begin=RSIPeriod+1;
     }
//--- the main loop of calculations
   for(int i=begin;i<rates_total && !IsStopped();i++)
     {
      diffC = close[i]-close[i-1];
      diffH = (high[i]-close[i-1])/RSIPeriod;
      diffL = (low[i]-close[i-1])/RSIPeriod;
      currPositive = (prevPositive*(RSIPeriod-1)+(diffC>0.0? diffC:0.0))/RSIPeriod;
      currNegative = (prevNegative*(RSIPeriod-1)+(diffC<0.0?-diffC:0.0))/RSIPeriod;
      //--- check zero divide, calculate rsi and fill candle buffers
      if(prevNegative!=0.0)
        {
         HighBuffer[i]= 100.0-100.0/(1.0+(prevPositive+diffH)/prevNegative);
         LowBuffer[i] = 100.0-100.0/(1.0+prevPositive/(prevNegative-diffL));
        }
      else
      if(prevPositive!=0.0)
                       HighBuffer[i]= LowBuffer[i] = 100.0;
      else
         HighBuffer[i]=LowBuffer[i]=50.0;
      if(currNegative!=0.0)
         CloseBuffer[i]=100.0-100.0/(1.0+currPositive/currNegative);
      else
      if(currPositive!=0.0)
                       CloseBuffer[i]=100.0;
      else
         CloseBuffer[i]=50.0;
      //---check for new bar
      static int k;
      if(k!=i)
        {
         prevPositive = currPositive;
         prevNegative = currNegative;
         OpenBuffer[i]= CloseBuffer[i-1];
         k=i;
        }
      //---set candle color
      ColorBuffer[i]=(CloseBuffer[i]>OpenBuffer[i])?0:1;
      //---horizontal value line
      if(PriceLine)
         PriceLine(CloseBuffer[i]);
      count++;
     }
//---rsi done.return count.
   return(count);
  }
//+------------------------------------------------------------------+
//| Commodity Channel Index                                          |
//+------------------------------------------------------------------+
int CCI(const int rates_total,
        const int prev_calculated,
        const double &high[],
        const double &low[],
        const double &close[])
  {
//--- check bars and input vars
   if(rates_total<=CCIPeriod || CCIPeriod<=1)
      return(0);
//--- declare vars
   int begin,count=0;
   double sum,mul;
//--- initial zero
   if(prev_calculated<1)
     {
      for(int i=0;i<CCIPeriod-1 && !IsStopped();i++)
        {
         OpenBuffer[i]=HighBuffer[i]=LowBuffer[i]=CloseBuffer[i]=0.0;
         PriceBuffer[i] = (high[i]+low[i]+close[i])/3;
         MovAvBuffer[i] = 0.0;
         count++;
        }
     }
//--- calculate position
   begin=prev_calculated-1;
   if(begin<CCIPeriod-1)
      begin=CCIPeriod-1;
//--- typical price and its moving average
   for(int i=begin;i<rates_total && !IsStopped();i++)
     {
      PriceBuffer[i] = (high[i]+low[i]+close[i])/3;
      MovAvBuffer[i] = SimpleMA(i,CCIPeriod,PriceBuffer);
     }
//--- standard deviations and cci counting
   mul=0.015/CCIPeriod;
   begin=prev_calculated-1;
   if(begin<CCIPeriod-1)
      begin=CCIPeriod-1;
//---
   for(int i=begin;i<rates_total && !IsStopped();i++)
     {
      sum=0.0;
      int k=i-CCIPeriod+1;
      while(k<=i)
        {
         sum+=MathAbs(PriceBuffer[k]-MovAvBuffer[i]);
         k++;
        }
      sum*=mul;
      //---check zero divide and fill candle buffers
      if(sum==0.0)
         HighBuffer[i]=LowBuffer[i]=CloseBuffer[i]=0.0;
      else
        {
         HighBuffer[i]=(high[i]-MovAvBuffer[i])/sum;
         LowBuffer[i] =(low[i]-MovAvBuffer[i])/sum;
         CloseBuffer[i]=(close[i]-MovAvBuffer[i])/sum;
        }
      //---check for new bar
      static int m;
      if(m!=i)
        {
         OpenBuffer[i]=CloseBuffer[i-1];
         m=i;
        }
      //---set candle color
      ColorBuffer[i]=(CloseBuffer[i]>OpenBuffer[i])?0:1;
      //---horizontal value line
      if(PriceLine)
         PriceLine(CloseBuffer[i]);
      count++;
     }
//---cci done. return count.
   return(count);
  }
//+------------------------------------------------------------------+
//| Momentum                                                         |
//+------------------------------------------------------------------+
int Momentum(const int rates_total,
             const int prev_calculated,
             const double &high[],
             const double &low[],
             const double &close[])
  {
//--- check bars and input param
   if(rates_total<=MomPeriod || MomPeriod<=0)
      return(0);
   int begin,count=0;
//--- initial zero
   if(prev_calculated<=0)
     {
      for(int i=0;i<MomPeriod && !IsStopped();i++)
        {
         OpenBuffer[i]=HighBuffer[i]=LowBuffer[i]=CloseBuffer[i]=0.0;
         count++;
        }
      begin=MomPeriod;
     }
   else
      begin=prev_calculated-1;
      
   static double closeMomPeriod;
//--- the main loop of calculations
   for(int i=begin;i<rates_total && !IsStopped();i++)
     {
      //---check for new bar
      static int k;
      if(k!=i)
        {
         closeMomPeriod= close[i-MomPeriod];
        // if(closeMomPeriod == 0)
        //    continue;

        if(closeMomPeriod == 0)
         closeMomPeriod = 1;

            
         OpenBuffer[i] = CloseBuffer[i-1];
         k=i;
        }
        
        
      HighBuffer[i]= high[i]*100/closeMomPeriod;
      LowBuffer[i] = low[i]*100/closeMomPeriod;
      CloseBuffer[i]=close[i]*100/closeMomPeriod;
      //---set candle color
      ColorBuffer[i]=(CloseBuffer[i]>OpenBuffer[i])?0:1;
      //---horizontal value line
      if(PriceLine)
         PriceLine(CloseBuffer[i]);
      count++;
     }
//--- momentum done. return count
   return(count);
  }
//+------------------------------------------------------------------+
//| Horizontal value line                                            |
//+------------------------------------------------------------------+
void PriceLine(const double &close_price)
  {
   if(ObjectFind(chartID,priceLine)!=OBJ_NONE)
      ObjectDelete(chartID,priceLine);
   if(!ObjectCreate(chartID,priceLine,OBJ_HLINE,window,0,close_price))
     {
      Print(__FUNCTION__,": error ",GetLastError());
      return;
     }
   ObjectSetInteger(chartID,priceLine,OBJPROP_WIDTH,1);
   ObjectSetInteger(chartID,priceLine,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(chartID,priceLine,OBJPROP_COLOR,clrLightSlateGray);
   ObjectSetInteger(chartID,priceLine,OBJPROP_HIDDEN,true);
   ObjectSetInteger(chartID,priceLine,OBJPROP_SELECTABLE,false);
   return;
  }
//+------------------------------------------------------------------+
//| Auto colors for candles                                          |
//+------------------------------------------------------------------+
bool SetColors()
  {
   color colorBase=clrNONE,
   colorQote=clrNONE;
   string base,
   qote;
   string Name[9] = {"AUD","CAD","CHF","EUR","GBP","JPY","NZD","USD","XAU"};
   color Color[9] = 
     {
      clrDarkOrange,clrWhiteSmoke,clrFireBrick,clrRoyalBlue,
      clrSilver,clrYellow,clrDarkViolet,clrLimeGreen,clrGold
     };
   base = StringSubstr(_Symbol,0,3);  //Base currency name
   qote = StringSubstr(_Symbol,3,3);  //Quote currency name
   for(int i=0;i<9;i++)
     {
      if(base==Name[i])
         colorBase=Color[i];
      if(qote==Name[i])
         colorQote=Color[i];
     }
   if(!PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,colorBase) || 
      !PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,colorQote))
      return(false);
   if(ChartGetInteger(0,CHART_COLOR_CANDLE_BULL)!=colorBase)
     {
      if(!ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,colorBase) || 
         !ChartSetInteger(0,CHART_COLOR_CHART_UP,colorBase))
         return(false);
     }
   if(ChartGetInteger(0,CHART_COLOR_CANDLE_BEAR)!=colorQote)
     {
      if(!ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,colorQote) || 
         !ChartSetInteger(0,CHART_COLOR_CHART_DOWN,colorQote))
         return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
