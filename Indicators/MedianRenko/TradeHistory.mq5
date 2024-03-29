#property copyright "Copyright © 2022, Artur Zas"
#property link      "https://www.az-invest.eu"
#property version   "1.01"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0

#define CHART_ID 0
#define CHART_SUBWINDOW_ID 0
#define OBJECT_NAME_PREFIX "TH_"
#define AUTOTRADE_OBJECT_NAME_PREFIX "autotrade "

input color BuyArrowColorInp = C'3,95,172'; // Buy arrow color
input color SellArrowColorInp = C'255,68,29'; // Sell arrow color
input ENUM_LINE_STYLE LineStyleInp = STYLE_DOT; // Line style
input int LineWidthInp = 1; // Line width

#include <AZ-INVEST/Double.mqh>
#include <AZ-INVEST/CustomBarConfig.mqh>
#include <AZ-INVEST/sdk/HistoryHandler.mqh>

CHistoryHandler historyHandler;

//+------------------------------------------------------------------+
//| Custom indicator init/deinit function                            |
//+------------------------------------------------------------------+
int OnInit()
{
   customChartIndicator.SetGetTimeFlag();      
   deleteAllCreatedObjects();   
   
   return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason)
{
   deleteAllCreatedObjects();
}  

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,time,close))
      return(0);
      
   if(!customChartIndicator.BufferSynchronizationCheck(close))
      return(0);
   
   historyHandler.GetHistoryDiff(_Symbol);
   if(historyHandler.HistoryChanged())
   {
      deleteAutotradeObjects();
   }
   
   int count = historyHandler.Count();
      
   for(int i = 0; i < count; i++)
   {
      if(!historyHandler.SelectByPositionIndex(i))
         continue;
      
      TradeInfoObject o = historyHandler.GetTradeInfoObject();
      if(o.Ticket == 0)
         continue;
         
      datetime canvasChartTradeOpenTime;            
      datetime canvasChartTradeCloseTime;   
      
      bool result = customChartIndicator.CustomChartTimeToCanvasTime(o.OpenTime, canvasChartTradeOpenTime);
      result &= customChartIndicator.CustomChartTimeToCanvasTime(o.CloseTime, canvasChartTradeCloseTime);

      if(!result)
         continue;

      o.OpenTime = canvasChartTradeOpenTime;
      o.CloseTime = canvasChartTradeCloseTime;
           
      drawTrendline(o);
      drawEndpoints(o);
   }
      
   return(rates_total);
}
//+------------------------------------------------------------------+

void drawTrendline(TradeInfoObject &t)
{
   string lineName = OBJECT_NAME_PREFIX+(string)t.Ticket;
   
   
   if(!CDouble::IsEqual(t.OpenPrice,0,_Digits) || !CDouble::IsEqual(t.ClosePrice,0,_Digits) || t.OpenTime<=0 || t.CloseTime<=0) 
   {
      ObjectDelete(CHART_ID, lineName);
      return;
   };
   
   if (ObjectFind(CHART_ID, lineName) != 0) 
   {
      ObjectCreate(CHART_ID,lineName, OBJ_TREND, CHART_SUBWINDOW_ID, t.OpenTime, t.OpenPrice, t.CloseTime, t.ClosePrice);
      ObjectSetInteger(CHART_ID, lineName, OBJPROP_STYLE, LineStyleInp);
      ObjectSetInteger(CHART_ID, lineName, OBJPROP_COLOR, isBuy(t.Type) ? BuyArrowColorInp : SellArrowColorInp);
      ObjectSetInteger(CHART_ID, lineName, OBJPROP_WIDTH, LineWidthInp);
      ObjectSetInteger(CHART_ID, lineName, OBJPROP_BACK,  false);
      ObjectSetInteger(CHART_ID, lineName, OBJPROP_RAY,  false);
      ObjectSetInteger(CHART_ID, lineName, OBJPROP_SELECTABLE, false);
      ObjectSetString(CHART_ID, lineName, OBJPROP_TOOLTIP, "\n");
   }
   else 
   {
      ObjectMove(CHART_ID, lineName, 0, t.OpenTime, t.OpenPrice);
      ObjectMove(CHART_ID, lineName, 1, t.CloseTime, t.ClosePrice);
   }
}

void drawEndpoints(TradeInfoObject &t)
{
   string startArrowName = OBJECT_NAME_PREFIX+(string)t.Ticket+"s";
   
   if (ObjectFind(CHART_ID, startArrowName) != 0) 
   {
      ObjectCreate(CHART_ID, startArrowName, (isBuy(t.Type) ? OBJ_ARROW_BUY : OBJ_ARROW_SELL), CHART_SUBWINDOW_ID, t.OpenTime, t.OpenPrice);
      ObjectSetInteger(CHART_ID, startArrowName, OBJPROP_ARROWCODE, 3);
      ObjectSetInteger(CHART_ID, startArrowName, OBJPROP_COLOR, isBuy(t.Type) ? BuyArrowColorInp : SellArrowColorInp);
      ObjectSetString(CHART_ID, startArrowName, OBJPROP_TOOLTIP, buildToolTip(t, true));
   }
   else
   {
      ObjectMove(CHART_ID, startArrowName, 0, t.OpenTime, t.OpenPrice);
   }
      
   string endArrowName = OBJECT_NAME_PREFIX+(string)t.Ticket+"e";

   if(CDouble::IsEqual(t.ClosePrice,0,_Digits) || t.CloseTime==0) 
   {
      ObjectDelete(CHART_ID, endArrowName);
      return;
   };

   if (ObjectFind(CHART_ID, endArrowName) != 0) 
   {
      ObjectCreate(CHART_ID, endArrowName, (!isBuy(t.Type) ? OBJ_ARROW_BUY : OBJ_ARROW_SELL), CHART_SUBWINDOW_ID, t.CloseTime, t.ClosePrice);
      ObjectSetInteger(CHART_ID, endArrowName, OBJPROP_ARROWCODE, 3);
      ObjectSetInteger(CHART_ID, endArrowName, OBJPROP_COLOR, !isBuy(t.Type) ? BuyArrowColorInp : SellArrowColorInp);
      ObjectSetString(CHART_ID, endArrowName, OBJPROP_TOOLTIP, buildToolTip(t, false));
   }
   else
   {
      ObjectMove(CHART_ID, endArrowName, 0, t.CloseTime, t.ClosePrice);
   }
}

string buildToolTip(TradeInfoObject &t, bool isOpen)
{
   return "#"+(string)t.Ticket+" "+
      (isBuy(t.Type) ? "buy " : "sell ")+
      DoubleToString(isOpen ? t.OpenVolume : t.CloseVolume, 2)+" "+
      DoubleToString(isOpen ? t.OpenPrice : t.ClosePrice, _Digits);
}

bool isBuy(ENUM_ORDER_TYPE type)
{
   if(type == ORDER_TYPE_BUY 
      || type == ORDER_TYPE_BUY_LIMIT 
      || type == ORDER_TYPE_BUY_STOP 
      || type == ORDER_TYPE_BUY_STOP_LIMIT)
      return true;

   return false;
}

void deleteAllCreatedObjects()
{
   ObjectsDeleteAll(CHART_ID, OBJECT_NAME_PREFIX, CHART_SUBWINDOW_ID, OBJ_TREND);
   ObjectsDeleteAll(CHART_ID, OBJECT_NAME_PREFIX, CHART_SUBWINDOW_ID, OBJ_ARROW_BUY);
   ObjectsDeleteAll(CHART_ID, OBJECT_NAME_PREFIX, CHART_SUBWINDOW_ID, OBJ_ARROW_SELL);
}

void deleteAutotradeObjects()
{
   ObjectsDeleteAll(CHART_ID, AUTOTRADE_OBJECT_NAME_PREFIX);
}