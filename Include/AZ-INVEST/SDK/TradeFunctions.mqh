//+------------------------------------------------------------------+
//|                                               TradeFunctions.mqh |
//|                                        Copyright 2017, AZ-iNVEST |
//|                                          http://www.az-invest.eu |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, AZ-iNVEST"
#property link      "http://www.az-invest.eu"
#include <Trade\Trade.mqh>

#define POSITION_TYPE_NONE -1

//
// Positions (market orders)
//

struct CMarketOrderParameters
{
   bool              m_async_mode;      // trade mode
   ulong             m_magic;           // expert magic number
   ulong             m_deviation;       // deviation default
   ENUM_ORDER_TYPE_FILLING m_type_filling;   
   
   int numberOfRetries;
   int busyTimeout_ms; 
   int requoteTimeout_ms;
   
};

class CMarketOrder
{
   protected:
   
   CTrade * ctrade;
   
   int numberOfRetries;
   int busyTimeout_ms; 
   int requoteTimeout_ms;   
   
   public:
   
   CMarketOrder(CMarketOrderParameters &params);
   ~CMarketOrder(void);
   
   bool Long(string symbol, double lots, uint stoploss = 0, uint takeprofit = 0);
   bool Long(string symbol,double lots, double priceSL=0,double priceTP=0);
   bool Short(string symbol,double lots, uint stoploss = 0, uint takeprofit = 0);
   bool Short(string symbol,double lots, double priceSL=0,double priceTP=0);
   bool Modify(ulong ticket, uint stoploss = 0, uint takeprofit = 0);
   bool Modify(ulong ticket, double priceSL=0,double priceTP=0);
   bool Close(ulong ticket);
   bool ClosePartial(ulong ticket, double lots);
   bool Reverse(ulong ticket,double lots = 0, uint stoploss=0, uint takeprofit=0);
   bool Reverse(ulong ticket,double lots = 0, double priceSL=0,double priceTP=0);
   bool IsOpen(string symbol, ENUM_POSITION_TYPE type, long magicNumber = 0);
   bool IsOpen(ulong &ticket, string symbol, ENUM_POSITION_TYPE type, long magicNumber = 0);
   bool IsOpen(string symbol, long magicNumber = 0);
   bool IsOpen(ulong &ticket, string symbol, long magicNumber = 0);
   bool IsOpen(ulong &ticket, ENUM_POSITION_TYPE &type, string symbol, long magicNumber = 0);
   
   string PositionTypeToString(ENUM_POSITION_TYPE t);
   bool RetryOrderRequest(int retryNumber);

   private: 
   
   bool _IsOpen(ulong &ticket, string symbol, ENUM_POSITION_TYPE type, long magicNumber);
   bool _IsOpen(ulong &ticket, string symbol, long magicNumber);
   bool _IsNettingAccount() { return ((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) ? true : false; };

};

CMarketOrder::CMarketOrder(CMarketOrderParameters &params)
{
   ctrade = new CTrade();

   ctrade.SetExpertMagicNumber(params.m_magic);
   ctrade.SetDeviationInPoints(params.m_deviation);
   ctrade.SetTypeFilling(params.m_type_filling);
   ctrade.SetAsyncMode(params.m_async_mode);
   
   this.numberOfRetries = (params.numberOfRetries == 0) ? 25 : params.numberOfRetries;
   this.busyTimeout_ms = (params.busyTimeout_ms == 0) ? 1000 : params.busyTimeout_ms;
   this.requoteTimeout_ms = (params.requoteTimeout_ms == 0) ? 250 : params.requoteTimeout_ms;
   
}

CMarketOrder::~CMarketOrder(void)
{
   if(ctrade != NULL)
      delete ctrade;
}

bool CMarketOrder::Long(string symbol, double lots,uint stoploss=0,uint takeprofit=0)
{  
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      double price = SymbolInfoDouble(symbol,SYMBOL_ASK);
      double _point = SymbolInfoDouble(symbol,SYMBOL_POINT);
      
      //calc SL + TP
      double priceSL = (stoploss   ? NormalizePrice(symbol,price -   stoploss*_point) : 0.0);
      double priceTP = (takeprofit ? NormalizePrice(symbol,price + takeprofit*_point) : 0.0);
      
      //attempt to buy
      result = ctrade.Buy(NormalizeLots(symbol,lots), symbol, price, priceSL, priceTP);
      
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

bool CMarketOrder::Long(string symbol, double lots,double priceSL=0,double priceTP=0)
{
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      double price = SymbolInfoDouble(symbol,SYMBOL_ASK);
      
      //attempt to buy
      result = ctrade.Buy(NormalizeLots(symbol,lots), symbol, price, priceSL, priceTP);
      
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

bool CMarketOrder::Short(string symbol, double lots,uint stoploss=0,uint takeprofit=0)
{
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      double price = SymbolInfoDouble(symbol,SYMBOL_BID);
      double _point = SymbolInfoDouble(symbol,SYMBOL_POINT);
         
      //calc SL + TP
      double priceSL = (stoploss   ? NormalizePrice(symbol,price +   stoploss*_point) : 0.0);
      double priceTP = (takeprofit ? NormalizePrice(symbol,price - takeprofit*_point) : 0.0);
      
      //attempt to sell
      result = ctrade.Sell(NormalizeLots(symbol,lots), symbol, price, priceSL, priceTP);
      
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

bool CMarketOrder::Short(string symbol, double lots,double priceSL=0,double priceTP=0)
{
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      double price = SymbolInfoDouble(symbol,SYMBOL_BID);
   
      //attempt to sell
      result = ctrade.Sell(NormalizeLots(symbol,lots), symbol, price, priceSL, priceTP);

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

bool CMarketOrder::Modify(ulong ticket, uint stoploss = 0, uint takeprofit = 0)
{
   if(!PositionSelectByTicket(ticket))
      return false;
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   double price = PositionGetDouble(POSITION_PRICE_CURRENT);
   double _point = SymbolInfoDouble(symbol,SYMBOL_POINT);   
   double priceSL;
   double priceTP;
   
   if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
      priceSL = (stoploss   ? NormalizePrice(symbol,price -   stoploss*_point) : PositionGetDouble(POSITION_SL));
      priceTP = (takeprofit ? NormalizePrice(symbol,price + takeprofit*_point) : PositionGetDouble(POSITION_TP));
   }
   else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
      priceSL = (stoploss   ? NormalizePrice(symbol,price +   stoploss*_point) : PositionGetDouble(POSITION_SL));
      priceTP = (takeprofit ? NormalizePrice(symbol,price - takeprofit*_point) : PositionGetDouble(POSITION_TP));
   }
   else
      return false;
      
   //there's no change in SL or TP - do nothing!
   if (priceSL == PositionGetDouble(POSITION_SL) 
    && priceTP == PositionGetDouble(POSITION_TP))
      return true;
      
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {
      //attempt to modify position
      result = ctrade.PositionModify(symbol,priceSL,priceTP);
   
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
   double price = PositionGetDouble(POSITION_PRICE_CURRENT);
   double _point = SymbolInfoDouble(symbol,SYMBOL_POINT);   
      
   //there's no change in SL or TP - do nothing!
   if (priceSL == PositionGetDouble(POSITION_SL) 
    && priceTP == PositionGetDouble(POSITION_TP))
      return true;
      
   bool result = false;
   int counter = 0;
   
   while(!IsStopped() && !result)
   {      
      //attempt to modify position
      result = ctrade.PositionModify(symbol,priceSL,priceTP);
   
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

bool CMarketOrder::RetryOrderRequest(int retryNumber)
{
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
         return false;
   }

}

//+------------------------------------------------------------------+
//| Normalizing                                                      |
//+------------------------------------------------------------------+

double NormalizeLots(string symbol, double InputLots)
{
   double lotsMin    = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double lotsMax    = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   int lotsDigits  = (int) - MathLog10(SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));

   if(InputLots < lotsMin)
      InputLots = lotsMin;
   if(InputLots > lotsMax)
      InputLots = lotsMax;

   return NormalizeDouble(InputLots, lotsDigits);
}

double NormalizePrice(string symbol, double price, double tick = 0)
{
   double _tick = tick ? tick : SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   int _digits = (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   
   if (tick) 
      return NormalizeDouble(MathRound(price/_tick)*_tick,_digits);
   else 
      return NormalizeDouble(price,_digits);
}
 