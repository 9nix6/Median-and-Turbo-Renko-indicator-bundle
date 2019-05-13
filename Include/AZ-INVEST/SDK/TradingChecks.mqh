//
// Copyright 2018, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

#ifdef __MQL5__
   //--- class for performing trade operations
   #include <Trade\Trade.mqh>
   CTrade trade;
   //--- class for working with orders
   #include <Trade\OrderInfo.mqh>
   COrderInfo orderinfo;
   //--- class for working with positions
   #include <Trade\PositionInfo.mqh>
   CPositionInfo positioninfo;

   //--- introduce the predefined variables from MQL4 for versatility of the code
   #define Ask    SymbolInfoDouble(_symbol,SYMBOL_ASK)
   #define Bid    SymbolInfoDouble(_symbol,SYMBOL_BID)
   
   bool suppressLogOutput = false;
   
   void SuppressGlobalLogOutput() { suppressLogOutput = true; };
   
#endif

#define _point SymbolInfoDouble(_symbol,SYMBOL_POINT)

//--- redefine the order types from MQL5 to MQL4 for use in common code
#ifdef __MQL4__ 
#define ORDER_TYPE_BUY        OP_BUY
#define ORDER_TYPE_SELL       OP_SELL
#define ORDER_TYPE_BUY_LIMIT  OP_BUYLIMIT
#define ORDER_TYPE_SELL_LIMIT OP_SELLLIMIT
#define ORDER_TYPE_BUY_STOP   OP_BUYSTOP
#define ORDER_TYPE_SELL_STOP  OP_SELLSTOP
#endif 

enum ENUM_TC_ERROR
{
   tcErrorNONE = 0,
   tcErrorNotEnoughMoney,
   tcErrorInvalidStops,
   tcErrorOrderLimitReached,
   tcErrorFreezeLevel,
   tcErrorNothingChanged,
   tcErrorInvalidPrice,
};

class CTradingChecks
{
   private:
   
   ENUM_TC_ERROR _err;
   bool _suppressLogOutput;
   
   public:
   
   CTradingChecks();
   ~CTradingChecks();
   
   string GetCheckErrorToString();
   void SuppressLogOutput() { _suppressLogOutput = true; };
   
   bool OkToOpenOrder(string _symbol,ENUM_ORDER_TYPE type, double lots, double entryPrice, double sl, double tp);
   bool OkToModifyOrder(string _symbol,ulong ticket,double price, double sl, double tp);
#ifdef __MQL5__      
   bool OkToOpenPosition(string _symbol,ENUM_ORDER_TYPE type, double lots, double entryPrice, double sl, double tp);
   bool OkToModifyPosition(string _symbol,ulong ticket, double sl, double tp);
#endif   
};

CTradingChecks::CTradingChecks(void)
{
   suppressLogOutput = false;
}

CTradingChecks::~CTradingChecks(void)
{
}

string CTradingChecks::GetCheckErrorToString(void)
{
   switch(_err)
   {
      case tcErrorNONE:
         return "No Error";
      case tcErrorNotEnoughMoney:
         return "Not enough money (check previous message in Experts log)";
      case tcErrorInvalidStops:
         return "Invalid stops (check previous message in Experts log)";
      case tcErrorOrderLimitReached:
         return "Maximum order limit reached";
      case tcErrorFreezeLevel:
         return "Freeze level (check previous message in Experts log)";
      case tcErrorNothingChanged:
         return "Nothing to change";
      case tcErrorInvalidPrice:
         return "Invalid entry price for this order type";
         
      default:
         return "";
   }   
}

bool CTradingChecks::OkToOpenOrder(string _symbol,ENUM_ORDER_TYPE type, double lots, double entryPrice,double sl, double tp)
{
   if(!IsNewPendingOrderAllowed())
   {
      _err = tcErrorOrderLimitReached;
      return false;
   }

   if(!CheckStopLoss_Takeprofit(_symbol,type,entryPrice,sl,tp))
   {
      _err = tcErrorInvalidStops;
      return false;
   }

   _err = tcErrorNONE;
   return true;
}

#ifdef __MQL5__
bool CTradingChecks::OkToOpenPosition(string _symbol,ENUM_ORDER_TYPE type, double lots, double entryPrice,double sl, double tp)
{
#ifdef __MQL5__   
   if(!CheckMoneyForTrade(_symbol,lots,type))
   {
      _err = tcErrorNotEnoughMoney;
      return false;   
   }
  // if(NewOrderAllowedVolume(_symbol) < lots)
  //    return false;
#else
   if(!CheckMoneyForTrade(_symbol,lots,(int)type))
   {
      _err = tcErrorNotEnoughMoney;
      return false;   
   }
   if(!IsNewPendingOrderAllowed())
   {
      _err = tcErrorOrderLimitReached;
      return false;
   }
#endif   

   if(!CheckStopLoss_Takeprofit(_symbol,type,entryPrice,sl,tp))
   {
      _err = tcErrorInvalidStops;
      return false;
   }
   
   _err = tcErrorNONE;
   return true;
}
#endif;

bool CTradingChecks::OkToModifyOrder(string _symbol, ulong ticket,double price, double sl, double tp)
{
#ifdef __MQL5__
   if(!OrderModifyCheck(ticket,price,sl,tp))
   {
      _err = tcErrorNothingChanged;
      return false;
   }
   if(!CheckOrderForFREEZE_LEVEL(_symbol,ticket))
   {
      _err = tcErrorFreezeLevel;
      return false;
   }
#else   
   if(!OrderModifyCheck((int)ticket,price,sl,tp))
   {
      _err = tcErrorNothingChanged;
      return false;
   }
   if(!CheckOrderForFREEZE_LEVEL(_symbol,(int)ticket))
   {
      _err = tcErrorFreezeLevel;
      return false;
   }
#endif   

   if(!CheckPendingOrderEntryChange(_symbol,ticket,price))
   {
      _err = tcErrorInvalidPrice;
      return false;
   }   

   _err = tcErrorNONE;
   return true;
}

#ifdef __MQL5__
bool CTradingChecks::OkToModifyPosition(string _symbol, ulong ticket,double sl,double tp)
{
   if(!PositionModifyCheck(ticket,sl,tp))
   {
      _err = tcErrorNothingChanged;
      return false;
   }
   if(!CheckPositionForFREEZE_LEVEL(_symbol,ticket))
   {
      _err = tcErrorFreezeLevel;
      return false;
   }
   
   _err = tcErrorNONE;
   return true;
}
#endif 

//////////////////////////////////////////////////////////////////
//
// Helper functions from https://www.mql5.com/en/articles/2555
// 
///////////////////////////////////////////////////////////////////

#ifdef __MQL5__
bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
  {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   //--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false
      if(suppressLogOutput == false)
      {
         Print("Error in ",__FUNCTION__," code=",GetLastError());
      }
        
      return(false);
     }
   //--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      if(suppressLogOutput == false)
      {
         Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
         Print("Required margin:"+DoubleToString(margin,2)+"; free margin:"+DoubleToString(free_margin,2));
      }
      return(false);
     }
//--- checking successful
   return(true);
  }
#else  
bool CheckMoneyForTrade(string symb, double lots,int type)
  {
   double free_margin=AccountFreeMarginCheck(symb,type, lots);
   //-- if there is not enough money
   if(free_margin<0)
     {
      string oper=(type==OP_BUY)? "Buy":"Sell";
      if(suppressLogOutput == false)
      {
         Print("Not enough money for ", oper," ",lots, " ", symb, " Error code=",GetLastError());
      }
      
      return(false);
     }
   //--- checking successful
   return(true);
  }  
#endif


//+------------------------------------------------------------------+
//| Check if another order can be placed                             |
//+------------------------------------------------------------------+
bool IsNewPendingOrderAllowed()
  {
//--- get the number of pending orders allowed on the account
   int max_allowed_orders=(int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);

//--- if there is no limitation, return true; you can send an order
   if(max_allowed_orders==0) return(true);

//--- if we passed to this line, then there is a limitation; find out how many orders are already placed
   int orders=OrdersTotal();

//--- return the result of comparing
   return(orders<max_allowed_orders);
  }
  
#ifdef __MQL5__
//+------------------------------------------------------------------+
//| Return the size of position on the specified symbol              |
//+------------------------------------------------------------------+
double PositionVolume(string symbol)
  {
//--- try to select position by a symbol
   bool selected=PositionSelect(symbol);
//--- there is a position
   if(selected)
      //--- return volume of the position
      return(PositionGetDouble(POSITION_VOLUME));
   else
     {
      //--- report a failure to select position
      if(suppressLogOutput == false)
      {
         Print(__FUNCTION__," Failed to perform PositionSelect() for symbol ",
            symbol," Error ",GetLastError());
      }
      return(-1);
     }
  }
  
//+------------------------------------------------------------------+
//|  returns the volume of current pending order by a symbol         |
//+------------------------------------------------------------------+
double   PendingsVolume(string symbol)
  {
   double volume_on_symbol=0;
   ulong ticket;
//---  get the number of all currently placed orders by all symbols
   int all_orders=OrdersTotal();

//--- get over all orders in the loop
   for(int i=0;i<all_orders;i++)
     {
      //--- get the ticket of an order by its position in the list
      ticket = OrderGetTicket(i);
      if((bool)ticket)
        {
         //--- if our symbol is specified in the order, add the volume of this order
         if(symbol==OrderGetString(ORDER_SYMBOL))
            volume_on_symbol+=OrderGetDouble(ORDER_VOLUME_INITIAL);
        }
     }
//--- return the total volume of currently placed pending orders for a specified symbol
   return(volume_on_symbol);
  }  
  
//+------------------------------------------------------------------+
//| Return the maximum allowed volume for an order on the symbol     |
//+------------------------------------------------------------------+
double NewOrderAllowedVolume(string symbol)
  {
   double allowed_volume=0;
//--- get the limitation on the maximal volume of an order
   double symbol_max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
//--- get the limitation on the volume by a symbol
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_LIMIT);

//--- get the volume of the open position by a symbol
   double opened_volume=PositionVolume(symbol);
   if(opened_volume>=0)
     {
      //--- if we have exhausted the volume
      if(max_volume-opened_volume<=0)
         return(0);

      //--- volume of the open position doesn't exceed max_volume
      double orders_volume_on_symbol=PendingsVolume(symbol);
      allowed_volume=max_volume-opened_volume-orders_volume_on_symbol;
      if(allowed_volume>symbol_max_volume) allowed_volume=symbol_max_volume;
     }
   return(allowed_volume);
  }
#endif  

//+------------------------------------------------------------------+
//| Check the correctness of StopLoss and TakeProfit                 |
//+------------------------------------------------------------------+
bool CheckStopLoss_Takeprofit(string _symbol, ENUM_ORDER_TYPE type,double price,double SL,double TP)
  {
//--- get the SYMBOL_TRADE_STOPS_LEVEL level
   int stops_level=(int)SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
   if(stops_level!=0)
     {
      if(suppressLogOutput == false)
      {
         PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must"+
                  " not be nearer than %d points from the closing price",stops_level,stops_level);
      }
     }
//---
   bool SL_check=false,TP_check=false;
//--- check the order type
   switch(type)
     {
      //--- Buy operation
      case  ORDER_TYPE_BUY:
        {
         //--- check the StopLoss
         SL_check= (SL==0) ? true : (Bid-SL>stops_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("For order %s   StopLoss=%.5f must be less than %.5f"+
                        " (Bid=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SL,Bid-stops_level*_point,Bid,stops_level);
         //--- check the TakeProfit
         TP_check= (TP==0) ? true : (TP-Bid>stops_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("For order %s   TakeProfit=%.5f must be greater than %.5f"+
                        " (Bid=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TP,Bid+stops_level*_point,Bid,stops_level);
         //--- return the result of checking
         return(SL_check&&TP_check);
        }
      //--- Sell operation
      case  ORDER_TYPE_SELL:
        {
         //--- check the StopLoss
         SL_check= (SL==0) ? true : (SL-Ask>stops_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("For order %s   StopLoss=%.5f must be greater than %.5f"+
                        " (Ask=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SL,Ask+stops_level*_point,Ask,stops_level);
         //--- check the TakeProfit
         TP_check= (TP==0) ? true : (Ask-TP>stops_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("For order %s   TakeProfit=%.5f must be less than %.5f"+
                        " (Ask=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TP,Ask-stops_level*_point,Ask,stops_level);
         //--- return the result of checking
         return(TP_check&&SL_check);
        }
      break;
      //--- BuyLimit pending order
      case  ORDER_TYPE_BUY_LIMIT:
        {
         //--- check the StopLoss
         SL_check= (SL==0) ? true : ((price-SL)>stops_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("For order %s   StopLoss=%.5f must be less than %.5f"+
                        " (Open-StopLoss=%d points ==> SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SL,price-stops_level*_point,(int)((price-SL)/_point),stops_level);
         //--- check the TakeProfit
         TP_check= (TP==0) ? true : ((TP-price)>stops_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("For order %s   TakeProfit=%.5f must be greater than %.5f"+
                        " (TakeProfit-Open=%d points ==> SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TP,price+stops_level*_point,(int)((TP-price)/_point),stops_level);
         //--- return the result of checking
         return(SL_check&&TP_check);
        }
      //--- SellLimit pending order
      case  ORDER_TYPE_SELL_LIMIT:
        {
         //--- check the StopLoss
         SL_check= (SL==0) ? true : ((SL-price)>stops_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("For order %s   StopLoss=%.5f must be greater than %.5f"+
                        " (StopLoss-Open=%d points ==> SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SL,price+stops_level*_point,(int)((SL-price)/_point),stops_level);
         //--- check the TakeProfit
         TP_check= (TP==0) ? true : ((price-TP)>stops_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("For order %s   TakeProfit=%.5f must be less than %.5f"+
                        " (Open-TakeProfit=%d points ==> SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TP,price-stops_level*_point,(int)((price-TP)/_point),stops_level);
         //--- return the result of checking
         return(TP_check&&SL_check);
        }
      break;
      //--- BuyStop pending order
      case  ORDER_TYPE_BUY_STOP:
        {
         //--- check the StopLoss
         SL_check= (SL==0) ? true : ((price-SL)>stops_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("For order %s   StopLoss=%.5f must be less than %.5f"+
                        " (Open-StopLoss=%d points ==> SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SL,price-stops_level*_point,(int)((price-SL)/_point),stops_level);
         //--- check the TakeProfit
         TP_check= (TP==0) ? true : ((TP-price)>stops_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("For order %s   TakeProfit=%.5f must be greater than %.5f"+
                        " (TakeProfit-Open=%d points ==> SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TP,price-stops_level*_point,(int)((TP-price)/_point),stops_level);
         //--- return the result of checking
         return(SL_check&&TP_check);
        }
      //--- SellStop pending order
      case  ORDER_TYPE_SELL_STOP:
        {
         //--- check the StopLoss
         SL_check= (SL==0) ? true : ((SL-price)>stops_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("For order %s   StopLoss=%.5f must be greater than %.5f"+
                        " (StopLoss-Open=%d points ==> SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SL,price+stops_level*_point,(int)((SL-price)/_point),stops_level);
         //--- check the TakeProfit
         TP_check= (TP==0) ? true : ((price-TP)>stops_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("For order %s   TakeProfit=%.5f must be less than %.5f"+
                        " (Open-TakeProfit=%d points ==> SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TP,price-stops_level*_point,(int)((price-TP)/_point),stops_level);
         //--- return the result of checking
         return(TP_check&&SL_check);
        }
      break;
     }

//---
   return false;
  }
  
#ifdef __MQL5__
//+------------------------------------------------------------------+
//| Checking the new values of levels before order modification      |
//+------------------------------------------------------------------+
bool OrderModifyCheck(ulong ticket,double price,double sl,double tp)
  {
//--- select order by ticket
   if(orderinfo.Select(ticket))
     {
      //--- point size and name of the symbol, for which a pending order was placed
      string symbol=orderinfo.Symbol();
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
      //--- check if there are changes in the Open price
      bool PriceOpenChanged=(MathAbs(orderinfo.PriceOpen()-price)>point);
      //--- check if there are changes in the StopLoss level
      bool StopLossChanged=(MathAbs(orderinfo.StopLoss()-sl)>point);
      //--- check if there are changes in the Takeprofit level
      bool TakeProfitChanged=(MathAbs(orderinfo.TakeProfit()-tp)>point);
      //--- if there are any changes in levels
      if(PriceOpenChanged || StopLossChanged || TakeProfitChanged)
         return(true);  // order can be modified      
      //--- there are no changes in the Open, StopLoss and Takeprofit levels
      else
      {
      //--- notify about the error
         if(suppressLogOutput == false)
         {
            PrintFormat("Order #%d already has levels of Open=%.5f SL=%.5f TP=%.5f",
                     ticket,orderinfo.PriceOpen(),orderinfo.StopLoss(),orderinfo.TakeProfit());
         }
      }
     }
//--- came to the end, no changes for the order
   return(false);       // no point in modifying 
  }
//+------------------------------------------------------------------+
//| Checking the new values of levels before order modification      |
//+------------------------------------------------------------------+
bool PositionModifyCheck(ulong ticket,double sl,double tp)
  {
//--- select order by ticket
   if(positioninfo.SelectByTicket(ticket))
     {
      //--- point size and name of the symbol, for which a pending order was placed
      string symbol=positioninfo.Symbol();
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      //--- check if there are changes in the StopLoss level
      bool StopLossChanged=(MathAbs(positioninfo.StopLoss()-sl)>point);
      //--- check if there are changes in the Takeprofit level
      bool TakeProfitChanged=(MathAbs(positioninfo.TakeProfit()-tp)>point);
      //--- if there are any changes in levels
      if(StopLossChanged || TakeProfitChanged)
         return(true);  // position can be modified      
      //--- there are no changes in the StopLoss and Takeprofit levels
      else
      {
      //--- notify about the error
         if(suppressLogOutput == false)
         {
            PrintFormat("Order #%d already has levels of Open=%.5f SL=%.5f TP=%.5f",
                     ticket,orderinfo.PriceOpen(),orderinfo.StopLoss(),orderinfo.TakeProfit());
         }
      }
     }
//--- came to the end, no changes for the order
   return(false);       // no point in modifying 
  }
#else
//+------------------------------------------------------------------+
//| Checking the new values of levels before order modification      |
//+------------------------------------------------------------------+
bool OrderModifyCheck(int ticket,double price,double sl,double tp)
  {
//--- select order by ticket
   if(OrderSelect(ticket,SELECT_BY_TICKET))
     {
      //--- point size and name of the symbol, for which a pending order was placed
      string symbol=OrderSymbol();
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      //--- check if there are changes in the Open price
      bool PriceOpenChanged=true;
      int type=OrderType();
      if(!(type==OP_BUY || type==OP_SELL))
        {
         PriceOpenChanged=(MathAbs(OrderOpenPrice()-price)>point);
        }
      //--- check if there are changes in the StopLoss level
      bool StopLossChanged=(MathAbs(OrderStopLoss()-sl)>point);
      //--- check if there are changes in the Takeprofit level
      bool TakeProfitChanged=(MathAbs(OrderTakeProfit()-tp)>point);
      //--- if there are any changes in levels
      if(PriceOpenChanged || StopLossChanged || TakeProfitChanged)
         return(true);  // order can be modified      
      //--- there are no changes in the Open, StopLoss and Takeprofit levels
      else
      {
      //--- notify about the error
         if(suppressLogOutput == false)
         {
            PrintFormat("Order #%d already has levels of Open=%.5f SL=%.5f TP=%.5f",
                     ticket,OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
         }
      }
     }
//--- came to the end, no changes for the order
   return(false);       // no point in modifying 
  }
#endif 


#ifdef __MQL5__
//+------------------------------------------------------------------+
//| Check the distance from opening price to activation price        |
//+------------------------------------------------------------------+
bool CheckOrderForFREEZE_LEVEL(string _symbol, ulong ticket)
  {
//--- get the SYMBOL_TRADE_FREEZE_LEVEL level
   int freeze_level=(int)SymbolInfoInteger(_symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   if(freeze_level!=0)
     {
      if(suppressLogOutput == false)
      {
         PrintFormat("SYMBOL_TRADE_FREEZE_LEVEL=%d: Cannot modify order"+
                  "  nearer than %d points from the activation price",freeze_level,freeze_level);
      }
     }
//--- select order for working
   if(!OrderSelect(ticket))
     {
      //--- failed to select order
      return(false);
     }
//--- get the order data
   double price=OrderGetDouble(ORDER_PRICE_OPEN);
   double sl=OrderGetDouble(ORDER_SL);
   double tp=OrderGetDouble(ORDER_TP);
   ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
//--- result of checking 
   bool check=false;
//--- check the order type
   switch(type)
     {
      //--- BuyLimit pending order
      case  ORDER_TYPE_BUY_LIMIT:
        {
         //--- check the distance from the opening price to the activation price
         check=((Ask-price)>freeze_level*_point);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order %s #%d cannot be modified: Ask-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        EnumToString(type),ticket,(int)((Ask-price)/_point),freeze_level);
         return(check);
        }
      //--- BuyLimit pending order
      case  ORDER_TYPE_SELL_LIMIT:
        {
         //--- check the distance from the opening price to the activation price
         check=((price-Bid)>freeze_level*_point);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order %s #%d cannot be modified: Open-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        EnumToString(type),ticket,(int)((price-Bid)/_point),freeze_level);
         return(check);
        }
      break;
      //--- BuyStop pending order
      case  ORDER_TYPE_BUY_STOP:
        {
         //--- check the distance from the opening price to the activation price
         check=((price-Ask)>freeze_level*_point);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order %s #%d cannot be modified: Ask-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        EnumToString(type),ticket,(int)((price-Ask)/_point),freeze_level);
         return(check);
        }
      //--- SellStop pending order
      case  ORDER_TYPE_SELL_STOP:
        {
         //--- check the distance from the opening price to the activation price
         check=((Bid-price)>freeze_level*_point);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order %s #%d cannot be modified: Bid-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        EnumToString(type),ticket,(int)((Bid-price)/_point),freeze_level);
         return(check);
        }
      break;
     }
//--- order did not pass the check
   return (false);
  }
//+------------------------------------------------------------------+
//| Check if the TP and SL are too close to activation price         |
//+------------------------------------------------------------------+
bool CheckPositionForFREEZE_LEVEL(string _symbol, ulong ticket)
  {
     
//--- get the SYMBOL_TRADE_FREEZE_LEVEL level
   int freeze_level=(int)SymbolInfoInteger(_symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   if(freeze_level!=0 && suppressLogOutput == false)
     {
      PrintFormat("SYMBOL_TRADE_FREEZE_LEVEL=%d: Cannot modify order"+
                  "  nearer than %d points from the activation price",freeze_level,freeze_level);
     }
//--- select position for working
   if(!PositionSelectByTicket(ticket))
     {
      //--- failed to select position
      return(false);
     }
//--- get the order data     
   ENUM_POSITION_TYPE pos_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double sl=PositionGetDouble(POSITION_SL);
   double tp=PositionGetDouble(POSITION_TP);
//--- result of checking StopLoss and TakeProfit
   bool SL_check=false,TP_check=false;
//--- position type
   switch(pos_type)
     {
      //--- buy
      case POSITION_TYPE_BUY:
        {
         SL_check=(sl == 0) ? true: (Bid-sl>freeze_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("Position %s #%d cannot be modified: Bid-StopLoss=%d points"+
                        " < SYMBOL_TRADE_FREEZE_LEVEL=%d points)",
                        EnumToString(pos_type),ticket,(int)((Bid-sl)/_point),freeze_level);
         TP_check=(tp == 0) ? true: (tp-Bid>freeze_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("Position %s #%d cannot be modified: TakeProfit-Bid=%d points"+
                        " < SYMBOL_TRADE_FREEZE_LEVEL=%d points)",
                        EnumToString(pos_type),ticket,(int)((tp-Bid)/_point),freeze_level);
         //--- return the result of checking
         return(SL_check&&TP_check);
        }
      break;
      //--- sell
      case POSITION_TYPE_SELL:
        {
         SL_check=(sl == 0) ? true: (sl-Ask>freeze_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("Position %s cannot be modified: StopLoss-Ask=%d points"+
                        " < SYMBOL_TRADE_FREEZE_LEVEL=%d points)",
                        EnumToString(pos_type),(int)((sl-Ask)/_point),freeze_level);
         TP_check=(tp == 0) ? true: (Ask-tp>freeze_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("Position %s cannot be modified: Ask-TakeProfit=%d points"+
                     " < SYMBOL_TRADE_FREEZE_LEVEL=%d points)",
                     EnumToString(pos_type),(int)((Ask-tp)/_point),freeze_level);
         //--- return the result of checking
         return(SL_check&&TP_check);
        }
      break;
     }
//--- position did not pass the check
   return (false);
  }
#else
bool CheckOrderForFREEZE_LEVEL(string _symbol,int ticket)
  {
//--- get the SYMBOL_TRADE_FREEZE_LEVEL level
   int freeze_level=(int)SymbolInfoInteger(_symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   if(freeze_level!=0 && suppressLogOutput == false)
     {
      PrintFormat("SYMBOL_TRADE_FREEZE_LEVEL=%d: Cannot modify order"+
                  "  nearer than %d points from the activation price",freeze_level,freeze_level);
     }
//--- select order for working
   if(!OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      //--- failed to select order
      return (false);
     }
//--- get the order data
   double price=OrderOpenPrice();
   double sl=OrderStopLoss();
   double tp=OrderTakeProfit();
   int type=OrderType();
//--- result of checking 
   bool check=false;
//--- check the order type
   switch(type)
     {
      //--- BuyLimit pending order
      case  OP_BUYLIMIT:
        {
         //--- check the distance from the opening price to the activation price
         check=((Ask-price)>freeze_level*_point);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order OP_BUYLIMIT #%d cannot be modified: Ask-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        ticket,(int)((Ask-price)/_point),freeze_level);
         return(check);
        }
      //--- BuyLimit pending order
      case  OP_SELLLIMIT:
        {
         //--- check the distance from the opening price to the activation price
         check=((price-Bid)>freeze_level*_point);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order OP_SELLLIMIT #%d cannot be modified: Open-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        ticket,(int)((price-Bid)/_point),freeze_level);
         return(check);
        }
      break;
      //--- BuyStop pending order
      case  OP_BUYSTOP:
        {
         //--- check the distance from the opening price to the activation price
         check=((price-Ask)>freeze_level*_point);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order OP_BUYSTOP #%d cannot be modified: Ask-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        ticket,(int)((price-Ask)/_point),freeze_level);
         return(check);
        }
      //--- SellStop pending order
      case  OP_SELLSTOP:
        {
         //--- check the distance from the opening price to the activation price
         check=((Bid-price)>freeze_level*_point);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order OP_SELLSTOP #%d cannot be modified: Bid-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        ticket,(int)((Bid-price)/_point),freeze_level);
         return(check);
        }
      break;
      //--- checking opened Buy order
      case  OP_BUY:
        {
         //--- check TakeProfit distance to the activation price
         bool TP_check=(tp == 0) ? true: (tp-Bid>freeze_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("Order OP_BUY %d cannot be modified: TakeProfit-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        ticket,(int)((tp-Bid)/_point),freeze_level);
         //--- check TakeProfit distance to the activation price
         bool SL_check=(sl == 0) ? true: (Bid-sl>freeze_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("Order OP_BUY %d cannot be modified: TakeProfit-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        ticket,(int)((Bid-sl)/_point),freeze_level);
         return(SL_check&&TP_check);
        }
      break;
      //--- checking opened Sell order
      case  OP_SELL:
        {
         //--- check TakeProfit distance to the activation price
         bool TP_check=(tp == 0) ? true: (Ask-tp>freeze_level*_point);
         if(!TP_check && suppressLogOutput == false)
            PrintFormat("Order OP_SELL %d cannot be modified: Ask-TakeProfit=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        ticket,(int)((Ask-tp)/_point),freeze_level);
         //--- check TakeProfit distance to the activation price
         bool SL_check=(sl == 0) ? true: (sl-Ask>freeze_level*_point);
         if(!SL_check && suppressLogOutput == false)
            PrintFormat("Order OP_BUY %d cannot be modified: TakeProfit-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        ticket,(int)((sl-Ask)/_point),freeze_level);
         return(SL_check&&TP_check);
        }
      break;
     }
//--- order did not pass the check
   return (false);
  }
#endif  

bool CheckPendingOrderEntryChange(string _symbol, ulong ticket, double newEntryPrice)
  {
//--- select order for working
   if(!OrderSelect(ticket))
     {
      //--- failed to select order
      return(false);
     }
//--- get the order data
   ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
//--- result of checking 
   bool check=false;
//--- check the order type
   switch(type)
     {
      //--- BuyLimit pending order
      case  ORDER_TYPE_BUY_LIMIT:
        {
         //--- check the distance from the opening price to the activation price
         check= (newEntryPrice < Ask);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order %s #%d cannot be modified",
                        EnumToString(type),ticket);
         return(check);
        }
      //--- BuyLimit pending order
      case  ORDER_TYPE_SELL_LIMIT:
        {
         //--- check the distance from the opening price to the activation price
         check=(newEntryPrice > Bid);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order %s #%d cannot be modified",
                        EnumToString(type),ticket);
         return(check);
        }
      break;
      //--- BuyStop pending order
      case  ORDER_TYPE_BUY_STOP:
        {
         //--- check the distance from the opening price to the activation price
         check=(newEntryPrice > Ask);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order %s #%d cannot be modified",
                        EnumToString(type),ticket);
         return(check);
        }
      //--- SellStop pending order
      case  ORDER_TYPE_SELL_STOP:
        {
         //--- check the distance from the opening price to the activation price
         check=(newEntryPrice < Bid);
         if(!check && suppressLogOutput == false)
            PrintFormat("Order %s #%d cannot be modified",
                        EnumToString(type),ticket);
         return(check);
        }
      break;
     }
//--- order did not pass the check
   return (false);
  }        