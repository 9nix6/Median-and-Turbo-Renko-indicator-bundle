//
// Copyright 2017-2019, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

#property copyright "Copyright 2017-2020, AZ-iNVEST"
#property link      "http://www.az-invest.eu"
#property version   "1.22"
#property description "Example EA: Trading based on Renko SuperTrend signals." 
#property description "One trade at a time. Each trade has TP & SL" 
#property strict
//#define DEVELOPER_VERSION

// #define IS_DEBUG // Uncomment for additional messages in the "Experts" tab

//
// Helper functions for placing market orders.
//

#include <AZ-INVEST/SDK/TradeFunctions.mqh>

//
//  Inputs
//

input double   InpLotSize = 0.1;
input int      InpSLPoints = 200;
input int      InpTPPoints = 400;

input ulong    InpMagicNumber=5150;
input ulong    InpDeviationPoints = 0;
input int      InpNumberOfRetries = 50;
input int      InpBusyTimeout_ms = 1000; 
input int      InpRequoteTimeout_ms = 250;

//
//  Globa variables
//

ENUM_POSITION_TYPE Signal;
ulong currentTicket;

//
// SHOW_INDICATOR_INPUTS *NEEDS* to be defined, if the EA needs to be *tested in MT5's backtester*
// -------------------------------------------------------------------------------------------------
// Using '#define SHOW_INDICATOR_INPUTS' will show the MedianRenko indicator's inputs 
// NOT using the '#define SHOW_INDICATOR_INPUTS' statement will read the settigns a chart with 
// the MedianRenko indicator attached.
//

#define SHOW_INDICATOR_INPUTS

//
// You need to include the MedianRenko.mqh header file
//

#include <AZ-INVEST/SDK/MedianRenko.mqh>
//
//  To use the MedainRenko indicator in your EA you need do instantiate the indicator class (MedianRenko)
//  and call the Init() method in your EA's OnInit() function.
//  Don't forget to release the indicator when you're done by calling the Deinit() method.
//  Example shown in OnInit & OnDeinit functions below:
//

MedianRenko    *medianRenko = NULL;
CMarketOrder   *marketOrder = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(medianRenko == NULL)
       medianRenko = new MedianRenko(MQLInfoInteger((int)MQL5_TESTING) ? false : true);
   
   medianRenko.Init();
   if(medianRenko.GetHandle() == INVALID_HANDLE)
      return(INIT_FAILED);
   
   //
   //  Init MarketOrder class - used for placing market orders.
   //
   
   CMarketOrderParameters params;
   {
      params.m_async_mode = false;
      params.m_magic = InpMagicNumber;
      params.m_deviation = InpDeviationPoints;
      params.m_type_filling = ORDER_FILLING_FOK;
      
      params.numberOfRetries = InpNumberOfRetries;
      params.busyTimeout_ms = InpBusyTimeout_ms; 
      params.requoteTimeout_ms = InpRequoteTimeout_ms;         
   }
   
   if(marketOrder == NULL)
      marketOrder = new CMarketOrder(params);
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   medianRenko.Deinit();
   
   //
   //  delete MarketOrder class
   //
   
   if(marketOrder != NULL)
   {
      delete marketOrder;
      marketOrder = NULL;
   }
  
   // 
   // delete MedianRenko class
   //
   
   if(medianRenko != NULL)
   {
      delete medianRenko;
      medianRenko = NULL;
   }   
}

//
//  At this point you may use the renko data fetching methods in your EA.
//  Brief demonstration presented below in the OnTick() function:
//

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //
   // It is considered good trading & EA coding practice to perform calculations
   // when a new bar is fully formed. 
   // The IsNewBar() method is used for checking if a new renko bar has formed 
   //
   
   if(medianRenko.IsNewBar())
   {
      #ifdef IS_DEBUG
         Print("New bar");
      #endif
      
      //
      // Getting SuperTrend values is done using the
      // GetSuperTrend(double &SuperTrendHighArray[], double &SuperTrendArray[], double &SuperTrendLowArray[], int start, int count) 
      // method. Example below:
      //

      double HighArray[];     // This array will store the values of the high SuperTrend line
      double MidArray[];      // This array will store the values of the middle SuperTrend line
      double LowArray[];      // This array will store the values of the low SuperTrend line
      
      int startAtBar   = 1;   // get values starting from the last completed bar.
      int numberOfBars = 2;   // gat a total of 3 values (for 3 bars starting from bar 1 (last completed))     
            
      if(medianRenko.GetChannel(HighArray,MidArray,LowArray,startAtBar,numberOfBars))
      {
         //
         // Read signal bar's time for optional debug log
         //

         string barTime = "";                     
         MqlRates RenkoRatesInfoArray[];  // This array will store the MqlRates data for renkos
         if(medianRenko.GetMqlRates(RenkoRatesInfoArray,startAtBar,numberOfBars))
            barTime = (string)RenkoRatesInfoArray[0].time;
         //
         //
         //

         if(SuperTrendSignal(HighArray,MidArray,LowArray,Signal,barTime))
         {         
            if(Signal == POSITION_TYPE_NONE)
               return;
               
            //
            // Trade signal on the SuperTrend indicator
            // Open trade only if there are currntly no active trades
            //
          
            if(!marketOrder.IsOpen(currentTicket,_Symbol,InpMagicNumber))
            {
               if(Signal == POSITION_TYPE_BUY)
               {
                  #ifdef IS_DEBUG
                     Print("BUY signal at "+barTime); // optional debug log
                  #endif
                  
                  if(marketOrder.Long(_Symbol,InpLotSize,InpSLPoints,InpTPPoints))
                  {
                     Print("Long position opened.");
                  }
               }  
               else if(Signal == POSITION_TYPE_SELL)
               {
                  #ifdef IS_DEBUG
                     Print("SELL singal at "+barTime); // optional debug log
                  #endif
                  
                  if(marketOrder.Short(_Symbol,InpLotSize,InpSLPoints,InpTPPoints))
                  {
                     Print("Short position opened.");
                  }
               }
            }
         }         
      }       
   } 
}

//
// Function determines the trade signal on the SuperTrend indicator
//

bool SuperTrendSignal(double &H[], double &M[], double &L[], ENUM_POSITION_TYPE &signal,string time)
{
   if((H[1] == 0) && (L[1] == 0)) // no data to process
   {
      signal = POSITION_TYPE_NONE;
      return false;
   }

   #ifdef IS_DEBUG
      Print(time+": H[1] = "+DoubleToString(H[1],_Digits)+" L[0] = "+DoubleToString(L[0],_Digits)+" | L[1] = "+DoubleToString(L[1],_Digits)+" H[0] = "+DoubleToString(H[0],_Digits));
   #endif
   
   if((H[1] == M[1]) && (L[0] == M[0]))
   {
      //
      // Super trend shifted from Low to High band => Buy Signal
      //
      
      signal = POSITION_TYPE_BUY;
      return true;
   }
   else if((L[1] == M[1]) && (H[0] == M[0]))
   {
      //
      // Super trend shifted from High to Low band => Sell Signal
      //
      
      signal = POSITION_TYPE_SELL;
      return true;
   }
   
   //
   // No signal detected
   //
   
   signal = POSITION_TYPE_NONE;
   return false; 
}