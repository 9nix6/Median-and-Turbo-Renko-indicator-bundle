//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   3
#property indicator_label1  "Gann zone"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrGainsboro,clrGainsboro
#property indicator_label2  "Gann middle"
#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_DOT
#property indicator_color2  clrGray
#property indicator_label3  "Gann high/low"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrDimGray,clrLimeGreen,clrDarkOrange
#property indicator_width3  2

//
//
#include <AZ-INVEST/CustomBarConfig.mqh>
//
//

enum enMaTypes
{
   ma_sma,    // Simple moving average
   ma_ema,    // Exponential moving average
   ma_smma,   // Smoothed MA
   ma_lwma    // Linear weighted MA
};
enum enFilterWhat
{
   flt_prc,  // Filter the prices
   flt_val,  // Filter the averages value
   flt_all   // Filter all
};
      ENUM_TIMEFRAMES TimeFrame   = PERIOD_CURRENT; // Time frame
input int             AvgPeriod       = 10;         // Average period
input enMaTypes       AvgType         = ma_sma;     // Average method
input double          Filter          = 0;          // Filter to use (<=0 for no filter)
input enFilterWhat    FilterOn        = flt_prc;    // Filter :
input bool            alertsOn        = false;      // Turn alerts on?
input bool            alertsOnCurrent = true;       // Alert on current bar?
input bool            alertsMessage   = true;       // Display messageas on alerts?
input bool            alertsSound     = false;      // Play sound on alerts?
input bool            alertsEmail     = false;      // Send email on alerts?
input bool            alertsNotify    = false;      // Send push notification on alerts?
input bool            Interpolate     = true;       // Interpolate mtf data ?

double sup[],supc[],mid[],fup[],fdn[],_count[];
ENUM_TIMEFRAMES timeFrame;
string indName;

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,fup,INDICATOR_DATA);
   SetIndexBuffer(1,fdn,INDICATOR_DATA);
   SetIndexBuffer(2,mid,INDICATOR_DATA);
   SetIndexBuffer(3,sup,INDICATOR_DATA);
   SetIndexBuffer(4,supc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,_count,INDICATOR_CALCULATIONS); 
      
      //
      //
      //
      //
      //
      
   customChartIndicator.SetGetTimeFlag();
         
//      timeFrame = MathMax(_Period,TimeFrame);
      indName   = getIndicatorName();
   IndicatorSetString(INDICATOR_SHORTNAME,periodToString(timeFrame)+" Gann high/low activator("+string(AvgPeriod)+")");
   return(0);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{                
   if (Bars(_Symbol,_Period)<rates_total) return(-1);

   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,time,close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(close))
      return(0);

   int _prev_calculated = customChartIndicator.GetPrevCalculated();
         
           
   double pfilter = Filter; if (FilterOn==flt_val) pfilter=0;
   double vfilter = Filter; if (FilterOn==flt_prc) vfilter=0;

   for (int i=(int)MathMax(_prev_calculated-1,1); i<rates_total && !IsStopped(); i++)
   {
      fup[i] = iFilter(iCustomMa(AvgType,iFilter(customChartIndicator.High[i-1],pfilter,AvgPeriod,i,rates_total,0),AvgPeriod,i,rates_total,0),vfilter,AvgPeriod,i,rates_total,1);
      fdn[i] = iFilter(iCustomMa(AvgType,iFilter(customChartIndicator.Low[i-1] ,pfilter,AvgPeriod,i,rates_total,2),AvgPeriod,i,rates_total,1),vfilter,AvgPeriod,i,rates_total,3);
      mid[i] = (fup[i]+fdn[i])/2.0;
         double pclose = iFilter(customChartIndicator.Close[i],pfilter,AvgPeriod,i,rates_total,4);
               supc[i] = (pclose>fup[i]) ? 1 : (pclose<fdn[i]) ? 2 : supc[i-1];
               sup[i]  = (supc[i]==1) ? fdn[i] : (supc[i]==2) ? fup[i] : pclose;
   }
   manageAlerts(customChartIndicator.Time,supc,rates_total);
   _count[rates_total-1] = MathMax(rates_total-_prev_calculated+1,1);

   return(rates_total);
}




//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

#define _filterInstances 5
double workFil[][_filterInstances*3];

#define _fchange 0
#define _fachang 1
#define _fvalue  2

double iFilter(double value, double filter, int period, int i, int bars, int instanceNo=0)
{
   if (filter<=0 || period<=0) return(value);
   if (ArrayRange(workFil,0)!= bars) ArrayResize(workFil,bars); instanceNo*=3;
   
   //
   //
   //
   //
   //
   
   workFil[i][instanceNo+_fvalue] = value;
   if (i>0)
   {
      workFil[i][instanceNo+_fchange] = MathAbs(workFil[i][instanceNo+_fvalue]-workFil[i-1][instanceNo+_fvalue]);
      workFil[i][instanceNo+_fachang] = workFil[i][instanceNo+_fchange];

      double fdev=0, fdif=0;
      for (int k=1; k<period && (i-k)>=0; k++) workFil[i][instanceNo+_fachang] += workFil[i-k][instanceNo+_fchange]; workFil[i][instanceNo+_fachang] /= (double)period;
      for (int k=0; k<period && (i-k)>=0; k++) fdev += MathPow(workFil[i-k][instanceNo+_fchange]-workFil[i-k][instanceNo+_fachang],2); fdev = MathSqrt(fdev/(double)period); fdif = filter*fdev;
      if (MathAbs(workFil[i][instanceNo+_fvalue]-workFil[i-1][instanceNo+_fvalue])<fdif) 
                  workFil[i][instanceNo+_fvalue]=workFil[i-1][instanceNo+_fvalue];
   }
   return(workFil[i][instanceNo+_fvalue]);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void manageAlerts(const datetime& time[], double& trend[], int bars)
{
   if (!alertsOn) return;
      int whichBar = bars-1; if (!alertsOnCurrent) whichBar = bars-2; datetime time1 = time[whichBar];
      if (trend[whichBar] != trend[whichBar-1])
      {
         if (trend[whichBar] == 1) doAlert(time1,"up");
         if (trend[whichBar] == 2) doAlert(time1,"down");
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
   string message;
   
   if (previousAlert != doWhat || previousTime != forTime) 
   {
      previousAlert  = doWhat;
      previousTime   = forTime;

      //
      //
      //
      //
      //

      message = periodToString(_Period)+" "+_Symbol+" at "+TimeToString(TimeLocal(),TIME_SECONDS)+" Gann high/low activator state changed to "+doWhat;
         if (alertsMessage) Alert(message);
         if (alertsEmail)   SendMail(_Symbol+" Gann high/low activator",message);
         if (alertsNotify)  SendNotification(message);
         if (alertsSound)   PlaySound("alert2.wav");
   }
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

#define _maInstances 2
#define _maWorkBufferx1 1*_maInstances
#define _maWorkBufferx2 2*_maInstances

double iCustomMa(int mode, double price, double length, int r, int bars, int instanceNo=0)
{
   switch (mode)
   {
      case ma_sma   : return(iSma(price,(int)length,r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)length,r,bars,instanceNo));
      default       : return(price);
   }
}

//
//
//
//
//

double workSma[][_maWorkBufferx2];
double iSma(double price, int period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workSma,0)!= _bars) ArrayResize(workSma,_bars); instanceNo *= 2; int k;

   //
   //
   //
   //
   //
      
   workSma[r][instanceNo+0] = price;
   workSma[r][instanceNo+1] = price; for(k=1; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo+0];  
   workSma[r][instanceNo+1] /= 1.0*k;
   return(workSma[r][instanceNo+1]);
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workEma,0)!= _bars) ArrayResize(workEma,_bars);

   //
   //
   //
   //
   //
      
   workEma[r][instanceNo] = price;
   double alpha = 2.0 / (1.0+period);
   if (r>0)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workSmma,0)!= _bars) ArrayResize(workSmma,_bars);

   //
   //
   //
   //
   //

   if (r<period)
         workSmma[r][instanceNo] = price;
   else  workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workLwma,0)!= _bars) ArrayResize(workLwma,_bars);
   
   //
   //
   //
   //
   //
   
   workLwma[r][instanceNo] = price;
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

string getIndicatorName()
{
   string progPath = MQL5InfoString(MQL5_PROGRAM_PATH); int start=-1;
   while (true)
   {
      int foundAt = StringFind(progPath,"\\",start+1);
      if (foundAt>=0) 
               start = foundAt;
      else  break;     
   }
   
   string indicatorName = StringSubstr(progPath,start+1);
          indicatorName = StringSubstr(indicatorName,0,StringLen(indicatorName)-4);
   return(indicatorName);
}

//
//
//
//
//

int    _tfsPer[]={PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
string _tfsStr[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes","15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours","12 hours","daily","weekly","monthly"};
string periodToString(int period)
{
   if (period==PERIOD_CURRENT) 
       period = _Period;   
         int i; for(i=0;i<ArraySize(_tfsPer);i++) if(period==_tfsPer[i]) break;
   return(_tfsStr[i]);   
}