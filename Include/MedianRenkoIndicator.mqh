//+------------------------------------------------------------------+
//|                                         MedainRenkoIndicator.mq5 |
//|                                        Copyright 2017, AZ-iNVEST |
//|                                          http://www.az-invest.eu |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2017, AZ-iNVEST"
#property link      "http://www.az-invest.eu"
#property version   "1.00"
#include <MedianRenko.mqh>

class MedianRenkoIndicator
{

   private: 
   
      MedianRenko * medianRenko;
      int rates_total;
      int prev_calculated;
      
   public:
   
      double Open[];
      double Low[];
      double High[];
      double Close[];
   
      MedianRenkoIndicator();
      ~MedianRenkoIndicator();
      
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

};

MedianRenkoIndicator::MedianRenkoIndicator(void)
{
   medianRenko = new MedianRenko();
   if(medianRenko != NULL)
      medianRenko.Init();
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

   if(Canvas_IsRatesTotalChanged(_rates_total))
   {
      OLHCResize();
      
      this.prev_calculated = prev_calculated; 
      Canvas_IsNewBar(Time);
      return true;   
   }
   /*
   else if(Canvas_IsNewBar(Time))
   {
      //GetOLHC(0,0);
      if(ArraySize(this.Open) == 0)
      {
         GetOLHC(0,_rates_total);
         this.prev_calculated = 0;
         Print("canvas new bar ZERO elements -> getting new : ArraySize of Open  = "+ArraySize(this.Open));
         return false;      
      
      }

      OLHCShiftRight();
      this.prev_calculated = prev_calculated; 
      return true;
   }
   */
   
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
     
     return 1;
   }
   else
   {
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
   }
   
   this.Open[0] = 0.0;
   this.High[0] = 0.0;
   this.Low[0] = 0.0;
   this.Close[0] = 0.0;
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

