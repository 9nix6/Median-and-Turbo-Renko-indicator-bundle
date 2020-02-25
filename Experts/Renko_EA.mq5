//
// Copyright 2018-2020, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//
// Renko_EA uses "Median and Turbo renko indicator bundle" for the renko chart.
// You can get this indicator from MQL5 market: 
// https://www.mql5.com/en/market/product/16347
// 

//
// SHOW_INDICATOR_INPUTS *NEEDS* to be defined, if the EA needs to be *tested in MT5's backtester*
// -------------------------------------------------------------------------------------------------
// Using '#define SHOW_INDICATOR_INPUTS' will show the MedianRenko indicator's inputs 
// NOT using the '#define SHOW_INDICATOR_INPUTS' statement will read the settigns a chart with 
// the MedianRenko indicator attached.
//

// #define SHOW_INDICATOR_INPUTS

#define SHOW_DEBUG
#ifdef _DEBUG
   #ifndef SHOW_DEBUG
      #define SHOW_DEBUG
   #endif
#endif

#include "Renko_EA_Logic.mqh"

//
//  Inputs
//

input string            InpComment0          = "==============";  // EA settings
input ENUM_TRADING_MODE InpMode              = TRADING_MODE_ALL;  // Trading mode
input int               InpOpenXSignal       = 1;                 // Open signal confirmation bars
input int               InpCloseXSignal      = 1;                 // Close signal confirmation bars
input double            InpLotSize           = 0.1;               // Lot size
input int               InpSLPoints          = 200;               // StopLoss (Points) [ 0 = OFF ]
input int               InpTPPoints          = 400;               // TakeProfit (Points) [ 0 = OFF ]
input string            InpComment1          = "Stop & Reverse";  // *** If StopLoss & TakeProfit = 0
input int               InpBEPoints          = 0;                 // BreakEven (Points) [ 0 = OFF ]
input int               InpTrailByPoints     = 100;               // Trail by (Points) [ 0 = OFF ]
input int               InpTrailStartPoints  = 150;               // Start trailing after (Points)

input string            InpStart             = "9:00";            // Start trading at (24h server time)
input string            InpEnd               = "16:00";           // End trading at (24h server time)
input string            InpComment2          = "Always trade";    // *** If Start = "0" & End = "0" =>
input bool              InpCloseTradesEOD    = false;             // Close trades at "End trading" time

input ENUM_FILTER_MODE  InpMA1Filter         = FILTER_MODE_OFF;   // Use MA1 filter
input ENUM_FILTER_MODE  InpMA2Filter         = FILTER_MODE_OFF;   // Use MA2 filter
input ENUM_FILTER_MODE  InpMA3Filter         = FILTER_MODE_OFF;   // Use MA3 filter
input ENUM_FILTER_MODE  InpSuperTrendFilter  = FILTER_MODE_OFF;   // Use SuprTrend filter

input ulong             InpMagicNumber       = 82;                // EA magic number (Trade ID)
input ulong             InpDeviationPoints   = 0;                 // Maximum deviation points
input int               InpNumberOfRetries   = 15;                // Max. number of retries
input int               InpBusyTimeout_ms    = 1000;              // Server busy timeount [ms]
input int               InpRequoteTimeout_ms = 250;               // Requote timeout [ms]

MedianRenko * medianRenko;
CEaLogic eaLogic;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   medianRenko = new MedianRenko(MQLInfoInteger((int)MQL5_TESTING) ? false : true);
   if(medianRenko == NULL)
      return(INIT_FAILED);
      
   medianRenko.Init();
   if(medianRenko.GetHandle() == INVALID_HANDLE)
      return(INIT_FAILED);
  
   CEaLogicPartameters params;
   {
      params.TradingMode         = InpMode;
      params.OpenXSignal         = InpOpenXSignal;
      params.CloseXSignal        = InpCloseXSignal;
      params.LotSize             = InpLotSize;
      params.SLPoints            = InpSLPoints;
      params.TPPoints            = InpTPPoints;
      params.BEPoints            = InpBEPoints;
      params.TrailByPoints       = InpTrailByPoints;
      params.TrailStartPoints    = InpTrailStartPoints;
      params.StartTrading        = InpStart;
      params.EndTrading          = InpEnd;
      params.CloseEOD            = InpCloseTradesEOD;
      params.MA1Filter           = InpMA1Filter;
      params.MA2Filter           = InpMA2Filter;
      params.MA3Filter           = InpMA3Filter;
      params.SuperTrendFilter    = InpSuperTrendFilter;
      params.MagicNumber         = InpMagicNumber;
      params.DeviationPoints     = InpDeviationPoints;
      params.NumberOfRetries     = InpNumberOfRetries;
      params.BusyTimeout_ms      = InpBusyTimeout_ms;
      params.RequoteTimeout_ms   = InpRequoteTimeout_ms;
   }
   
   if(!eaLogic.Initialize(params, medianRenko))
      return(INIT_FAILED);
       
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(medianRenko != NULL)
   {
      medianRenko.Deinit();
      delete medianRenko;
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(eaLogic.OkToStartBacktest()) // wait with backtest for enough bars based on MA settings.   
      eaLogic.Run();
}
