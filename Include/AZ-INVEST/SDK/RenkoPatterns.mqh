//
// Copyright 2018, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

#define CURRENT_UNCOMPLETED_BAR  0
#define LAST_COMPLETED_BAR       1

class CRenkoPatterns
{
   public:
       CRenkoPatterns();
       ~CRenkoPatterns();
       
       bool IsBullReversal(MqlRates &renkos[], int confirmationBars);
       bool IsBearReversal(MqlRates &renkos[], int confirmationBars);
};

CRenkoPatterns::CRenkoPatterns(void)
{
}

CRenkoPatterns::~CRenkoPatterns(void)
{
}

bool CRenkoPatterns::IsBearReversal(MqlRates &renkos[], int confirmationBars)
{
   if(ArraySize(renkos) < (confirmationBars+2))
      return false; // not enough data
      
   if(renkos[confirmationBars+1].open < renkos[confirmationBars+1].close)
   {
      for(int i=LAST_COMPLETED_BAR; i<=confirmationBars; i++)
      {
         if(renkos[i].open > renkos[i].close)
         {
            continue; 
         }
         else
            return false; // pattern failure
      }
   }
   else
      return false; // pattern failure
   
   return true; // pattern detexted
}

bool CRenkoPatterns::IsBullReversal(MqlRates &renkos[], int confirmationBars)
{
   if(ArraySize(renkos) < (confirmationBars+2))
      return false; // not enough data

   if(renkos[confirmationBars+1].open > renkos[confirmationBars+1].close)
   {
      for(int i=LAST_COMPLETED_BAR; i<=confirmationBars; i++)
      {
         if(renkos[i].open < renkos[i].close)
         {
            continue; 
         }
         else
            return false; // pattern failure
      }
   }
   else
      return false; // pattern failure
   
   return true; // pattern detected
}



