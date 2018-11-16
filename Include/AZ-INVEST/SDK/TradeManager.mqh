//
// Copyright 2018, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

#include <AZ-INVEST/SDK/TradeFunctions.mqh>

class CTradeManagerState
{
   public:
   
   void Clear() { DoneBreakEven = false; TrailStarted = false; };
   
   // Break Even
   bool DoneBreakEven;
   
   // Trailing Stop
   bool TrailStarted;
};

struct CTradeManagerParameters
{  
   // Break Even
   int BEPoints;
   
   // Trailing Stop
   int TrailByPoints;
   int TrailStartPoints;
};

class CTradeManager
{
   private:
   
      bool                    initialized;
      CMarketOrder            *orderHandler;
      CTradeManagerParameters inputs;
     
      ENUM_ORDER_TYPE         __type;
      double                  __open;
      string                  __symbol;
      double                  __tp;
      double                  __sl;      
      double                  __bid;
      double                  __ask;     
   
   public:
   
      CTradeManager();
      CTradeManager(CTradeManagerParameters &params, CMarketOrder *orderHalder);
      ~CTradeManager();
      
      bool IsInitialized() { return this.initialized; };
      bool Initialize(CTradeManagerParameters &params, CMarketOrder *orderHalder);
      bool Manage(ulong ticket, CTradeManagerState &_state);
      
   private:
         
      bool GetTradeInfo(ulong ticket);
      bool BreakEven(ulong ticket);
      bool OkToTrailStop(ulong ticket);
      bool TrailStop(ulong ticket);
      bool Close(ulong ticket);
      ENUM_ORDER_TYPE GetType(ulong ticket);
};


CTradeManager::CTradeManager(void)
{
   this.orderHandler   = NULL;
   this.initialized    = false;
}

CTradeManager::CTradeManager(CTradeManagerParameters &params,CMarketOrder *_orderHandler)
{
   this.orderHandler   = NULL;
   this.initialized    = false;
   Initialize(params, _orderHandler);   
}

CTradeManager::~CTradeManager(void)
{

}

bool CTradeManager::GetTradeInfo(ulong ticket)
{
   __type = GetType(ticket);
   __open = PositionGetDouble(POSITION_PRICE_OPEN);
   if(__open == 0)
      return false;
      
   __symbol = PositionGetString(POSITION_SYMBOL);   
   __tp = PositionGetDouble(POSITION_TP);      
   __sl = PositionGetDouble(POSITION_SL);      
   __bid = SymbolInfoDouble(__symbol,SYMBOL_BID);
   __ask = SymbolInfoDouble(__symbol,SYMBOL_ASK);

   return true;
}

bool CTradeManager::Initialize(CTradeManagerParameters &params, CMarketOrder *_orderHandler)
{
   // Dependency injection
   this.orderHandler                = _orderHandler;
   if(this.orderHandler == NULL)
   {
      Print(__FUNCTION__," failed on orderHandler == NULL");
      return false;   
   }
   //
      
   this.inputs.BEPoints             = params.BEPoints;
   this.inputs.TrailByPoints        = params.TrailByPoints;
   this.inputs.TrailStartPoints     = params.TrailStartPoints;
   this.initialized                 = true;
   
   return initialized;
}

bool CTradeManager::Manage(ulong ticket, CTradeManagerState &_state)
{
   if(!GetTradeInfo(ticket))
      return false;
      
   if(!_state.DoneBreakEven)
   {
      if(BreakEven(ticket))
         _state.DoneBreakEven = true;      
   }
   
   if(!_state.TrailStarted)
   {
      _state.TrailStarted = OkToTrailStop(ticket);
   }

   if(_state.TrailStarted)
   {
      TrailStop(ticket);
   }
      
   return true;
}

bool CTradeManager::Close(ulong ticket)
{
   return false;
}

bool CTradeManager::BreakEven(ulong ticket)
{
   if(this.inputs.BEPoints == 0)
      return false;
      
   double _beDistance = SymbolInfoDouble(__symbol,SYMBOL_POINT) * this.inputs.BEPoints;
   bool doBreakEven = false;
   
   if(__type == ORDER_TYPE_BUY)
   {
      if((__bid - _beDistance) >= __open)
         doBreakEven = true;         
   }
   else if(__type == ORDER_TYPE_SELL)
   {
      if((__ask + _beDistance) <= __open)
         doBreakEven = true;            
   }
   
   if(!doBreakEven)
      return false;
      
   return orderHandler.Modify(ticket,__open,__tp);
}

bool CTradeManager::OkToTrailStop(ulong ticket)
{
   if(this.inputs.TrailByPoints == 0)
      return false;

   double _startDistance = SymbolInfoDouble(__symbol,SYMBOL_POINT) * this.inputs.TrailStartPoints;
   bool okToStart = false;
      
   if(__type == ORDER_TYPE_BUY)
   {
      if((__bid - _startDistance) >= __open)
         okToStart = true;         
   }
   else if(__type == ORDER_TYPE_SELL)
   {
      if((__ask + _startDistance) <= __open)
         okToStart = true;            
   }   
   
   if(!okToStart)
      return false;
      
   return true;      
}

bool CTradeManager::TrailStop(ulong ticket)
{
   if(this.inputs.TrailByPoints == 0)
      return false;

   double _trailDistance = SymbolInfoDouble(__symbol,SYMBOL_POINT) * this.inputs.TrailByPoints;
   double _sl = __sl;
   bool okToModify = false;
   
   if(__type == ORDER_TYPE_BUY)
   {
      _sl = (__bid - _trailDistance);
      if(_sl > __sl)
         okToModify = true;         
   }
   else if(__type == ORDER_TYPE_SELL)
   {
      _sl = (__ask + _trailDistance);
      if(_sl < __sl)
         okToModify = true;         
   }   

   if(okToModify)
      return orderHandler.Modify(ticket,_sl,__tp);
   
   return false;
}

ENUM_ORDER_TYPE CTradeManager::GetType(ulong ticket)
{
   ENUM_POSITION_TYPE _pType;
   orderHandler.GetPositionType(ticket,_pType);
   return orderHandler.TradeBias((ENUM_ORDER_TYPE)_pType);
}