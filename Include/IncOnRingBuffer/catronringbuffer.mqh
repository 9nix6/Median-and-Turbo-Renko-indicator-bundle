//+------------------------------------------------------------------+
//|                                             CATROnRingBuffer.mqh |
//|                               Copyright 2012, Konstantin Gruzdev |
//|                            https://login.mql5.com/ru/users/Lizar |
//|                                             Revision 01 Dec 2012 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2012, Konstantin Gruzdev"
#property link        "https://login.mql5.com/ru/users/Lizar"

//--- Class to calculate the MA using the ring buffer:
#include <IncOnRingBuffer\CMAOnRingBuffer.mqh>
//+------------------------------------------------------------------+
//| Class CATROnRingBuffer                                           |
//| Appointment: class is designed for the calculation of the        |
//|              technical indicator  Average True Range (Average    |
//|              True Range, ATR) using the class for working with   |
//|              the ring buffer.                                    |
//| Link: http://www.mql5.com/ru/code/1344                           |
//+------------------------------------------------------------------+
class CATROnRingBuffer
  {
private:
   CMAOnRingBuffer   m_ma;             // instance the class for MA calculation
   double            m_tr;             // true range
   double            m_atr;            // average true range
   string            m_name;           // indicator name
   bool              m_as_series;      // true, if the indexing as in time series
   int               m_bars_required;  // number of elements required to calculate
   int               m_begin;          // index of the first significant element
   int               m_start;          // index of element to start the calculation
   int               m_index;          // current element index
   double            m_close;          // closing price of the current bar
   double            m_prev_close;     // closing price of the previous bar
public:
                     CATROnRingBuffer() {} 
                    ~CATROnRingBuffer() {}
   //--- initialization method:
   bool              Init(int ma_period=14,ENUM_MA_METHOD ma_method=MODE_SMA, int size_buffer=256, bool as_series=false);             
   //--- basic methods:          
   int               MainOnArray(const int      rates_total, 
                                 const int      prev_calculated,
                                 const double  &high[],
                                 const double  &low[],
                                 const double  &close[]);
   double            MainOnValue(const int      rates_total,
                                 const int      prev_calculated, 
                                 const int      begin, 
                                 const double   high, 
                                 const double   low, 
                                 const double   close, 
                                 const int      index);
   //--- methods to get access to private data:
   int               BarsRequired()                { return(m_bars_required);             }
   string            Name()                        { return(m_name);                      }
   string            MAMethod()                    { return(m_ma.MAMethod());             }
   int               MAPeriod()                    { return(m_ma.MAPeriod());             }
   int               Size()                        { return(m_ma.Size());                 }
   //--- returns the value of element with the specified index:
   double operator   [](const int index) const     { return(m_ma.At(index));              }
  };

//+------------------------------------------------------------------+
//|  Initialization method                                           |
//+------------------------------------------------------------------+
bool CATROnRingBuffer :: Init(int ma_period=14,ENUM_MA_METHOD ma_method=MODE_SMA, int size_buffer=256, bool as_series=false)
  {
//--- Initialization for MA:
   if(!m_ma.Init(ma_period,ma_method,size_buffer)) return false;
//---
   m_as_series=as_series;
   m_bars_required=m_ma.BarsRequired()+1;
   m_name="ATR("+IntegerToString(ma_period)+","+MAMethod()+")";
//---
   return true;   
  }

//+------------------------------------------------------------------+
//| Indicator on array                                               |
//+------------------------------------------------------------------+
int CATROnRingBuffer :: MainOnArray(const int      rates_total, 
                                    const int      prev_calculated,
                                    const double  &high[],
                                    const double  &low[],
                                    const double  &close[])
  {
//--- save as_series flags:
   bool as_series_high  = ArrayGetAsSeries(high);
   bool as_series_low   = ArrayGetAsSeries(low);
   bool as_series_close = ArrayGetAsSeries(close);
   if(as_series_high)  ArraySetAsSeries(high, false);
   if(as_series_low)   ArraySetAsSeries(low,  false);
   if(as_series_close) ArraySetAsSeries(close,false);
//--- first calculation:
   if(prev_calculated==0)
     {
      for(int i=0;i<rates_total;i++)
        {
         if(high[i]!=0 && high[i]!=EMPTY_VALUE && 
            low[i]!=0 && low[i]!=EMPTY_VALUE && 
            close[i]!=0 && close[i]!=EMPTY_VALUE)
           {
            m_start=MathMax(i+1,rates_total-Size()-m_bars_required);
            break;
           }
        }
      m_begin=m_start;
     }
//--- number of bars was changed:
   else m_start=prev_calculated-1;
//--- main loop:
   for(int i=m_start;i<rates_total;i++)
     {
      m_tr=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      m_ma.MainOnValue(rates_total,prev_calculated,m_begin,m_tr,i);
     }
//--- restore as_series flags:
   if(as_series_high)  ArraySetAsSeries(high, true);
   if(as_series_low)   ArraySetAsSeries(low,  true);
   if(as_series_close) ArraySetAsSeries(close,true);
//--- return value of prev_calculated for next call:
   return(rates_total);
  }
  
//+------------------------------------------------------------------+
//| Indicator on value                                               |
//+------------------------------------------------------------------+
double CATROnRingBuffer:: MainOnValue(const int    rates_total,
                                      const int    prev_calculated, 
                                      const int    begin, 
                                      const double high, 
                                      const double low, 
                                      const double close, 
                                      const int    index)
  {
//--- check as_series flags:
   if(m_as_series) m_index=rates_total-1-index;
   else m_index=index;
//--- check begin:
   if(m_index<begin) return(EMPTY_VALUE);
//--- initial calculation:
   if(m_index==begin) 
     {
      m_close=close;
      return (EMPTY_VALUE);
     }
//--- remember the closing price:
   if(prev_calculated-1!=m_index) m_prev_close=close;
   m_close=close;
//--- main calculation:
   m_tr=MathMax(high,m_prev_close)-MathMin(low,m_prev_close);
   m_ma.MainOnValue(rates_total,prev_calculated,begin+1,m_tr,m_index);
//--- result:
   return(m_ma.Last());          
  }       
