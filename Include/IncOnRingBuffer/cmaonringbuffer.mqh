//+------------------------------------------------------------------+
//|                                              CMAOnRingBuffer.mqh |
//|                               Copyright 2012, Konstantin Gruzdev |
//|                            https://login.mql5.com/ru/users/Lizar |
//|                                             Revision 30 Nov 2012 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2012, Konstantin Gruzdev"
#property link        "https://login.mql5.com/ru/users/Lizar"

//--- Class for working with the ring buffer of data:
#include <IncOnRingBuffer\CArrayRing.mqh>
//+------------------------------------------------------------------+
//| Class CMAOnRingBuffer                                            |
//| Appointment: class is designed to calculate a moving averages    |
//|              using the class for working with the ring           |
//|              buffer.                                             |
//| Link: http://www.mql5.com/ru/code/1342                           |
//+------------------------------------------------------------------+
class CMAOnRingBuffer :public CArrayRing
  {
private:
   CArrayRing        *m_array_in;      // ring buffer for input data
   int               m_ma_period;      // number of elements to analyze
   ENUM_MA_METHOD    m_ma_method;      // MA calculation method
   bool              m_as_series;      // true, if the indexing as in time series
   double            m_k1,m_k2;        
   double            m_LK[];
   string            m_name;           // indicator name
   int               m_bars_required;  // number of elements required to calculate
   int               m_start;          // index of element to start the calculation
   int               m_index;          // current element index

public:
                     CMAOnRingBuffer() {} 
                    ~CMAOnRingBuffer();
   //--- initialization method:
   bool              Init(int ma_period=14,ENUM_MA_METHOD ma_method=MODE_SMA, int size_buffer=256, bool as_series=false);             
   //--- basic methods:          
   int               MainOnArray(const int rates_total, const int prev_calculated,const double &array[]);
   double            MainOnValue(const int rates_total, const int prev_calculated, const int begin, const double value, const int index);
   //--- methods to get access to private data:
   int               BarsRequired()                { return(m_bars_required);             }
   string            Name()                        { return(m_name);                      }
   string            MAMethod()                    { return(MethodToString(m_ma_method)); }
   int               MAPeriod()                    { return(m_ma_period);                 }
   //--- returns the value of element with the specified index:
   double operator   [](const int index) const   { return(At(index));                   }
   
private:
   //--- methods of calculation based on the array of input data:
   void              SMAOnArray (const int rates_total, const int prev_calculated, const double &array[]);
   void              EMAOnArray (const int rates_total, const int prev_calculated, const double &array[]);
   void              LWMAOnArray(const int rates_total, const int prev_calculated, const double &array[]);
   //--- methods to calculate the sequential values ??of the indicator elements:     
   double            SMAOnValue (const int prev_calculated, const int begin, const double value, const int index);
   double            EMAOnValue (const int prev_calculated, const int begin, const double value, const int index);
   double            LWMAOnValue(const int prev_calculated, const int begin, const double value, const int index);
   //--- auxiliary methods:
   int               Begin(const int rates_total,const double &array[]);
   bool              FillArrayIn(const int prev_calculated, const double value);
   string            MethodToString(ENUM_MA_METHOD method);
  };

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CMAOnRingBuffer:: ~CMAOnRingBuffer()
  {
   if(CheckPointer(m_array_in)!=POINTER_INVALID) delete m_array_in;
  }

//+------------------------------------------------------------------+
//| Indicator on array                                               |
//+------------------------------------------------------------------+
int CMAOnRingBuffer:: MainOnArray(const int rates_total,const int prev_calculated,const double &array[])
  {
//--- save as_series flags
   bool as_series=ArrayGetAsSeries(array);
   if(as_series)  ArraySetAsSeries(array,false);
//--- main calculation:
   switch(m_ma_method)
     {
      case MODE_SMA:    SMAOnArray(rates_total,prev_calculated,array);   break;
      case MODE_EMA:
      case MODE_SMMA:   EMAOnArray(rates_total,prev_calculated,array);   break;
      case MODE_LWMA:   LWMAOnArray(rates_total,prev_calculated,array);  break;
     }
//--- restore as_series flags
   if(as_series)  ArraySetAsSeries(array,true);
//--- return value of prev_calculated for next call
   return(rates_total);
  }  

//+------------------------------------------------------------------+
//| Indicator on value                                               |
//+------------------------------------------------------------------+
double CMAOnRingBuffer:: MainOnValue(const int rates_total, const int prev_calculated, const int begin, const double value, const int index)
  {
//--- check as_series flags:
      if(m_as_series) m_index=rates_total-1-index;
      else m_index=index;
//--- check begin:
      if(m_index<begin) return(EMPTY_VALUE);
//--- main calculation:
      switch(m_ma_method)
        {
         case MODE_SMA:    return(SMAOnValue(prev_calculated,begin,value,index));
         case MODE_EMA:
         case MODE_SMMA:   return(EMAOnValue(prev_calculated,begin,value,index));
         case MODE_LWMA:   return(LWMAOnValue(prev_calculated,begin,value,index));
        }
//--- result:
   return(EMPTY_VALUE);
  }       

//+------------------------------------------------------------------+
//| Simple moving average on array                                   |
//+------------------------------------------------------------------+
void CMAOnRingBuffer:: SMAOnArray(const int rates_total, const int prev_calculated, const double &array[])
  {
//--- first calculation:
   if(prev_calculated==0)
     {
      m_start=Begin(rates_total,array)+m_ma_period-1;
      double sum=0.0;
      for(int i=m_start;i>m_start-m_ma_period;i--) sum+=array[i];
      Last(sum/m_ma_period);
     }
//--- number of bars was changed:
   else 
     {
      m_start=prev_calculated-1;
      Last(At(1)-(array[m_start-m_ma_period]-array[m_start])/m_ma_period);      
     }      
//--- main loop
   for(int i=m_start+1;i<rates_total && !IsStopped();i++)
      Add(Last()-(array[i-m_ma_period]-array[i])/m_ma_period);
  }   
  
//+------------------------------------------------------------------+
//|  Exponential moving average on array                             |
//+------------------------------------------------------------------+
void CMAOnRingBuffer:: EMAOnArray(const int rates_total,const int prev_calculated,const double &array[])
  {
//--- first calculation:
   if(prev_calculated==0)
     {
      m_start=Begin(rates_total,array);
      Last(array[m_start]);
     }
//--- number of bars was changed:
   else
     { 
      m_start=prev_calculated-1;
      Last(m_k1*array[m_start]+m_k2*At(1));
     }
//--- main loop:
   for(int i=m_start+1;i<rates_total && !IsStopped();i++)
      Add(m_k1*array[i]+m_k2*Last());
  }
  
//+------------------------------------------------------------------+
//|  Linear weighted moving average on array                         |
//+------------------------------------------------------------------+
void CMAOnRingBuffer:: LWMAOnArray(const int rates_total, const int prev_calculated, const double &array[])
  {
//--- first calculation:
   if(prev_calculated==0)
      m_start=Begin(rates_total,array)+m_ma_period-1;
//--- number of bars was changed:
   else m_start=prev_calculated-1;
   
   double volue=0.0;
   for(int j=0;j<m_ma_period && !IsStopped();j++)
      volue+=array[m_start-j]*m_LK[j];
   Last(volue);
//--- main loop
   for(int i=m_start+1;i<rates_total && !IsStopped();i++)
     {
      volue=0.0;
      for(int j=0;j<m_ma_period && !IsStopped();j++)
         volue+=array[i-j]*m_LK[j];
      Add(volue);
     }
  }
  
//+------------------------------------------------------------------+
//| Simple moving average on value                                   |
//+------------------------------------------------------------------+
double CMAOnRingBuffer:: SMAOnValue(const int prev_calculated, const int begin, const double value, const int index)
  {
//--- fill the ring buffer of input data:
   if(!FillArrayIn(prev_calculated,value)) return(EMPTY_VALUE);
//--- initial calculation:
   m_start=begin+m_ma_period-1;
   if(m_index<m_start) return (EMPTY_VALUE);
   else if(m_index==m_start)
          {
           double sum=0.0;
           for(int i=0;i<m_ma_period && !IsStopped();i++) sum+=m_array_in[i];
           Last(sum/m_ma_period);
           return(Last());
          }
//--- main calculation:
   if(prev_calculated-1==m_index) 
      Last(At(1)-(m_array_in[m_ma_period]-value)/m_ma_period);      
   else
      Add(Last()-(m_array_in[m_ma_period]-value)/m_ma_period);
//--- result:
   return(Last());        
  }   
     
//+------------------------------------------------------------------+
//|  Exponential moving average on value                             |
//+------------------------------------------------------------------+
double CMAOnRingBuffer:: EMAOnValue(const int prev_calculated, const int begin, const double value, const int index)
  {
//--- initial calculation:
   if(m_index==begin)
    {
     Last(value);
     return(value);
    }        
//--- main calculation:
   if(prev_calculated-1==m_index) 
      Last(m_k1*value+m_k2*At(1));      
   else
      Add(m_k1*value+m_k2*Last());
//--- result:
   return(Last());        
  }   

//+------------------------------------------------------------------+
//|  Linear weighted moving average on value                         |
//+------------------------------------------------------------------+
double CMAOnRingBuffer:: LWMAOnValue(const int prev_calculated, const int begin, const double value, const int index)
  {
//--- fill the ring buffer of input data:
   if(!FillArrayIn(prev_calculated,value)) return(EMPTY_VALUE);
//--- initial calculation:
   if(m_index<begin+m_ma_period-1) return (EMPTY_VALUE);
//--- main calculation:
   double volue=0.0;
   for(int j=0;j<m_ma_period && !IsStopped();j++)
      volue+=m_array_in[j]*m_LK[j];
   if(prev_calculated-1==m_index) Last(volue);      
   else Add(volue);
//--- result:
   return(Last());        
  }   
  
//+------------------------------------------------------------------+
//|  Defines the index of the first element for calculation          |
//+------------------------------------------------------------------+
int CMAOnRingBuffer:: Begin(const int rates_total,const double &array[])
  {
//--- looking the start of significant data:
   int i=-1;
   while(++i<rates_total && !IsStopped())
     {
      if(array[i]!=0 && array[i]!=EMPTY_VALUE) break;
     }
//--- Return the index of the element from which start calculations:
   return(MathMax(i,rates_total-Size()-m_bars_required));
  }
  
//+------------------------------------------------------------------+
//|  Fill the ring buffer by input data                              |
//+------------------------------------------------------------------+
bool CMAOnRingBuffer:: FillArrayIn(const int prev_calculated, const double value)
  {
//--- check pointer:
   if(CheckPointer(m_array_in)==POINTER_INVALID)
     {
      if((m_array_in=new CArrayRing())==NULL) return false;
      if(!m_array_in.Init(Size())) return false;
     }
//--- fill the ring buffer of input data:
   if(prev_calculated-1==m_index) m_array_in.Last(value);
   else m_array_in.Add(value);
//--- successful
   return true;
  }

//+------------------------------------------------------------------+
//|  Initialization method                                           |
//+------------------------------------------------------------------+
bool CMAOnRingBuffer:: Init(int ma_period=14,ENUM_MA_METHOD ma_method=MODE_SMA, int size_buffer=256, bool as_series=false)
  {
//--- check for input values
   if(ma_period<=0)
     {
      m_ma_period=14;
      printf("Input parameter ma_period has incorrect value (%d). Indicator will use value %d for calculations.",
             ma_period,m_ma_period);
     }
   else m_ma_period=ma_period;
   if(size_buffer<=m_ma_period)
     {
      printf("Input parameter size_buffer has incorrect value (%d). Indicator will use value %d for calculations.",
             size_buffer,m_ma_period);
      size_buffer=m_ma_period;
     }
//--- initialization of the ring buffer for the indicator data:
   if(!CArrayRing::Init(size_buffer)) return false;
//--- data initialization:
   int coeff_required=10;
   m_as_series=as_series;
   m_ma_method=ma_method;
   switch(m_ma_method)
     {
      case  MODE_SMA:
        {
         m_bars_required=m_ma_period;
         break;
        }
      case  MODE_EMA:
        {
         m_k1=2.0/(m_ma_period+1.0);
         m_k2=1.0-m_k1;
         m_bars_required=m_ma_period*coeff_required;
         break;
        }
      case  MODE_SMMA:
        {
         m_k1=1.0/m_ma_period;
         m_k2=1.0-m_k1;
         m_bars_required=m_ma_period*coeff_required;
         break;
        }
      case  MODE_LWMA:
        {
         ArrayResize(m_LK,m_ma_period);
         double sum=0;
         for(int j=0;j<m_ma_period;j++) sum+=m_LK[j]=m_ma_period-j;
         for(int j=0;j<m_ma_period;j++) m_LK[j]/=sum;
         sum=0;
         for(int j=0;j<m_ma_period;j++) sum+=m_LK[j];
         m_bars_required=m_ma_period;
         break;
        }
      default:
        break;
     }        
   m_name=MethodToString(m_ma_method)+"("+IntegerToString(m_ma_period)+")";
//--- successful
   return true;
  }            
  
//+------------------------------------------------------------------+
//|  Transformation of moving method in the text representation      |
//+------------------------------------------------------------------+
string CMAOnRingBuffer:: MethodToString(ENUM_MA_METHOD method)
  { 
   switch(method)
     {
      case  MODE_SMA: return("SMA");
      case  MODE_EMA: return("EMA");
      case  MODE_LWMA: return("LWMA");
      case  MODE_SMMA: return("SMMA");
     }
   return(EnumToString(method));                 
  }
  