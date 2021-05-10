//
// Copyright 2018-2021, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

#include <AZ-INVEST/SDK/TradeFunctions.mqh>

class CTradeManagerState
{
   public:
   
   void Clear() { DoneBreakEven = false; TrailStarted = false; DonePartialClose = false; };
   
   // Break Even
   bool DoneBreakEven;
   
   // Trailing Stop
   bool TrailStarted;
   
   // Partial Close
   bool DonePartialClose;
};

struct CTradeManagerParameters
{  
   // Break Even
   int BEPoints;
   
   // Trailing Stop
   int TrailByPoints;
   int TrailStartPoints;
   
   // Partial Close
   int PartialCloseAtProfitPoints;
   int PartialClosePercentage;
};

class CTradeManager
{
   private:
   
      bool                    initialized;
      CMarketOrder            *orderHandler;
      CTradeManagerParameters inputs;
     
      ENUM_ORDER_TYPE         __type;
      double                  __open;
      double                  __lots;   
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
      string ToString();
      
   private:
         
      bool GetTradeInfo(ulong ticket);
      bool BreakEven(ulong ticket);
      bool OkToTrailTheStop(ulong ticket);
      bool TrailTheStop(ulong ticket);
      bool PartialClose(ulong ticket, double lots);
      double GetPartialCloseLotSize();
      bool IsDistanceFromOpenReached(double distancePriceDiff);
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
      
   __lots = PositionGetDouble(POSITION_VOLUME);
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
   this.inputs       = params;      
   
   // normalize inputs
   this.inputs.PartialClosePercentage = MathMin(MathAbs(this.inputs.PartialClosePercentage), 100);
   
   //   
   this.initialized  = true;
   return initialized;
}

bool CTradeManager::Manage(ulong ticket, CTradeManagerState &_state)
{
   if(!GetTradeInfo(ticket))
      return false; // trade info not available
      
   if(!_state.DonePartialClose)
   {
      _state.DonePartialClose = PartialClose(ticket, GetPartialCloseLotSize());
   }

   if(!_state.DoneBreakEven)
   {
      if(BreakEven(ticket))
         _state.DoneBreakEven = true;      
   }
      
   if(!_state.TrailStarted)
   {
      _state.TrailStarted = OkToTrailTheStop(ticket);
   }

   if(_state.TrailStarted)
   {
      TrailTheStop(ticket);
   }
            
   return true;
}

bool CTradeManager::PartialClose(ulong ticket, double lots)
{
   if(this.inputs.PartialCloseAtProfitPoints == 0 || lots == 0)
      return false; // nothing to do
   
   double _partialCloseDistance = SymbolInfoDouble(__symbol,SYMBOL_POINT) * this.inputs.PartialCloseAtProfitPoints;   
   if(!IsDistanceFromOpenReached(_partialCloseDistance))
      return false;

   return orderHandler.ClosePartial(ticket, lots);
}

bool CTradeManager::BreakEven(ulong ticket)
{
   if(this.inputs.BEPoints == 0)
      return false; // nothing to do
      
   double _beDistance = SymbolInfoDouble(__symbol,SYMBOL_POINT) * this.inputs.BEPoints;
   if(!IsDistanceFromOpenReached(_beDistance))
      return false;
      
   return orderHandler.Modify(ticket,__open,__tp);
}

bool CTradeManager::OkToTrailTheStop(ulong ticket)
{
   if(this.inputs.TrailByPoints == 0)
      return false; // nothing to do

   double _startDistance = SymbolInfoDouble(__symbol,SYMBOL_POINT) * this.inputs.TrailStartPoints;
   if(!IsDistanceFromOpenReached(_startDistance))
      return false;
      
   return true;      
}

bool CTradeManager::TrailTheStop(ulong ticket)
{
   if(this.inputs.TrailByPoints == 0)
      return false; // nothing to do

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

double CTradeManager::GetPartialCloseLotSize()
{
   double lotsToClose = (__lots * inputs.PartialClosePercentage) / 100;   
   return NormalizeLots(__symbol, lotsToClose);   
}

bool CTradeManager::IsDistanceFromOpenReached(double distancePriceDiff)
{
   if(__type == ORDER_TYPE_BUY)
   {
      if((__bid - distancePriceDiff) >= __open)
         return true;         
   }
   else if(__type == ORDER_TYPE_SELL)
   {
      if((__ask + distancePriceDiff) <= __open)
         return true;            
   }   
   
   return false;
}

string CTradeManager::ToString()
{
   string _be = (inputs.BEPoints > 0) ? "[BE ON] " : "[BE off] ";
   string _trail = (inputs.TrailByPoints > 0) ? "[Trail ON] ": "[Trail off] ";
   string _partial = (inputs.PartialCloseAtProfitPoints > 0) ? "[Partial "+(string)inputs.PartialClosePercentage+"%] ": "[Partial off] ";
   
   return _be+_trail+_partial;
}