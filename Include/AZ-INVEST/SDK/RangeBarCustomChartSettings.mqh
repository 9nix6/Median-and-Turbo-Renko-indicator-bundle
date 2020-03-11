#include <AZ-INVEST/SDK/CommonSettings.mqh>

#ifdef DEVELOPER_VERSION
   #define CUSTOM_CHART_NAME "RangeBars_TEST"
#else
   #define CUSTOM_CHART_NAME "Range Bars"
#endif

//
// Tick chart specific settings
//
#ifdef SHOW_INDICATOR_INPUTS
   #ifdef MQL5_MARKET_DEMO // hardcoded values
   
      int               barSizeInTicks = 180;                     // Range bar size (in ticks)
      ENUM_BOOL         atrEnabled = false;                       // Enable ATR based bar size calculation
      ENUM_TIMEFRAMES   atrTimeFrame = PERIOD_D1;                 // Use ATR period
      int               atrPeriod = 14;                           // ATR period
      int               atrPercentage = 10;                       // Use percentage of ATR
      int               showNumberOfDays = 7;                     // Show history for number of days
      ENUM_BOOL         resetOpenOnNewTradingDay = true;          // Synchronize first bar's open on new day
   
   #else // user defined settings
   
   
      input int               barSizeInTicks = 100;                // Range bar size (in ticks)
      input ENUM_BOOL         atrEnabled = false;                 // Enable ATR based bar size calculation
            ENUM_TIMEFRAMES   atrTimeFrame = PERIOD_D1;           // Use ATR period
      input int               atrPeriod = 14;                     // ATR period
      input int               atrPercentage = 10;                 // Use percentage of ATR
   
      input int         showNumberOfDays = 5;                     // Show history for number of days
      input ENUM_BOOL   resetOpenOnNewTradingDay = true;          // Synchronize first bar's open on new day
   
   #endif
#else // don't SHOW_INDICATOR_INPUTS 
      int               barSizeInTicks = 180;                     // Range bar size (in ticks)
      ENUM_BOOL         atrEnabled = false;                       // Enable ATR based bar size calculation
      ENUM_TIMEFRAMES   atrTimeFrame = PERIOD_D1;                 // Use ATR period
      int               atrPeriod = 14;                           // ATR period
      int               atrPercentage = 10;                       // Use percentage of ATR
      int               showNumberOfDays = 7;                     // Show history for number of days
      ENUM_BOOL         resetOpenOnNewTradingDay = true;          // Synchronize first bar's open on new day
#endif

//
// Remaining settings are located in the include file below.
// These are common for all custom charts
//
#include <az-invest/sdk/CustomChartSettingsBase.mqh>

struct RANGEBAR_SETTINGS
{
   int                  barSizeInTicks;
   ENUM_BOOL            atrEnabled;
   ENUM_TIMEFRAMES      atrTimeFrame;
   int                  atrPeriod;
   int                  atrPercentage;
   int                  showNumberOfDays;
   ENUM_BOOL            resetOpenOnNewTradingDay;  
};


class CRangeBarCustomChartSettigns : public CCustomChartSettingsBase
{
   protected:
      
   RANGEBAR_SETTINGS settings;

   public:
   
   CRangeBarCustomChartSettigns();
   ~CRangeBarCustomChartSettigns();

   RANGEBAR_SETTINGS GetCustomChartSettings() { return this.settings; };   
   
   virtual void SetCustomChartSettings();
   virtual string GetSettingsFileName();
   virtual uint CustomChartSettingsToFile(int handle);
   virtual uint CustomChartSettingsFromFile(int handle);
};

void CRangeBarCustomChartSettigns::CRangeBarCustomChartSettigns()
{
   settingsFileName = GetSettingsFileName();
}

void CRangeBarCustomChartSettigns::~CRangeBarCustomChartSettigns()
{
}

string CRangeBarCustomChartSettigns::GetSettingsFileName()
{
   return CUSTOM_CHART_NAME+(string)ChartID()+".set";  
}

uint CRangeBarCustomChartSettigns::CustomChartSettingsToFile(int file_handle)
{
   return FileWriteStruct(file_handle,this.settings);
}

uint CRangeBarCustomChartSettigns::CustomChartSettingsFromFile(int file_handle)
{
   return FileReadStruct(file_handle,this.settings);
}

void CRangeBarCustomChartSettigns::SetCustomChartSettings()
{
   settings.barSizeInTicks = barSizeInTicks;
   
   settings.atrEnabled = atrEnabled;
   settings.atrTimeFrame = atrTimeFrame;
   settings.atrPeriod = atrPeriod;
   settings.atrPercentage = atrPercentage;
   settings.showNumberOfDays = showNumberOfDays;
   settings.resetOpenOnNewTradingDay = resetOpenOnNewTradingDay;
}
