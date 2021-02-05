//+------------------------------------------------------------------+
//|                                                     ma cross.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3 
#property indicator_plots   2
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLightSeaGreen
#property indicator_width1  2
#property indicator_label1  "Bull ADX Cross"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  2
#property indicator_label2 "Bear ADX Cross"
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

input int    AdxPeriod        = 14;          // ADX period
input bool   alertsOn         = true;        // Turn alerts on?
input bool   alertsOnCurrent  = false;       // Alert on current bar?
input bool   alertsMessage    = true;        // Display messages on alerts?
input bool   alertsSound      = false;       // Play sound on alerts?
input bool   alertsEmail      = false;       // Send email on alerts?
input bool   alertsNotify     = false;       // Send push notification on alerts?
input int    lookback         = 256;         // Maximum lookback period

double crossUp[],crossDn[],cross[];

#include <IncOnRingBuffer\CATROnRingBuffer.mqh>
#include <IncOnRingBuffer\CADXOnRingBuffer.mqh>

CATROnRingBuffer atr;
CADXOnRingBuffer adx;
int _start = 0;
  
//
// Initialize custom chart indicator for data processing 
// according to settings of the custom chart indicator already on chart
//

#include <AZ-INVEST/CustomBarConfig.mqh>

//
//
//
  
int OnInit()
  {
//--- indicator buffers mapping
    SetIndexBuffer(0,crossUp,INDICATOR_DATA);  PlotIndexSetInteger(0,PLOT_ARROW,233);
    SetIndexBuffer(1,crossDn,INDICATOR_DATA);  PlotIndexSetInteger(1,PLOT_ARROW,234);
    SetIndexBuffer(2,cross);
    
   if(!adx.Init(AdxPeriod,MODE_EMA,lookback)) return(INIT_FAILED);
   if(!atr.Init(15,MODE_SMA,lookback)) return(INIT_FAILED);

   customChartIndicator.SetGetTimeFlag();
   
   IndicatorSetString(INDICATOR_SHORTNAME,"ADX cross "+(string)AdxPeriod+")");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
}

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
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
   
   atr.MainOnArray(rates_total,_prev_calculated,customChartIndicator.High,customChartIndicator.Low,customChartIndicator.Close);
   adx.MainOnArray(rates_total,_prev_calculated,customChartIndicator.High,customChartIndicator.Low,customChartIndicator.Close);
   
   ArraySetAsSeries(customChartIndicator.Low, false);
   ArraySetAsSeries(customChartIndicator.High, false);
     
   if(_prev_calculated==0)
   {
      _start = rates_total-adx.Size()+1;
   }
   else 
      _start = MathMax(_prev_calculated-1,1);         
     
   for(int i=_start;i<rates_total;i++)
   {
      int ix = rates_total-1-i;
      
      cross[i] = (ix>0) ? (adx.pdi[ix]>adx.ndi[ix]) ? 1 : (adx.pdi[ix]<adx.ndi[ix]) ? 2 : cross[i-1] : 0;  
      crossUp[i] = EMPTY_VALUE;
      crossDn[i] = EMPTY_VALUE;

      if (i>0 && cross[i]!=cross[i-1])
      {
         if (cross[i] == 1) crossUp[i] = customChartIndicator.Low[i]-atr[ix];
         if (cross[i] == 2) crossDn[i] = customChartIndicator.High[i]+atr[ix];
      }
   }

   manageAlerts(customChartIndicator.Time,cross,rates_total);
   return (rates_total);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void manageAlerts(const datetime& _time[], double& _trend[], int bars)
{
   if (alertsOn)
   {
      int whichBar = bars-1; if (!alertsOnCurrent) whichBar = bars-2; datetime time1 = _time[whichBar];
      if (_trend[whichBar] != _trend[whichBar-1])
      {          
         if (_trend[whichBar] == 1) doAlert(time1," plus DI crossing minus DI up");
         if (_trend[whichBar] == 2) doAlert(time1," plus DI crossing minus DI down");
      }         
   }
}   

//
//
//
//
//

void doAlert(datetime forTime, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   
   if (previousAlert != doWhat || previousTime != forTime) 
   {
      previousAlert  = doWhat;
      previousTime   = forTime;

      //
      //
      //
      //
      //

      string message = TimeToString(TimeLocal(),TIME_SECONDS)+" "+_Symbol+" Adx "+doWhat;
         if (alertsMessage) Alert(message);
         if (alertsEmail)   SendMail(_Symbol+"Adx",message);
         if (alertsNotify)  SendNotification(message);
         if (alertsSound)   PlaySound("alert2.wav");
   }
}


