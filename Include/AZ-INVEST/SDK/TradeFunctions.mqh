//
// Copyright 2017-2018, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

#include <Trade\Trade.mqh>
#include <AZ-INVEST/SDK/Normailze.mqh>
#include <AZ-INVEST/SDK/TradingChecks.mqh>
CTradingChecks tradingChecks;

#define POSITION_TYPE_NONE -1

//
// Positions (market orders)
//

struct CMarketOrderParameters
{
   bool                    m_async_mode;      // trade mode
   ulong                   m_magic;           // expert magic number
   ulong                   m_deviation;       // deviation default
   ENUM_ORDER_TYPE_FILLING m_type_filling;   
   
   int                     numberOfRetries;
   int                     busyTimeout_ms; 
   int                     requoteTimeout_ms;   
};

class CMarketOrder
{
   protected:
   
   CTrade                  *ctrade;
   
   bool                    initialized;
   
   int                     numberOfRetries;
   int                     busyTimeout_ms; 
   int                     requoteTimeout_ms;   
   
   public:
   
   CMarketOrder(void);
   CMarketOrder(CMarketOrderParameters &params);
   ~CMarketOrder(void);
   
   bool Initialize(CMarketOrderParameters &params);
   bool IsInitialized() {return initialized;};
   
   bool Long(string symbol, double lots, uint stoploss = 0, uint takeprofit = 0,bool stopsInPips = true, string comment = "");
   bool Long(string symbol,double lots, double priceSL=0,double priceTP=0, string comment = "");
   bool Short(string symbol,double lots, uint stoploss = 0, uint takeprofit = 0,bool stopsInPips = true, string comment = "");
   bool Short(string symbol,double lots, double priceSL=0,double priceTP=0, string comment = "");
   
   bool PendingLong(ENUM_ORDER_TYPE orderType, string symbol, double lots, double price, uint stoploss=0,uint takeprofit=0,bool stopsInPips = true, string comment = "");
   bool PendingLong(ENUM_ORDER_TYPE orderType, string symbol, double lots, double price, double priceSL=0, double priceTP=0, string comment = "");
   bool PendingShort(ENUM_ORDER_TYPE orderType, string symbol, double lots, double price, uint stoploss=0,uint takeprofit=0,bool stopsInPips = true, string comment = "");
   bool PendingShort(ENUM_ORDER_TYPE orderType, string symbol, double lots, double price, double priceSL=0, double priceTP=0, string comment = "");
   
   bool Modify(ulong ticket, bool stopsInPips = true, int stoploss = -1, int takeprofit = -1);   
   bool Modify(ulong ticket, double priceSL=0,double priceTP=0);

   bool ModifyPending(ulong ticket, double entry, bool stopsInPips = true, int stoploss = -1, int takeprofit = -1, ENUM_ORDER_TYPE_TIME orderTypeTime = ORDER_TIME_GTC, datetime expires = 0);
   bool ModifyPending(ulong ticket, double entry, double priceSL=0, double priceTP=0, ENUM_ORDER_TYPE_TIME orderTypeTime = ORDER_TIME_GTC, datetime expires = 0);
   
   bool Close(ulong ticket);
   bool ClosePartial(ulong ticket, double lots);
   bool CloseAll(string symbol = "");
   bool Delete(ulong ticket);

   bool Reverse(ulong ticket,double lots = 0, uint stoploss=0, uint takeprofit=0);
   bool Reverse(ulong ticket,double lots = 0, double priceSL=0,double priceTP=0);
   bool IsOpen(string symbol, ENUM_POSITION_TYPE type, long magicNumber = 0);
   bool IsOpen(ulong &ticket, string symbol, ENUM_POSITION_TYPE type, long magicNumber = 0);
   bool IsOpen(string symbol, long magicNumber = 0);
   bool IsOpen(ulong &ticket, string symbol, long magicNumber = 0);
   bool IsOpen(ulong &ticket, ENUM_POSITION_TYPE &type, string symbol, long magicNumber = 0);
   
   bool GetPositionType(ulong ticket, ENUM_POSITION_TYPE &_pType);
   string PositionTypeToString(ENUM_POSITION_TYPE t);
   string OrderTypeToString(ENUM_ORDER_TYPE t);
   ENUM_ORDER_TYPE TradeBias(ENUM_ORDER_TYPE t);
   bool RetryOrderRequest(int retryNumber);
   
   void SetTradeId(ulong tradeId);

   private: 
   
   bool _IsOpen(ulong &ticket, string symbol, ENUM_POSITION_TYPE type, long magicNumber);
   bool _IsOpen(ulong &ticket, string symbol, long magicNumber);
   bool _IsNettingAccount() { return ((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) ? true : false; };

};

CMarketOrder::CMarketOrder(void)
{
   ctrade = new CTrade();
   this.initialized = false;
}

CMarketOrder::CMarketOrder(CMarketOrderParameters &params)
{
   ctrade = new CTrade();
   Initialize(params);
}

bool CMarketOrder::Initialize(CMarketOrderParameters &params)
{
   ctrade.SetExpertMagicNumber(params.m_magic);
   ctrade.SetDeviationInPoints(params.m_deviation);
   ctrade.SetTypeFilling(params.m_type_filling);
   ctrade.SetAsyncMode(params.m_async_mode);
   
   this.numberOfRetries    = (params.numberOfRetries == 0) ? 25 : params.numberOfRetries;
   this.busyTimeout_ms     = (params.busyTimeout_ms == 0) ? 1000 : params.busyTimeout_ms;
   this.requoteTimeout_ms  = (params.requoteTimeout_ms == 0) ? 250 : params.requoteTimeout_ms;
   
   this.initialized = true;
   return this.initialized;
}

CMarketOrder::~CMarketOrder(void)
{
   if(ctrade != NULL)
      delete ctrade;
}

bool CMarketOrder::Long(string symbol, double lots,uint stoploss=0,uint takeprofit=0,bool stopsInPips = true, string comment = "")
{  
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      double price = SymbolInfoDouble(symbol,SYMBOL_ASK);
      double point = SymbolInfoDouble(symbol,SYMBOL_POINT);
      
      //calc SL + TP
      double priceSL = (stoploss   ? NormalizePrice(symbol,price -   stoploss*point) : 0.0);
      double priceTP = (takeprofit ? NormalizePrice(symbol,price + takeprofit*point) : 0.0);
      
      //do checks
      if(!tradingChecks.OkToOpenPosition(symbol,ORDER_TYPE_BUY,lots,price,priceSL,priceTP))
      {
         Alert("Unable to place trade: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
      
      //attempt to buy
      result = ctrade.Buy(NormalizeLots(symbol,lots), symbol, price, priceSL, priceTP, comment);
      
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;
}

bool CMarketOrder::Long(string symbol, double lots,double priceSL=0,double priceTP=0, string comment = "")
{
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      double price = SymbolInfoDouble(symbol,SYMBOL_ASK);
      
      //do checks
      if(!tradingChecks.OkToOpenPosition(symbol,ORDER_TYPE_BUY,lots,price,priceSL,priceTP))
      {
         Alert("Unable to place trade: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
      
      //attempt to buy
      result = ctrade.Buy(NormalizeLots(symbol,lots), symbol, price, priceSL, priceTP, comment);
      
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;     
}

bool CMarketOrder::Short(string symbol, double lots,uint stoploss=0,uint takeprofit=0,bool stopsInPips = true, string comment = "")
{
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      double price = SymbolInfoDouble(symbol,SYMBOL_BID);
      double point = SymbolInfoDouble(symbol,SYMBOL_POINT);
         
      //calc SL + TP
      double priceSL = (stoploss   ? NormalizePrice(symbol,price +   stoploss*point) : 0.0);
      double priceTP = (takeprofit ? NormalizePrice(symbol,price - takeprofit*point) : 0.0);
      
      //do checks
      if(!tradingChecks.OkToOpenPosition(symbol,ORDER_TYPE_SELL,lots,price,priceSL,priceTP))
      {
         Alert("Unable to place trade: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
            
      //attempt to sell
      result = ctrade.Sell(NormalizeLots(symbol,lots), symbol, price, priceSL, priceTP, comment);
      
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;    
}

bool CMarketOrder::Short(string symbol, double lots,double priceSL=0,double priceTP=0, string comment = "")
{
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      double price = SymbolInfoDouble(symbol,SYMBOL_BID);
   
      //do checks
      if(!tradingChecks.OkToOpenPosition(symbol,ORDER_TYPE_SELL,lots,price,priceSL,priceTP))
      {
         Alert("Unable to place trade: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
   
      //attempt to sell
      result = ctrade.Sell(NormalizeLots(symbol,lots), symbol, price, priceSL, priceTP, comment);

      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;    
}


bool CMarketOrder::PendingLong(ENUM_ORDER_TYPE orderType, string symbol, double lots, double price, uint stoploss=0,uint takeprofit=0,bool stopsInPips = true, string comment = "")
{  
   bool result = false;
   
   while(!IsStopped() && !result)
   {
      double point = SymbolInfoDouble(symbol,SYMBOL_POINT);
      
      //calc SL + TP
      double priceSL = (stoploss   ? NormalizePrice(symbol,price -   stoploss*point) : 0.0);
      double priceTP = (takeprofit ? NormalizePrice(symbol,price + takeprofit*point) : 0.0);
      
      //do checks
      if(!tradingChecks.OkToOpenPosition(symbol,orderType,lots,price,priceSL,priceTP))
      {
         Alert("Unable to place trade: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
            
      //attempt to place buy
      if(orderType == ORDER_TYPE_BUY_LIMIT)
         result = ctrade.BuyLimit(NormalizeLots(symbol,lots),price,symbol,priceSL,priceTP,ORDER_TIME_GTC,0,comment);
      else if(orderType == ORDER_TYPE_BUY_STOP)
         result = ctrade.BuyStop(NormalizeLots(symbol,lots),price,symbol,priceSL,priceTP,ORDER_TIME_GTC,0,comment);
      
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
        string err = ctrade.ResultRetcodeDescription();
        MessageBox(err,"Operation failed",MB_ICONEXCLAMATION);
        return false;
      }         
   }

   return false;
}

bool CMarketOrder::PendingLong(ENUM_ORDER_TYPE orderType, string symbol, double lots, double price, double priceSL=0, double priceTP=0, string comment = "")
{
   bool result = false;
   
   while(!IsStopped() && !result)
   {
      //do checks
      if(!tradingChecks.OkToOpenPosition(symbol,orderType,lots,price,priceSL,priceTP))
      {
         Alert("Unable to place trade: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
      
      //attempt to buy
      if(orderType == ORDER_TYPE_BUY_LIMIT)
         result = ctrade.BuyLimit(NormalizeLots(symbol,lots),price,symbol,priceSL,priceTP,ORDER_TIME_GTC,0,comment);
      else if(orderType == ORDER_TYPE_BUY_STOP)
         result = ctrade.BuyStop(NormalizeLots(symbol,lots),price,symbol,priceSL,priceTP,ORDER_TIME_GTC,0,comment);
      
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         string err = ctrade.ResultRetcodeDescription();
         MessageBox(err,"Operation failed",MB_ICONEXCLAMATION);
         return false;
      }         
   }

   return false;     
}


bool CMarketOrder::PendingShort(ENUM_ORDER_TYPE orderType, string symbol, double lots, double price, uint stoploss=0,uint takeprofit=0,bool stopsInPips = true, string comment = "")
{
   bool result = false;
   
   while(!IsStopped() && !result)
   {
      double point = SymbolInfoDouble(symbol,SYMBOL_POINT);
         
      //calc SL + TP
      double priceSL = (stoploss   ? NormalizePrice(symbol,price +   stoploss*point) : 0.0);
      double priceTP = (takeprofit ? NormalizePrice(symbol,price - takeprofit*point) : 0.0);
      
      //do checks
      if(!tradingChecks.OkToOpenPosition(symbol,orderType,lots,price,priceSL,priceTP))
      {
         Alert("Unable to place trade: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
      
      //attempt to sell
      if(orderType == ORDER_TYPE_SELL_LIMIT)
         result = ctrade.SellLimit(NormalizeLots(symbol,lots),price,symbol,priceSL,priceTP,ORDER_TIME_GTC,0,comment);
      else if(orderType == ORDER_TYPE_SELL_STOP)
         result = ctrade.SellStop(NormalizeLots(symbol,lots),price,symbol,priceSL,priceTP,ORDER_TIME_GTC,0,comment);
      
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
        string err = ctrade.ResultRetcodeDescription();
        MessageBox(err,"Operation failed",MB_ICONEXCLAMATION);
        return false;
      }         
   }

   return false;    
}

bool CMarketOrder::PendingShort(ENUM_ORDER_TYPE orderType, string symbol, double lots, double price, double priceSL=0, double priceTP=0, string comment = "")
{
   bool result = false;
   
   while(!IsStopped() && !result)
   {
      //do checks
      if(!tradingChecks.OkToOpenPosition(symbol,orderType,lots,price,priceSL,priceTP))
      {
         Alert("Unable to place trade: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
      
      //attempt to sell
      if(orderType == ORDER_TYPE_SELL_LIMIT)
         result = ctrade.SellLimit(NormalizeLots(symbol,lots),price,symbol,priceSL,priceTP,ORDER_TIME_GTC,0,comment);
      else if(orderType == ORDER_TYPE_SELL_STOP)
         result = ctrade.SellStop(NormalizeLots(symbol,lots),price,symbol,priceSL,priceTP,ORDER_TIME_GTC,0,comment);

      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         string err = ctrade.ResultRetcodeDescription();
         MessageBox(err,"Operation failed",MB_ICONEXCLAMATION);
         return false;
      }         
   }

   return false;    
}

bool CMarketOrder::Modify(ulong ticket, bool stopsInPips = true, int stoploss = -1, int takeprofit = -1)
{
   if(!PositionSelectByTicket(ticket))
      return false;
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   double price = PositionGetDouble(POSITION_PRICE_OPEN);
   double point = SymbolInfoDouble(symbol,SYMBOL_POINT);   
   double priceSL;
   double priceTP;
   
   if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
   {
      priceSL = (stoploss < 0) 
                  ? PositionGetDouble(POSITION_SL) 
                  : (stoploss == 0) 
                     ? 0
                     : NormalizePrice(symbol,price - stoploss*point);
      
      priceTP = (takeprofit < 0) 
                  ? PositionGetDouble(POSITION_TP)
                  : (takeprofit == 0)
                     ? 0
                     : NormalizePrice(symbol,price + takeprofit*point);      
//      priceSL = (stoploss   ? NormalizePrice(symbol,price -   stoploss*_point) : PositionGetDouble(POSITION_SL));
//      priceTP = (takeprofit ? NormalizePrice(symbol,price + takeprofit*_point) : PositionGetDouble(POSITION_TP));
   }
   else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
   {
//      priceSL = (stoploss   ? NormalizePrice(symbol,price +   stoploss*_point) : PositionGetDouble(POSITION_SL));
//      priceTP = (takeprofit ? NormalizePrice(symbol,price - takeprofit*_point) : PositionGetDouble(POSITION_TP));
      priceSL = (stoploss < 0)
                  ? PositionGetDouble(POSITION_SL)
                  : (stoploss == 0)
                     ? 0
                     : NormalizePrice(symbol,price + stoploss*point);
      
      priceTP = (takeprofit < 0)
                  ? PositionGetDouble(POSITION_TP)
                  : (takeprofit == 0)
                     ? 0
                     : NormalizePrice(symbol,price - takeprofit*point);
   }
   else
      return false;
      
   //there's no change in SL or TP - do nothing!
   if (priceSL == PositionGetDouble(POSITION_SL) 
    && priceTP == PositionGetDouble(POSITION_TP))
      return false;
      
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      //do checks
      if(!tradingChecks.OkToModifyPosition(symbol,ticket,priceSL,priceTP))
      {
         Print("Unable to modify: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
      
      //attempt to modify position
      if(_IsNettingAccount())
         result = ctrade.PositionModify(symbol,priceSL,priceTP);
      else
         result = ctrade.PositionModify(ticket,priceSL,priceTP);
   
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;    
}

bool CMarketOrder::Modify(ulong ticket, double priceSL=0,double priceTP=0)
{
   if(!PositionSelectByTicket(ticket))
      return false;
      
   string symbol = PositionGetString(POSITION_SYMBOL);
   double price = PositionGetDouble(POSITION_PRICE_OPEN);
   //double point = SymbolInfoDouble(symbol,SYMBOL_POINT);   
      
   //there's no change in SL or TP - do nothing!
   if (priceSL == PositionGetDouble(POSITION_SL) 
    && priceTP == PositionGetDouble(POSITION_TP))
      return false;
      
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {      
      //do checks
      if(!tradingChecks.OkToModifyPosition(symbol,ticket,priceSL,priceTP))
      {
         Print("Unable to modify: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
   
      //attempt to modify position
      if(_IsNettingAccount())
         result = ctrade.PositionModify(symbol,priceSL,priceTP);
      else
         result = ctrade.PositionModify(ticket,priceSL,priceTP);
   
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;    
}

bool CMarketOrder::ModifyPending(ulong ticket, double entry, bool stopsInPips = true, int stoploss = -1, int takeprofit = -1, ENUM_ORDER_TYPE_TIME orderTypeTime = ORDER_TIME_GTC, datetime expires = 0)
{
   if(!OrderSelect(ticket))
      return false;
      
   string symbol = OrderGetString(ORDER_SYMBOL);
   double point = SymbolInfoDouble(symbol,SYMBOL_POINT);   
   if(entry == 0)
      entry = OrderGetDouble(ORDER_PRICE_OPEN);

   double priceSL;
   double priceTP;
   
   if((OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY) ||
      (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT) ||
      (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP) ||
      (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP_LIMIT))
   {
      priceSL = (stoploss < 0) 
                  ? OrderGetDouble(ORDER_SL) 
                  : (stoploss == 0) 
                     ? 0
                     : NormalizePrice(symbol,entry - stoploss*point);
      
      priceTP = (takeprofit < 0) 
                  ? OrderGetDouble(ORDER_TP) 
                  : (takeprofit == 0)
                     ? 0
                     : NormalizePrice(symbol,entry + takeprofit*point);
   }
   else if((OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL) ||
      (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_LIMIT) ||
      (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP) ||
      (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP_LIMIT))
   {
      priceSL = (stoploss < 0)
                  ? OrderGetDouble(ORDER_SL)
                  : (stoploss == 0)
                     ? 0
                     : NormalizePrice(symbol,entry + stoploss*point);
      
      priceTP = (takeprofit < 0)
                  ? OrderGetDouble(ORDER_TP)
                  : (takeprofit == 0)
                     ? 0
                     : NormalizePrice(symbol,entry - takeprofit*point);
   }
   else
      return false;
      
   //there's no change in parameters - do nothing!
   if (priceSL == OrderGetDouble(ORDER_SL) 
    && priceTP == OrderGetDouble(ORDER_TP)
    && entry == OrderGetDouble(ORDER_PRICE_OPEN)
    && orderTypeTime == OrderGetInteger(ORDER_TYPE_TIME)
    && expires == OrderGetInteger(ORDER_TIME_EXPIRATION))
      return false;
            
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      //do checks
      if(!tradingChecks.OkToModifyOrder(symbol,ticket,entry,priceSL,priceTP))
      {
         Print("Unable to modify: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
      
      //attempt to modify position
      result = ctrade.OrderModify(ticket,entry,priceSL,priceTP,orderTypeTime,expires);  
   
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;    
}


bool CMarketOrder::ModifyPending(ulong ticket, double entry, double priceSL=0, double priceTP=0, ENUM_ORDER_TYPE_TIME orderTypeTime = ORDER_TIME_GTC, datetime expires = 0)
{
   if(!OrderSelect(ticket))
      return false;
      
   string symbol = OrderGetString(ORDER_SYMBOL);
   if(entry == 0)
      entry = OrderGetDouble(ORDER_PRICE_OPEN);
         
   //there's no change in parameters - do nothing!
   if (priceSL == OrderGetDouble(ORDER_SL) 
    && priceTP == OrderGetDouble(ORDER_TP)
    && entry == OrderGetDouble(ORDER_PRICE_OPEN)
    && orderTypeTime == OrderGetInteger(ORDER_TYPE_TIME)
    && expires == OrderGetInteger(ORDER_TIME_EXPIRATION))
      return false;
      
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {      
      //do checks
      if(!tradingChecks.OkToModifyOrder(symbol,ticket,entry,priceSL,priceTP))
      {
         Print("Unable to modify: "+tradingChecks.GetCheckErrorToString());
         return false;
      }
   
      //attempt to modify position
      result = ctrade.OrderModify(ticket,entry,priceSL,priceTP,orderTypeTime,expires);  
   
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;    
}

bool CMarketOrder::Close(ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
      return false;

   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      result = ctrade.PositionClose(ticket);
      
      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;          
}

bool CMarketOrder::ClosePartial(ulong ticket, double lots)
{
   if(!PositionSelectByTicket(ticket))
      return false;
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      result = ctrade.PositionClosePartial(ticket, NormalizeLots(symbol,lots));

      if(result)
      {
         Sleep(500);
         return true;
      }
      else
      {
         if(!RetryOrderRequest(++counter))
            return false;
      }         
   }

   return false;          
}

bool CMarketOrder::Delete(ulong ticket)
{
   return ctrade.OrderDelete(ticket);           
}

bool CMarketOrder::Reverse(ulong ticket,double lots = 0, uint stoploss=0, uint takeprofit=0)
{
   if(!PositionSelectByTicket(ticket))
      return false;
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   double positionLots = PositionGetDouble(POSITION_VOLUME);
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   if(!this.Close(ticket))
      return false;
   
   if(type == POSITION_TYPE_BUY)
   {         
      return this.Short(symbol,(lots ? lots : positionLots),stoploss,takeprofit);
   }
   else if(type == POSITION_TYPE_SELL)
   {
      return this.Long(symbol,(lots ? lots : positionLots),stoploss,takeprofit);
   }

   return false;
}

bool CMarketOrder::Reverse(ulong ticket,double lots = 0, double priceSL=0,double priceTP=0)
{
   if(!PositionSelectByTicket(ticket))
      return false;
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   double positionLots = PositionGetDouble(POSITION_VOLUME);
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   if(!this.Close(ticket))
      return false;
   
   if(type == POSITION_TYPE_BUY)
   {         
      return this.Short(symbol,(lots ? lots : positionLots),priceSL,priceTP);
   }
   else if(type == POSITION_TYPE_SELL)
   {
      return this.Long(symbol,(lots ? lots : positionLots),priceSL,priceTP);
   }

   return false;
}

bool CMarketOrder::IsOpen(string symbol, ENUM_POSITION_TYPE type, long magicNumber = 0)
{
   ulong ticket;
   return this._IsOpen(ticket,symbol,type,magicNumber);
}

bool CMarketOrder::IsOpen(ulong &ticket, string symbol, ENUM_POSITION_TYPE type, long magicNumber = 0)
{
   return this._IsOpen(ticket, symbol,type,magicNumber);
}

bool CMarketOrder::IsOpen(string symbol, long magicNumber = 0)
{
   ulong ticket;
   return this._IsOpen(ticket,symbol,magicNumber);
}

bool CMarketOrder::IsOpen(ulong &ticket, string symbol, long magicNumber = 0)
{
   return this._IsOpen(ticket,symbol,magicNumber);
}

bool CMarketOrder::CloseAll(string symbol = "")
{
   int positions=PositionsTotal();
   ulong ticketsToClose[];
   int ticketsToCloseCounter = 0;
   
   if(positions > 0)
      ArrayResize(ticketsToClose,positions);
   else
      return false;
      
   for(int i=0;i<positions;i++)
   {
//      ResetLastError();
      ulong _ticket=PositionGetTicket(i);
      if(_ticket!=0)
      {
         if(PositionSelectByTicket(_ticket))
         {
            if((PositionGetString(POSITION_SYMBOL) == symbol) || (symbol == ""))
            {
               ticketsToClose[ticketsToCloseCounter] = _ticket;
               ticketsToCloseCounter++;
            }
         }         
         
      }
   }   
   
   ArrayResize(ticketsToClose,ticketsToCloseCounter);   
   for(int i=0;i<ticketsToCloseCounter;i++)
   {
      this.Close(ticketsToClose[i]);
   }   
   
   return true;
}

bool CMarketOrder::IsOpen(ulong &ticket,ENUM_POSITION_TYPE &type,string symbol,long magicNumber=0)
{
   int positions=PositionsTotal();
   
   for(int i=0;i<positions;i++)
   {
      ResetLastError();

      ulong _ticket=PositionGetTicket(i);
      
      if(_ticket!=0)
      {
         if(PositionSelectByTicket(_ticket))
         {
            if(magicNumber > 0)
            {
               if(PositionGetInteger(POSITION_MAGIC) != magicNumber)
                  continue;
            }
            
            if(PositionGetString(POSITION_SYMBOL) == symbol)
            {
               ticket = _ticket;
               type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               return true;
            }
         }         
      }
      else        
      {
         PrintFormat("Error when obtaining position from the list to the cache. Error code: %d",GetLastError());
      }
   }
   
   return false;      

}

bool CMarketOrder::GetPositionType(ulong ticket, ENUM_POSITION_TYPE &_pType)
{
   if(!PositionSelectByTicket(ticket))   
      return false;
      
   _pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);      
   return true;   
}

bool CMarketOrder::_IsOpen(ulong &ticket, string symbol, ENUM_POSITION_TYPE type, long magicNumber)
{
   int positions=PositionsTotal();
   long _type;
   
   for(int i=0;i<positions;i++)
   {
      ResetLastError();

      ulong _ticket=PositionGetTicket(i);
      
      if(_ticket!=0)
      {
         if(PositionSelectByTicket(_ticket))
         {
            
            if(magicNumber > 0)
            {
               if(PositionGetInteger(POSITION_MAGIC) != magicNumber)
                  continue;
            }
            
            if(!PositionGetInteger(POSITION_TYPE,_type))
               continue;
            
            if((_type == type) && (PositionGetString(POSITION_SYMBOL) == symbol))
            {
               ticket = _ticket;
               return true;
            }
         }         
      }
      else        
      {
         PrintFormat("Error when obtaining position from the list to the cache. Error code: %d",GetLastError());
      }
   }
   
   return false;      
}

bool CMarketOrder::_IsOpen(ulong &ticket, string symbol, long magicNumber = 0)
{
   int positions=PositionsTotal();
   
   
   for(int i=0;i<positions;i++)
   {
      ResetLastError();

      ulong _ticket=PositionGetTicket(i);
      
      if(_ticket!=0)
      {
         if(PositionSelectByTicket(_ticket))
         {
            if(magicNumber > 0)
            {
               if(PositionGetInteger(POSITION_MAGIC) != magicNumber)
                  continue;
            }
            
            if((PositionGetString(POSITION_SYMBOL) == symbol))
            {
               ticket = _ticket;
               return true;
            }
         }         
      }
      else        
      {
         PrintFormat("Error when obtaining position from the list to the cache. Error code: %d",GetLastError());
      }
   }
   
   return false;      
}

string CMarketOrder::PositionTypeToString(ENUM_POSITION_TYPE t)
{
   if(t == POSITION_TYPE_BUY)
      return "Buy";
   else if(t == POSITION_TYPE_SELL)
      return "Sell";
   else
      return "-";
}

string CMarketOrder::OrderTypeToString(ENUM_ORDER_TYPE t)
{
   if(t == ORDER_TYPE_BUY)
      return "Buy";
   else if(t == ORDER_TYPE_BUY_LIMIT)
      return "Buy Limit";
   else if(t == ORDER_TYPE_BUY_STOP)
      return "Buy Stop";
   else if(t == ORDER_TYPE_BUY_STOP_LIMIT)
      return "Buy Stop Limit";
   else if(t == ORDER_TYPE_SELL)
      return "Sell";
   else if(t == ORDER_TYPE_SELL_LIMIT)
      return "Sell Limit";
   else if(t == ORDER_TYPE_SELL_STOP)
      return "Sell Stop";
   else if(t == ORDER_TYPE_SELL_STOP_LIMIT)
      return "Sell Stop Limit";
   else
      return "-";
}

ENUM_ORDER_TYPE CMarketOrder::TradeBias(ENUM_ORDER_TYPE t)
{
   if((t == ORDER_TYPE_BUY) ||
      (t == ORDER_TYPE_BUY_LIMIT) ||
      (t == ORDER_TYPE_BUY_STOP) ||
      (t == ORDER_TYPE_BUY_STOP_LIMIT))
         return ORDER_TYPE_BUY;
   else 
         return ORDER_TYPE_SELL;
}

bool CMarketOrder::RetryOrderRequest(int retryNumber)
{
   Print(ctrade.ResultRetcodeDescription());

   if(retryNumber >= this.numberOfRetries)
   {
      PrintFormat("Giving up on maximum number of retries (%d)",this.numberOfRetries);
      return false;
   }
      
   switch(ctrade.ResultRetcode())
   {
      case TRADE_RETCODE_REQUOTE           :

         Sleep(this.requoteTimeout_ms);
         return true;
               
      break;

      case TRADE_RETCODE_REJECT            :
      case TRADE_RETCODE_ERROR             :
      case TRADE_RETCODE_TIMEOUT           :
      case TRADE_RETCODE_PRICE_OFF         :
      case TRADE_RETCODE_TOO_MANY_REQUESTS :

         Sleep(this.busyTimeout_ms);
         return true;
   
      break;
      
      default:
         MessageBox(ctrade.ResultRetcodeDescription(),"Operation failed",MB_ICONEXCLAMATION);
         return false;
   }

}

void CMarketOrder::SetTradeId(ulong tradeId)
{
   ctrade.SetExpertMagicNumber(tradeId);
}


 