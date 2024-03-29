//+------------------------------------------------------------------+
//|                                      Ozymandias_System_Alert.mq5 |
//|                                     Copyright © 2014, GoldnMoney |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2014, GoldnMoney"
#property link "http://www.mql5.com"
//--- номер версии индикатора
#property version   "1.01"
//--- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 9
#property indicator_buffers 9 
//---- использовано 4 графических построения
#property indicator_plots   4
//+-----------------------------------------+
//|  Параметры отрисовки индикатора         |
//+-----------------------------------------+
//--- отрисовка индикатора в виде многоцветной линии
#property indicator_type1   DRAW_COLOR_LINE
//--- в качестве цветов двухцветной линии использованы
#property indicator_color1  clrDeepPink,clrDodgerBlue
//--- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//--- толщина линии индикатора равна 3
#property indicator_width1  3
//--- отображение метки индикатора
#property indicator_label1  "Ozymandias"
//+-----------------------------------------+
//|  Параметры отрисовки индикатора уровней |
//+-----------------------------------------+
//--- отрисовка уровней в виде линий
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
//--- выбор цветов уровней
#property indicator_color2  clrRosyBrown
#property indicator_color3  clrRosyBrown
//--- уровни - штрихпунктирные кривые
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_SOLID
//--- толщина уровней равна 2
#property indicator_width2  2
#property indicator_width3  2
//--- отображение метки уровней
#property indicator_label2  "Upper Ozymandias"
#property indicator_label3  "Lower Ozymandias"
//+--------------------------------------------+
//| Параметры отрисовки свечей                 |
//+--------------------------------------------+
//---- в качестве индикатора использованы цветные свечи
#property indicator_type4   DRAW_COLOR_CANDLES
#property indicator_color4   clrGold,clrBrown,clrGreen,clrLimeGreen
//---- отображение метки индикатора
#property indicator_label4  "OzymandiasOpen;OzymandiasHigh;OzymandiasLow;OzymandiasClose"
//+-----------------------------------------+
//| объявление констант                     |
//+-----------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчёт индикатора
//+-----------------------------------------+
//| Входные параметры индикатора            |
//+-----------------------------------------+
input uint Length=2;
input  ENUM_MA_METHOD MAType=MODE_SMA;
input uint Shift=0;   //Сдвиг канала по горизонтали в право в барах
input uint NumberofBar=1;//Номер бара для подачи сигнала
input bool SoundON=true; //Разрешение алерта
input uint NumberofAlerts=2;//Количество алертов
input bool EMailON=false; //Разрешение почтовой отправки сигнала
input bool PushON=false; //Разрешение отправки сигнала на мобильный
input int  InpLookback = 3000; // Maximum lookback period
//+-----------------------------------------+
//--- объявление динамических массивов, которые в дальнейшем будут использованы в качестве индикаторных буферов
double ExtOpenBuffer[],ExtHighBuffer[],ExtLowBuffer[],ExtCloseBuffer[],ExtColorBuffer[];
double IndBuffer[],ColorIndBuffer[];
double UpBuffer[],DnBuffer[];
//--- объявление целочисденных переменных начала отсчета данных
int min_rates_total;
//int ATR_Handle,HMA_Handle,LMA_Handle;

#include <IncOnRingBuffer\CATROnRingBuffer.mqh>
#include <AZ-INVEST/CustomBarConfig.mqh>

int _start = 0;
CATROnRingBuffer ATR;
CMAOnRingBuffer HMA;
CMAOnRingBuffer LMA;

//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//--- инициализация переменных начала отсчета данных
   min_rates_total=int(Length);
//--- инициализация глобальных переменных 
   int ATR_Period=100;
   min_rates_total=MathMax(min_rates_total,ATR_Period);
//--- получение хендла индикатора ATR
//   ATR_Handle=iATR(NULL,0,ATR_Period);
//   if(ATR_Handle==INVALID_HANDLE)
     if(!ATR.Init(ATR_Period,MODE_SMA,InpLookback,true))
     {
      Print(" Не удалось получить хендл индикатора ATR");
      return(INIT_FAILED);
     }
//--- получение хендла индикатора iMA
//   HMA_Handle=iMA(NULL,0,Length,0,MAType,PRICE_HIGH);
//   if(HMA_Handle==INVALID_HANDLE)
     if(!HMA.Init(Length, MAType, InpLookback))
     {
      Print(" Не удалось получить хендл индикатора iMA");
      return(INIT_FAILED);
     }
//--- получение хендла индикатора iMA
//   LMA_Handle=iMA(NULL,0,Length,0,MAType,PRICE_LOW);
//   if(LMA_Handle==INVALID_HANDLE)
     if(!LMA.Init(Length, MAType, InpLookback))
     {
      Print(" Не удалось получить хендл индикатора iMA");
      return(INIT_FAILED);
     }
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(IndBuffer,true);
//--- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ColorIndBuffer,true);
//--- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,NULL);
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,UpBuffer,INDICATOR_DATA);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(UpBuffer,true);
//--- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//--- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,NULL);
//--- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(3,DnBuffer,INDICATOR_DATA);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(DnBuffer,true);
//--- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//--- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,NULL);
//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(4,ExtOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,ExtLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(7,ExtCloseBuffer,INDICATOR_DATA);
//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(8,ExtColorBuffer,INDICATOR_COLOR_INDEX);
//---- установка позиции, с которой начинается линий канала
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,NULL);
//---- осуществление сдвига индикатора по горизонтали
//PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ExtOpenBuffer,true);
   ArraySetAsSeries(ExtHighBuffer,true);
   ArraySetAsSeries(ExtLowBuffer,true);
   ArraySetAsSeries(ExtCloseBuffer,true);
   ArraySetAsSeries(ExtColorBuffer,true);
//--- инициализации переменной для короткого имени индикатора
   string shortname="Ozymandias_System_Alert";
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- проверка количества баров на достаточность для расчёта
//   if(BarsCalculated(ATR_Handle)<rates_total
//      || BarsCalculated(HMA_Handle)<rates_total
//      || BarsCalculated(LMA_Handle)<rates_total
//      || rates_total<min_rates_total) return(RESET);
      
   if(rates_total<min_rates_total)
      return(RESET);
      
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,Time,Close) 
      || !customChartIndicator.BufferSynchronizationCheck(Close))
      return(0);
      
   int _prev_calculated = customChartIndicator.GetPrevCalculated();
   int _rates_total = ArraySize(customChartIndicator.Close);

//--- объявление переменных
   int to_copy,limit,trend0,nexttrend0;
   double hh,ll,maxl0,minh0,lma,hma,atr;//,ATR[],HMA[],LMA[];
   static int trend1,nexttrend1;
   static double maxl1,minh1;

//--- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(customChartIndicator.Open,true);
   ArraySetAsSeries(customChartIndicator.Close,true);
   ArraySetAsSeries(customChartIndicator.High,true);
   ArraySetAsSeries(customChartIndicator.Low,true);
//   ArraySetAsSeries(ATR,true);
//   ArraySetAsSeries(HMA,true);
//   ArraySetAsSeries(LMA,true);
//--- расчёт стартового номера limit для цикла пересчёта баров
   if(_prev_calculated>_rates_total || _prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=_rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
      trend1=0;
      nexttrend1=0;
      maxl1=0;
      minh1=9999999;
      IndBuffer[limit+1]=customChartIndicator.Close[limit+1];
     }
   else limit=_rates_total-_prev_calculated;  // стартовый номер для расчёта только новых баров
   to_copy=limit+1;
//--- копируем вновь появившиеся данные в массивы

   ATR.MainOnArray(_rates_total, _prev_calculated, customChartIndicator.High, customChartIndicator.Low, customChartIndicator.Close);
   HMA.MainOnArray(_rates_total, _prev_calculated, customChartIndicator.High);
   LMA.MainOnArray(_rates_total, _prev_calculated, customChartIndicator.Low);
//   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
//   if(CopyBuffer(HMA_Handle,0,0,to_copy,HMA)<=0) return(RESET);
//   if(CopyBuffer(LMA_Handle,0,0,to_copy,LMA)<=0) return(RESET);
//---
   nexttrend0=nexttrend1;
   maxl0=maxl1;
   minh0=minh1;
//--- основной цикл расчёта индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      hh=customChartIndicator.High[ArrayMaximum(customChartIndicator.High,bar,Length)];
      ll=customChartIndicator.Low[ArrayMinimum(customChartIndicator.Low,bar,Length)];
      lma=LMA[bar];
      hma=HMA[bar];
      atr=ATR[bar]/2;
      trend0=trend1;
      //---
      if(nexttrend0==1)
        {
         maxl0=MathMax(ll,maxl0);

         if(hma<maxl0 && customChartIndicator.Close[bar]<customChartIndicator.Low[bar+1])
           {
            trend0=1;
            nexttrend0=0;
            minh0=hh;
           }
        }
      //---
      if(nexttrend0==0)
        {
         minh0=MathMin(hh,minh0);

         if(lma>minh0 && customChartIndicator.Close[bar]>customChartIndicator.High[bar+1])
           {
            trend0=0;
            nexttrend0=1;
            maxl0=ll;
           }
        }
      //---
      if(trend0==0)
        {
         if(trend1!=0.0)
           {
            IndBuffer[bar]=IndBuffer[bar+1];
            ColorIndBuffer[bar]=1;
           }
         else
           {
            IndBuffer[bar]=MathMax(maxl0,IndBuffer[bar+1]);
            ColorIndBuffer[bar]=1;
           }
         UpBuffer[bar]=IndBuffer[bar]+atr;
         DnBuffer[bar]=IndBuffer[bar]-atr;
        }
      else
        {
         if(trend1!=1)
           {
            IndBuffer[bar]=IndBuffer[bar+1];
            ColorIndBuffer[bar]=0;
           }
         else
           {
            IndBuffer[bar]=MathMin(minh0,IndBuffer[bar+1]);
            ColorIndBuffer[bar]=0;
           }
         UpBuffer[bar]=IndBuffer[bar]+atr;
         DnBuffer[bar]=IndBuffer[bar]-atr;
        }
      //---
      if(bar)
        {
         nexttrend1=nexttrend0;
         trend1=trend0;
         maxl1=maxl0;
         minh1=minh0;
        }
     }
//---- основной цикл исправления и окрашивания свечей
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ExtOpenBuffer[bar]=ExtCloseBuffer[bar]=ExtHighBuffer[bar]=ExtLowBuffer[bar]=ExtColorBuffer[bar]=NULL;
      ExtColorBuffer[bar]=4;
      //----
      if(customChartIndicator.Close[bar]>UpBuffer[bar+Shift])
        {
         ExtOpenBuffer[bar]=customChartIndicator.Open[bar];
         ExtCloseBuffer[bar]=customChartIndicator.Close[bar];
         ExtHighBuffer[bar]=customChartIndicator.High[bar];
         ExtLowBuffer[bar]=customChartIndicator.Low[bar];
         if(customChartIndicator.Close[bar]>=customChartIndicator.Open[bar]) ExtColorBuffer[bar]=3;
         else ExtColorBuffer[bar]=2;
        }
      //----
      if(customChartIndicator.Close[bar]<DnBuffer[bar+Shift])
        {
         ExtOpenBuffer[bar]=customChartIndicator.Open[bar];
         ExtCloseBuffer[bar]=customChartIndicator.Close[bar];
         ExtHighBuffer[bar]=customChartIndicator.High[bar];
         ExtLowBuffer[bar]=customChartIndicator.Low[bar];
         if(customChartIndicator.Close[bar]<=customChartIndicator.Open[bar]) ExtColorBuffer[bar]=0;
         else ExtColorBuffer[bar]=1;
        }
     }
//---     
   BuySignal("Ozymandias_System_Alert",ExtColorBuffer,_rates_total,_prev_calculated,customChartIndicator.Close,spread);
   SellSignal("Ozymandias_System_Alert",ExtColorBuffer,_rates_total,_prev_calculated,customChartIndicator.Close,spread);
//---    
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Buy signal function                                              |
//+------------------------------------------------------------------+
void BuySignal(string SignalSirname,      // текст имени индикатора для почтовых и пуш-сигналов
               double &ColorArrow[],      // цветовой индикаторный  буфер с сигналами для покупки
               const int Rates_total,     // текущее количество баров
               const int Prev_calculated, // количество баров на предыдущем тике
               const double &Close[],     // цена закрытия
               const int &Spread[])       // спред
  {
//---
   static uint counter=0;
   //if(Rates_total!=Prev_calculated) counter=0;
   if(customChartIndicator.IsNewBar) 
      counter=0;

   bool BuySignal=false;
   bool SeriesTest=ArrayGetAsSeries(ColorArrow);
   int index,index1;
   if(SeriesTest)
     {
      index=int(NumberofBar);
      index1=index+1;
     }
   else
     {
      index=Rates_total-int(NumberofBar)-1;
      index1=index-1;
     }
   if((ColorArrow[index]==2 || ColorArrow[index]==3) && (ColorArrow[index1]<2 || ColorArrow[index1]==4)) BuySignal=true;
   if(BuySignal && counter<=NumberofAlerts)
     {
      counter++;
      MqlDateTime tm;
      TimeToStruct(TimeCurrent(),tm);
      string text=TimeToString(TimeCurrent(),TIME_DATE)+" "+string(tm.hour)+":"+string(tm.min);
      SeriesTest=ArrayGetAsSeries(Close);
      if(SeriesTest) index=int(NumberofBar);
      else index=Rates_total-int(NumberofBar)-1;
      double Ask=Close[index];
      double Bid=Close[index];
      SeriesTest=ArrayGetAsSeries(Spread);
      if(SeriesTest) index=int(NumberofBar);
      else index=Rates_total-int(NumberofBar)-1;
      Bid+=Spread[index]*_Point;
      string sAsk=DoubleToString(Ask,_Digits);
      string sBid=DoubleToString(Bid,_Digits);
      string sPeriod=GetStringTimeframe(ChartPeriod());
      if(SoundON) Alert("BUY signal \n Ask=",Ask,"\n Bid=",Bid,"\n currtime=",text,"\n Symbol=",Symbol()," Period=",sPeriod);
      if(EMailON) SendMail(SignalSirname+": BUY signal alert","BUY signal at Ask="+sAsk+", Bid="+sBid+", Date="+text+" Symbol="+Symbol()+" Period="+sPeriod);
      if(PushON) SendNotification(SignalSirname+": BUY signal at Ask="+sAsk+", Bid="+sBid+", Date="+text+" Symbol="+Symbol()+" Period="+sPeriod);
     }

//---
  }
//+------------------------------------------------------------------+
//| Sell signal function                                             |
//+------------------------------------------------------------------+
void SellSignal(string SignalSirname,      // текст имени индикатора для почтовых и пуш-сигналов
                double &ColorArrow[],      // цветовой индикаторный  буфер с сигналами для продажи
                const int Rates_total,     // текущее количество баров
                const int Prev_calculated, // количество баров на предыдущем тике
                const double &Close[],     // цена закрытия
                const int &Spread[])       // спред
  {
//---
   static uint counter=0;
   //if(Rates_total!=Prev_calculated) counter=0;
   if(customChartIndicator.IsNewBar) 
      counter=0;

   bool SellSignal=false;
   bool SeriesTest=ArrayGetAsSeries(ColorArrow);
   int index,index1;
   if(SeriesTest)
     {
      index=int(NumberofBar);
      index1=index+1;
     }
   else
     {
      index=Rates_total-int(NumberofBar)-1;
      index1=index-1;
     }
   if((ColorArrow[index]==0 || ColorArrow[index]==1) && ColorArrow[index1]>1) SellSignal=true;
   if(SellSignal && counter<=NumberofAlerts)
     {
      counter++;
      MqlDateTime tm;
      TimeToStruct(TimeCurrent(),tm);
      string text=TimeToString(TimeCurrent(),TIME_DATE)+" "+string(tm.hour)+":"+string(tm.min);
      SeriesTest=ArrayGetAsSeries(Close);
      if(SeriesTest) index=int(NumberofBar);
      else index=Rates_total-int(NumberofBar)-1;
      double Ask=Close[index];
      double Bid=Close[index];
      SeriesTest=ArrayGetAsSeries(Spread);
      if(SeriesTest) index=int(NumberofBar);
      else index=Rates_total-int(NumberofBar)-1;
      Bid+=Spread[index]*_Point;
      string sAsk=DoubleToString(Ask,_Digits);
      string sBid=DoubleToString(Bid,_Digits);
      string sPeriod=GetStringTimeframe(ChartPeriod());
      if(SoundON) Alert("SELL signal \n Ask=",Ask,"\n Bid=",Bid,"\n currtime=",text,"\n Symbol=",Symbol()," Period=",sPeriod);
      if(EMailON) SendMail(SignalSirname+": SELL signal alert","SELL signal at Ask="+sAsk+", Bid="+sBid+", Date="+text+" Symbol="+Symbol()+" Period="+sPeriod);
      if(PushON) SendNotification(SignalSirname+": SELL signal at Ask="+sAsk+", Bid="+sBid+", Date="+text+" Symbol="+Symbol()+" Period="+sPeriod);
     }
//---
  }
//+------------------------------------------------------------------+
//|  Получение таймфрейма в виде строки                              |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {
//----
   return(StringSubstr(EnumToString(timeframe),7,-1));
//----
  }
//+------------------------------------------------------------------+
