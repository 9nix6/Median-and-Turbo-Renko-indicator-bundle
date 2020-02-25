#include <AZ-INVEST/SDK/CommonSettings.mqh>

#ifdef DEVELOPER_VERSION
   #define CUSTOM_CHART_NAME "Renko_TEST"
#else
   #ifdef P_RENKO_BR
      #ifdef P_RENKO_BR_PRO
         #define CUSTOM_CHART_NAME "P-RENKO BR Pro"
         #import "P-RenkoEngine.dll"
            void InitializeEngine();
            int CheckInitDLL();
            int GetToken(int i);   
            int GetPro(int i);   
         #import      
      #else
         #define CUSTOM_CHART_NAME "P-RENKO BR Lite"
         #import "P-RenkoEngine.dll"
   //      #import "P-RenkoEngineLite.dll"
           void InitializeEngine();
           int CheckInitDLL();
           int GetToken(int i);   
         #import           
      #endif
   #else
      #define CUSTOM_CHART_NAME "Ultimate Renko"
   #endif 
#endif

//
// Tick chart specific settings
//
#ifdef SHOW_INDICATOR_INPUTS
   #ifdef MQL5_MARKET_DEMO // hardcoded values
   
      int               barSizeInTicks = 200;                     // Renko body size (in ticks)
      input ENUM_CUSTOM_BAR_TYPE    PredefinedSetting=cbtRenko;               // Renko mode preset
      int                     InpOpen=50;                               // Open offset % (0 to ..)
      int                     InpRevShadow=50;                          // Reversal Open offset % (0 to ..)
      int                     InpRev=150;                               // Reversal bar size % (0 to ..)
      ENUM_BOOL         showWicks = true;                   // Show wicks
      ENUM_BOOL         atrEnabled = false;                       // Enable ATR based bar size calculation
      ENUM_TIMEFRAMES   atrTimeFrame = PERIOD_D1;                 // Use ATR period
      int               atrPeriod = 14;                           // ATR period
      int               atrPercentage = 10;                       // Use percentage of ATR
      ENUM_BOOL         applyOffsetToFirstBar = true;      // Apply offset to first renko
      int               offsetValue = 0;                    // Offset value
      int               showNumberOfDays = 21;                    // Show history for number of days
      ENUM_BOOL         resetOpenOnNewTradingDay = false;         // Synchronize first bar's open on new day
   
   #else // user defined settings
   
   
      input int               barSizeInTicks = 20;               // Renko body size (in ticks)
      
      input ENUM_CUSTOM_BAR_TYPE    PredefinedSetting=cbtRenko;               // Renko mode preset
      input int                     InpOpen=50;                               // Open offset % (0 to ..)
      input int                     InpRevShadow=50;                          // Reversal Open offset % (0 to ..)
      input int                     InpRev=150;                               // Reversal bar size % (0 to ..)
      
      //input double            retracementFactor = 0.5;            // Retracement factor (0.01 to 1.00)
      //input ENUM_BOOL         symetricalReversals = true;         // Asymmetrical reversals
      input ENUM_BOOL         showWicks = true;                   // Show wicks
      
      input ENUM_BOOL         atrEnabled = false;                 // Enable ATR based bar size calculation
            ENUM_TIMEFRAMES   atrTimeFrame = PERIOD_D1;           // Use ATR period
      input int               atrPeriod = 14;                     // ATR period
      input int               atrPercentage = 10;                 // Use percentage of ATR
      
      input ENUM_BOOL         applyOffsetToFirstBar = false;      // Apply offset to first renko
      input int               offsetValue = 0;                    // Offset value
   
      input int         showNumberOfDays = 5;                     // Show history for number of days
      input ENUM_BOOL   resetOpenOnNewTradingDay = true;          // Synchronize first bar's open on new day
   
   #endif
#else // don't SHOW_INDICATOR_INPUTS 
      int               barSizeInTicks = 180;                     // Range bar size (in ticks)
      //double            retracementFactor = 0.5;                  // Retracement factor (0.01 to 1.00)
      //ENUM_BOOL         symetricalReversals = true;               // Asymmetrical reversals
      ENUM_CUSTOM_BAR_TYPE    PredefinedSetting=cbtRenko;               // Renko mode preset
      int                     InpOpen=50;                               // Open offset % (0 to ..)
      int                     InpRevShadow=50;                          // Reversal Open offset % (0 to ..)
      int                     InpRev=150;                               // Reversal bar size % (0 to ..)
      
      ENUM_BOOL         showWicks = true;                         // Show wicks
      ENUM_BOOL         atrEnabled = false;                       // Enable ATR based bar size calculation
      ENUM_TIMEFRAMES   atrTimeFrame = PERIOD_D1;                 // Use ATR period
      int               atrPeriod = 14;                           // ATR period
      int               atrPercentage = 10;                       // Use percentage of ATR
      ENUM_BOOL         applyOffsetToFirstBar = false;      // Apply offset to first renko
      int               offsetValue = 0;                    // Offset value
      int               showNumberOfDays = 7;                     // Show history for number of days
      ENUM_BOOL         resetOpenOnNewTradingDay = true;          // Synchronize first bar's open on new day
#endif

//
// Remaining settings are located in the include file below.
// These are common for all custom charts
//
#include <az-invest/sdk/CustomChartSettingsBase.mqh>

struct RENKO_SETTINGS
{
   int                  barSizeInTicks;
//#ifdef USE_CUSTOM_SYMBOL
   ENUM_CUSTOM_BAR_TYPE predefinedSettings;
   double               pOpen;
   double               pReversal;
   double               pReversalShadow;
//#else   
//   double               retracementFactor;
//   ENUM_BOOL            symetricalReversals;
//#endif   
   ENUM_BOOL            showWicks;
   ENUM_BOOL            atrEnabled;
   ENUM_TIMEFRAMES      atrTimeFrame;
   int                  atrPeriod;
   int                  atrPercentage;
   int                  showNumberOfDays;
   ENUM_BOOL            resetOpenOnNewTradingDay;  
   
   ENUM_BOOL            applyOffsetToFirstBar;
   int                  offsetValue;      
};

class CRenkoCustomChartSettigns : public CCustomChartSettingsBase
{
   protected:
      
   RENKO_SETTINGS settings;

   public:
   
   CRenkoCustomChartSettigns();
   ~CRenkoCustomChartSettigns();

   RENKO_SETTINGS GetCustomChartSettings() { return this.settings; };   
   
   virtual void SetCustomChartSettings();
   virtual string GetSettingsFileName();
   virtual uint CustomChartSettingsToFile(int handle);
   virtual uint CustomChartSettingsFromFile(int handle);
};

void CRenkoCustomChartSettigns::CRenkoCustomChartSettigns()
{
   settingsFileName = GetSettingsFileName();
}

void CRenkoCustomChartSettigns::~CRenkoCustomChartSettigns()
{
}

string CRenkoCustomChartSettigns::GetSettingsFileName()
{
   return CUSTOM_CHART_NAME+(string)ChartID()+".set";  
}

uint CRenkoCustomChartSettigns::CustomChartSettingsToFile(int file_handle)
{
   return FileWriteStruct(file_handle,this.settings);
}

uint CRenkoCustomChartSettigns::CustomChartSettingsFromFile(int file_handle)
{
   return FileReadStruct(file_handle,this.settings);
}

void CRenkoCustomChartSettigns::SetCustomChartSettings()
{
   settings.barSizeInTicks = barSizeInTicks;
   
   settings.predefinedSettings = PredefinedSetting;
   settings.pOpen = MathAbs(InpOpen * 0.01); // value in percentage
   settings.pReversal = MathAbs(InpRev * 0.01); // value in percentage
   settings.pReversalShadow = fmax(0.01, MathAbs(InpRevShadow * 0.01)); // value in percentage   
   
   //settings.retracementFactor = retracementFactor;
   //settings.symetricalReversals = symetricalReversals;   
   settings.showWicks = showWicks;
   
   settings.atrEnabled = atrEnabled;
   settings.atrTimeFrame = atrTimeFrame;
   settings.atrPeriod = atrPeriod;
   settings.atrPercentage = atrPercentage;
   settings.showNumberOfDays = showNumberOfDays;
   settings.resetOpenOnNewTradingDay = resetOpenOnNewTradingDay;
   
   settings.applyOffsetToFirstBar = applyOffsetToFirstBar;
   settings.offsetValue = offsetValue;
}
