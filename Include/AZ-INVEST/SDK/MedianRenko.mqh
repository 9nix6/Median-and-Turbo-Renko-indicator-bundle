//+------------------------------------------------------------------+
//|                                       MedianRenko.mqh ver:2.01.1 |
//|                                        Copyright 2017, AZ-iNVEST |
//|                                          http://www.az-invest.eu |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, AZ-iNVEST"
#property link      "http://www.az-invest.eu"

#ifdef P_RENKO_BR
   #ifdef P_RENKO_BR_PRO
      #define RENKO_INDICATOR_NAME "MedianRenko\\P-RENKO BR Pro" 
   #else
      #define RENKO_INDICATOR_NAME "MedianRenko\\P-RENKO BR Lite 2.03" 
   //   #define RENKO_INDICATOR_NAME "P-RENKO BR Lite" 
   #endif
#else
   //#define RENKO_INDICATOR_NAME "MedianRenko\\MedianRenkoOverlay204" 
   #define RENKO_INDICATOR_NAME "Market\\Median and Turbo renko indicator bundle" 
#endif

//
//  Data buffer offset values
//
#ifdef P_RENKO_BR
   #define RENKO_OPEN            00
   #define RENKO_HIGH            01
   #define RENKO_LOW             02
   #define RENKO_CLOSE           03 
   #define RENKO_BAR_COLOR       04
   #define RENKO_MA1             05
   #define RENKO_MA2             06
   #define RENKO_MA3             07

   #ifdef P_RENKO_BR_PRO
      #define RENKO_CHANNEL_HIGH    08
      #define RENKO_CHANNEL_MID     09
      #define RENKO_CHANNEL_LOW     10
      #define RENKO_BAR_OPEN_TIME   11
      #define RENKO_TICK_VOLUME     12
      #define RENKO_REAL_VOLUME     13
      #define RENKO_BUY_VOLUME      14
      #define RENKO_SELL_VOLUME     15
      #define RENKO_BUYSELL_VOLUME  16
   #else
      #define RENKO_BAR_OPEN_TIME   08
      #define RENKO_TICK_VOLUME     09
      #define RENKO_REAL_VOLUME     10
   #endif
#else
   #define RENKO_OPEN            00
   #define RENKO_HIGH            01
   #define RENKO_LOW             02
   #define RENKO_CLOSE           03 
   #define RENKO_BAR_COLOR       04
   #define RENKO_MA1             05
   #define RENKO_MA2             06
   #define RENKO_MA3             07
   #define RENKO_CHANNEL_HIGH    08
   #define RENKO_CHANNEL_MID     09
   #define RENKO_CHANNEL_LOW     10
   #define RENKO_BAR_OPEN_TIME   11
   #define RENKO_TICK_VOLUME     12
   #define RENKO_REAL_VOLUME     13
   #define RENKO_BUY_VOLUME      14
   #define RENKO_SELL_VOLUME     15
   #define RENKO_BUYSELL_VOLUME  16
#endif

#include <AZ-INVEST/SDK/RenkoSettings.mqh>

class MedianRenko
{
   private:
   
      RenkoSettings * medianRenkoSettings;

      //
      //  Median renko indicator handle
      //
      
      int medianRenkoHandle;
      string medianRenkoSymbol;
      bool usedByIndicatorOnRenkoChart;
   
   public:
      
      MedianRenko();   
      MedianRenko(bool isUsedByIndicatorOnRenkoChart);   
      MedianRenko(string symbol);
      ~MedianRenko(void);
      
      int Init();
      void Deinit();
      bool Reload();
      
      int  GetHandle(void) { return medianRenkoHandle; };
      bool GetMqlRates(MqlRates &ratesInfoArray[], int start, int count);
      bool GetBuySellVolumeBreakdown(double &buy[], double &sell[], double &buySell[], int start, int count);
      bool GetMA1(double &MA[], int start, int count);
      bool GetMA2(double &MA[], int start, int count);
      bool GetMA3(double &MA[], int start, int count);
      bool GetDonchian(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
      bool GetBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
      bool GetSuperTrend(double &SuperTrendHighArray[], double &SuperTrendArray[], double &SuperTrendLowArray[], int start, int count); 
      
      bool IsNewBar();
      
   private:

      bool GetChannel(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
      void Debug(RENKO_SETTINGS &s, CHART_INDICATOR_SETTINGS &cis);
      int GetIndicatorHandle();
   
};

MedianRenko::MedianRenko(void)
{
#define CONSTRUCTOR1
   medianRenkoSettings = new RenkoSettings();
   medianRenkoHandle = INVALID_HANDLE;
   medianRenkoSymbol = _Symbol;
   usedByIndicatorOnRenkoChart = false;
}

MedianRenko::MedianRenko(bool isUsedByIndicatorOnRenkoChart)
{
   medianRenkoSettings = new RenkoSettings();
   medianRenkoHandle = INVALID_HANDLE;
   medianRenkoSymbol = _Symbol;
   usedByIndicatorOnRenkoChart = isUsedByIndicatorOnRenkoChart;
}

MedianRenko::MedianRenko(string symbol)
{
#define CONSTRUCTOR2
   medianRenkoSettings = new RenkoSettings();
   medianRenkoHandle = INVALID_HANDLE;
   medianRenkoSymbol = symbol;
   usedByIndicatorOnRenkoChart = false;
}

MedianRenko::~MedianRenko(void)
{
   if(medianRenkoSettings != NULL)
      delete medianRenkoSettings;
}

//
//  Function for initializing the median renko indicator handle
//

int MedianRenko::Init()
{
   if(!MQLInfoInteger((int)MQL5_TESTING)) // not testing
   {
      if(usedByIndicatorOnRenkoChart) 
      {
         //
         // Indicator on Renko chart uses the values of the Renko chart for calculations
         //      
         medianRenkoHandle = GetIndicatorHandle();
         return medianRenkoHandle;
      }
   
      if(!medianRenkoSettings.Load())
      {
         if(medianRenkoHandle != INVALID_HANDLE)
         {
            // could not read new settings - keep old settings
            
            return medianRenkoHandle;
         }
         else
         {
            Print("Failed to load indicator settings - Renko indicator not on chart");
            return INVALID_HANDLE;
         }
      }   
     
      if(medianRenkoHandle != INVALID_HANDLE)
         Deinit();

   }
   else
   {
      if(usedByIndicatorOnRenkoChart) 
      {
         //
         // Indicator on Renko chart uses the values of the Renko chart for calculations
         //      
         medianRenkoHandle = GetIndicatorHandle();
         return medianRenkoHandle;
      }
      else
      {
         #ifdef SHOW_INDICATOR_INPUTS
            //
            //  Load settings from EA inputs
            //
            medianRenkoSettings.Load();
            
         #else
            //
            //  Save indicator inputs for use by EA attached to same chart.
            //
            medianRenkoSettings.Save();
         #endif      
      }
   }   

   RENKO_SETTINGS s = medianRenkoSettings.GetRenkoSettings();
   CHART_INDICATOR_SETTINGS cis = medianRenkoSettings.GetChartIndicatorSettings(); 
   
  // this.Debug(s, cis);
      
#ifdef P_RENKO_BR
   #ifdef P_RENKO_BR_PRO
   medianRenkoHandle = iCustom(this.medianRenkoSymbol,_Period,RENKO_INDICATOR_NAME, 
                                       s.barSizeInTicks,
                                       //s.retracementFactor,
                                       //s.symetricalReversals,
                                       s.showWicks,
                                       //s.atrEnabled,
                                       //s.atrTimeFrame,
                                       //s.atrPeriod,
                                       //s.atrPercentage,
                                       s.showNumberOfDays,
                                       //s.applyOffsetToFirstBar,
                                       //s.offsetValue,
                                       s.resetOpenOnNewTradingDay,
                                       TopBottomPaddingPercentage,
                                       showPivots,
                                       pivotPointCalculationType,
                                       RColor,
                                       PColor,
                                       SColor,
                                       PDHColor,
                                       PDLColor,
                                       PDCColor,   
                                       showNextBarLevels,
                                       HighThresholdIndicatorColor,
                                       LowThresholdIndicatorColor,
                                       //showCurrentBarOpenTime,
                                       InfoTextColor,
                                       NewBarAlert,
                                       //OnlySignalReversalBars,
                                       //UseAlertWindow,
                                       //SendPushNotifications,
                                       SoundFileBull,
                                       SoundFileBear,
                                       cis.MA1on, 
                                       cis.MA1period,
                                       cis.MA1method,
                                       cis.MA1applyTo,
                                       cis.MA1shift,
                                       cis.MA2on,
                                       cis.MA2period,
                                       cis.MA2method,
                                       cis.MA2applyTo,
                                       cis.MA2shift,
                                       cis.MA3on,
                                       cis.MA3period,
                                       cis.MA3method,
                                       cis.MA3applyTo,
                                       cis.MA3shift,
                                       cis.ShowChannel,
                                       "",
                                       cis.DonchianPeriod,
                                       cis.BBapplyTo,
                                       cis.BollingerBandsPeriod,
                                       cis.BollingerBandsDeviations,
                                       cis.SuperTrendPeriod,
                                       cis.SuperTrendMultiplier,
                                       "",
                                       DisplayAsBarChart,
                                       DisplayAsBarChart,
                                       ShiftObj,
                                       UsedInEA);   
   #else
      medianRenkoHandle = iCustom(this.medianRenkoSymbol,_Period,RENKO_INDICATOR_NAME, 
                                       s.barSizeInTicks,
                                       s.showWicks,
                                       s.showNumberOfDays,
                                       s.resetOpenOnNewTradingDay,
                                       TopBottomPaddingPercentage,
                                       showPivots,
                                       pivotPointCalculationType,
                                       RColor,
                                       PColor,
                                       SColor,
                                       PDHColor,
                                       PDLColor,
                                       PDCColor,   
                                       showNextBarLevels,
                                       HighThresholdIndicatorColor,
                                       LowThresholdIndicatorColor,
                                       InfoTextColor,
                                       NewBarAlert,
                                       SoundFileBull,
                                       SoundFileBear,
                                       cis.MA1on, 
                                       cis.MA1period,
                                       cis.MA1method,
                                       cis.MA1applyTo,
                                       cis.MA1shift,
                                       cis.MA2on,
                                       cis.MA2period,
                                       cis.MA2method,
                                       cis.MA2applyTo,
                                       cis.MA2shift,
                                       cis.MA3on,
                                       cis.MA3period,
                                       cis.MA3method,
                                       cis.MA3applyTo,
                                       cis.MA3shift,
                                       ShiftObj,
                                       UsedInEA);                                       
   #endif
#else   
   medianRenkoHandle = iCustom(this.medianRenkoSymbol,_Period,RENKO_INDICATOR_NAME, 
                                       s.barSizeInTicks,
                                       s.retracementFactor,
                                       s.symetricalReversals,
                                       s.showWicks,
                                       s.atrEnabled,
                                       //s.atrTimeFrame,
                                       s.atrPeriod,
                                       s.atrPercentage,
                                       s.showNumberOfDays,
                                       s.applyOffsetToFirstBar,
                                       s.offsetValue,
                                       s.resetOpenOnNewTradingDay,
                                       TopBottomPaddingPercentage,
                                       showPivots,
                                       pivotPointCalculationType,
                                       RColor,
                                       PColor,
                                       SColor,
                                       PDHColor,
                                       PDLColor,
                                       PDCColor,   
                                       showNextBarLevels,
                                       HighThresholdIndicatorColor,
                                       LowThresholdIndicatorColor,
                                       showCurrentBarOpenTime,
                                       InfoTextColor,
                                       NewBarAlert,
                                       ReversalBarAlert,
                                       MaCrossAlert,
                                       UseAlertWindow,
                                       UseSound,    
                                       UsePushNotifications,
                                       SoundFileBull,
                                       SoundFileBear,
                                       cis.MA1on, 
                                       cis.MA1period,
                                       cis.MA1method,
                                       cis.MA1applyTo,
                                       cis.MA1shift,
                                       cis.MA2on,
                                       cis.MA2period,
                                       cis.MA2method,
                                       cis.MA2applyTo,
                                       cis.MA2shift,
                                       cis.MA3on,
                                       cis.MA3period,
                                       cis.MA3method,
                                       cis.MA3applyTo,
                                       cis.MA3shift,
                                       cis.ShowChannel,
                                       "",
                                       cis.DonchianPeriod,
                                       cis.BBapplyTo,
                                       cis.BollingerBandsPeriod,
                                       cis.BollingerBandsDeviations,
                                       cis.SuperTrendPeriod,
                                       cis.SuperTrendMultiplier,
                                       "",
                                       DisplayAsBarChart,
                                       ShiftObj,
                                       UsedInEA);
#endif                                       
      
    if(medianRenkoHandle == INVALID_HANDLE)
    {
#ifdef P_RENKO_BR
      Print("P-RENKO BR indicator init failed on error ",GetLastError());
#else
      Print("Median Renko indicator init failed on error ",GetLastError());
#endif
    }
    else
    {
#ifdef P_RENKO_BR
      Print("P_RENKO BR indicator init OK");
#else
      Print("Median Renko indicator init OK");
#endif
    }
     
    return medianRenkoHandle;
}

//
// Function for reloading the Median Renko indicator if needed
//

bool MedianRenko::Reload()
{
   if(medianRenkoSettings.Changed())
   {
      Deinit();
      if(Init() == INVALID_HANDLE)
         return false;
      
      return true;
   }
   
   return false;
}

//
// Function for releasing the Median Renko indicator hanlde - free resources
//

void MedianRenko::Deinit()
{
   if(medianRenkoHandle == INVALID_HANDLE)
      return;
   
   if(!usedByIndicatorOnRenkoChart)
   {
      if(IndicatorRelease(medianRenkoHandle))
#ifdef P_RENKO_BR
         Print("P-RENKO BR indicator handle released");
#else   
         Print("Median Renko indicator handle released");
#endif
      else 
#ifdef P_RENKO_BR
         Print("Failed to release P-RENKO BR indicator handle");
#else   
         Print("Failed to release Median Renko indicator handle");
#endif
   }

   medianRenkoHandle = INVALID_HANDLE;
}

//
// Function for detecting a new Renko bar
//

bool MedianRenko::IsNewBar()
{
   MqlRates currentRenko[1];
   static datetime prevRenkoTime;
   
   GetMqlRates(currentRenko,0,1);
   
   if(currentRenko[0].time == 0)
      return false;
   
   if(prevRenkoTime < currentRenko[0].time)
   {
      prevRenkoTime = currentRenko[0].time;
      return true;
   }

   return false;
}

//
// Get "count" Renko MqlRates into "ratesInfoArray[]" array starting from "start" bar  
// RENKO_BAR_COLOR value is stored in ratesInfoArray[].spread
//

bool MedianRenko::GetMqlRates(MqlRates &ratesInfoArray[], int start, int count)
{
   double o[],l[],h[],c[],barColor[],time[],tick_volume[],real_volume[];

   if(ArrayResize(o,count) == -1)
      return false;
   if(ArrayResize(l,count) == -1)
      return false;
   if(ArrayResize(h,count) == -1)
      return false;
   if(ArrayResize(c,count) == -1)
      return false;
   if(ArrayResize(barColor,count) == -1)
      return false;
   if(ArrayResize(time,count) == -1)
      return false;
   if(ArrayResize(tick_volume,count) == -1)
      return false;
   if(ArrayResize(real_volume,count) == -1)
      return false;

  
   if(CopyBuffer(medianRenkoHandle,RENKO_OPEN,start,count,o) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_LOW,start,count,l) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_HIGH,start,count,h) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_CLOSE,start,count,c) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_BAR_OPEN_TIME,start,count,time) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_BAR_COLOR,start,count,barColor) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_TICK_VOLUME,start,count,tick_volume) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_REAL_VOLUME,start,count,real_volume) == -1)
      return false;

   if(ArrayResize(ratesInfoArray,count) == -1)
      return false; 
   
   int tempOffset = count-1;
   for(int i=0; i<count; i++)
   {
      ratesInfoArray[tempOffset-i].open = o[i];
      ratesInfoArray[tempOffset-i].low = l[i];
      ratesInfoArray[tempOffset-i].high = h[i];
      ratesInfoArray[tempOffset-i].close = c[i];
      ratesInfoArray[tempOffset-i].time = (datetime)time[i];
      ratesInfoArray[tempOffset-i].tick_volume = (long)tick_volume[i];
      ratesInfoArray[tempOffset-i].real_volume = (long)real_volume[i];
      ratesInfoArray[tempOffset-i].spread = (int)barColor[i];
   }
   
   ArrayFree(o);
   ArrayFree(l);
   ArrayFree(h);
   ArrayFree(c);
   ArrayFree(barColor);
   ArrayFree(time);
   ArrayFree(tick_volume);   
   ArrayFree(real_volume);   
   
   return true;
}

bool MedianRenko::GetBuySellVolumeBreakdown(double &buy[], double &sell[], double &buySell[], int start, int count)
{
   double b[],s[],bs[];
   
   if(ArrayResize(b,count) == -1)
      return false;
   if(ArrayResize(s,count) == -1)
      return false;
   if(ArrayResize(bs,count) == -1)
      return false;

#ifdef P_RENKO_BR
   #ifdef P_RENKO_BR_PRO
   if(CopyBuffer(medianRenkoHandle,RENKO_BUY_VOLUME,start,count,b) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_SELL_VOLUME,start,count,s) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_BUYSELL_VOLUME,start,count,bs) == -1)
      return false;
   #endif
#else
   if(CopyBuffer(medianRenkoHandle,RENKO_BUY_VOLUME,start,count,b) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_SELL_VOLUME,start,count,s) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_BUYSELL_VOLUME,start,count,bs) == -1)
      return false;
#endif

   if(ArrayResize(buy,count) == -1)
      return false; 
   if(ArrayResize(sell,count) == -1)
      return false; 
   if(ArrayResize(buySell,count) == -1)
      return false; 

   int tempOffset = count-1;
   for(int i=0; i<count; i++)
   {
      buy[tempOffset-i] = b[i];
      sell[tempOffset-i] = s[i];
      buySell[tempOffset-i] = bs[i];
   }
   
   ArrayFree(b);
   ArrayFree(s);
   ArrayFree(bs);
   
   return true;


}

//
// Get "count" MovingAverage1 values into "MA[]" array starting from "start" bar  
//

bool MedianRenko::GetMA1(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(medianRenkoHandle,RENKO_MA1,start,count,tempMA) == -1)
      return false;

   for(int i=0; i<count; i++)
   {
      MA[count-1-i] = tempMA[i];
   }

   ArrayFree(tempMA);      
   return true;
}

//
// Get "count" MovingAverage2 values into "MA[]" starting from "start" bar  
//

bool MedianRenko::GetMA2(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(medianRenkoHandle,RENKO_MA2,start,count,tempMA) == -1)
      return false;
   
   for(int i=0; i<count; i++)
   {
      MA[count-1-i] = tempMA[i];
   }
   
   ArrayFree(tempMA);   
   return true;
}

//
// Get "count" MovingAverage3 values into "MA[]" starting from "start" bar  
//

bool MedianRenko::GetMA3(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(medianRenkoHandle,RENKO_MA3,start,count,tempMA) == -1)
      return false;
   
   for(int i=0; i<count; i++)
   {
      MA[count-1-i] = tempMA[i];
   }
   
   ArrayFree(tempMA);   
   return true;
}

//
// Get "count" Renko Donchian channel values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool MedianRenko::GetDonchian(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   return GetChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Get "count" Bollinger band values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool MedianRenko::GetBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   return GetChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Get "count" SuperTrend values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool MedianRenko::GetSuperTrend(double &SuperTrendHighArray[], double &SuperTrendArray[], double &SuperTrendLowArray[], int start, int count)
{
   return GetChannel(SuperTrendHighArray,SuperTrendArray,SuperTrendLowArray,start,count);
}


//
// Private function used by GetRenkoDonchian and GetRenkoBollingerBands functions to get data
//

bool MedianRenko::GetChannel(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   double tempH[], tempM[], tempL[];

#ifdef P_RENKO_BR
   return false;
#else
   if(ArrayResize(tempH,count) == -1)
      return false;
   if(ArrayResize(tempM,count) == -1)
      return false;
   if(ArrayResize(tempL,count) == -1)
      return false;

   if(ArrayResize(HighArray,count) == -1)
      return false;
   if(ArrayResize(MidArray,count) == -1)
      return false;
   if(ArrayResize(LowArray,count) == -1)
      return false;
   
   if(CopyBuffer(medianRenkoHandle,RENKO_CHANNEL_HIGH,start,count,tempH) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_CHANNEL_MID,start,count,tempM) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_CHANNEL_LOW,start,count,tempL) == -1)
      return false;
   
   int tempOffset = count-1;
   for(int i=0; i<count; i++)
   {
      HighArray[tempOffset-i] = tempH[i];
      MidArray[tempOffset-i] = tempM[i];
      LowArray[tempOffset-i] = tempL[i];
   }   
   
   ArrayFree(tempH);
   ArrayFree(tempM);
   ArrayFree(tempL);
   
   return true;
#endif
}

void MedianRenko::Debug(RENKO_SETTINGS &s, CHART_INDICATOR_SETTINGS &cis)
{
   int h = FileOpen("MedianRenkoDebug.txt",FILE_WRITE|FILE_ANSI);
   if(h == INVALID_HANDLE)
      return;

   FileWriteString(h,"barSizeInTicks = "+(string)s.barSizeInTicks+"\n");
   FileWriteString(h,"retracementFactor = "+(string)s.retracementFactor+"\n");
   FileWriteString(h,"symmetricalReversals = "+(string)s.symetricalReversals+"\n");
   FileWriteString(h,"showWicks = "+(string)s.showWicks+"\n");
   FileWriteString(h,"atrEnabled = "+(string)s.atrEnabled+"\n");
   FileWriteString(h,"atrPeriod = "+(string)s.atrPeriod+"\n");
   FileWriteString(h,"atrPercentage = "+(string)s.atrPercentage+"\n");
   FileWriteString(h,"showNumberOfDays = "+(string)s.showNumberOfDays+"\n");
   FileWriteString(h,"applyOffsetToFirstBar = "+(string)s.applyOffsetToFirstBar+"\n");
   FileWriteString(h,"offsetValue = "+(string)s.offsetValue+"\n");
   FileWriteString(h,"resetOpenOnNewTradingDay = "+(string)s.resetOpenOnNewTradingDay+"\n");
   /*                                  cis.MA1on, 
                                       cis.MA1period,
                                       cis.MA1method,
                                       cis.MA1applyTo,
                                       cis.MA1shift,
                                       cis.MA2on,
                                       cis.MA2period,
                                       cis.MA2method,
                                       cis.MA2applyTo,
                                       cis.MA2shift,
                                       cis.MA3on,
                                       cis.MA3period,
                                       cis.MA3method,
                                       cis.MA3applyTo,
                                       cis.MA3shift,
                                       cis.ShowChannel,
                                       cis.DonchianPeriod,
                                       cis.BBapplyTo,
                                       cis.BollingerBandsPeriod,
                                       cis.BollingerBandsDeviations,
                                       cis.SuperTrendPeriod,
                                       cis.SuperTrendMultiplier,
   */
   FileWriteString(h,"DisplayAsBarChart = "+(string)DisplayAsBarChart);
   FileWriteString(h,"UsedInEA = "+(string)UsedInEA);
   FileClose(h);
}

int MedianRenko::GetIndicatorHandle(void)
{
   int i = ChartIndicatorsTotal(0,0);
   int j=0;
   
   while(j < i)
   {
      string iName = ChartIndicatorName(0,0,j);
      if(StringFind(iName,CUSTOM_CHART_NAME) != -1)
      {
         Print("Using handle of "+iName);
         return ChartIndicatorGet(0,0,iName);   
      }   
      j++;
   }
   
   return INVALID_HANDLE;
}