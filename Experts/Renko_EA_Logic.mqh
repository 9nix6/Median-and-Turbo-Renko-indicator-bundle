//
// Copyright 2018-2019, Artur Zas
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
   int                     TrailStartPoints;
   int                     TrailByPoints;
   
   string                  StartTrading;
   string                  EndTrading;
   bool                    CloseEOD;
   
   ENUM_FILTER_MODE        MA1Filter;
   ENUM_FILTER_MODE        MA2Filter;
   ENUM_FILTER_MODE        MA3Filter;
   ENUM_FILTER_MODE        SuperTrendFilter;

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
   this.inputs.TradingMode       = inputParams.TradingMode;
   this.inputs.OpenXSignal       = inputParams.OpenXSignal;
   this.inputs.CloseXSignal      = inputParams.CloseXSignal;
   this.inputs.LotSize           = inputParams.LotSize;
   this.inputs.SLPoints          = inputParams.SLPoints;
   this.inputs.TPPoints          = inputParams.TPPoints;
   this.inputs.BEPoints          = inputParams.BEPoints;
   this.inputs.TrailByPoints     = inputParams.TrailByPoints;
   this.inputs.TrailStartPoints  = inputParams.TrailStartPoints;
   this.inputs.StartTrading      = inputParams.StartTrading;
   this.inputs.EndTrading        = inputParams.EndTrading;
   this.inputs.CloseEOD          = inputParams.CloseEOD;
   this.inputs.MA1Filter         = inputParams.MA1Filter;
   this.inputs.MA2Filter         = inputParams.MA2Filter;
   this.inputs.MA3Filter         = inputParams.MA3Filter;
   this.inputs.SuperTrendFilter  = inputParams.SuperTrendFilter;
   
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
      params2.BEPoints           = this.inputs.BEPoints;
      params2.TrailByPoints      = this.inputs.TrailByPoints;
      params2.TrailStartPoints   = this.inputs.TrailStartPoints;
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

void CEaLogic::Run(void)
{
   bool  _inTrade;
   ulong _ticket;
   int   _iterations;
   
   if(_inTrade = orderHandler.IsOpen(_ticket, _Symbol,this.inputs.MagicNumber))
   {
      // checks done on every tick

      if(TryCloseTradeOnEOD(_ticket)) // filtering not applied
         return;
     
      if((this.inputs.SuperTrendFilter == FILTER_MODE_ENTRY_EXIT) || (this.inputs.SuperTrendFilter == FILTER_MODE_EXIT))
      {
         // only check on each tick if SuperTrend filter applied to exit
         
         _iterations = 0;
         GetRenkoInfo(CURRENT_UNCOMPLETED_BAR,_iterations);
         if(TryCloseTradeOnFilterCondition(_ticket))
            return;
      }

      tradeManager.Manage(_ticket, tradeManagerState);               
   }
   
   if(IsNewBar())   
   {
      // checks done on new bar only

      _iterations = 0;
      GetRenkoInfo(CURRENT_UNCOMPLETED_BAR,_iterations);
      
      if(_inTrade)
      {
         if(IsReversalCondition(this.RenkoRatesInfoArray, _ticket))
         {
            if(TryReverseTrade(_ticket))
               return;
            if(TryCloseTradeOnReversal(_ticket))
               return;
         }

         if(TryCloseTradeOnFilterCondition(_ticket))
            return;
      }
      else
         TryOpenTrade(this.RenkoRatesInfoArray);
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
   // filter out filler bars 
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
      GetRenkoInfo((offset + _fillerCount),_iteration);
      return;
   }
   
   //
   
   if(this.inputs.MA1Filter != FILTER_MODE_OFF)
   {
      if(!medianRenko.GetMA1(MA1,_startAtBar,_numberOfBars))
      {
         Print(__FUNCTION__," failed on GetMA1");
         return;
      }
    }  

   if(this.inputs.MA2Filter != FILTER_MODE_OFF)
   {
      if(!medianRenko.GetMA2(MA2,_startAtBar,_numberOfBars))
      {
         Print(__FUNCTION__," failed on GetMA2");
         return;
      }
    }  
   
   if(this.inputs.MA3Filter != FILTER_MODE_OFF)
   {
      if(!medianRenko.GetMA3(MA3,_startAtBar,_numberOfBars))
      {
         Print(__FUNCTION__," failed on GetMA3");
         return;
      }
    }  
   
   if(this.inputs.SuperTrendFilter != FILTER_MODE_OFF)
   {
      if(!medianRenko.GetSuperTrend(HighArray,SuperTrend,LowArray,_startAtBar,_numberOfBars))
      {
         Print(__FUNCTION__," failed on GetSuprTrend");
         return;
      }
   }  
}

bool CEaLogic::TryReverseTrade(ulong _ticket)
{
   /* Always in stop & reverse mode
   if((this.inputs.SLPoints > 0) || (this.inputs.TPPoints > 0))
   {
      // EA not in Stop&Revese mode
      return false;  
   }
   */
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
   //if((this.inputs.MA1Filter == FILTER_MODE_ENTRY_EXIT) || (this.inputs.MA1Filter == FILTER_MODE_EXIT))
   bool _filterValidated, _filterResult;
   
   ENUM_POSITION_TYPE _pType;
   if(!orderHandler.GetPositionType(_ticket,_pType))
   {
      Print(__FUNCTION__," failed on GetPositionType for tricket "+(string)_ticket);
      return false;  
   }
   
   ENUM_ORDER_TYPE _type = orderHandler.TradeBias((ENUM_ORDER_TYPE)_pType);   
        
   if(_type == ORDER_TYPE_BUY)
   {
      if(_invertCondition)
      {
         _filterResult = FilterShortOK(FILTER_MODE_EXIT, _filterValidated);
         if(_filterValidated)
            return _filterResult;
      }
      else
      {
         _filterResult = FilterLongOK(FILTER_MODE_EXIT, _filterValidated);
         if(_filterValidated)
            return _filterResult;
      }  
   }   
   else if(_type == ORDER_TYPE_SELL)
   {
      if(_invertCondition)
      {
         _filterResult = FilterLongOK(FILTER_MODE_EXIT, _filterValidated);
         if(_filterValidated)
            return _filterResult;
      }
      else
      {
         _filterResult = FilterShortOK(FILTER_MODE_EXIT, _filterValidated);
         if(_filterValidated)
            return _filterResult;
      }  
   } 
   
   return false;  
}

bool CEaLogic::TryCloseTradeOnReversal(ulong _ticket)
{
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
   {
      return false;
   }
   else
   {
      //#ifdef SHOW_DEBUG 
      //   Print("DEBUG: ",__FUNCTION__," => Not closing trade "+(string)_ticket+" due to filter condition.");
      //#endif

      if(!_filterResult)
         return false;
   }      

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
  
   if((this.inputs.MA1Filter == onAction) || (this.inputs.MA1Filter == FILTER_MODE_ENTRY_EXIT))
   {
      _filterValidLong &= filters.OpenOrCloseAboveValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.MA1[LAST_COMPLETED_BAR]);
      _validated = true;
   }  

   if((this.inputs.MA2Filter == onAction) || (this.inputs.MA2Filter == FILTER_MODE_ENTRY_EXIT))
   {
      _filterValidLong &= filters.OpenOrCloseAboveValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.MA2[LAST_COMPLETED_BAR]);
      _validated = true;
   }  
   
   if((this.inputs.MA3Filter == onAction) || (this.inputs.MA3Filter == FILTER_MODE_ENTRY_EXIT))
   {
      _filterValidLong &= filters.OpenOrCloseAboveValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.MA3[LAST_COMPLETED_BAR]);
      _validated = true;
   }
      
   if((this.inputs.SuperTrendFilter == onAction) || (this.inputs.SuperTrendFilter == FILTER_MODE_ENTRY_EXIT))
   {
      if(onAction == FILTER_MODE_ENTRY)
         _filterValidLong &= filters.OpenOrCloseAboveValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.SuperTrend[LAST_COMPLETED_BAR]);
      else if(onAction == FILTER_MODE_EXIT)
         _filterValidLong &= filters.CloseAtOrAboveValue(this.RenkoRatesInfoArray[CURRENT_UNCOMPLETED_BAR],this.SuperTrend[LAST_COMPLETED_BAR]); 
      _validated = true;
   }
   
   #ifdef SHOW_DEBUG 
      if(_validated)
         Print("DEBUG: ",__FUNCTION__," => "," filter condition = "+(string)_filterValidLong+" validation(",(string)_validated,")");
   #endif
   
//   return _validated ? _filterValidLong : ((onAction == FILTER_MODE_EXIT) ? true : false);
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

   if((this.inputs.MA1Filter == onAction) || (this.inputs.MA1Filter == FILTER_MODE_ENTRY_EXIT))
   {
      _filterValidShort &= filters.OpenOrCloseBelowValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.MA1[LAST_COMPLETED_BAR]);
      _validated = true;
   }  

   if((this.inputs.MA2Filter == onAction) || (this.inputs.MA2Filter == FILTER_MODE_ENTRY_EXIT))
   {
      _filterValidShort &= filters.OpenOrCloseBelowValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.MA2[LAST_COMPLETED_BAR]);
      _validated = true;
   }  
   
   if((this.inputs.MA3Filter == onAction) || (this.inputs.MA3Filter == FILTER_MODE_ENTRY_EXIT))
   {
      _filterValidShort &= filters.OpenOrCloseBelowValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.MA3[LAST_COMPLETED_BAR]);
      _validated = true;
   }
      
   if((this.inputs.SuperTrendFilter == onAction) || (this.inputs.SuperTrendFilter == FILTER_MODE_ENTRY_EXIT))
   {
      if(onAction == FILTER_MODE_ENTRY)
         _filterValidShort &= filters.OpenOrCloseBelowValue(this.RenkoRatesInfoArray[LAST_COMPLETED_BAR],this.SuperTrend[LAST_COMPLETED_BAR]);
      else if(onAction == FILTER_MODE_EXIT)
      {
         _filterValidShort &= filters.CloseAtOrBelowValue(this.RenkoRatesInfoArray[CURRENT_UNCOMPLETED_BAR],this.SuperTrend[LAST_COMPLETED_BAR]); 
      }
      _validated = true;
   }
         
   #ifdef SHOW_DEBUG 
      if(_validated)
         Print("DEBUG: ",__FUNCTION__," => "," filter condition = "+(string)_filterValidShort+" validation(",(string)_validated,")");
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
         if(MA1on && (this.inputs.MA1Filter != FILTER_MODE_OFF))
            _count = MA1period;
         if(MA2on && (this.inputs.MA2Filter != FILTER_MODE_OFF))
            _count = MathMax(_count,MA2period);
         if(MA3on && (this.inputs.MA3Filter != FILTER_MODE_OFF))
            _count = MathMax(_count,MA3period);
         if((ShowChannel == _SuperTrend) && (this.inputs.SuperTrendFilter != FILTER_MODE_OFF))
            _count = MathMax(_count,SuperTrendPeriod);
      
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
