//+------------------------------------------------------------------+
//|                                         MedianRenko.mqh ver:1.44 |
//|                                        Copyright 2017, AZ-iNVEST |
//|                                          http://www.az-invest.eu |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, AZ-iNVEST"
#property link      "http://www.az-invest.eu"

#define RENKO_INDICATOR_NAME "Market\\Median and Turbo renko indicator bundle" 

#define RENKO_MA1 0
#define RENKO_MA2 1
#define RENKO_CHANNEL_HIGH 2
#define RENKO_CHANNEL_MID 3
#define RENKO_CHANNEL_LOW 4
#define RENKO_OPEN 5
#define RENKO_HIGH 6
#define RENKO_LOW 7
#define RENKO_CLOSE 8
#define RENKO_TICK_VOLUME 9
#define RENKO_BAR_OPEN_TIME 10

enum BufferDataType
{
   Close = 0,
   Open = 1,
   High = 2,
   Low = 3,
   Median_Price = 4,
   Typical_Price = 5,
   Weighted_Close = 6,
};
 
enum MaMethodType
{
   Simple = 0,
   Exponential = 1,
   Smoothed = 2,
   LinearWeighted = 3,
};
 
enum ChannelType
{
   None = 0,
   Donchian_Channel,
   Bollinger_Bands,
//   VWAP,
};

//
// Indicator settings
//

input int MR_barSizeInTicks = 100; // Bars size (in ticks)
input double MR_retracementFactor = 1; // Retracement factor (0.01 to 1.00)
input bool   MR_symetricalReversals = true; // Symmetrical reversals
input bool   MR_showWicks = true; // Show wicks
input datetime MR_startFromDateTime = 0; // Start building chart from date/time
input bool  MR_resetOpenOnNewTradingDay = false; // Synchronize first bar's open on new day
      bool  MR_showNextBarLevels = false; // Show current bar's close projections -- not needed when calling indicator from EA
      color MR_HighThresholdIndicatorColor = clrNONE; // Bullish bar projection color -- not needed when calling indicator from EA
      color MR_LowThresholdIndicatorColor = clrNONE; // Bearish bar projection color -- not needed when calling indicator from EA
      bool  MR_showCurrentBarOpenTime = false; // Display current bar's open time -- not needed when calling indicator from EA
      color MR_InfoTextColor = clrNONE; // Current bar's open time info color -- not needed when calling indicator from EA
      bool      MR_UseSoundSignalOnNewBar = false; // Play sound on new bar -- not needed when calling indicator from EA
      bool      MR_OnlySignalReversalBars = false; // Only play sound on reversals -- not needed when calling indicator from EA
      bool      MR_UseAlertWindow = false; // Display Alert window with new bar info -- not needed when calling indicator from EA
      bool      MR_SendPushNotifications = false; // Send new bar info push notification to smartphone -- not needed when calling indicator from EA
      string    MR_SoundFileBull = ""; // Use sound file for bullish bar close -- not needed when calling indicator from EA
      string    MR_SoundFileBear = ""; // Use sound file for bearish bar close -- not needed when calling indicator from EA
input bool MR_MA1on = true; // Use first MA 
input int MR_MA1period = 3; // 1st MA period
input MaMethodType MR_MA1method = Exponential; // 1st MA metod
input BufferDataType MR_MA1applyTo = Close; //1st MA apply to
input bool MR_MA2on = true; // Use second MA 
input int MR_MA2period = 5; // 2nd MA period
input MaMethodType MR_MA2method = Exponential; // 2nd MA method
input BufferDataType MR_MA2applyTo = Close; // 2nd MA apply to
input ChannelType MR_ShowChannel = None;
input string MR_Channel_Settings = "--------------------------";
input int MR_DonchianPeriod = 20; // Donchan Channel period
input BufferDataType MR_BBapplyTo = Close; //Bollinger Bands apply to
input int MR_BollingerBandsPeriod = 20; // Bollinger Bands period
input double MR_BollingerBandsDeviations = 2.0; // Bollinger Bands deviations
      bool MR_UsedInEA = true;

//
//  Median renko indicator handle
//

int MedianRenkoHandle = -1;

//
//  Function for initializing the median renko indicator handle
//

int InitMedianRenko(string symbol)
{
   MedianRenkoHandle = iCustom(symbol,PERIOD_M1,RENKO_INDICATOR_NAME, 
                                       MR_barSizeInTicks,
                                       MR_retracementFactor,
                                       MR_symetricalReversals,
                                       MR_showWicks,
                                       MR_startFromDateTime,
                                       MR_resetOpenOnNewTradingDay,
                                       MR_showNextBarLevels,
                                       MR_HighThresholdIndicatorColor,
                                       MR_LowThresholdIndicatorColor,
                                       MR_showCurrentBarOpenTime,
                                       MR_InfoTextColor,
                                       MR_UseSoundSignalOnNewBar,
                                       MR_OnlySignalReversalBars,
                                       MR_UseAlertWindow,
                                       MR_SendPushNotifications,
                                       MR_SoundFileBull,
                                       MR_SoundFileBear,
                                       MR_MA1on, 
                                       MR_MA1period,
                                       MR_MA1method,
                                       MR_MA1applyTo,
                                       MR_MA2on,
                                       MR_MA2period,
                                       MR_MA2method,
                                       MR_MA2applyTo,
                                       MR_ShowChannel,
                                       "",
                                       MR_DonchianPeriod,
                                       MR_BBapplyTo,
                                       MR_BollingerBandsPeriod,
                                       MR_BollingerBandsDeviations,
                                       MR_UsedInEA);
  
    
    if(MedianRenkoHandle == INVALID_HANDLE)
    {
      Print("Median Renko indicator init failed on error ",GetLastError());
    }
    else
      Print("Median Renko indicator init OK");
      
    return MedianRenkoHandle;
}

//
// Function for releasing the Median Renko indicator hanlde - free resources
//

void DeinitMedianRenko()
{
   if(MedianRenkoHandle == INVALID_HANDLE)
      return;
      
   if(IndicatorRelease(MedianRenkoHandle))
      Print("Median Rneko indicator handle released");
   else 
      Print("Failed to release Median Renko indicator handle");
}

//
// Function for detecting a new Renko bar
//

bool IsNewRenkoBar()
{
    double currentRenkoOpen[1];
    static double prevRenkoOpen = 0;

    CopyBuffer(MedianRenkoHandle,RENKO_OPEN,0,1,currentRenkoOpen);
      
    if(prevRenkoOpen != currentRenkoOpen[0])
    {
      prevRenkoOpen = currentRenkoOpen[0];
      return true;
    }

    return false;
}

//
// Get "count" Renko MqlRates into "ratesInfoArray[]" array starting from "start" bar  
//

bool GetRenkoMqlRates(MqlRates &ratesInfoArray[], int start, int count)
{
   double o[],l[],h[],c[],time[],tick_volume[];

   if(ArrayResize(o,count) == -1)
      return false;
   if(ArrayResize(l,count) == -1)
      return false;
   if(ArrayResize(h,count) == -1)
      return false;
   if(ArrayResize(c,count) == -1)
      return false;
   if(ArrayResize(time,count) == -1)
      return false;
   if(ArrayResize(tick_volume,count) == -1)
      return false;

  
   if(CopyBuffer(MedianRenkoHandle,RENKO_OPEN,start,count,o) == -1)
      return false;
   if(CopyBuffer(MedianRenkoHandle,RENKO_LOW,start,count,l) == -1)
      return false;
   if(CopyBuffer(MedianRenkoHandle,RENKO_HIGH,start,count,h) == -1)
      return false;
   if(CopyBuffer(MedianRenkoHandle,RENKO_CLOSE,start,count,c) == -1)
      return false;
   if(CopyBuffer(MedianRenkoHandle,RENKO_BAR_OPEN_TIME,start,count,time) == -1)
      return false;
   if(CopyBuffer(MedianRenkoHandle,RENKO_TICK_VOLUME,start,count,tick_volume) == -1)
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
   }
   
   ArrayFree(o);
   ArrayFree(l);
   ArrayFree(h);
   ArrayFree(c);
   ArrayFree(time);
   ArrayFree(tick_volume);   
   
   return true;
}

//
// Get "count" MovingAverage1 values into "MA[]" array starting from "start" bar  
//

bool GetRenkoMA1(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(MedianRenkoHandle,RENKO_MA1,start,count,tempMA) == -1)
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

bool GetRenkoMA2(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(MedianRenkoHandle,RENKO_MA2,start,count,tempMA) == -1)
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

bool GetRenkoDonchian(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   return GetRenkoChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Get "count" Bollinger band values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool GetRenkoBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   return GetRenkoChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Used by GetRenkoDonchian and GetRenkoBollingerBands functions to get data
//

bool GetRenkoChannel(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
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
   
   if(CopyBuffer(MedianRenkoHandle,RENKO_CHANNEL_HIGH,start,count,tempH) == -1)
      return false;
   if(CopyBuffer(MedianRenkoHandle,RENKO_CHANNEL_MID,start,count,tempM) == -1)
      return false;
   if(CopyBuffer(MedianRenkoHandle,RENKO_CHANNEL_LOW,start,count,tempL) == -1)
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