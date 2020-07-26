#property copyright "Copyright 2018-2020, Level Up Software"
#property link      "http://www.az-invest.eu"

#ifdef DEVELOPER_VERSION
   #define RENKO_INDICATOR_NAME "MedianRenko\\MedianRenkoOverlay308" 
#else
   #ifdef P_RENKO_BR_PRO
      #define RENKO_INDICATOR_NAME "P-RENKO BR Ultimate" 
   #else
      #define RENKO_INDICATOR_NAME "Market\\Median and Turbo renko indicator bundle" 
   #endif
#endif

//
//  Data buffer offset values
//
#define RENKO_OPEN               00
#define RENKO_HIGH               01
#define RENKO_LOW                02
#define RENKO_CLOSE              03 
#define RENKO_BAR_COLOR          04
#define RENKO_SESSION_RECT_H     05
#define RENKO_SESSION_RECT_L     06
#define RENKO_MA1                07
#define RENKO_MA2                08
#define RENKO_MA3                09
#define RENKO_MA4                10
#define RENKO_CHANNEL_HIGH       11
#define RENKO_CHANNEL_MID        12
#define RENKO_CHANNEL_LOW        13
#define RENKO_BAR_OPEN_TIME      14
#define RENKO_TICK_VOLUME        15
#define RENKO_REAL_VOLUME        16
#define RENKO_BUY_VOLUME         17
#define RENKO_SELL_VOLUME        18
#define RENKO_BUYSELL_VOLUME     19
#define RENKO_RUNTIME_ID         20

#include <az-invest/sdk/RenkoCustomChartSettings.mqh>

class MedianRenko
{
   private:
   
      CRenkoCustomChartSettigns * medianRenkoSettings;

      int medianRenkoHandle; //  Median renko indicator handle
      string medianRenkoSymbol;
      bool usedByIndicatorOnRenkoChart;
   
      datetime prevBarTime;    

   public:
      
      MedianRenko();   
      MedianRenko(bool isUsedByIndicatorOnRenkoChart);   
      MedianRenko(string symbol);
      ~MedianRenko(void);
      
      int Init();
      void Deinit();
      bool Reload();
      void ReleaseHandle();
      
      int  GetHandle(void) { return medianRenkoHandle; };
      double GetRuntimeId();

      bool IsNewBar();
      
      bool GetMqlRates(MqlRates &ratesInfoArray[], int start, int count);
      bool GetBuySellVolumeBreakdown(double &buy[], double &sell[], double &buySell[], int start, int count);      
      bool GetMA(int MaBufferId, double &MA[], int start, int count);
      bool GetChannel(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);

      // The following 6 functions are deprecated, please use GetMA & GetChannelData functions instead 
      bool GetMA1(double &MA[], int start, int count);
      bool GetMA2(double &MA[], int start, int count);
      bool GetMA3(double &MA[], int start, int count);
      bool GetDonchian(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
      bool GetBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
      bool GetSuperTrend(double &SuperTrendHighArray[], double &SuperTrendArray[], double &SuperTrendLowArray[], int start, int count); 
      //

   private:

      int GetIndicatorHandle(void);
      bool GetChannelData(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);   
};

MedianRenko::MedianRenko(void)
{
   #ifdef IS_DEBUG
      Print(__FUNCTION__);
   #endif

   medianRenkoSettings = new CRenkoCustomChartSettigns();
      
   medianRenkoHandle = INVALID_HANDLE;
   medianRenkoSymbol = _Symbol;
   usedByIndicatorOnRenkoChart = false;
   prevBarTime = 0;
}

MedianRenko::MedianRenko(bool isUsedByIndicatorOnRenkoChart)
{
   #ifdef IS_DEBUG
      Print(__FUNCTION__);
   #endif

   medianRenkoSettings = new CRenkoCustomChartSettigns();

   medianRenkoHandle = INVALID_HANDLE;
   medianRenkoSymbol = _Symbol;
   usedByIndicatorOnRenkoChart = isUsedByIndicatorOnRenkoChart;
   prevBarTime = 0;
}

MedianRenko::MedianRenko(string symbol)
{
   #ifdef IS_DEBUG
      Print(__FUNCTION__);
   #endif

   medianRenkoSettings = new CRenkoCustomChartSettigns();

   medianRenkoHandle = INVALID_HANDLE;
   medianRenkoSymbol = symbol;
   usedByIndicatorOnRenkoChart = false;
   prevBarTime = 0;
}

MedianRenko::~MedianRenko(void)
{
   #ifdef IS_DEBUG
      Print(__FUNCTION__);
   #endif
   
   if(medianRenkoSettings != NULL)
   {
      delete medianRenkoSettings;
      medianRenkoSettings = NULL;  
   }
}

void MedianRenko::ReleaseHandle()
{ 
   if(medianRenkoHandle != INVALID_HANDLE)
   {
      IndicatorRelease(medianRenkoHandle); 
      medianRenkoSettings = NULL;
   }
}

//
//  Function for initializing the median renko indicator handle
//

int MedianRenko::Init()
{
   if(!MQLInfoInteger((int)MQL5_TESTING))
   {
      if(usedByIndicatorOnRenkoChart) 
      {
         //
         // Indicator on renko chart uses the values of the renko chart for calculations
         //      
         
         IndicatorRelease(medianRenkoHandle);
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
         // Indicator on renko chart uses the values of the renko chart for calculations
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
         #endif
      }
   }   

   RENKO_SETTINGS s = medianRenkoSettings.GetCustomChartSettings(); 
   CHART_INDICATOR_SETTINGS cis = medianRenkoSettings.GetChartIndicatorSettings(); 
   
  // this.Debug(s, cis);
      
   medianRenkoHandle = iCustom(this.medianRenkoSymbol, _Period, RENKO_INDICATOR_NAME, 
                                       s.barSizeInTicks,
                                       s.predefinedSettings,
                                       s.pOpen,
                                       s.pReversalShadow,
                                       s.pReversal,
                                       s.showWicks,
                                       s.atrEnabled,
                                       //s.atrTimeFrame,
                                       s.atrPeriod,
                                       s.atrPercentage,
                                       s.applyOffsetToFirstBar,
                                       s.offsetValue,
                                       s.showNumberOfDays, s.resetOpenOnNewTradingDay,
                                       "",
                                       showPivots,
                                       pivotPointCalculationType,
                                       RColor,
                                       PColor,
                                       SColor,
                                       PDHColor,
                                       PDLColor,
                                       PDCColor,   
                                       AlertMeWhen,
                                       AlertNotificationType,
                                       cis.MA1on, 
                                       cis.MA1lineType,
                                       cis.MA1period,
                                       cis.MA1method,
                                       cis.MA1applyTo,
                                       cis.MA1shift,
                                       cis.MA1priceLabel,
                                       cis.MA2on, 
                                       cis.MA2lineType,
                                       cis.MA2period,
                                       cis.MA2method,
                                       cis.MA2applyTo,
                                       cis.MA2shift,
                                       cis.MA2priceLabel,
                                       cis.MA3on, 
                                       cis.MA3lineType,
                                       cis.MA3period,
                                       cis.MA3method,
                                       cis.MA3applyTo,
                                       cis.MA3shift,
                                       cis.MA3priceLabel,
                                       cis.MA4on, 
                                       cis.MA4lineType,
                                       cis.MA4period,
                                       cis.MA4method,
                                       cis.MA4applyTo,
                                       cis.MA4shift,
                                       cis.MA4priceLabel,
                                       cis.ShowChannel,
                                       cis.ChannelPeriod,
                                       cis.ChannelAtrPeriod,
                                       cis.ChannelAppliedPrice,
                                       cis.ChannelMultiplier,
                                       cis.ChannelBandsDeviations, 
                                       cis.ChannelPriceLabel,
                                       cis.ChannelMidPriceLabel,
                                       true); // used in EA
// TopBottomPaddingPercentage,
// showCurrentBarOpenTime,
// SoundFileBull,
// SoundFileBear,
// DisplayAsBarChart
// ShiftObj; all letft at defaults
      
    if(medianRenkoHandle == INVALID_HANDLE)
    {
      Print(RENKO_INDICATOR_NAME+" indicator init failed on error ",GetLastError());
    }
    else
    {
      Print(RENKO_INDICATOR_NAME+" indicator init OK");
    }
     
    return medianRenkoHandle;
}

//
// Function for reloading the Median Renko indicator if needed
//

bool MedianRenko::Reload()
{
   bool actionNeeded = false;
   int temp = GetIndicatorHandle(); // TODO: further optimization to be done here
   
   if(temp != medianRenkoHandle)
   {
      IndicatorRelease(medianRenkoHandle); 
      medianRenkoHandle = INVALID_HANDLE;

      actionNeeded = true;
   }
   
   if(medianRenkoSettings.Changed(GetRuntimeId()))
   {
      actionNeeded = true;      
   }
   
   if(actionNeeded)
   {
      if(medianRenkoHandle != INVALID_HANDLE)
      {
         IndicatorRelease(medianRenkoHandle); 
         medianRenkoHandle = INVALID_HANDLE;
      }

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
         Print(RENKO_INDICATOR_NAME+" indicator handle released");
      else 
         Print("Failed to release "+RENKO_INDICATOR_NAME+" indicator handle");
   }
}

//
// Function for detecting a new Renko bar
//

bool MedianRenko::IsNewBar()
{
   MqlRates currentBar[1];   
   GetMqlRates(currentBar,0,1);
   
   if(currentBar[0].time == 0)
   {
      return false;
   }
   
   if(prevBarTime < currentBar[0].time)
   {
      prevBarTime = currentBar[0].time;
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

   if(CopyBuffer(medianRenkoHandle,RENKO_BUY_VOLUME,start,count,b) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_SELL_VOLUME,start,count,s) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_BUYSELL_VOLUME,start,count,bs) == -1)
      return false;

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
// Get "count" values for MaBufferId buffer into "MA[]" array starting from "start" bar  
//

bool MedianRenko::GetMA(int MaBufferId, double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA, count) == -1)
      return false;

   if(ArrayResize(MA, count) == -1)
      return false;
   
   if(MaBufferId != RENKO_MA1 && MaBufferId != RENKO_MA2 && MaBufferId != RENKO_MA3 && MaBufferId != RENKO_MA4)
   {
      Print("Incorrect MA buffer id specified in "+__FUNCTION__);
      return false;
   }
   
   if(CopyBuffer(medianRenkoHandle, MaBufferId,start,count,tempMA) == -1)
   {
      return false;
   }
   
   for(int i=0; i<count; i++)
   {
      MA[count-1-i] = tempMA[i];
   }

   ArrayFree(tempMA);      
   return true;
}

//
// Get "count" MovingAverage1 values into "MA[]" array starting from "start" bar  
//

bool MedianRenko::GetMA1(double &MA[], int start, int count)
{
   Print(__FUNCTION__+" is deprecated, please use GetMA instead");
   
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
   Print(__FUNCTION__+" is deprecated, please use GetMA instead");
   
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
   Print(__FUNCTION__+" is deprecated, please use GetMA instead");
   
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
   Print(__FUNCTION__+" is deprecated, please use GetChannelData instead");
   return GetChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Get "count" Bollinger band values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool MedianRenko::GetBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   Print(__FUNCTION__+" is deprecated, please use GetChannelData instead");
   return GetChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Get "count" SuperTrend values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool MedianRenko::GetSuperTrend(double &SuperTrendHighArray[], double &SuperTrendArray[], double &SuperTrendLowArray[], int start, int count)
{
   Print(__FUNCTION__+" is deprecated, please use GetChannelData instead");
   return GetChannel(SuperTrendHighArray,SuperTrendArray,SuperTrendLowArray,start,count);
}

//
// Get Channel values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool MedianRenko::GetChannel(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   return GetChannelData(HighArray,MidArray,LowArray,start,count);
}

//
// Private function used by GetRenkoDonchian and GetRenkoBollingerBands functions to get data
//

bool MedianRenko::GetChannelData(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   double tempH[], tempM[], tempL[];

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
}

int MedianRenko::GetIndicatorHandle(void)
{
   int i = ChartIndicatorsTotal(0,0);
   int j=0;
   string iName;
   
   while(j < i)
   {
      iName = ChartIndicatorName(0,0,j);
      if(StringFind(iName, CUSTOM_CHART_NAME) != -1)
      {
         return ChartIndicatorGet(0,0,iName);   
      }   
      
      j++;
   }
   
   Print("Failed getting handle of "+CUSTOM_CHART_NAME);
   return INVALID_HANDLE;
}

double MedianRenko::GetRuntimeId()
{
   double runtimeId[1];
    
   if(CopyBuffer(medianRenkoHandle, RENKO_RUNTIME_ID, 0, 1, runtimeId) == -1)
      return -1;

   return runtimeId[0];   
}