#property copyright "Copyright 2017-2021, Artur Zas"
// GNU General Public License v3.0 -> https://github.com/9nix6/Median-and-Turbo-Renko-indicator-bundle/blob/master/LICENSE
#property link      "https://www.az-invest.eu"
#property version   "1.06"

//#define ULTIMATE_RENKO_LICENSE // uncomment when used on Ultimate Renko chart from https://www.az-invest.eu/ultimate-renko-indicator-generator-for-metatrader-5
//#define VOLUMECHART_LICENSE // uncomment when used on a Tick & Volume bar chart from https://www.az-invest.eu/Tick-chart-and-volume-chart-for-mt5

//
// Uncomment only ONE of the 3 directives listed below and recompile
// -----------------------------------------------------------------
//
//
//#define EA_ON_RANGE_BARS   // Use EA on RangeBar chart 
#define EA_ON_RENKO        // Use EA on Renko charts
//#define EA_ON_XTICK_CHART  // Use EA on XTick Chart
//#define EA_ON_TICK_VOLUME_CHART  // Use EA on Tick & Volume Bar Chart

// Uncomment the directive below and recompile if EA is used with P-Renko BR Ultimate
// ----------------------------------------------------------------------------------
//
// #define P_RENKO_BR_PRO     // Use in P-Renko BR Ultimate version

//
// Uncomment the directive below and recompile for use in a backtest only
// ----------------------------------------------------------------------
//
// #define SHOW_INDICATOR_INPUTS

// Include all needed files

#ifdef EA_ON_RANGE_BARS
   #include <AZ-INVEST/SDK/RangeBars.mqh>
   RangeBars *customBars = NULL;
#endif
#ifdef EA_ON_RENKO
   #include <AZ-INVEST/SDK/MedianRenko.mqh>
   MedianRenko *customBars = NULL;
#endif
#ifdef EA_ON_XTICK_CHART
   #include <AZ-INVEST/SDK/TickChart.mqh>
   TickChart *customBars = NULL;
#endif
#ifdef EA_ON_TICK_VOLUME_CHART
   #include <AZ-INVEST/SDK/VolumeBarChart.mqh>
   TickChart *customBars = NULL;
#endif

#include <AZ-INVEST/SDK/TimeControl.mqh>
#include <AZ-INVEST/SDK/TradeFunctions.mqh>

enum ENUM_TRADE_DIRECTION 
{
   TRADE_DIRECTION_BUY = POSITION_TYPE_BUY,    // Buy
   TRADE_DIRECTION_SELL = POSITION_TYPE_SELL,  // Sell
   TRADE_DIRECTION_ALL = 1000,                 // Buy & Sell
};

// EA input parameters

input double               Lots = 0.1;                                  // Traded lots
input uint                 StopLoss = 0;                                // Stop Loss
input uint                 TakeProfit = 0;                              // Take profit
input int                  ConfirmationBars = 1;                        // Signal confirmation bars
input int                  PrevSignalBars = 1;                          // Prev signal confirmation bars
input ENUM_TRADE_DIRECTION ValidTradeDirection = TRADE_DIRECTION_ALL;   // Valid trading type
input bool                 CloseTradeOnSignalChange = true;             // Close trade on signal change
input bool                 ForceSR = false;                             // Force Stop & Reverse
input bool                 CloseTradeAfterTradingHours = true;          // Close trade after trading hours
input ulong                DeviationPoints = 0;                         // Maximum defiation (in points)
input double               ManualTickSize = 0.000;                      // Tick Size (0 = auto detect) 
input string               Start="9:00";                                // Start trading at 
input string               End="17:55";                                 // End trading at
input ulong                MagicNumber=8888;                            // Assign trade ID 
input int                  NumberOfRetries = 50;                        // Maximum number of retries
input int                  BusyTimeout_ms = 1000;                       // Wait [ms] before retry on bussy errors
input int                  RequoteTimeout_ms = 250;                     // Wait [ms] before retry on requotes

// Global data buffers 

MqlRates RateInfo[];  // Buffer for custom price bars
double MA1[];         // Buffer for moving average 1 

// Read 4 rates MA1 values starting from current (uncompleted) bar

int startAtBar   = 0;   
int numberOfBars;   
int _confirmationBars;
int _prevSignalBars;

// EA variables

CMarketOrder *marketOrder;
CTimeControl *timeControl;

ulong currentTicket;
ENUM_POSITION_TYPE currentPositionType;
ENUM_POSITION_TYPE signal;
ENUM_POSITION_TYPE validation;

#ifdef EA_ON_RANGE_BARS
   static int _MA1 = RANGEBAR_MA1;
   static int _MA2 = RANGEBAR_MA2;
#endif
#ifdef EA_ON_RENKO
   static int _MA1 = RENKO_MA1;
   static int _MA2 = RENKO_MA2;
#endif
#ifdef EA_ON_XTICK_CHART
   static int _MA1 = TICKCHART_MA1;
   static int _MA2 = TICKCHART_MA2;
#endif
#ifdef EA_ON_TICK_VOLUME_CHART
   static int _MA1 = VOLUMECHART_MA1;
   static int _MA2 = VOLUMECHART_MA2;
#endif

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(customBars == NULL)
   {
      #ifdef EA_ON_RANGE_BARS
         customBars = new RangeBars(MQLInfoInteger((int)MQL5_TESTING) ? false : true);
      #endif
      #ifdef EA_ON_RENKO
         customBars = new MedianRenko(MQLInfoInteger((int)MQL5_TESTING) ? false : true);
      #endif
      #ifdef EA_ON_XTICK_CHART   
         customBars = new TickChart(MQLInfoInteger((int)MQL5_TESTING) ? false : true);
      #endif   
      #ifdef EA_ON_TICK_VOLUME_CHART
         customBars = new TickChart(MQLInfoInteger((int)MQL5_TESTING) ? false : true);
      #endif         
   }

   customBars.Init();
   
   signal = POSITION_TYPE_NONE;
   _confirmationBars = (ConfirmationBars < 1) ? 1 : ConfirmationBars;
   _prevSignalBars = (PrevSignalBars < 1) ? 1 : PrevSignalBars;
   numberOfBars = _confirmationBars + _prevSignalBars + 1; 
   
   CMarketOrderParameters params;
   {
      params.m_async_mode = false;
      params.m_magic = MagicNumber;
      params.m_deviation = DeviationPoints;
      params.m_type_filling = ORDER_FILLING_FOK;
      
      params.numberOfRetries = NumberOfRetries;
      params.busyTimeout_ms = BusyTimeout_ms; 
      params.requoteTimeout_ms = RequoteTimeout_ms;         
   }
   
   marketOrder = new CMarketOrder(params);
   
   if(timeControl == NULL)
   {
      timeControl = new CTimeControl();
   }
   
   timeControl.SetValidTraingHours(Start,End);
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   customBars.Deinit();

   //  delete TimeControl class
   
   if(timeControl != NULL)
   {
      delete timeControl;
      timeControl = NULL;
   }
      
   //  delete MarketOrder class
   
   if(marketOrder != NULL)
   {
      delete marketOrder;
      marketOrder = NULL;
   }
  
   // delete MedianRenko class
   
   if(customBars != NULL)
   {
      delete customBars;
      customBars = NULL;
   }   
      
   Comment("");
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(marketOrder == NULL)
      return;
      
   if(customBars.IsNewBar())
   {
      if(timeControl.IsScheduleEnabled())
      {
         Comment("EA trading schedule ON ("+Start+" to "+End+") | trading enabled = "+(string)timeControl.IsTradingTimeValid());
      }
      else
      {
         Comment("EA trading schedule OFF");
      }
             
      if(!timeControl.IsTradingTimeValid())
      {
         if(marketOrder.IsOpen(currentTicket,_Symbol,MagicNumber))
         {
            if(currentTicket > 0 && CloseTradeAfterTradingHours)
            {
               // close position outside of trading hours
               marketOrder.Close(currentTicket);
            }
         }

         return;
      }
         
      //
      //  Get MqlRateInfo & moving average values for current, last completed bar and the bar before that...
      //
      
      if(!customBars.GetMqlRates(RateInfo,startAtBar,numberOfBars))
      {
         Print("Error getting MqlRates for custom chart");
      }
      else if(!customBars.GetMA(_MA1, MA1, startAtBar, numberOfBars))
      {
         Print("Error getting values from MA1 - please enable MA1 on chart");
      }
      else
      {
        
         signal = PriceAndMovingAverageCross(_confirmationBars, _prevSignalBars);
  
         if(timeControl.IsScheduleEnabled())
         {
            Comment("EA trading schedule ("+Start+" to "+End+") | trading enabled = "+(string)timeControl.IsTradingTimeValid()+
            "\n MA_1 [2]: "+DoubleToString(MA1[2],_Digits)+" [1]: "+DoubleToString(MA1[1],_Digits)+
            "\n Close[2]: "+DoubleToString(RateInfo[2].close,_Digits)+" [1]: "+DoubleToString(RateInfo[1].close,_Digits)+
            "\n Price & MA cross signal = "+marketOrder.PositionTypeToString(signal)+
            "\n");
         }
         else
         {
            Comment("EA trading schedule not used. Trading is enabled."+
            "\n MA_1 [2]: "+DoubleToString(MA1[2],_Digits)+" [1]: "+DoubleToString(MA1[1],_Digits)+
            "\n Close[2]: "+DoubleToString(RateInfo[2].close,_Digits)+" [1]: "+DoubleToString(RateInfo[1].close,_Digits)+
            "\n Price & MA cross signal = "+marketOrder.PositionTypeToString(signal)+
            "\n");
         }

         if(signal == POSITION_TYPE_BUY)
         {
            if(marketOrder.IsOpen(currentTicket,_Symbol,POSITION_TYPE_SELL,MagicNumber))
            {
               if(currentTicket > 0 && ForceSR)
               {
                  if(IsTradeDirectionValid(POSITION_TYPE_SELL))
                  {
                     PrintFormat("Reversing %s position on Stop&Reverse condition (ticket:%d)", _Symbol, currentTicket);
                     marketOrder.Reverse(currentTicket,Lots,StopLoss,TakeProfit);
                  }
               }  
               else if(currentTicket > 0)
               {
                  // close trade on signal change
                  if(CloseTradeOnSignalChange)
                  {
                     PrintFormat("Closing %s position on signal change (ticket:%d)", _Symbol, currentTicket);
                     marketOrder.Close(currentTicket);                  
                  }
               }
               return;
            }
            
            if(!marketOrder.IsOpen(_Symbol,POSITION_TYPE_BUY,MagicNumber))
            {
               if(IsTradeDirectionValid(POSITION_TYPE_BUY))
                  marketOrder.Long(_Symbol,Lots,StopLoss,TakeProfit);
                  
               return;
            }
         }
         else if(signal == POSITION_TYPE_SELL)
         {
            if(marketOrder.IsOpen(currentTicket,_Symbol,POSITION_TYPE_BUY,MagicNumber))
            {
               if(currentTicket > 0 && ForceSR)
               {
                  if(IsTradeDirectionValid(POSITION_TYPE_BUY))
                  {
                     PrintFormat("Reversing %s position on Stop&Reverse condition (ticket:%d)", _Symbol, currentTicket);
                     marketOrder.Reverse(currentTicket,Lots,StopLoss,TakeProfit);
                  }
               }   
               else if(currentTicket > 0)
               {
                  // close trade on signal change
                  if(CloseTradeOnSignalChange)
                  {
                     PrintFormat("Closing %s position on signal change (ticket:%d)", _Symbol, currentTicket);
                     marketOrder.Close(currentTicket);                                    
                  }
               }
               return;
            }

            if(!marketOrder.IsOpen(_Symbol,POSITION_TYPE_SELL,MagicNumber))
            {
               if(IsTradeDirectionValid(POSITION_TYPE_SELL))
                  marketOrder.Short(_Symbol,Lots,StopLoss,TakeProfit);
                  
               return;
            }
         }         
      }      
   } 
}

//
// Trade direction validation (Is it OK to trade in the given direction?)
//

bool IsTradeDirectionValid(ENUM_POSITION_TYPE signalDirection)
{
   if(ValidTradeDirection == TRADE_DIRECTION_ALL)
      return true;
      
   if(signalDirection == POSITION_TYPE_BUY && ValidTradeDirection == TRADE_DIRECTION_BUY)
      return true;
   else if(signalDirection == POSITION_TYPE_SELL && ValidTradeDirection == TRADE_DIRECTION_SELL)
      return true;
   else      
      return false;
}

//
// Price & MA cross logic
//

ENUM_POSITION_TYPE PriceAndMovingAverageCross(int confirmationBars, int prevSignalBars)
{
   if(numberOfBars < confirmationBars+1)
   {
      Alert("Invalid number of MqlRates and MA readings defined! Crossover cannot be determined.");
      return POSITION_TYPE_NONE;
   }
   
   bool confirmedSell = true;
   bool confirmedBuy  = true;

   // check trailing bar for confirmation of previous signal   
   for(int i=(confirmationBars+1); i<=(confirmationBars+prevSignalBars); i++)
   {
      if(RateInfo[i].close > MA1[i])
      {
        confirmedBuy = false;
      }
      else if(RateInfo[i].close < MA1[i])
      {
         confirmedSell = false;
      }
   }
      
   // check confirmation bars for current signal
   for(int i=1; i<=confirmationBars; i++)
   {
      if(RateInfo[i].close == MA1[i])
      {
         confirmedSell = false;
         confirmedBuy  = false;
      }
      else if(RateInfo[i].close < MA1[i])
      {
         confirmedBuy  = false;
      }
      else if(RateInfo[i].close > MA1[i])
      {
         confirmedSell = false;
      }
   }
   
   // signal aggregate
   if(confirmedSell)
      return POSITION_TYPE_SELL;
   else if(confirmedBuy)
      return POSITION_TYPE_BUY;
   else
      return POSITION_TYPE_NONE;
}

