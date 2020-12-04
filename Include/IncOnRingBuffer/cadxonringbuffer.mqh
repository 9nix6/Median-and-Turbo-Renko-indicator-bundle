//+------------------------------------------------------------------+
//|                                             CADXOnRingBuffer.mqh |
//|                               Copyright 2012, Konstantin Gruzdev |
//|                            https://login.mql5.com/ru/users/Lizar |
//|                                             Revision 01 Dec 2012 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2012, Konstantin Gruzdev"
#property link        "https://login.mql5.com/ru/users/Lizar"

//--- Class to calculate the MA using the ring buffer:
#include <IncOnRingBuffer\CMAOnRingBuffer.mqh>
//+------------------------------------------------------------------+
//| Class CADXOnRingBuffer                                           |
//| Appointment: class is designed for the calculation of the        |
//|              ADX indicator (Average Directional Movement Index,  |
//|              ADX) using the class for working with the ring      |
//|              buffer.                                             |
//| Link: http://www.mql5.com/ru/code/1343                           |
//+------------------------------------------------------------------+
class CADXOnRingBuffer
  {
public:
   CMAOnRingBuffer   pdi;              // positive directional index 
   CMAOnRingBuffer   ndi;              // negative directional index
private:
   CMAOnRingBuffer   m_adx;            // average directional movement index
   string            m_name;           // indicator name  
   bool              m_as_series;      // true, if the indexing as in time series
   int               m_bars_required;  // number of elements required to calculate
   int               m_begin;          // index of the first significant element
   int               m_start;          // index of element to start the calculation
   int               m_index;          // current element index
   
   double            m_high;           // maximal value
   double            m_low;            // minimal value
   double            m_close;          // closing price
   double            m_phigh;          // maximum value of the previous bar
   double            m_plow;           // minimum value of the previous bar
   double            m_pclose;         // closing price of the previous bar
   
   double            m_PD;
   double            m_ND;
public:
                     CADXOnRingBuffer() {} 
                    ~CADXOnRingBuffer() {}
   //--- initialization method:
   bool              Init(int             ma_period=14,
                          ENUM_MA_METHOD  ma_method=MODE_EMA, 
                          int             size_buffer=256, 
                          bool            as_series=false);             
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
   string            NameADX()                     { return("ADX"+m_name);                }
   string            NameNDI()                     { return("-DI"+m_name);                }
   string            NamePDI()                     { return("+DI"+m_name);                }
   string            MAMethod()                    { return(m_adx.MAMethod());            }
   int               MAPeriod()                    { return(m_adx.MAPeriod());            }
   int               Size()                        { return(m_adx.Size());                }
   //--- returns the value of element with the specified index:
   double operator   [](const int index) const     { return(m_adx.At(index));             }
private:
   //--- indicator calculation method:
   void              ADX(const int rates_total, const int prev_calculated);
  };

//+------------------------------------------------------------------+
//|  Initialization method                                           |
//+------------------------------------------------------------------+
bool CADXOnRingBuffer :: Init(int ma_period=14,ENUM_MA_METHOD ma_method=MODE_EMA, int size_buffer=256, bool as_series=false)
  {
//--- initialize the CMAOnRingBuffer class instances:
   if(!pdi.Init(ma_period,ma_method,size_buffer))   return false;
   if(!ndi.Init(ma_period,ma_method,size_buffer))   return false;
   if(!m_adx.Init(ma_period,ma_method,size_buffer)) return false;
//---
   m_name="("+IntegerToString(ma_period)+","+MAMethod()+")";
//---
   m_as_series=as_series;
   m_bars_required=m_adx.BarsRequired()+1;
   return true;   
  }

//+------------------------------------------------------------------+
//| Indicator on array                                               |
//+------------------------------------------------------------------+
int CADXOnRingBuffer :: MainOnArray(const int      rates_total, 
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
         if(high[i]!=0  && high[i] != EMPTY_VALUE && 
            low[i]!=0   && low[i]  != EMPTY_VALUE && 
            close[i]!=0 && close[i]!= EMPTY_VALUE)
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
   for(m_index=m_start;m_index<rates_total;m_index++)
     {
   //--- fill main positive and main negative buffers:
      m_phigh  = high [m_index-1];
      m_plow   = low  [m_index-1];
      m_pclose = close[m_index-1];   
      m_high   = high [m_index];
      m_low    = low  [m_index]; 
   //--- calculation of the average directional movement index:
      ADX(rates_total,prev_calculated);
     }
//--- restore as_series flags
   if(as_series_high)  ArraySetAsSeries(high, true);
   if(as_series_low)   ArraySetAsSeries(low,  true);
   if(as_series_close) ArraySetAsSeries(close,true);
//--- return value of prev_calculated for next call:
   return(rates_total);
  }
  
//+------------------------------------------------------------------+
//| Indicator on value                                               |
//+------------------------------------------------------------------+
double CADXOnRingBuffer:: MainOnValue(const int    rates_total,
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
      m_high=high;
      m_low=low;
      m_close=close;
      m_begin=begin+1;
      return(EMPTY_VALUE);
     }     
//--- remember the prices:
   if(prev_calculated-1!=m_index) 
     {
      m_phigh  = m_high;
      m_plow   = m_low;
      m_pclose = m_close;   
     }
   m_high  = high;
   m_low   = low;
   m_close = close;  
//--- calculation of the average directional movement index:
   ADX(rates_total,prev_calculated);
//--- result:
   return(m_adx.Last());          
  }       
  
//+------------------------------------------------------------------+
//| Average directional movement index                               |
//+------------------------------------------------------------------+
void CADXOnRingBuffer:: ADX(const int rates_total, const int prev_calculated)
  {
//--- fill main positive and main negative buffers
   double dTmpP=m_high-m_phigh;
   double dTmpN=m_plow-m_low;
   if(dTmpP<0.0)   dTmpP=0.0;
   if(dTmpN<0.0)   dTmpN=0.0;
   if(dTmpP>dTmpN) dTmpN=0.0;
   else
     {
      if(dTmpP<dTmpN) dTmpP=0.0;
      else
        {
         dTmpP=0.0;
         dTmpN=0.0;
        }
     }
//--- define TR
   double tr=MathMax(MathMax(MathAbs(m_high-m_low),MathAbs(m_high-m_pclose)),MathAbs(m_low-m_pclose)); 
//---
   if(tr!=0.0)
     {
      m_PD=100.0*dTmpP/tr;
      m_ND=100.0*dTmpN/tr;
     }
   else
     {
      m_PD=0.0;
      m_ND=0.0;
     }
//--- main calculation:
   //--- fill smoothed positive and negative buffers
   pdi.MainOnValue(rates_total,prev_calculated,m_begin,m_PD,m_index);
   ndi.MainOnValue(rates_total,prev_calculated,m_begin,m_ND,m_index);
   //--- fill ADXTmp buffer
   double dTmp=pdi.Last()+ndi.Last();
   if(dTmp!=0.0)
      dTmp=100.0*MathAbs((pdi.Last()-ndi.Last())/dTmp);
   else
      dTmp=0.0;
   //--- fill smoothed ADX buffer
   m_adx.MainOnValue(rates_total,prev_calculated,m_begin,dTmp,m_index);         
  }         