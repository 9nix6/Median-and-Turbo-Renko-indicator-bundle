#include <Generic/ArrayList.mqh>
#include <Trade/DealInfo.mqh>

struct TradeInfoObject
{
   long Ticket;
   ENUM_ORDER_TYPE Type;   
   datetime OpenTime;
   double OpenPrice;
   double OpenVolume;
   datetime CloseTime;
   double ClosePrice;
   double CloseVolume;
};

class CHistoryHandler
{
   private:
   
   datetime _startDate;
   CArrayList<long> _historyList;
      
   public:
   
   void CHistoryHandler(datetime startDate = 0);
   void ~CHistoryHandler();
   
   void GetHistoryDiff(string symbol = "");
   bool HistoryChanged();
   int Count() { return _historyList.Count(); };
   bool SelectByPositionIndex(int ix);
   TradeInfoObject GetTradeInfoObject();
   
   private:
   
   void Reset();   
   bool AddItem(CDealInfo &dealInfo);
   bool ContainsElement(long positionId);
};

void CHistoryHandler::CHistoryHandler(datetime startDate = 0)
{
   _startDate = startDate;
   Reset();
}

void CHistoryHandler::~CHistoryHandler()
{
   Reset();
}

bool CHistoryHandler::AddItem(CDealInfo &dealInfo)
{
   
   return _historyList.Add(dealInfo.PositionId());
}

void CHistoryHandler::GetHistoryDiff(string symbol="")
{
   HistorySelect(_startDate, TimeCurrent());
   CDealInfo dealInfo;
   
   for(int pos=HistoryDealsTotal()-1; pos>=0; pos--)
   {   
      if(!dealInfo.SelectByIndex(pos) || dealInfo.PositionId() == 0)
         continue;
      
      bool contains = ContainsElement(dealInfo.PositionId());
      
      if(contains || (symbol != "" && dealInfo.Symbol() != symbol))
         continue;         
    
      _historyList.Add(dealInfo.PositionId());      
   }   
}

bool CHistoryHandler::ContainsElement(long positionId)
{
   if(_historyList.Count() == 0)
      return false;
   
   return _historyList.Contains(positionId);
}

bool CHistoryHandler::HistoryChanged()
{
   static int _prevCount = 0;
   
   int currentCount = _historyList.Count();
   if(currentCount != _prevCount)
   {
      _prevCount = currentCount;
      return true;
   }
   
   return false;
}

void CHistoryHandler::Reset()
{
   long temp;
   
   while(_historyList.Count() > 0)
   {      
      if(_historyList.TryGetValue(0, temp))
      {
         _historyList.RemoveAt(0);
      }
   }   
}

bool CHistoryHandler::SelectByPositionIndex(int ix)
{
   long positionId = 0;
   bool result = _historyList.TryGetValue(ix, positionId);
   
   if(!result || !HistorySelectByPosition(positionId))
      return false;
      
   return true;
}

TradeInfoObject CHistoryHandler::GetTradeInfoObject()
{
    TradeInfoObject trade;
    trade.Ticket = 0;
     
    for(int i = 0; i<HistoryDealsTotal(); i++)
    {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0)
         continue;
         
      ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
      
      if(dealEntry == DEAL_ENTRY_IN)
      {
         trade.Ticket = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
         trade.Type = (ENUM_ORDER_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
         trade.OpenPrice = HistoryDealGetDouble(ticket, DEAL_PRICE);
         trade.OpenTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         trade.OpenVolume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
      }
      else if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY)
      {
         trade.ClosePrice = HistoryDealGetDouble(ticket, DEAL_PRICE);
         trade.CloseTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);      
         trade.CloseVolume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
      }         
    }

    return trade;
}

