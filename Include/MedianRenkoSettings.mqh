//+------------------------------------------------------------------+
//|                                          MedianRenkoSettings.mqh |
//|                                        Copyright 2017, AZ-iNVEST |
//|                                          http://www.az-invest.eu |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, AZ-iNVEST"
#property link      "http://www.az-invest.eu"
 
enum ENUM_CHANNEL_TYPE
{
   None = 0,            // None
   Donchian_Channel,    // Donchian Channel
   Bollinger_Bands,     // Bollinger Bands
   SuperTrend,          // Super Trend
//   VWAP,
};

#ifdef SHOW_INDICATOR_INPUTS

   input int barSizeInTicks = 100; // Bars size (in points)
         double customBarSize = barSizeInTicks * Point();
   input double _retracementFactor = 0.5; // Retracement factor (0.01 to 1.00)
         double retracementFactor = 0.5;
         bool   useTickVolume = true; // Use tick volume (for FX)            
   input bool   symetricalReversals = true; // Symmetrical reversals
   input bool   showWicks = true; // Show wicks
   input datetime _startFromDateTime = 0; // Start building chart from date/time
         datetime startFromDateTime = 0;
   input bool  resetOpenOnNewTradingDay = false; // Synchronize first bar's open on new day
   input bool  showNextBarLevels = true; // Show current bar's close projections
   input color HighThresholdIndicatorColor = clrLime; // Bullish bar projection color
   input color LowThresholdIndicatorColor = clrRed; // Bearish bar projection color
   input bool  showCurrentBarOpenTime = true; // Display chart info and current bar's open time
   input color InfoTextColor = clrWhite; // Current bar's open time info color
   input bool      UseSoundSignalOnNewBar = false; // Play sound on new bar
   input bool      OnlySignalReversalBars = false; // Only signal reversals
   input bool      UseAlertWindow = false; // Display Alert window with new bar info
   input bool      SendPushNotifications = false; // Send new bar info push notification to smartphone
   input string    SoundFileBull = "news.wav"; // Use sound file for bullish bar close
   input string    SoundFileBear = "news.wav"; // Use sound file for bearish bar close
   input bool MA1on = false; // Show first MA 
   input int MA1period = 20; // 1st MA period
   input ENUM_MA_METHOD MA1method =  MODE_EMA; // 1st MA metod
   input ENUM_APPLIED_PRICE MA1applyTo = PRICE_CLOSE; //1st MA apply to
   input int MA1shift = 0; //1st MA shift
   input bool MA2on = false; // Show second MA 
   input int MA2period = 50; // 2nd MA period
   input ENUM_MA_METHOD MA2method = MODE_EMA; // 2nd MA method
   input ENUM_APPLIED_PRICE MA2applyTo = PRICE_CLOSE; // 2nd MA apply to
   input int MA2shift = 0; //2nd MA shift
   input ENUM_CHANNEL_TYPE ShowChannel = None; // Show Channel
   input string Channel_Settings = "--------------------------"; // Channel settings 
   input int DonchianPeriod = 20; // Donchan Channel period
   input ENUM_APPLIED_PRICE BBapplyTo = PRICE_CLOSE; //Bollinger Bands apply to
   input int BollingerBandsPeriod = 20; // Bollinger Bands period
   input double BollingerBandsDeviations = 2.0; // Bollinger Bands deviations
   input int SuperTrendPeriod = 10; // Super Trend period
   input double SuperTrendMultiplier=1.7; // Super Trend multiplier
   input string Misc_Settings = "--------------------------"; // Misc settings
   input bool UsedInEA = false; // Indicator used in EA via iCustom()

#else

   int barSizeInTicks;
   double _retracementFactor;
   double retracementFactor;
   bool   useTickVolume = true;
   bool   symetricalReversals;
   bool   showWicks;
   datetime startFromDateTime;
   datetime _startFromDateTime = 0;   
   bool  resetOpenOnNewTradingDay;
   
   bool  showNextBarLevels = false;
   color HighThresholdIndicatorColor = clrNONE;
   color LowThresholdIndicatorColor = clrNONE;
   bool  showCurrentBarOpenTime = false;
   color InfoTextColor = clrNONE;
   bool      UseSoundSignalOnNewBar = false;
   bool      OnlySignalReversalBars = false;
   bool      UseAlertWindow = false;
   bool      SendPushNotifications = false;
   string    SoundFileBull = "";
   string    SoundFileBear = "";
   
   bool MA1on;
   int MA1period;
   ENUM_MA_METHOD MA1method;
   ENUM_APPLIED_PRICE MA1applyTo;
   int MA1shift;
   
   bool MA2on;
   int MA2period;
   ENUM_MA_METHOD MA2method;
   ENUM_APPLIED_PRICE MA2applyTo;
   int MA2shift;

   ENUM_CHANNEL_TYPE ShowChannel;
   int DonchianPeriod;
   ENUM_APPLIED_PRICE BBapplyTo;
   int BollingerBandsPeriod;
   double BollingerBandsDeviations;
   int SuperTrendPeriod = 10;
   double SuperTrendMultiplier=1.7;
      
   bool UsedInEA = true;

#endif

struct MEDIANRENKO_SETTINGS
{
   int                  barSizeInTicks;
   double               _retracementFactor;
   bool                 useTickVolume;
   bool                 symetricalReversals;
   bool                 showWicks;
   datetime             _startFromDateTime;
   bool                 resetOpenOnNewTradingDay;
   
   bool                 MA1on; 
   int                  MA1period;
   ENUM_MA_METHOD       MA1method;
   ENUM_APPLIED_PRICE   MA1applyTo;
   int                  MA1shift;
   
   bool                 MA2on; 
   int                  MA2period;
   ENUM_MA_METHOD       MA2method;
   ENUM_APPLIED_PRICE   MA2applyTo;
   int                  MA2shift;
   
   ENUM_CHANNEL_TYPE    ShowChannel;
   
   int                  DonchianPeriod;
   
   ENUM_APPLIED_PRICE   BBapplyTo;
   int                  BollingerBandsPeriod;
   double               BollingerBandsDeviations;
   
   int                  SuperTrendPeriod;
   double               SuperTrendMultiplier;   
};

class MedianRenkoSettings
{
   protected:
   
      string settingsFileName;
      MEDIANRENKO_SETTINGS settings;
            
   public:
   
      MedianRenkoSettings(void);
      ~MedianRenkoSettings(void);
      
      void Save(void);
      bool Load(void);
      void Delete(void);
      bool Changed(void);

      MEDIANRENKO_SETTINGS Get(void);
      void Debug(void);
      
};

void MedianRenkoSettings::MedianRenkoSettings(void)
{
   this.settingsFileName = "MedianRenko"+(string)ChartID()+".set";
}

void MedianRenkoSettings::~MedianRenkoSettings(void)
{

}

void MedianRenkoSettings::Save(void)
{
   settings.barSizeInTicks = barSizeInTicks;
   settings._retracementFactor = retracementFactor;
   settings.useTickVolume = useTickVolume;
   settings.symetricalReversals = symetricalReversals;
   settings.showWicks = showWicks;
   settings._startFromDateTime = startFromDateTime;
   settings.resetOpenOnNewTradingDay = resetOpenOnNewTradingDay;
   settings.MA1on = MA1on;
   settings.MA1period = MA1period;
   settings.MA1method = MA1method;
   settings.MA1applyTo = MA1applyTo;
   settings.MA1shift = MA1shift;
   settings.MA2on = MA2on;
   settings.MA2period = MA2period;
   settings.MA2method = MA2method;
   settings.MA2applyTo = MA2applyTo;
   settings.MA2shift = MA2shift;
   settings.ShowChannel = ShowChannel;
   settings.DonchianPeriod = DonchianPeriod;
   settings.BBapplyTo = BBapplyTo;
   settings.BollingerBandsPeriod = BollingerBandsPeriod;
   settings.BollingerBandsDeviations = BollingerBandsDeviations;
   settings.SuperTrendPeriod = SuperTrendPeriod;
   settings.SuperTrendMultiplier = SuperTrendMultiplier;
      
   this.Delete();
   
   int handle = FileOpen(this.settingsFileName,FILE_SHARE_READ|FILE_WRITE|FILE_BIN);  
   FileWriteStruct(handle,this.settings);
   FileClose(handle);
}

void MedianRenkoSettings::Delete(void)
{
   if(FileIsExist(this.settingsFileName))
      FileDelete(this.settingsFileName);     
}

bool MedianRenkoSettings::Load(void)
{
   if(!FileIsExist(this.settingsFileName))
      return false;
      
   int handle = FileOpen(this.settingsFileName,FILE_SHARE_READ|FILE_BIN);  
   if(handle == INVALID_HANDLE)
      return false;
      
   if(FileReadStruct(handle,this.settings) <= 0)
   {
      Print("Failed loading settigns!");
      FileClose(handle); 
      return false;
   }
   
   this.Debug();
   FileClose(handle);
   return true;
}

MEDIANRENKO_SETTINGS MedianRenkoSettings::Get(void)
{
   return this.settings;
}

bool MedianRenkoSettings::Changed(void)
{
   static datetime prevFileTime = 0;

   if(!FileIsExist(this.settingsFileName))
      return false;
      
   int handle = FileOpen(this.settingsFileName,FILE_SHARE_READ|FILE_BIN);  
   datetime currFileTime = (datetime)FileGetInteger(handle,FILE_CREATE_DATE);  
   FileClose(handle); 
 
   if(prevFileTime != currFileTime)
   {
      prevFileTime = currFileTime;
      return true;
   }
   
   return false;
}

void MedianRenkoSettings::Debug(void)
{
   Print("MedianRenko settings:");
   Print("barSizeInTicks = "+(string)settings.barSizeInTicks);
   Print("retracementFactor = "+(string)settings._retracementFactor);
   Print("useTickVolume = "+(string)settings.useTickVolume);
   Print("symetricalReversals = "+(string)settings.symetricalReversals);
   Print("showWicks = "+(string)settings.showWicks);
   Print("startFromDateTime = "+(string)settings._startFromDateTime);
   Print("resetOpenOnNewTradingDay = "+(string)settings.resetOpenOnNewTradingDay);
   Print("MA1on = "+(string)settings.MA1on);
   Print("MA1period = "+(string)settings.MA1period);
   Print("MA1method = "+(string)settings.MA1method);
   Print("MA1applyTo = "+(string)settings.MA1applyTo);
   Print("MA1shift = "+(string)settings.MA1shift);
   Print("MA2on = "+(string)settings.MA2on);
   Print("MA2period = "+(string)settings.MA2period);
   Print("MA2method = "+(string)settings.MA2method);
   Print("MA2applyTo = "+(string)settings.MA2applyTo);
   Print("MA2shift = "+(string)settings.MA1shift);
   Print("ShowChannel = "+(string)settings.ShowChannel);
   Print("DonchianPeriod = "+(string)settings.DonchianPeriod);
   Print("BBapplyTo = "+(string)settings.BBapplyTo);
   Print("BBperiod = "+(string)settings.BollingerBandsPeriod);
   Print("BBdeviations = "+(string)settings.BollingerBandsDeviations);
   Print("SuperTrendPeriod = "+(string)settings.SuperTrendPeriod);
   Print("SuperTrendMultiplier = "+(string)settings.SuperTrendMultiplier);
}