#property copyright "Copyright 2017, AZ-iNVEST"
#property link      "http://www.az-invest.eu"
#property version   "2.00"
#property description "Example EA showing the way to use the MedianRenko class defined in MedianRenko.mqh" 

//
// You need to include the MedianRenko.mqh header file
//

#include "MedianRenko.mqh"

//
//  To use the MedainRenko indicator in your EA you need do instantiate the indicator class (MedianRenko)
//  and call the Init() method in your EA's OnInit() function.
//  Don't forget to release the indicator when you're done by calling the Deinit() method.
//  Example shown in OnInit & OnDeinit functions below:
//

MedianRenko * medianRenko;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   medianRenko = new MedianRenko(); 
   if(medianRenko == NULL)
      return(INIT_FAILED);
   
   medianRenko.Init();
   if(medianRenko.GetHandle() == INVALID_HANDLE)
      return(INIT_FAILED);
   
   //
   //  your custom code goes here...
   //
   
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
   
   //
   //  your custom code goes here...
   //
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
      //
      //  There are two methods for getting the Moving Average values.
      //  The example below gets the moving average values for 3 latest bars
      //  counting to the left from the most current (uncompleted) bar.
      //
      
      int startAtBar = 0;   // get value starting from the most current (uncompleted) bar.
      int numberOfBars = 3; // gat a total of 3 MA values (for the 3 latest bars)
      
      //
      // Values will be stored in 2 arrays defined below
      //
      
      double MA1[]; // array to be filled by values of the first moving average
      double MA2[]; // array to be filled by values of the second moving average
      
      if(medianRenko.GetMA1(MA1,startAtBar,numberOfBars) && medianRenko.GetMA1(MA2,startAtBar,numberOfBars))
      {
         //
         // Values are stored in the MA1 and MA2 arrays and are now ready for use
         //
         // MA1[0] contains the 1st moving average value for the latest (uncompleted) bar
         // MA1[1] contains the 1st moving average value for the 1st bar to the left from the latest (uncompleted) bar
         // MA1[2] contains the 1st moving average value for the 2nd bar to the left from the latest (uncompleted) bar
         // MA1[3]..MA1[n] do not exist since we retrieved the values for 3 bars (defined by "numnberOfBars")
         //
         // The values for the 2nd moving average are stored in MA2[] and are accessed identically to values of MA1[] (shown above)
      }
      
      //
      // Getting the MqlRates info for renko bars is done using the
      // GetMqlRates(MqlRates &ratesInfoArray[], int start, int count) 
      // method. Example below:
      //
      
      MqlRates RenkoRatesInfoArray[];  // This array will store the MqlRates data for renkos
      startAtBar = 1;                  // get values starting from the last completed bar.
      numberOfBars = 2;                // gat a total of 2 MqlRates values (for 2 bars starting from bar 1 (last completed))
      
      if(medianRenko.GetMqlRates(RenkoRatesInfoArray,startAtBar,numberOfBars))
      {
         //
         //  Check if a renko reversal bar has formed
         //
         
         if((RenkoRatesInfoArray[0].open < RenkoRatesInfoArray[0].close) &&
            (RenkoRatesInfoArray[1].open > RenkoRatesInfoArray[1].close))
         {
            // bullish reversal
         }
         else if((RenkoRatesInfoArray[0].open > RenkoRatesInfoArray[0].close) &&
            (RenkoRatesInfoArray[1].open < RenkoRatesInfoArray[1].close))
         {
            // bearish reversal
         }
      }
      
      //
      // Getting Donchain channel values is done using the
      // GetDonchian(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count) 
      // method. Example below:
      //
      
      double HighArray[];  // This array will store the values of the high band
      double MidArray[];   // This array will store the values of the middle band
      double LowArray[];   // This array will store the values of the low band
      startAtBar = 1;      // get values starting from the last completed bar.
      numberOfBars = 20;   // gat a total of 20 values (for 20 bars starting from bar 1 (last completed))
      
      if(medianRenko.GetDonchian(HighArray,MidArray,LowArray,startAtBar,numberOfBars))
      {
         //
         // Apply your Donchian channel logic here...
         //
      }
      
      //
      // Getting Bollinger Bands values is done using the
      // GetBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count) 
      // method. Example below:
      //
      
      // HighArray[] array will store the values of the high band
      // MidArray[] array will store the values of the middle band
      // LowArray[] array will store the values of the low band
      
      startAtBar = 1;      // get values starting from the last completed bar.
      numberOfBars = 10;   // gat a total of 10 values (for 10 bars starting from bar 1 (last completed))     
      
      if(medianRenko.GetBollingerBands(HighArray,MidArray,LowArray,startAtBar,numberOfBars))
      {
         //
         // Apply your Bollinger Bands logic here...
         //
      } 
      
   } 
}
