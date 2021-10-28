//
// Copyright 2018-2020, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

#include <AZ-INVEST/SDK/TradeFunctions.mqh>
#include <AZ-INVEST/SDK/MedianRenko.mqh>
#include <AZ-INVEST/SDK/TimeControl.mqh>
#include <AZ-INVEST/SDK/TradeManager.mqh>
#include <AZ-INVEST/SDK/RenkoPatterns.mqh>
CRenkoPatterns renkoPatterns;
#include <AZ-INVEST/SDK/Filters.mqh>
CFilters filters;

enum ENUM_TRADING_MODE
{
   TRADING_MODE_BUY,       // Buy only
   TRADING_MODE_SELL,      // Sell only
   TRADING_MODE_ALL,       // Buy & Sell
};

struct CEaLogicPartameters
{
   ENUM_TRADING_MODE       TradingMode;
   int                     OpenXSignal;
   int                     CloseXSignal;
   double                  LotSize;
   int                     SLPoints;
   int                     TPPoints;
   int                     BEPoints;
   bool                    StopAndReverse;
   bool                    CloseOnRevesal;
   int                     TrailStartPoints;
   int                     TrailByPoints;
   int                     PartialCloseAtProfitPoints;
   int                     PartialClosePercentage;      
   
   string                  StartTrading;
   string                  EndTrading;
   bool                    CloseEOD;
   
   ENUM_FILTER_MODE        MA1Filter;
   ENUM_FITER_CONDITION    MA1FilterCond;
   int                     MA1FilterCheckBars;
   ENUM_FILTER_MODE        MA2Filter;
   ENUM_FITER_CONDITION    MA2FilterCond;
   int                     MA2FilterCheckBars;
   ENUM_FILTER_MODE        MA3Filter;
   ENUM_FITER_CONDITION    MA3FilterCond;
   int                     MA3FilterCheckBars;
   ENUM_FILTER_MODE        SuperTrendFilter;
   ENUM_FITER_CONDITION    SuperTrendFilterCond;
   int                     SuperTrendFilterCheckBars;

   ulong                   MagicNumber;
   ulong                   DeviationPoints;
   int                     NumberOfRetries;
   int                     BusyTimeout_ms;
   int                     RequoteTimeout_ms;
};

class CEaLogic 
{
   private:

      CEaLogicPartameters  inputs;
   
      MedianRenko          *medianRenko;      
      CMarketOrder         *orderHandler;
      CTimeControl         *timeControl;
      CTradeManager        *tradeManager;

      CTradeManagerState   tradeManagerState;
      
      MqlRates             RenkoRatesInfoArray[];
      double               MA1[];                  // array to be filled by values of the first moving average
      double               MA2[];                  // array to be filled by values of the second moving average
      double               MA3[];                  // array to be filled by values of the third moving average
      double               HighArray[];            // This array will store the values of the high SuperSignal band
      double               SuperTrend[];           // This array will store the values of the SuperSignal band
      double               LowArray[];             // This array will store the values of the low SuperSignal band      
      
   public:
   
      CEaLogic();
      ~CEaLogic();
      
      bool Initialize(CEaLogicPartameters &inputParams, MedianRenko *_medianRenko);
      bool OkToStartBacktest();
      void Run();
      
   private:
   
      bool IsNewBar();
      
      void GetRenkoInfo(int offset, int &_iteration);
      bool IsReversalCondition(MqlRates &_renkoRatesInfoArray[],ulong _ticket);
      bool TryReverseTrade(ulong _ticket);
      bool TryCloseTradeOnFilterCondition(ulong _ticket);
      bool TryCloseTradeOnReversal(ulong _ticket);
      bool TryCloseTradeOnEOD(ulong _ticket);
      bool TryOpenTrade(MqlRates &_renkoRatesInfoArray[]);

      bool FilterShortOK(ENUM_FILTER_MODE onAction, bool & _validated);
      bool FilterLongOK(ENUM_FILTER_MODE onAction, bool & _validated);
      bool OkToCloseByFilter(ulong _ticket, bool _invertCondition, bool &_validated);
};

CEaLogic::CEaLogic(void)
{
   this.orderHandler    = NULL;
   this.timeControl     = NULL;
   this.tradeManager    = NULL;
}

CEaLogic::~CEaLogic(void)
{
   if(orderHandler != NULL)
      delete orderHandler;
   
   if(tradeManager != NULL)
      delete tradeManager;
   
   if(timeControl != NULL)
      delete timeControl;
}

bool CEaLogic::Initialize(CEaLogicPartameters &inputParams, MedianRenko *_medianRenko)
{
   this.inputs = inputParams;
   
   this.medianRenko = _medianRenko;
   if(this.medianRenko == NULL)
   {
      Print(__FUNCTION__," failed on medianRenko == NULL");
      return false;
   } 
   
   //
   //  Init order handler
   //
   
   CMarketOrderParameters params;
   {
      params.m_async_mode        = false;
      params.m_magic             = inputParams.MagicNumber;
      params.m_deviation         = inputParams.DeviationPoints;
      params.m_type_filling      = ORDER_FILLING_FOK;
      
      params.numberOfRetries     = inputParams.NumberOfRetries;
      params.busyTimeout_ms      = inputParams.BusyTimeout_ms; 
      params.requoteTimeout_ms   = inputParams.RequoteTimeout_ms;         
   }
   
   if(orderHandler != NULL)
      delete orderHandler;
   orderHandler = new CMarketOrder(params);
   if(orderHandler == NULL)
   {
      Print(__FUNCTION__," failed on orderHandler == NULL");
      return false;
   }

   //
   // Init TradeManager
   //        

   CTradeManagerParameters params2;
   {
      params2.BEPoints                    = this.inputs.BEPoints;
      params2.TrailByPoints               = this.inputs.TrailByPoints;
      params2.TrailStartPoints            = this.inputs.TrailStartPoints;
      params2.PartialCloseAtProfitPoints  = this.inputs.PartialCloseAtProfitPoints;
      params2.PartialClosePercentage      = this.inputs.PartialClosePercentage;      
      
   }
        
   if(tradeManager != NULL)
      delete tradeManager;     
             
   tradeManager = new CTradeManager(params2, orderHandler);
   if(tradeManager == NULL)
   {
      Print(__FUNCTION__," failed on tradeManager == NULL");
      return false;
   }
        
   //
   // Init time control
   //
    
   if(timeControl != NULL)
      delete timeControl;
   timeControl = new CTimeControl();
   if(timeControl == NULL)
   {
      Print(__FUNCTION__," failed on timeControl == NULL");
      return false;
   }
         
   timeControl.SetValidTraingHours(this.inputs.StartTrading,this.inputs.EndTrading);     
      
   return true;
}

bool CEaLogic::IsNewBar(void)
{
   if(this.medianRenko == NULL)
      return false;
      
   return this.medianRenko.IsNewBar();
}

//
// Main EA logic
//

void CEaLogic::Run(void)
{
   ulong _ticket;
   bool  _inTrade = orderHandler.IsOpen(_ticket, _Symbol, this.inputs.MagicNumber);
   int   _iterations = 0;

   //
   // checks done on every tick
   //
   
   if(_inTrade)
   {
      
      // close trade at the end of the day?
      
      if(TryCloseTradeOnEOD(_ticket)) // filtering not applied
         return;
     
      // close trade on SuperTrend exit filter signal?
      
      if((this.inputs.SuperTrendFilter == FILTER_MODE_ENTRY_EXIT) || (this.inputs.SuperTrendFilter == FILTER_MODE_EXIT))
      {
         // only check on each tick if SuperTrend filter applied to exit
         
         GetRenkoInfo(CURRENT_UNCOMPLETED_BAR, _iterations);
         
         if(TryCloseTradeOnFilterCondition(_ticket))
            return;
      }

      // trade management
      
      tradeManager.Manage(_ticket, tradeManagerState);               
   }

   //
   // checks done on new bar only
   //
   
   if(IsNewBar())   
   {
      
      _iterations = 0;
      GetRenkoInfo(CURRENT_UNCOMPLETED_BAR, _iterations);
      
      if(_inTrade)
      {
         if(IsReversalCondition(this.RenkoRatesInfoArray, _ticket))
         {
            // trade reversal signal detected
            
            if(TryReverseTrade(_ticket))
               return;
               
            if(TryCloseTradeOnReversal(_ticket))
               return;
         }

         if(TryCloseTradeOnFilterCondition(_ticket))
            return;
      }
      else
      {
         // enter the trade
         
         TryOpenTrade(this.RenkoRatesInfoArray);
      }
   }   
}

void CEaLogic::GetRenkoInfo(int offset, int &_iteration)
{
   int _startAtBar = offset; // first bar to get
   int _numberOfBars = (int)MathMax(this.inputs.OpenXSignal,this.inputs.CloseXSignal) + 2;
      
   if(!medianRenko.GetMqlRates(this.RenkoRatesInfoArray,_startAtBar,_numberOfBars))
   {
      Print(__FUNCTION__," failed on GetMqlRates");
      return;
   }
   
   //
   // filter out phantom bars (price jumps and gaps)
   //
   
   _iteration++;
   int _fillerCount = 0;
   for (int i = LAST_COMPLETED_BAR; i<_numberOfBars; i++)
   {
      if((this.RenkoRatesInfoArray[i].real_volume == 0) &&
         (this.RenkoRatesInfoArray[i].tick_volume == 0))
            _fillerCount++;
   }
   
   if(_fillerCount > 0)
   {
      GetRenkoInfo((offset + _fillerCount), _iteration);
      return; 
   }
   
   // get values for filters
   
   if(this.inputs.MA1Filter != FILTER_MODE_OFF)
   {
      if(!medianRenko.GetMA(RENKO_MA1, MA1, _startAtBar, _numberOfBars))
      {
         Print(__FUNCTION__," failed on GetMA1");
         return;
      }
    }  

   if(this.inputs.MA2Filter != FILTER_MODE_OFF)
   {
      if(!medianRenko.GetMA(RENKO_MA2, MA2, _startAtBar, _numberOfBars))
      {
         Print(__FUNCTION__," failed on GetMA2");
         return;
      }
    }  
   
   if(this.inputs.MA3Filter != FILTER_MODE_OFF)
   {
      if(!medianRenko.GetMA(RENKO_MA3, MA3, _startAtBar, _numberOfBars))
      {
         Print(__FUNCTION__," failed on GetMA3");
         return;
      }
    }  
   
   if(this.inputs.SuperTrendFilter != FILTER_MODE_OFF)
   {
      if(!medianRenko.GetChannel(HighArray, SuperTrend, LowArray, _startAtBar, _numberOfBars))
      {
         Print(__FUNCTION__," failed on GetSuprTrend");
         return;
      }
   }  
}

bool CEaLogic::TryReverseTrade(ulong _ticket)
{
   // only stop&reverse if option enabled in EA inputs
   if(this.inputs.StopAndReverse == false)
      return false;
      
   if(this.inputs.TradingMode != TRADING_MODE_ALL)
   {
      // EA not in Trading mode for buys & sells
      return false;
   }
         
   if(!timeControl.IsTradingTimeValid())
   {
      Print(__FUNCTION__," Not reversing trade "+(string)_ticket+" outside of trading hours.");
      return false;
   }
   
   bool _filterValidated, _filterResult;
   _filterResult = OkToCloseByFilter(_ticket, true, _filterValidated);
   if(_filterValidated && !_filterResult)
   {
      Print(__FUNCTION__," Not reversing trade "+(string)_ticket+" due to filter condition.");
      return false;
   }      
      
   if(!orderHandler.Reverse(_ticket,inputs.LotSize,(uint)this.inputs.SLPoints,(uint)this.inputs.TPPoints))
   {
      Print(__FUNCTION__," failed on Reverse");
      return false;
   }  
   
   tradeManagerState.Clear();
   
   #ifdef SHOW_DEBUG 
      Print("DEBUG: ",__FUNCTION__," => "," reversed trade");
   #endif
   
   return true;
}

bool CEaLogic::OkToCloseByFilter(ulong _ticket, bool _invertCondition, bool &_validated)
{
   bool _filterResult;
   
   ENUM_POSITION_TYPE _pType;
   if(!orderHandler.GetPositionType(_ticket,_pType))
   {
      Print(__FUNCTION__," failed on GetPositionType for tricket "+(string)_ticket);
      return false;  
   }
   
   ENUM_ORDER_TYPE _type = orderHandler.TradeBias((ENUM_ORDER_TYPE)_pType);   
        
   if(_type == ORDER_TYPE_BUY)
   {
      // current trade is LONG
      
      if(_invertCondition)
      {
         _filterResult = FilterShortOK(FILTER_MODE_EXIT, _validated);
         if(_validated)
            return _filterResult;
      }
      else
      {
         _filterResult = FilterLongOK(FILTER_MODE_EXIT, _validated);
         if(_validated)
            return _filterResult;
      }  
   }   
   else if(_type == ORDER_TYPE_SELL)
   {
      // current trade is SHORT
      
      if(_invertCondition)
      {
         _filterResult = FilterLongOK(FILTER_MODE_EXIT, _validated);
         if(_validated)
            return _filterResult;
      }
      else
      {
         _filterResult = FilterShortOK(FILTER_MODE_EXIT, _validated);
         if(_validated)
            return _filterResult;
      }  
   } 
   
   return false;  
}

bool CEaLogic::TryCloseTradeOnReversal(ulong _ticket)
{
   // only close on reversals if option enabled in EA inputs
   if(this.inputs.CloseOnRevesal == false)
      return false;
   
   if(!timeControl.IsTradingTimeValid())
   {
      Print(__FUNCTION__," Not closing trade "+(string)_ticket+" outside of trading hours.");
      return false;
   }
   
   bool _filterValidated, _filterResult;
   _filterResult = OkToCloseByFilter(_ticket, true, _filterValidated);
   if(_filterValidated)
   {
      if(!_filterResult)
      {
         Print(__FUNCTION__," Not closing trade "+(string)_ticket+" due to filter condition.");
         return false;
      }
   }      
   
   if(!orderHandler.Close(_ticket))
   {
      Print(__FUNCTION__," failed on close trade "+(string)_ticket);
      return false;
   }  
   
   #ifdef SHOW_DEBUG 
      Print("DEBUG: ",__FUNCTION__," => "," closed");
   #endif
   
   return true;     
}

bool CEaLogic::TryOpenTrade(MqlRates &_renkoRatesInfoArray[])
{
   bool _filterResult, _filterValidated;
   
   ENUM_ORDER_TYPE doOpen = ORDER_TYPE_BUY_LIMIT; // value assigned only for default state   
   
   if(renkoPatterns.IsBearReversal(_renkoRatesInfoArray,inputs.OpenXSignal))
   {
      if(this.inputs.TradingMode == TRADING_MODE_BUY)
         return false;
         
      _filterResult = FilterShortOK(FILTER_MODE_ENTRY, _filterValidated);
      if(_filterValidated && !_filterResult)
      {
         Print(__FUNCTION__," Not taking trade due to filter condition");
         return false;
      }   

      doOpen = ORDER_TYPE_SELL;
   }
   else if(renkoPatterns.IsBullReversal(_renkoRatesInfoArray,inputs.OpenXSignal))
   {
      if(this.inputs.TradingMode == TRADING_MODE_SELL)
         return false;

      _filterResult = FilterLongOK(FILTER_MODE_ENTRY, _filterValidated);
      if(_filterValidated && !_filterResult)
      {
         Print(__FUNCTION__," Not taking trade due to filter condition");
         return false;
      }   
         
      doOpen = ORDER_TYPE_BUY;
   }
   else
      return false;

   if(!timeControl.IsTradingTimeValid())
   {
      Print(__FUNCTION__," Not taking ",EnumToString(doOpen)," trade outside of trading hours.");
      return false;
   }
      
   if(doOpen == ORDER_TYPE_BUY)
      orderHandler.Long(_Symbol,this.inputs.LotSize,(uint)this.inputs.SLPoints,(uint)this.inputs.TPPoints,true);
   else if(doOpen == ORDER_TYPE_SELL)
      orderHandler.Short(_Symbol,this.inputs.LotSize,(uint)this.inputs.SLPoints,(uint)this.inputs.TPPoints,true);
   else
   {
      Print(__FUNCTION__," failed on open order -> order type = ",EnumToString(doOpen));
      return false;
   }
      
   tradeManagerState.Clear();
      
   #ifdef SHOW_DEBUG 
      Print("DEBUG: ",__FUNCTION__," => "," doOpen = "+EnumToString(doOpen));
   #endif
      
   return true;
}

bool CEaLogic::IsReversalCondition(MqlRates &_renkoRatesInfoArray[],ulong _ticket)
{
   ENUM_POSITION_TYPE _pType;
   if(!orderHandler.GetPositionType(_ticket,_pType))
   {
      Print(__FUNCTION__," failed on GetPositionType for ticket "+(string)_ticket);
      return false;
   }
      
   ENUM_ORDER_TYPE _type = orderHandler.TradeBias((ENUM_ORDER_TYPE)_pType);   
     
   if(_type == ORDER_TYPE_BUY)
   {
      if(renkoPatterns.IsBearReversal(_renkoRatesInfoArray,inputs.CloseXSignal))
      {
         Print("Found bear reversal condition");
         return true;
      }
   }
   else if(_type == ORDER_TYPE_SELL)
   {
      if(renkoPatterns.IsBullReversal(_renkoRatesInfoArray,inputs.CloseXSignal))
      {
         Print("Found bull reversal condition");
         return true;
      }
   }
   
   return false;
}

bool CEaLogic::TryCloseTradeOnEOD(ulong _ticket)
{
   if(this.inputs.CloseEOD && !timeControl.IsTradingTimeValid())
   {
      Print(__FUNCTION__," Closing trade at EOD");
      return orderHandler.Close(_ticket);      
   }
   
   return false;
}

bool CEaLogic::TryCloseTradeOnFilterCondition(ulong _ticket)
{
   bool _filterValidated, _filterResult;
   
   _filterResult = OkToCloseByFilter(_ticket, true, _filterValidated);
   
   if(!_filterValidated) 
      return false; // not all filters vaidated
   if(!_filterResult) 
      return false; // filter condition not met   

   #ifdef SHOW_DEBUG 
      Print("DEBUG: ",__FUNCTION__," => ","closing trade on filter condition");
   #endif

   return orderHandler.Close(_ticket);
}

bool CEaLogic::FilterLongOK(ENUM_FILTER_MODE onAction, bool & _validated)
{
   if(onAction == FILTER_MODE_ENTRY_EXIT)
   {
      Print(__FUNCTION__," Filter value ambiguous -> returning true");
      return false;
   }

   _validated = false;
   bool _filterValidLong  = true;
   MqlRates ratesArr[];
   double doubleArr[];
     
   if((this.inputs.MA1Filter == onAction) || (this.inputs.MA1Filter == FILTER_MODE_ENTRY_EXIT))
   {
      ArrayCopy(ratesArr, this.RenkoRatesInfoArray, 0, 1, this.inputs.MA1FilterCheckBars);
      ArrayCopy(doubleArr, this.MA1, 0, 1, this.inputs.MA1FilterCheckBars);
      _filterValidLong &= filters.AboveValue(this.inputs.MA1FilterCond, ratesArr, doubleArr, "MA1");
      _validated = true;
   }  

   if((this.inputs.MA2Filter == onAction) || (this.inputs.MA2Filter == FILTER_MODE_ENTRY_EXIT))
   {
      ArrayCopy(ratesArr, this.RenkoRatesInfoArray, 0, 1, this.inputs.MA2FilterCheckBars);
      ArrayCopy(doubleArr, this.MA2, 0, 1, this.inputs.MA2FilterCheckBars);
      _filterValidLong &= filters.AboveValue(this.inputs.MA2FilterCond, ratesArr, doubleArr, "MA2");
      _validated = true;
   }  
   
   if((this.inputs.MA3Filter == onAction) || (this.inputs.MA3Filter == FILTER_MODE_ENTRY_EXIT))
   {
      ArrayCopy(ratesArr, this.RenkoRatesInfoArray, 0, 1, this.inputs.MA3FilterCheckBars);
      ArrayCopy(doubleArr, this.MA3, 0, 1, this.inputs.MA3FilterCheckBars);
      _filterValidLong &= filters.AboveValue(this.inputs.MA3FilterCond, ratesArr, doubleArr, "MA3");
      _validated = true;
   }
      
   if((this.inputs.SuperTrendFilter == onAction) || (this.inputs.SuperTrendFilter == FILTER_MODE_ENTRY_EXIT))
   {
/* TODO - revist previous logic and verify the need for differnt logic on exits and entries
      if(onAction == FILTER_MODE_ENTRY)
         _filterValidLong &= filters.OpenOrCloseAboveValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.SuperTrend[LAST_COMPLETED_BAR], "SuperTrend");
      else if(onAction == FILTER_MODE_EXIT)
         _filterValidLong &= filters.CloseAtOrAboveValue(this.RenkoRatesInfoArray[CURRENT_UNCOMPLETED_BAR],this.SuperTrend[LAST_COMPLETED_BAR], "SuperTrend"); 
*/
      ArrayCopy(ratesArr, this.RenkoRatesInfoArray, 0, 1, this.inputs.SuperTrendFilterCheckBars);
      ArrayCopy(doubleArr, this.SuperTrend, 0, 1, this.inputs.SuperTrendFilterCheckBars);
      _filterValidLong &= filters.AboveValue(this.inputs.SuperTrendFilterCond, ratesArr, doubleArr, "SuperTrend"); 
      _validated = true;
   }
   
   #ifdef SHOW_DEBUG 
      if(_validated)
         Print("DEBUG: ",__FUNCTION__," => "," filter condition = "+(string)_filterValidLong+" | validation = ",(string)_validated);
   #endif
   
   return _filterValidLong;
}

bool CEaLogic::FilterShortOK(ENUM_FILTER_MODE onAction, bool & _validated)
{
   if(onAction == FILTER_MODE_ENTRY_EXIT)
   {
      Print(__FUNCTION__," Filter value ambiguous -> returning true");
      return false;
   }
      
   _validated = false;
   bool _filterValidShort = true;
   MqlRates ratesArr[];
   double doubleArr[];

   if((this.inputs.MA1Filter == onAction) || (this.inputs.MA1Filter == FILTER_MODE_ENTRY_EXIT))
   {
      ArrayCopy(ratesArr, this.RenkoRatesInfoArray, 0, 1, this.inputs.MA1FilterCheckBars);
      ArrayCopy(doubleArr, this.MA1, 0, 1, this.inputs.MA1FilterCheckBars);
      _filterValidShort &= filters.BelowValue(this.inputs.MA1FilterCond, ratesArr, doubleArr, "MA1");
      _validated = true;
   }  

   if((this.inputs.MA2Filter == onAction) || (this.inputs.MA2Filter == FILTER_MODE_ENTRY_EXIT))
   {
      ArrayCopy(ratesArr, this.RenkoRatesInfoArray, 0, 1, this.inputs.MA2FilterCheckBars);
      ArrayCopy(doubleArr, this.MA2, 0, 1, this.inputs.MA2FilterCheckBars);
      _filterValidShort &= filters.BelowValue(this.inputs.MA2FilterCond, ratesArr, doubleArr, "MA2");
      _validated = true;
   }  
   
   if((this.inputs.MA3Filter == onAction) || (this.inputs.MA3Filter == FILTER_MODE_ENTRY_EXIT))
   {
      ArrayCopy(ratesArr, this.RenkoRatesInfoArray, 0, 1, this.inputs.MA3FilterCheckBars);
      ArrayCopy(doubleArr, this.MA3, 0, 1, this.inputs.MA3FilterCheckBars);
      _filterValidShort &= filters.BelowValue(this.inputs.MA3FilterCond, ratesArr, doubleArr, "MA3");
      _validated = true;
   }
      
   if((this.inputs.SuperTrendFilter == onAction) || (this.inputs.SuperTrendFilter == FILTER_MODE_ENTRY_EXIT))
   {
/* TODO - revist previous logic and verify the need for differnt logic on exits and entries
      if(onAction == FILTER_MODE_ENTRY)
         _filterValidShort &= filters.OpenOrCloseBelowValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.SuperTrend[LAST_COMPLETED_BAR], "SuperTrend");
      else if(onAction == FILTER_MODE_EXIT)
      {
         _filterValidShort &= filters.CloseAtOrBelowValue(this.RenkoRatesInfoArray[CURRENT_UNCOMPLETED_BAR],this.SuperTrend[LAST_COMPLETED_BAR], "SuperTrend"); 
      }
*/

      ArrayCopy(ratesArr, this.RenkoRatesInfoArray, 0, 1, this.inputs.SuperTrendFilterCheckBars);
      ArrayCopy(doubleArr, this.SuperTrend, 0, 1, this.inputs.SuperTrendFilterCheckBars);
      _filterValidShort &= filters.BelowValue(this.inputs.SuperTrendFilterCond, ratesArr, doubleArr, "SuperTrend"); 
      _validated = true;
   }
         
   #ifdef SHOW_DEBUG 
      if(_validated)
         Print("DEBUG: ",__FUNCTION__," => "," filter condition = "+(string)_filterValidShort+" | validation = ",(string)_validated);
   #endif
   
   return _filterValidShort;
}

bool CEaLogic::OkToStartBacktest(void)
{
   #ifdef SHOW_INDICATOR_INPUTS   
      static bool _ok = false;
      if(MQLInfoInteger((int)MQL5_TESTING) && !_ok)
      {
         int _count = 0;
         if(InpMA1lineType != MA_NONE && (this.inputs.MA1Filter != FILTER_MODE_OFF))
            _count = InpMA1period;
         if(InpMA2lineType != MA_NONE && (this.inputs.MA2Filter != FILTER_MODE_OFF))
            _count = MathMax(_count,InpMA2period);
         if(InpMA3lineType != MA_NONE && (this.inputs.MA3Filter != FILTER_MODE_OFF))
            _count = MathMax(_count,InpMA3period);
         if((InpShowChannel == _SuperTrend) && (this.inputs.SuperTrendFilter != FILTER_MODE_OFF))
            _count = MathMax(_count, InpChannelPeriod); //  SuperTrendPeriod
      
         static bool _infoShown = false;
         if(!_infoShown)
         {
            Print("(!) Waiting for "+(string)_count+" bars to complete before starting.");
            _infoShown = true;
         }
         
         MqlRates _temp[];      
         if(medianRenko.GetMqlRates(_temp,0,Bars(_Symbol,_Period)))
         {
            int _i = 0;
            int _c = 0;
            
            while(_temp[_i].open > 0)
            {
               _c++;
               _i++;
               if(_i > (ArraySize(_temp) - 1))
                  break;
            }           
            
            if(_c > _count)
            {
               Print("(!) Starting the backtest "+(string)_count+" bars present");
               _ok = true;  
            }
         }
         ArrayFree(_temp);   
         
         if(!_ok)
            return false;
      }
   #endif     
   
   return true;
}
