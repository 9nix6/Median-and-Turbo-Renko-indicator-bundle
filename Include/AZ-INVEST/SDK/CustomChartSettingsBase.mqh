#property copyright "Copyright 2018-2020, Level Up Software"
#property link      "http://www.az-invest.eu"

#include <AZ-INVEST/SDK/ICustomChartSettings.mqh>

class CCustomChartSettingsBase : public ICustomChartSettings
{
   private:

      int                           handle;              

   protected:
   
      string                        settingsFileName;
      string                        chartTypeFileName;
      
      #ifdef USE_CUSTOM_SYMBOL      
         CUSTOM_SYMBOL_SETTINGS     customSymbolSettings;      
      #else      
         CHART_INDICATOR_SETTINGS   chartIndicatorSettings;
         ALERT_INFO_SETTINGS        alertInfoSettings;      
      #endif
           
   public:
   
                                    CCustomChartSettingsBase();
                                    ~CCustomChartSettingsBase();
                                 
      #ifdef USE_CUSTOM_SYMBOL
         CUSTOM_SYMBOL_SETTINGS     GetCustomSymbolSettings();
      #else
         ALERT_INFO_SETTINGS        GetAlertInfoSettings(void);
         CHART_INDICATOR_SETTINGS   GetChartIndicatorSettings(void);         
      #endif
      
      int                           GetHandle() { return handle; };
      
      void                          Set();
      void                          Save();
      bool                          Load();
      void                          Delete();
      bool                          Changed(double currentRuntimeId);
      
      virtual string                GetSettingsFileName() { return "must_override "+__FUNCTION__; };
      virtual void                  SetCustomChartSettings() {};
      virtual uint                  CustomChartSettingsToFile(int file_handle) {return 0;};
      virtual uint                  CustomChartSettingsFromFile(int file_handle) {return 0;};
      virtual uint                  CustomChartSettingsSize() {return 0;};
      
};

void CCustomChartSettingsBase::CCustomChartSettingsBase()
{
}

void CCustomChartSettingsBase::~CCustomChartSettingsBase()
{
}

#ifdef USE_CUSTOM_SYMBOL

   CUSTOM_SYMBOL_SETTINGS CCustomChartSettingsBase::GetCustomSymbolSettings()
   {
      return this.customSymbolSettings;
   }

#else

   ALERT_INFO_SETTINGS CCustomChartSettingsBase::GetAlertInfoSettings()
   {
      return this.alertInfoSettings;
   }
   
   CHART_INDICATOR_SETTINGS CCustomChartSettingsBase::GetChartIndicatorSettings()
   {
      return this.chartIndicatorSettings;
   }

#endif

void CCustomChartSettingsBase::Save(void)
{    
   #ifdef USE_CUSTOM_SYMBOL
   //
   #else
      if(IS_TESTING || this.chartIndicatorSettings.UsedInEA)
         return;
   
      this.Delete();
   
      //
      // Store indicator settings in file
      // 
   
      handle = FileOpen(this.settingsFileName,FILE_SHARE_READ|FILE_WRITE|FILE_BIN);  
      uint result = 0;
      
      result += CustomChartSettingsToFile(handle);
      result += FileWriteStruct(handle,this.chartIndicatorSettings);
      FileClose(handle);
   #endif
}


bool CCustomChartSettingsBase::Changed(double currentRuntimeId)
{
   if(MQLInfoInteger((int)MQL_TESTER))
      return false;
 
   static double prevRuntimeId = -2;

   if(prevRuntimeId != currentRuntimeId)
   {
      #ifdef IS_DEBUG
         Print(__FUNCTION__+" prevRuntimeId = "+(string)prevRuntimeId+", currentRuntimeId = "+(string)currentRuntimeId);
      #endif
      
      prevRuntimeId = currentRuntimeId;
      return true;
   }

   return false;
}

void CCustomChartSettingsBase::Delete(void)
{
   #ifdef USE_CUSTOM_SYMBOL
   //
   #else

   if(IS_TESTING || this.chartIndicatorSettings.UsedInEA)
      return;

   if(FileIsExist(this.settingsFileName))
      FileDelete(this.settingsFileName);     
   
   #endif
}

bool CCustomChartSettingsBase::Load(void)
{
   #ifdef SHOW_INDICATOR_INPUTS
      Set();
      return true;
   #else 

   //
   // Load indicator settings from file
   // 

   if(!FileIsExist(this.settingsFileName))
      return false;
      
   handle = FileOpen(this.settingsFileName,FILE_SHARE_READ|FILE_BIN);  
   if(handle == INVALID_HANDLE)
      return false;

   //
   // The settings file is two raw structs and carries no version field. The
   // indicator writes it; this SDK reads it. If the two were built against
   // different struct layouts, FileReadStruct still succeeds whenever enough
   // bytes remain -- it reports a short read, never a differently-shaped one --
   // and every field from the first changed offset on is silently reinterpreted.
   // The EA then runs on structurally valid garbage and the customer reports
   // "settings are wrong after updating", with nothing in either log to say why.
   //
   // Comparing the file's size against what this build expects catches any
   // layout change that alters a struct's size, which is what adding, removing
   // or retyping a field does. A same-size reordering still passes; detecting
   // that needs a version field in the file itself, which cannot be added from
   // this repository alone because the writer is the closed-source indicator.
   //
   uint expectedSize = CustomChartSettingsSize() + sizeof(this.chartIndicatorSettings);
   ulong actualSize = FileSize(handle);
   
   if(expectedSize > 0 && actualSize != expectedSize)
   {
      PrintFormat("%s: settings file '%s' is %I64u bytes, this build expects %u. "
                  "The indicator and the EA/SDK were built against different settings "
                  "layouts -- update both to the same release. Ignoring the file.",
                  __FUNCTION__, this.settingsFileName, actualSize, expectedSize);
      FileClose(handle);
      return false;
   }
        
   if(CustomChartSettingsFromFile(handle) <= 0)
   {
      Print("Failed loading settings in "+__FUNCTION__+" ("+__FILE__+", line#"+(string)__LINE__+")");
      FileClose(handle); 
      return false;
   }
   
   if(FileReadStruct(handle,this.chartIndicatorSettings) <= 0)
   {
      Print("Failed loading settings in "+__FUNCTION__+" ("+__FILE__+", line#"+(string)__LINE__+")");
      FileClose(handle); 
      return false;
   }

   // Every byte written must have been consumed. A trailing remainder means the
   // writer put more in the file than this build knows how to read.
   ulong consumed = FileTell(handle);
   if(consumed != actualSize)
   {
      PrintFormat("%s: settings file '%s' has %I64u trailing byte(s) after both "
                  "structs were read. The indicator and the EA/SDK disagree on the "
                  "settings layout -- update both to the same release. Ignoring the file.",
                  __FUNCTION__, this.settingsFileName, actualSize - consumed);
      FileClose(handle);
      return false;
   }
   
   FileClose(handle);
   return true;

#endif 
}

void CCustomChartSettingsBase::Set(void)
{
#ifdef SHOW_INDICATOR_INPUTS

   SetCustomChartSettings();
      
   //
   //
   //

   #ifdef USE_CUSTOM_SYMBOL     
   
      customSymbolSettings.CustomChartName = InpCustomChartName;
      customSymbolSettings.ApplyTemplate = InpApplyTemplate;
      customSymbolSettings.ForBacktesting = InpForBacktester;
      customSymbolSettings.ForceFasterRefresh = InpForceFasterRefresh;
      customSymbolSettings.ShowTradeLevels = InpShowTradeLevels;
   #else
          
      //chartIndicatorSettings.MA1on = MA1on;
      chartIndicatorSettings.MA1lineType = InpMA1lineType;
      chartIndicatorSettings.MA1period = InpMA1period;
      chartIndicatorSettings.MA1method = InpMA1method;
      chartIndicatorSettings.MA1applyTo = InpMA1applyTo;
      chartIndicatorSettings.MA1shift = InpMA1shift;
      chartIndicatorSettings.MA1priceLabel = InpMA1priceLabel;
      
      //chartIndicatorSettings.MA2on = MA2on;
      chartIndicatorSettings.MA2lineType = InpMA2lineType;
      chartIndicatorSettings.MA2period = InpMA2period;
      chartIndicatorSettings.MA2method = InpMA2method;
      chartIndicatorSettings.MA2applyTo = InpMA2applyTo;
      chartIndicatorSettings.MA2shift = InpMA2shift;
      chartIndicatorSettings.MA2priceLabel = InpMA2priceLabel;
      
      //chartIndicatorSettings.MA3on = MA3on;
      chartIndicatorSettings.MA3lineType = InpMA3lineType;
      chartIndicatorSettings.MA3period = InpMA3period;
      chartIndicatorSettings.MA3method = InpMA3method;
      chartIndicatorSettings.MA3applyTo = InpMA3applyTo;
      chartIndicatorSettings.MA3shift = InpMA3shift;
      chartIndicatorSettings.MA3priceLabel = InpMA3priceLabel;
      
      //chartIndicatorSettings.MA4on = MA4on;
      chartIndicatorSettings.MA4lineType = InpMA4lineType;
      chartIndicatorSettings.MA4period = InpMA4period;
      chartIndicatorSettings.MA4method = InpMA4method;
      chartIndicatorSettings.MA4applyTo = InpMA4applyTo;
      chartIndicatorSettings.MA4shift = InpMA4shift;
      chartIndicatorSettings.MA4priceLabel = InpMA4priceLabel;
      
      chartIndicatorSettings.ShowChannel = InpShowChannel;
      chartIndicatorSettings.ChannelAppliedPrice = InpChannelAppliedPrice;
      chartIndicatorSettings.ChannelPeriod = InpChannelPeriod;
      chartIndicatorSettings.ChannelAtrPeriod = InpChannelAtrPeriod;
      chartIndicatorSettings.ChannelMultiplier = InpChannelMultiplier;
      chartIndicatorSettings.ChannelBandsDeviations = InpChannelBandsDeviations;
      //chartIndicatorSettings.ChannelPriceLabel = InpChannelPriceLabel;
      //chartIndicatorSettings.ChannelMidPriceLabel = InpChannelMidPriceLabel;
      chartIndicatorSettings.ChannelPriceLabels = InpChannelPriceLabels;
      
      chartIndicatorSettings.ShiftObj = InpShiftObj;
      chartIndicatorSettings.UsedInEA = InpUsedInEA;
   
      //
      //
      //
         
      alertInfoSettings.TradingSessionTime = InpTradingSessionTime;
         
      alertInfoSettings.TopBottomPaddingPercentage = InpTopBottomPaddingPercentage;
      alertInfoSettings.showPivots = InpShowPivots;
      
      alertInfoSettings.pivotPointCalculationType = InpPivotPointCalculationType;
      alertInfoSettings.Rcolor = InpRColor;
      alertInfoSettings.Pcolor = InpPColor;
      alertInfoSettings.Scolor = InpSColor;
      alertInfoSettings.PDHColor = InpPDHColor;
      alertInfoSettings.PDLColor = InpPDLColor;
      alertInfoSettings.PDCColor = InpPDCColor;
      
#ifdef USES_PRICE_PROJECTIONS      
      alertInfoSettings.HighThresholdIndicatorColor = InpHighThresholdIndicatorColor;
      alertInfoSettings.LowThresholdIndicatorColor = InpLowThresholdIndicatorColor;
#endif
#ifdef USES_COUNTER      
      alertInfoSettings.CounterColor = InpCounterColor;
#endif      
      alertInfoSettings.MA1PriceLabelColor = InpMA1PriceLabelColor;
      alertInfoSettings.MA2PriceLabelColor = InpMA2PriceLabelColor;
      alertInfoSettings.MA3PriceLabelColor = InpMA3PriceLabelColor;
      alertInfoSettings.MA4PriceLabelColor = InpMA4PriceLabelColor;
      alertInfoSettings.ChannelHighPriceLabelColor = InpChannelHighPriceLabelColor;
      alertInfoSettings.ChannelMidPriceLabelColor = InpChannelMidPriceLabelColor;
      alertInfoSettings.ChannelLowPriceLabelColor = InpChannelLowPriceLabelColor;
      
      alertInfoSettings.showNextBarLevels = InpShowNextBarLevels;
      alertInfoSettings.showCurrentBarOpenTime = InpShowCurrentBarOpenTime;
      alertInfoSettings.InfoTextColor = InpInfoTextColor;
      
      #ifdef AMP_VERSION            
      //
         alertInfoSettings.NewBarAlert = InpNewBarAlert; 
         alertInfoSettings.ReversalBarAlert = InpReversalBarAlert;
         alertInfoSettings.MaCrossAlert = InpMaCrossAlert ;    
         alertInfoSettings.UseAlertWindow = InpUseAlertWindow;  
         alertInfoSettings.UseSound = InpUseSound;
         alertInfoSettings.UsePushNotifications = InpUsePushNotifications;
      //   
      #else
      //
         alertInfoSettings.NewBarAlert = (InpAlertMeWhen == ALERT_WHEN_All ||
                                          InpAlertMeWhen == ALERT_WHEN_NewBar ||
                                          InpAlertMeWhen == ALERT_WHEN_NewBarReversal ||
                                          InpAlertMeWhen == ALERT_WHEN_NewBarMaCross) ? BTrue : BFalse;
                                          
         alertInfoSettings.ReversalBarAlert = (InpAlertMeWhen == ALERT_WHEN_All ||
                                          InpAlertMeWhen == ALERT_WHEN_Reversal ||
                                          InpAlertMeWhen == ALERT_WHEN_NewBarReversal ||
                                          InpAlertMeWhen == ALERT_WHEN_ReversalMaCross) ? BTrue : BFalse;
                                          
         alertInfoSettings.BearishReversalAlert = (InpAlertMeWhen == ALERT_WHEN_NewBearishReversal) ? BTrue : BFalse;                                          

         alertInfoSettings.BullishReversalAlert = (InpAlertMeWhen == ALERT_WHEN_NewBullishReversal) ? BTrue : BFalse;                                          
                                          
         alertInfoSettings.MaCrossAlert = (InpAlertMeWhen == ALERT_WHEN_All ||
                                          InpAlertMeWhen == ALERT_WHEN_MaCross ||
                                          InpAlertMeWhen == ALERT_WHEN_NewBarMaCross ||
                                          InpAlertMeWhen == ALERT_WHEN_ReversalMaCross) ? BTrue : BFalse;
         

         alertInfoSettings.UseAlertWindow = (InpAlertNotificationType == ALERT_NOTIFY_TYPE_All ||
                                             InpAlertNotificationType == ALERT_NOTIFY_TYPE_Msg ||
                                             InpAlertNotificationType == ALERT_NOTIFY_TYPE_MsgSound ||
                                             InpAlertNotificationType == ALERT_NOTIFY_TYPE_MsgPush ) ? BTrue : BFalse;
                                             
         alertInfoSettings.UseSound = (InpAlertNotificationType == ALERT_NOTIFY_TYPE_All ||
                                             InpAlertNotificationType == ALERT_NOTIFY_TYPE_Sound ||
                                             InpAlertNotificationType == ALERT_NOTIFY_TYPE_MsgSound ||
                                             InpAlertNotificationType == ALERT_NOTIFY_TYPE_SoundPush ) ? BTrue : BFalse;
         
         alertInfoSettings.UsePushNotifications = (InpAlertNotificationType == ALERT_NOTIFY_TYPE_All ||
                                             InpAlertNotificationType == ALERT_NOTIFY_TYPE_Push ||
                                             InpAlertNotificationType == ALERT_NOTIFY_TYPE_SoundPush ||
                                             InpAlertNotificationType == ALERT_NOTIFY_TYPE_MsgPush ) ? BTrue : BFalse;                                                                                               
      //   
      #endif // AMP_VERSION
      
      alertInfoSettings.SoundFileBull = InpSoundFileBull;
      alertInfoSettings.SoundFileBear = InpSoundFileBear;
      alertInfoSettings.DisplayAsBarChart = InpDisplayAsBarChart;
   
   #endif
#endif
}

