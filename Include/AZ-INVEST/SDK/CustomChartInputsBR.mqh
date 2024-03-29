#property copyright "Copyright 2018-2021, Level Up Software"
#property link      "https://www.az-invest.eu"

#include <AZ-INVEST/SDK/CommonSettings.mqh>

#ifdef SHOW_INDICATOR_INPUTS
         
   #ifdef USE_CUSTOM_SYMBOL
   
      input group                      "### Diversos"
      input string                     InpCustomChartName = "";                        // Substituir o nome do gráfico personalizado (custom) por
      input string                     InpApplyTemplate = "default";                   // Aplicar um template ao gráfico personalizado
      input ENUM_BOOL                  InpForceFasterRefresh = true;                   // Forçar atualização mais rápida do gráfico
      input ENUM_BOOL                  InpForBacktester = false;                       // Criar gráfico apenas para backtest
      input ENUM_BOOL                  InpShowTradeLevels = false;                     // Mostrar os níveis de comércio no gráfico
   
   #endif // end of USE_CUSTOM_SYMBOL
      
   #ifndef USE_CUSTOM_SYMBOL // Main Inputs block
       
      input group                   "### Pivots"

      input ENUM_PIVOT_POINTS       InpShowPivots = ppNone;                            // Mostrar Níveis de Pivô
      input ENUM_PIVOT_TYPE         InpPivotPointCalculationType = ppHLC3;             // Cálculo do Ponto de Pivô
            ENUM_BOOL               InpShowNextBarLevels = false;                      // Mostrar projeção de fechamento do box
//            color                   InpHighThresholdIndicatorColor = clrLime;          // Cor da projetção do box de alta
//            color                   InpLowThresholdIndicatorColor = clrRed;            // Cor da projetção do box de baixa
            color                   InpInfoTextColor = clrNONE;                        // Cor da informação do horário de abertura da barra atual
      
      input group                   "### Alertas"
      
      input ENUM_ALERT_WHEN         InpAlertMeWhen = ALERT_WHEN_None;                  // Condição de Alerta
      input ENUM_ALERT_NOTIFY_TYPE  InpAlertNotificationType = ALERT_NOTIFY_TYPE_None; // Tipo de Notificação do Alerta
      
      input group                   "### Médias móveis"
      
      input ENUM_MA_LINE_TYPE       InpMA1lineType = MA_NONE;                          // Média Móvel 1
      input int                     InpMA1period = 9;                                  // Período da 1a. Média Móvel
      input ENUM_MA_METHOD_EXT      InpMA1method =  _MODE_EMA;                         // Tipo da 1a. Média Móvel
      input ENUM_APPLIED_PRICE      InpMA1applyTo = PRICE_CLOSE;                       // Aplicar a
      input int                     InpMA1shift = 0;                                   // Deslocamento 1a. Média Móvel
      input ENUM_BOOL               InpMA1priceLabel = false;                          // Exibir preço da 1a. Média Móvel
      
      input ENUM_MA_LINE_TYPE       InpMA2lineType = MA_NONE;                          // Média Móvel 2
      input int                     InpMA2period = 86;                                 // Período da 2a. Média Móvel
      input ENUM_MA_METHOD_EXT      InpMA2method = _LINEAR_REGRESSION;                 // Tipo da 2a. Média Móvel
      input ENUM_APPLIED_PRICE      InpMA2applyTo = PRICE_CLOSE;                       // Aplicar a
      input int                     InpMA2shift = 0;                                   // Deslocamento 2a. Média Móvel
      input ENUM_BOOL               InpMA2priceLabel = false;                          // Exibir preço da 2a. Média Móvel
      
      input ENUM_MA_LINE_TYPE       InpMA3lineType = MA_NONE;                          // Média Móvel 3
      input int                     InpMA3period = 20;                                 // Período da 3a. Média Móvel
      input ENUM_MA_METHOD_EXT      InpMA3method = _VWAP_TICKVOL;                      // Tipo da 3a. Média Móvel
      input ENUM_APPLIED_PRICE      InpMA3applyTo = PRICE_CLOSE;                       // Aplicar a
      input int                     InpMA3shift = 0;                                   // Deslocamento 3a. Média Móvel
      input ENUM_BOOL               InpMA3priceLabel = false;                          // Exibir preço da 3a. Média Móvel

      input ENUM_MA_LINE_TYPE       InpMA4lineType = MA_NONE;                          // Média Móvel 4
      input int                     InpMA4period = 21;                                 // Período da 4a. Média Móvel
      input ENUM_MA_METHOD_EXT      InpMA4method = _MODE_SMA;                          // Tipo da 4a. Média Móvel
      input ENUM_APPLIED_PRICE      InpMA4applyTo = PRICE_CLOSE;                       // Aplicar a
      input int                     InpMA4shift = 0;                                   // Deslocamento 4a. Média Móvel
      input ENUM_BOOL               InpMA4priceLabel = false;                          // Exibir preço da 4a. Média Móvel
      
      input group                   "### Canal"
      
      input ENUM_CHANNEL_TYPE       InpShowChannel = _None;                            // Mostrar Bandas & Canais
      input int                     InpChannelPeriod = 20;                             // Período dos Canais
      input int                     InpChannelAtrPeriod = 10;                          // Período ATR do Canais
      input ENUM_APPLIED_PRICE      InpChannelAppliedPrice = PRICE_CLOSE;              // Aplicar Canais em
      input double                  InpChannelMultiplier = 2;                          // Multiplicador dos Canais
      input double                  InpChannelBandsDeviations = 2.0;                   // Desvio das Banda
      input ENUM_CHANNEL_LABEL_DISP InpChannelPriceLabels = LABEL_NONE;                // Exibir preço das bandas
                        
      input group                   "### Diversos"
                        
      input ENUM_BOOL               InpUsedInEA = false;                               // Indicator used in EA via iCustom() 
      
      input string                  InpTradingSessionTime = "00:00-00:00";             // Horário da Sessão de Trade
      input double                  InpTopBottomPaddingPercentage = 0.30;              // Ajuste de plotagem margens (0.0 - 1.0)
      input color                   InpRColor = clrDodgerBlue;                         // Cor da linha de Resistência
      input color                   InpPColor = clrGold;                               // Cor da linha de Pivô
      input color                   InpSColor = clrFireBrick;                          // Cor da linha de Resistência
      input color                   InpPDHColor = clrHotPink;                          // Cor da máxima do dia anterior
      input color                   InpPDLColor = clrLightSkyBlue;                     // Cor da mínima do dia anterior
      input color                   InpPDCColor = clrGainsboro;                        // Cor do fechamento do dia anterior    
      
#ifdef USES_PRICE_PROJECTIONS      
      input color                   InpHighThresholdIndicatorColor = clrGreen;         // Cor da projetção do box de alta
      input color                   InpLowThresholdIndicatorColor = clrFireBrick;      // Cor da projetção do box de baixa
#endif 
#ifdef USES_COUNTER
      input color                   InpCounterColor = clrGold;                         // Counter color
#endif
      input color                   InpMA1PriceLabelColor = clrWhiteSmoke;             // Cor da etiqueta da MA1
      input color                   InpMA2PriceLabelColor = clrWhiteSmoke;             // Cor da etiqueta da MA2
      input color                   InpMA3PriceLabelColor = clrWhiteSmoke;             // Cor da etiqueta da MA3
      input color                   InpMA4PriceLabelColor = clrWhiteSmoke;             // Cor da etiqueta da MA4
      input color                   InpChannelHighPriceLabelColor = clrWhiteSmoke;     // Cor da etiqueta do canal/banda superior
      input color                   InpChannelMidPriceLabelColor = clrWhiteSmoke;      // Cor da etiqueta do canal/banda central
      input color                   InpChannelLowPriceLabelColor = clrWhiteSmoke;      // Cor da etiqueta do canal/banda inferior
        
      input ENUM_BOOL               InpShowCurrentBarOpenTime = true;                  // Mostrar informações do gráfico
      input string                  InpSoundFileBull = "news.wav";                     // Som do fechamento de box de alta
      input string                  InpSoundFileBear = "timeout.wav";                  // Som do fechamento de box de baixa      
      input ENUM_BOOL               InpDisplayAsBarChart = false;                      // Mostrar em forma de barras
      input ENUM_BOOL               InpShiftObj = false;                               // Deslocar objetos com gráfico

   #endif // !USE_CUSTOM_SYMBOL

#else // don't SHOW_INDICATOR_INPUTS

   //
   //  This block sets default values
   //
   
   string                     InpTradingSessionTime = "0:0-0:0"; 
   double                     InpTopBottomPaddingPercentage = 0;
   ENUM_PIVOT_POINTS          InpShowPivots = ppNone;
   ENUM_PIVOT_TYPE            InpPivotPointCalculationType = ppHLC3;
   color                      InpRColor = clrNONE;
   color                      InpPColor = clrNONE;
   color                      InpSColor = clrNONE;
   color                      InpPDHColor = clrNONE;
   color                      InpPDLColor = clrNONE;
   color                      InpPDCColor = clrNONE;
   
   color                      InpHighThresholdIndicatorColor = clrNONE;
   color                      InpLowThresholdIndicatorColor = clrNONE;
   color                      InpCounterColor = clrNONE;
   color                      InpMA1PriceLabelColor = clrNONE;
   color                      InpMA2PriceLabelColor = clrNONE;
   color                      InpMA3PriceLabelColor = clrNONE;
   color                      InpMA4PriceLabelColor = clrNONE;
   color                      InpChannelHighPriceLabelColor = clrNONE;
   color                      InpChannelMidPriceLabelColor = clrNONE;
   color                      InpChannelLowPriceLabelColor = clrNONE;
   
   ENUM_BOOL                  InpShowNextBarLevels = false;
   ENUM_BOOL                  InpShowCurrentBarOpenTime = false;
   color                      InpInfoTextColor = clrNONE;
   
   ENUM_ALERT_WHEN            InpAlertMeWhen = ALERT_WHEN_None;  
   ENUM_ALERT_NOTIFY_TYPE     InpAlertNotificationType = ALERT_NOTIFY_TYPE_None; 
      
   string                     InpSoundFileBull = "";
   string                     InpSoundFileBear = "";
   ENUM_BOOL                  InpDisplayAsBarChart = true;
   ENUM_BOOL                  InpShiftObj = false;
   ENUM_BOOL                  InpUsedInEA = true; // This should always be set to TRUE for EAs & Indicators
          
#endif // SHOW_INDICATOR_INPUTS
