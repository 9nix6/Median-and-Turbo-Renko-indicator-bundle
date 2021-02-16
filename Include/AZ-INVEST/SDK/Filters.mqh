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

enum ENUM_FITER_CONDITION
{
   FILTER_CONDITION_OPEN,           // Open
   FILTER_CONDITION_CLOSE,          // Close
   FILTER_CONDITION_OPEN_OR_CLOSE,  // Open or Close
   FILTER_CONDITION_OPEN_AND_CLOSE, // Open and Close
};

class CFilters
{
   public:
       CFilters();
       ~CFilters();
       
   virtual bool AboveValue(ENUM_FITER_CONDITION condition, MqlRates &lastCompletedBars[], double &compareToValues[], string desc);
   virtual bool BelowValue(ENUM_FITER_CONDITION condition, MqlRates &lastCompletedBars[], double &compareToValues[], string desc);
   
   virtual bool CloseAtOrAboveValue(MqlRates &currentUncompletedBar, double compareToValue, string desc);
   virtual bool CloseAtOrBelowValue(MqlRates &currentUncompletedBar, double compareToValue, string desc);
   
   virtual bool MaCrossUp(double &valuesFast[], double &valuesSlow[]);
   virtual bool MaCrossDown(double &valuesFast[], double &valuesSlow[]);
   
   private:
   
   bool MqlRatesArrayIsValid(MqlRates &arr[]);
   bool DoubleArrayIsValid(double &arr[]);
};

CFilters::CFilters(void)
{
}

CFilters::~CFilters(void)
{
}

//
// Last completed bars' open AND/OR close values are above VALUE
//

bool CFilters::AboveValue(ENUM_FITER_CONDITION condition, MqlRates &lastCompletedBars[], double &compareToValues[], string desc)
{
   if(DoubleArrayIsValid(compareToValues) == false || MqlRatesArrayIsValid(lastCompletedBars) == false)
      return false;      
      
   for(int i = 0; i<ArraySize(lastCompletedBars); i++)
   {  
      switch(condition)
      {
         case FILTER_CONDITION_OPEN:
            if(lastCompletedBars[i].open <= compareToValues[i])         
            {
               #ifdef SHOW_DEBUG 
                  Print("DEBUG: ",__FUNCTION__,"(",EnumToString(condition),") invalidated => ",desc,":",DoubleToString(compareToValues[i],_Digits),
                     " | lastCompletedBars[",i,"].open:",DoubleToString(lastCompletedBars[i].open,_Digits),
                     " | lastCompletedBars[",i,"].close:",DoubleToString(lastCompletedBars[i].close,_Digits));
               #endif
            
               return false;
            }
         break;

         case FILTER_CONDITION_CLOSE:
            if(lastCompletedBars[i].close <= compareToValues[i])         
            {
               #ifdef SHOW_DEBUG 
                  Print("DEBUG: ",__FUNCTION__,"(",EnumToString(condition),") invalidated => ",desc,":",DoubleToString(compareToValues[i],_Digits),
                     " | lastCompletedBars[",i,"].open:",DoubleToString(lastCompletedBars[i].open,_Digits),
                     " | lastCompletedBars[",i,"].close:",DoubleToString(lastCompletedBars[i].close,_Digits));
               #endif

               return false;
            }
         break;

         case FILTER_CONDITION_OPEN_OR_CLOSE:
            if(lastCompletedBars[i].open <= compareToValues[i] && lastCompletedBars[i].close <= compareToValues[i])         
            {
               #ifdef SHOW_DEBUG 
                  Print("DEBUG: ",__FUNCTION__,"(",EnumToString(condition),") invalidated => ",desc,":",DoubleToString(compareToValues[i],_Digits),
                     " | lastCompletedBars[",i,"].open:",DoubleToString(lastCompletedBars[i].open,_Digits),
                     " | lastCompletedBars[",i,"].close:",DoubleToString(lastCompletedBars[i].close,_Digits));
               #endif

               return false;
            }
         break;

         case FILTER_CONDITION_OPEN_AND_CLOSE:
            if(lastCompletedBars[i].open <= compareToValues[i] || lastCompletedBars[i].close <= compareToValues[i])         
            {
               #ifdef SHOW_DEBUG 
                  Print("DEBUG: ",__FUNCTION__,"(",EnumToString(condition),") invalidated => ",desc,":",DoubleToString(compareToValues[i],_Digits),
                     " | lastCompletedBars[",i,"].open:",DoubleToString(lastCompletedBars[i].open,_Digits),
                     " | lastCompletedBars[",i,"].close:",DoubleToString(lastCompletedBars[i].close,_Digits));
               #endif

               return false;
            }
         break;
         
         default:
            #ifdef SHOW_DEBUG 
               Print("DEBUG: ",__FUNCTION__," => Failed check on undef. filter condition");
            #endif            
            return false;
      }
   }
   
   return true;
}

//
// Last completed bar's open OR close values are below VALUE
//

bool CFilters::BelowValue(ENUM_FITER_CONDITION condition, MqlRates &lastCompletedBars[], double &compareToValues[], string desc)
{
   if(DoubleArrayIsValid(compareToValues) == false || MqlRatesArrayIsValid(lastCompletedBars) == false)
      return false;      
      
   for(int i = 0; i<ArraySize(lastCompletedBars); i++)
   {  
      switch(condition)
      {
         case FILTER_CONDITION_OPEN:
            if(lastCompletedBars[i].open >= compareToValues[i])         
            {
               #ifdef SHOW_DEBUG 
                  Print("DEBUG: ",__FUNCTION__,"(",EnumToString(condition),") invalidated => ",desc,":",DoubleToString(compareToValues[i],_Digits),
                     " | lastCompletedBars[",i,"].open:",DoubleToString(lastCompletedBars[i].open,_Digits),
                     " | lastCompletedBars[",i,"].close:",DoubleToString(lastCompletedBars[i].close,_Digits));
               #endif
            
               return false;
            }
         break;

         case FILTER_CONDITION_CLOSE:
            if(lastCompletedBars[i].close >= compareToValues[i])         
            {
               #ifdef SHOW_DEBUG 
                  Print("DEBUG: ",__FUNCTION__,"(",EnumToString(condition),") invalidated => ",desc,":",DoubleToString(compareToValues[i],_Digits),
                     " | lastCompletedBars[",i,"].open:",DoubleToString(lastCompletedBars[i].open,_Digits),
                     " | lastCompletedBars[",i,"].close:",DoubleToString(lastCompletedBars[i].close,_Digits));
               #endif

               return false;
            }
         break;

         case FILTER_CONDITION_OPEN_OR_CLOSE:
            if(lastCompletedBars[i].open >= compareToValues[i] && lastCompletedBars[i].close >= compareToValues[i])         
            {
               #ifdef SHOW_DEBUG 
                  Print("DEBUG: ",__FUNCTION__,"(",EnumToString(condition),") invalidated => ",desc,":",DoubleToString(compareToValues[i],_Digits),
                     " | lastCompletedBars[",i,"].open:",DoubleToString(lastCompletedBars[i].open,_Digits),
                     " | lastCompletedBars[",i,"].close:",DoubleToString(lastCompletedBars[i].close,_Digits));
               #endif

               return false;
            }
         break;

         case FILTER_CONDITION_OPEN_AND_CLOSE:
            if(lastCompletedBars[i].open >= compareToValues[i] || lastCompletedBars[i].close >= compareToValues[i])         
            {
               #ifdef SHOW_DEBUG 
                  Print("DEBUG: ",__FUNCTION__,"(",EnumToString(condition),") invalidated => ",desc,":",DoubleToString(compareToValues[i],_Digits),
                     " | lastCompletedBars[",i,"].open:",DoubleToString(lastCompletedBars[i].open,_Digits),
                     " | lastCompletedBars[",i,"].close:",DoubleToString(lastCompletedBars[i].close,_Digits));
               #endif

               return false;
            }
         break;
         
         default:
            #ifdef SHOW_DEBUG 
               Print("DEBUG: ",__FUNCTION__," => Failed check on undef. filter condition");
            #endif            
            return false;
      }
   }
   
   return true;
}



//
// Current bar's close is at or above VALUE
//

bool CFilters::CloseAtOrAboveValue(MqlRates &currentUncompletedBar, double compareToValue, string desc)
{
   if((compareToValue == 0) || (currentUncompletedBar.close == 0))
      return false;

   if(currentUncompletedBar.close >= compareToValue)
   {
      #ifdef SHOW_DEBUG 
         Print("DEBUG: ",__FUNCTION__," => compareToValue(",desc,"):",DoubleToString(compareToValue, _Digits)," lastCompletedBar.close:",DoubleToString(currentUncompletedBar.close, _Digits));
      #endif
      return true; 
   }   
   return false;
}

//
// Current bar's close is at or below VALUE
//

bool CFilters::CloseAtOrBelowValue(MqlRates &currentUncompletedBar, double compareToValue, string desc)
{
   if((compareToValue == 0) || (currentUncompletedBar.close == 0))
      return false;

   if(currentUncompletedBar.close <= compareToValue)
   {
      #ifdef SHOW_DEBUG 
         Print("DEBUG: ",__FUNCTION__," => compareToValue(",desc,"):",DoubleToString(compareToValue, _Digits)," lastCompletedBar.close:",DoubleToString(currentUncompletedBar.close, _Digits));
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

//
// Validate MqlRates array
//

bool CFilters::MqlRatesArrayIsValid(MqlRates &arr[])
{
   for(int i = 0; i<ArraySize(arr); i++)
   {
      if(arr[i].open == 0 || arr[i].close == 0 || arr[i].high == 0 || arr[i].low == 0)
         return false;
   }
   
   return true;
}

//
// Validate double values array
//

bool CFilters::DoubleArrayIsValid(double &arr[])
{
   for(int i = 0; i<ArraySize(arr); i++)
   {
      if(arr[i] == 0)
         return false;
   }
   
   return true;
}


