#include <AZ-INVEST/SDK/CommonSettings.mqh>

#ifdef DEVELOPER_VERSION
   #define CUSTOM_CHART_NAME "Ultimate Renko"
#else
   
   #ifdef P_RENKO_BR_PRO
      #ifdef P_RENKO_ALL
         #define CUSTOM_CHART_NAME "P-RENKO" 
      #else
         #define CUSTOM_CHART_NAME "P-RENKO Ultimate" 
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
   
      double                        InpBarSize = 200;                            // Renko body size
      ENUM_BAR_SIZE_CALC_MODE       InpBarSizeCalcMode = BAR_SIZE_ABSOLUTE_TICKS;// Renko body calculation mode
      input ENUM_CUSTOM_BAR_TYPE    InpPredefinedSetting=cbtRenko;               // Renko mode preset
      int                           InpOpen=50;                                  // Open offset % (0 to ..)
      int                           InpRevShadow=50;                             // Reversal Open offset % (0 to ..)
      int                           InpRev=150;                                  // Reversal bar size % (0 to ..)
      ENUM_BOOL                     InpShowWicks = true;                         // Show wicks
      ENUM_TIMEFRAMES               InpAtrTimeFrame = PERIOD_D1;                 // Use ATR period
      int                           InpAtrPeriod = 14;                           // ATR period
      ENUM_BOOL                     InpApplyOffsetToFirstBar = true;             // Truncate trailing digits on the first renko
      int                           InpOffsetValue = 0;                          // Number of digits to truncate
      int                           InpShowNumberOfDays = 5;                     // Show history for number of days
      datetime                      InpShowFromDate = 0;                         // Show history starting from
      ENUM_BOOL                     InpResetOpenOnNewTradingDay = false;         // Synchronize first bar's open on new day
   
   #else // Main Inputs block
   
      #ifdef P_RENKO_BR //################################################################################################
      
         input double                  InpBarSize = 100;                            // Tamanho do Renko
         input ENUM_BAR_SIZE_CALC_MODE InpBarSizeCalcMode = BAR_SIZE_ABSOLUTE_TICKS;// Método para Cálculo do Box
         input ENUM_CUSTOM_BAR_TYPE    InpPredefinedSetting=cbtRenko;               // Preset do Renko
         input int                     InpOpen=50;                                  // Offset de abertura %
         input int                     InpRevShadow=50;                             // Offset de abertura da reversão %
         input int                     InpRev=150;                                  // Tamanho da barra de reversão %
         
         input ENUM_BOOL               InpShowWicks = true;                         // Mostrar Pavio
         input int                     InpShowNumberOfDays = 5;                     // Número de dias para mostrar histórico
         input datetime                InpShowFromDate = 0;                         // Show history starting from
         
         input group                   "### Cálculo do box do renko baseado em ATR" 

         input ENUM_TIMEFRAMES         InpAtrTimeFrame = PERIOD_D1;                 // Usar Período do ATR
         input int                     InpAtrPeriod = 14;                           // Período do ATR
         
         input group                   "### Sincronização do gráfico"
         
         input ENUM_BOOL               InpApplyOffsetToFirstBar = false;            // Truncar os dígitos finais no primeiro renko
         input int                     InpOffsetValue = 1;                          // Número de dígitos a serem truncados         
         input ENUM_BOOL               InpResetOpenOnNewTradingDay = true;          // Sincronizar abertura do primeiro box
      
      #else //###########################################################################################################
      
         input double                  InpBarSize = 100;                            // Renko body size
         input ENUM_BAR_SIZE_CALC_MODE InpBarSizeCalcMode = BAR_SIZE_ABSOLUTE_TICKS;// Renko body calculation mode
         input ENUM_CUSTOM_BAR_TYPE    InpPredefinedSetting=cbtRenko;               // Renko mode preset
         input int                     InpOpen=50;                                  // Open offset % (0 to ..)
         input int                     InpRevShadow=50;                             // Reversal Open offset % (0 to ..)
         input int                     InpRev=150;                                  // Reversal bar size % (0 to ..)
         
         input ENUM_BOOL               InpShowWicks = true;                         // Show wicks
         input int                     InpShowNumberOfDays = 5;                     // Show history for number of days
         input datetime                InpShowFromDate = 0;                         // Show history starting from
         
         input group                   "### ATR renko body size calculation"
         input ENUM_TIMEFRAMES         InpAtrTimeFrame = PERIOD_D1;                 // ATR timeframe setting
         input int                     InpAtrPeriod = 14;                           // ATR period setting
         
         input group                   "### Chart synchronization"
         input ENUM_BOOL               InpApplyOffsetToFirstBar = false;            // Truncate trailing digits on the first renko
         input int                     InpOffsetValue = 1;                          // Number of digits to truncate         
         input ENUM_BOOL               InpResetOpenOnNewTradingDay = true;          // Synchronize first bar's open on new day

      #endif //#########################################################################################################
   #endif
#else // don't SHOW_INDICATOR_INPUTS 
      double                        InpBarSize = 180;                            // Renko brick size 
      ENUM_BAR_SIZE_CALC_MODE       InpBarSizeCalcMode = BAR_SIZE_ABSOLUTE_TICKS;// Renko body calculation mode
      ENUM_CUSTOM_BAR_TYPE          InpPredefinedSetting=cbtRenko;               // Renko mode preset
      int                           InpOpen=50;                                  // Open offset % (0 to ..)
      int                           InpRevShadow=50;                             // Reversal Open offset % (0 to ..)
      int                           InpRev=150;                                  // Reversal bar size % (0 to ..)
      
      ENUM_BOOL                     InpShowWicks = true;                         // Show wicks
      
      ENUM_TIMEFRAMES               InpAtrTimeFrame = PERIOD_D1;                 // ATR timeframe setting
      int                           InpAtrPeriod = 14;                           // ATR period setting

      ENUM_BOOL                     InpApplyOffsetToFirstBar = false;            // Truncate trailing digits on the first renko
      int                           InpOffsetValue = 1;                          // Number of digits to truncate
      int                           InpShowNumberOfDays = 7;                     // Show history for number of days
      datetime                      InpShowFromDate = 0;                         // Show history starting from
      ENUM_BOOL                     InpResetOpenOnNewTradingDay = true;          // Synchronize first bar's open on new day
#endif

//
// Remaining settings are located in the include file below.
// These are common for all custom charts
//

#include <AZ-INVEST/SDK/CustomChartSettingsBase.mqh>

#define SETNAME_BAR_SIZE_CALC_MODE  "barSizeCalcMode"
#define SETNAME_ATR_TIMEFRAME       "atrTimeFrame"
#define SETNAME_ATR_PERIOD          "atrPeriod"

struct RENKO_SETTINGS
{
   double                  barSize;
   ENUM_BAR_SIZE_CALC_MODE barSizeCalcMode;
   ENUM_CUSTOM_BAR_TYPE    predefinedSettings;
   double                  pOpen;
   double                  pReversal;
   double                  pReversalShadow;
   ENUM_BOOL               showWicks;
   ENUM_TIMEFRAMES         atrTimeFrame;
   int                     atrPeriod;
   int                     showNumberOfDays;
   datetime                showFromDate;
   ENUM_BOOL               resetOpenOnNewTradingDay;     
   ENUM_BOOL               applyOffsetToFirstBar;
   int                     offsetValue;      
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
   virtual uint CustomChartSettingsSize();
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

uint CRenkoCustomChartSettigns::CustomChartSettingsSize()
{
   return sizeof(this.settings);
}

void CRenkoCustomChartSettigns::SetCustomChartSettings()
{
   settings.barSize = InpBarSize;
   settings.barSizeCalcMode = InpBarSizeCalcMode;
   settings.predefinedSettings = InpPredefinedSetting;
   settings.pOpen = MathAbs(InpOpen * 0.01);                            // value as percentage
   settings.pReversal = MathAbs(InpRev * 0.01);                         // value as percentage
   settings.pReversalShadow = fmax(0.01, MathAbs(InpRevShadow * 0.01)); // value as percentage   
   settings.showWicks = InpShowWicks;
   settings.atrTimeFrame = InpAtrTimeFrame;
   settings.atrPeriod = InpAtrPeriod;
   settings.showNumberOfDays = InpShowNumberOfDays;
   settings.showFromDate = InpShowFromDate;
   settings.resetOpenOnNewTradingDay = InpResetOpenOnNewTradingDay;
   settings.applyOffsetToFirstBar = InpApplyOffsetToFirstBar;
   settings.offsetValue = ((MathAbs(InpOffsetValue) > _Digits) ? 0 : MathAbs(InpOffsetValue));
}
