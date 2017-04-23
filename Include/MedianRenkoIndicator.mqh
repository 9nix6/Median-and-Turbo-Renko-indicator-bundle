//+------------------------------------------------------------------+
//|                                         MedainRenkoIndicator.mq5 |
//|                                        Copyright 2017, AZ-iNVEST |
//|                                          http://www.az-invest.eu |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2017, AZ-iNVEST"
#property link      "http://www.az-invest.eu"
#property version   "1.11"
#include <MedianRenko.mqh>

class MedianRenkoIndicator
{

   private: 
   
      MedianRenko * medianRenko;
      int rates_total;
      int prev_calculated;
      bool useAppliedPrice;
      ENUM_APPLIED_PRICE applied_price;
      
   public:
   
      double Open[];
      double Low[];
      double High[];
      double Close[];
      double Price[];
   
      MedianRenkoIndicator();
      ~MedianRenkoIndicator();
      
      void SetUseAppliedPriceFlag(ENUM_APPLIED_PRICE _applied_price) { this.useAppliedPrice = true; this.applied_price = _applied_price; };
      
      bool OnCalculate(const int rates_total,const int prev_calculated, const datetime &Time[]);
      int GetPrevCalculated() { return prev_calculated; };     
      
   private:
   
      bool CheckStatus();
      bool NeedsReload();
      int  GetOLHC(int start, int count);
      void OLHCShiftRight();
      void OLHCResize();
      
      bool Canvas_IsNewBar(const datetime &_Time[]);
      bool Canvas_IsRatesTotalChanged(int ratesTotalNow);      
      
      ENUM_TIMEFRAMES TFMigrate(int tf);
      datetime iTime(string symbol,int tf,int index);

};

MedianRenkoIndicator::MedianRenkoIndicator(void)
{
   medianRenko = new MedianRenko();
   if(medianRenko != NULL)
      medianRenko.Init();
      
   useAppliedPrice = false;
}

MedianRenkoIndicator::~MedianRenkoIndicator(void)
{
   if(medianRenko != NULL)
   {
      medianRenko.Deinit();
      delete medianRenko;
   }
}

bool MedianRenkoIndicator::CheckStatus(void)
{
   int handle = medianRenko.GetHandle();
   
   if(handle == INVALID_HANDLE)
      return false;
   
   return true;
}

bool MedianRenkoIndicator::NeedsReload(void)
{
   if(medianRenko.Reload())
   {
     Print("Chart settings changed - reloading indicator with new settings");
     return true;
   }
   
   return false;
}

bool MedianRenkoIndicator::OnCalculate(const int _rates_total,const int _prev_calculated, const datetime &Time[])
{
   static bool firstRun = true;
   
   if(firstRun)
   {
      Canvas_IsRatesTotalChanged(_rates_total);   
      firstRun = false;
   }

   if(!CheckStatus())
      return false;
            
   ArraySetAsSeries(this.Open,false);
   ArraySetAsSeries(this.High,false);
   ArraySetAsSeries(this.Low,false);
   ArraySetAsSeries(this.Close,false);   
   ArraySetAsSeries(this.Price,false);   

   if(Canvas_IsRatesTotalChanged(_rates_total))
   {
      OLHCResize();
      
      this.prev_calculated = prev_calculated; 
      Canvas_IsNewBar(Time);
      return true;   
   }
   else if(Canvas_IsNewBar(Time))
   {
      //Print("Got Canvas_IsNewBar");
      //GetOLHC(0,0);
      if(ArraySize(this.Open) == 0)
      {
         GetOLHC(0,_rates_total);
         this.prev_calculated = 0;
         //Print("canvas new bar ZERO elements -> getting new : ArraySize of Open  = "+ArraySize(this.Open));
         return false;      
      
      }

      OLHCShiftRight();
      this.prev_calculated = prev_calculated; 
      return true;
   }
   
   if(NeedsReload() || medianRenko.IsNewBar())
   {
      GetOLHC(0,_rates_total);
      this.prev_calculated = 0;
      return false;
   } 

   //
   // Recalculate lst bar
   //
   
   GetOLHC(0,0);
   this.prev_calculated = prev_calculated;

   return true;
}

int MedianRenkoIndicator::GetOLHC(int start, int count)
{
   if((start == 0) && (count == 0))
   {
     MqlRates tempRates[1];
     int last = ArraySize(Open)-1;
     
     if(last < 0)
      return 0;
     
     medianRenko.GetMqlRates(tempRates,0,1);
     this.Open[last] = tempRates[0].open;
     this.Low[last] = tempRates[0].low;
     this.High[last] = tempRates[0].high;
     this.Close[last] = tempRates[0].close;    
     if(useAppliedPrice)
     {
        this.Price[last] = medianRenko.CalcAppliedPrice(tempRates[0],this.applied_price);
     }
     
     return 1;
   }
   else
   {
      if(useAppliedPrice)
         return medianRenko.GetOLHCAndApplPriceForIndicatorCalc(this.Open,this.Low,this.High,this.Close,this.Price,this.applied_price,0,count);   
      else
         return medianRenko.GetOLHCForIndicatorCalc(this.Open,this.Low,this.High,this.Close,0,count);
   
   }
}


void MedianRenkoIndicator::OLHCShiftRight()
{
   int count = ArraySize(this.Open);

   if(count <= 0)
      return;
   
   count--;
   
   for(int i=count; i>0; i--)
   {
      this.Open[i] = this.Open[i-1];
      this.High[i] = this.High[i-1];
      this.Low[i] = this.Low[i-1];
      this.Close[i] = this.Close[i-1];
      this.Price[i] = this.Price[i-1];
   }
   
   this.Open[0] = 0.0;
   this.High[0] = 0.0;
   this.Low[0] = 0.0;
   this.Close[0] = 0.0;
   this.Price[0] = 0.0;
}

void MedianRenkoIndicator::OLHCResize()
{
   int count = ArraySize(this.Open);
   
   if(count <= 0)
      return;
   
   ArrayResize(this.Open,count+1);
   ArrayResize(this.Low,count+1);
   ArrayResize(this.High,count+1);
   ArrayResize(this.Close,count+1);
   ArrayResize(this.Price,count+1);

   OLHCShiftRight();
}

bool MedianRenkoIndicator::Canvas_IsNewBar(const datetime &_Time[])
{
   ArraySetAsSeries(_Time,true);
   datetime now = _Time[0]; 
   ArraySetAsSeries(_Time,false);    
   
   static datetime prevTime = 0;
   
   if(prevTime != now)
   {
      prevTime = now;
      return true;
   }
   
   return false;
}

bool MedianRenkoIndicator::Canvas_IsRatesTotalChanged(int ratesTotalNow)
{
   static int prevRatesTotal = 0;
   
   if(prevRatesTotal == 0)
      prevRatesTotal = ratesTotalNow;
         
   if(prevRatesTotal != ratesTotalNow)
   {
      prevRatesTotal = ratesTotalNow;
      return true;
   }
   
   return false;
}


ENUM_TIMEFRAMES MedianRenkoIndicator::TFMigrate(int tf)
  {
   switch(tf)
     {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
      
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);      
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);      
      default: return(PERIOD_CURRENT);
     }
  }

datetime MedianRenkoIndicator::iTime(string symbol,int tf,int index)
{
   if(index < 0) return(-1);
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   datetime Arr[];
   if(CopyTime(symbol, timeframe, index, 1, Arr)>0)
        return(Arr[0]);
   else return(-1);
}


