//
// Copyright 2018, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

enum ENUM_FILTER_MODE
{
   FILTER_MODE_OFF,        // OFF
   FILTER_MODE_ENTRY,      // ON for entry
   FILTER_MODE_EXIT,       // ON for exit
   FILTER_MODE_ENTRY_EXIT, // ON for entry & exit
};

class CFilters
{
   public:
       CFilters();
       ~CFilters();
       
   virtual bool OpenOrCloseAboveValue(MqlRates &lastCompletedBar, double compareToValue);
   virtual bool OpenOrCloseBelowValue(MqlRates &lastCompletedBar, double compareToValue);
   virtual bool CloseAtOrAboveValue(MqlRates &currentUncompletedBar, double compareToValue);
   virtual bool CloseAtOrBelowValue(MqlRates &currentUncompletedBar, double compareToValue);
   
   virtual bool MaCrossUp(double &valuesFast[], double &valuesSlow[]);
   virtual bool MaCrossDown(double &valuesFast[], double &valuesSlow[]);
};

CFilters::CFilters(void)
{
}

CFilters::~CFilters(void)
{
}

//
// Last completed bar's open OR close values are above VALUE
//

bool CFilters::OpenOrCloseAboveValue(MqlRates &lastCompletedBar, double compareToValue)
{
   if((compareToValue == 0) || (lastCompletedBar.open == 0) || (lastCompletedBar.close == 0))
      return false;      
      
   if((lastCompletedBar.open > compareToValue) ||
      (lastCompletedBar.close > compareToValue))
      {
         #ifdef SHOW_DEBUG 
            Print("DEBUG: ",__FUNCTION__," => compareToValue:",compareToValue," lastCompletedBar.open:",lastCompletedBar.open," lastCompletedBar.close:",lastCompletedBar.close);
         #endif
      
         return true;
      }         
   return false;
}

//
// Last completed bar's open OR close values are below VALUE
//

bool CFilters::OpenOrCloseBelowValue(MqlRates &lastCompletedBar, double compareToValue)
{
   if((compareToValue == 0) || (lastCompletedBar.open == 0) || (lastCompletedBar.close == 0))
      return false;
      
   if((lastCompletedBar.open < compareToValue) ||
      (lastCompletedBar.close < compareToValue))
      {
         #ifdef SHOW_DEBUG 
            Print("DEBUG: ",__FUNCTION__," => compareToValue:",compareToValue," lastCompletedBar.open:",lastCompletedBar.open," lastCompletedBar.close:",lastCompletedBar.close);
         #endif

         return true;
      }         
   return false;
}

//
// Current bar's close is at or above VALUE
//

bool CFilters::CloseAtOrAboveValue(MqlRates &currentUncompletedBar, double compareToValue)
{
   if((compareToValue == 0) || (currentUncompletedBar.close == 0))
      return false;

   if(currentUncompletedBar.close >= compareToValue)
   {
      #ifdef SHOW_DEBUG 
         Print("DEBUG: ",__FUNCTION__," => compareToValue:",compareToValue," lastCompletedBar.close:",currentUncompletedBar.close);
      #endif
      return true; 
   }   
   return false;
}

//
// Current bar's close is at or below VALUE
//

bool CFilters::CloseAtOrBelowValue(MqlRates &currentUncompletedBar, double compareToValue)
{
   if((compareToValue == 0) || (currentUncompletedBar.close == 0))
      return false;

   if(currentUncompletedBar.close <= compareToValue)
   {
      #ifdef SHOW_DEBUG 
         Print("DEBUG: ",__FUNCTION__," => compareToValue:",compareToValue," lastCompletedBar.close:",currentUncompletedBar.close);
      #endif
      return true; 
   }   

   return false;
}

//
// Fast MA crosses Slow MA to the UP side
//

bool CFilters::MaCrossUp(double &valueFast[], double &valueSlow[])
{
   if((ArraySize(valueFast) < 3) || (ArraySize(valueSlow) < 3))
      return false;
      
   if((valueFast[1] == 0) || (valueFast[2] == 0) || (valueSlow[1] == 0) || (valueSlow[2] == 0))
      return false;
      
   if((valueFast[1] > valueSlow[1]) && (valueFast[2] < valueSlow[2]))
      if(valueFast[0] > valueSlow[0]) // extra validation
         return true;

   return false;
}

//
// Fast MA crosses Slow MA to the DOWN side
//

bool CFilters::MaCrossDown(double &valueFast[], double &valueSlow[])
{
   if((ArraySize(valueFast) < 3) || (ArraySize(valueSlow) < 3))
      return false;
      
   if((valueFast[1] == 0) || (valueFast[2] == 0) || (valueSlow[1] == 0) || (valueSlow[2] == 0))
      return false;

   if((valueFast[1] < valueSlow[1]) && (valueFast[2] > valueSlow[2]))
      if(valueFast[0] < valueSlow[0]) // extra validation
         return true;
   
   return false;
}
