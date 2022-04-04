//+------------------------------------------------------------------+
//|                                                      CDouble.mqh |
//|                                      Copyright 2017, nicholishen |
//|                         https://www.forexfactory.com/nicholishen |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, nicholishen"
#property link      "https://www.forexfactory.com/nicholishen"
#property version   "1.02"
/*********************************************************************
* Version 1.00: Initial release. See full documentation at
* https://www.mql5.com/en/code/19727
**********************************************************************

*********************************************************************
* Version 1.01:
* Fixed bug where arithmetic operators were not returning
* a rounded value. 
*
* Added void Symbol(string) to set the symbol after the constructor
* 
* CDouble::GetDigit - replaced "double num" with an instance of CDouble
* for rounding to the 14th digit. DO NOT USE GetDigit if you require precision
* beyond 14 digits.
**********************************************************************

*********************************************************************
* Version 1.02:
* Fixed bug where rounded result would drift from expected result. THANKS AMRALI!
*
**********************************************************************
*/


#ifdef __MQL4__
   #property strict
#endif 

#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayDouble.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDouble;
//+------------------------------------------------------------------+
//|   CDoubleVector: src at bottom of page                           |
//+------------------------------------------------------------------+
class CDoubleVector : public CArrayObj
{
public:
   CDouble          *operator[](const int index) const{ return At(index);}
   bool              Add(const double value);
   bool              AssignDoubleArray(const double &arr[]);
   bool              CopyOut(double &arr[]) const;
   bool              CopyOut(CArrayDouble &arr) const;
protected:
   virtual bool      CreateElement(const int index);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_PRECISION 
{
   PRECISION_DEFAULT   = 0,
   PRECISION_TICK_SIZE = 1,
   PRECISION_LOT_STEP  = 2
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDouble : public CObject
{
protected:
   string            m_symbol;
   double            m_value;
   uchar             m_step;
   uchar             m_digits;
   ENUM_PRECISION    m_mode;
public:
                     CDouble(const ENUM_PRECISION mode=PRECISION_DEFAULT,const string symbol=NULL);
                     CDouble(const CDouble &other);
                    ~CDouble();
   string            Symbol()              const { return m_symbol;  }
   void              Symbol(const string symbol) { m_symbol = symbol;}
//Precision control: Defaults: digits=8; step = 1e-08
   //Three ways to control precision: Step, Digits, or PrecisionMode. Any call to either of these setter methods will override prev settings.
   //Step is either the _Point or LOT_STEP or TickSize; represented as a floating point (eg. 0.00001, 0.025, etc.)
   //It is not necessary to set the step since RoundToTick and RoundToLot automatically use the appropriate step values.
   //(int)digits are automatically extracted from the "step" and will override any previous Digits set method call.
   void              Step(const double step_or_point);
   //returns the current working step
   double            Step(void)const;
   
   //Digits will override the step and precision mode -> as 1.0/(10^digits) ie. Digits(5) == step(0.00001) 
   void              Digits(const int digits);
   //returns the current working digit
   int               Digits(void)const;
   //PrecisionMode sets the default mode for rounding calulations and ToString. Overrides existing Step and Digit settings
   void              PrecisionMode(const ENUM_PRECISION mode);
   ENUM_PRECISION    PrecisionMode()      const;

   //Class methods to return modified values of the member double and uses the precision as set by Step() or Digits()
   //returns the raw value of stored double
   double            AsRawDouble()        const { return m_value; }
   //returns the rounded value to the nearest specified step. default = 1e-08
   double            AsRounded()          const;
   //returns the rounded up value to the specified step
   double            AsRoundedUp()        const;
   //returns the rounded down value to the specified step 
   double            AsRoundedDown()      const;
   //returns the rounded value to the nearest tick - sprecified by the symbol's tick-size.
   double            AsRoundedTick()      const;
   //returns the rounded value to the nearest lot - sprecified by the symbol's lot-step.
   double            AsRoundedLots(bool)  const;
   //conversion methods
   int               ToInt()              const { return  (int)RoundToStep(m_value,1); }
   long              ToLong()             const { return (long)RoundToStep(m_value,1); }
   string            ToStringPrecision()  const;
   //ToString truncates trialing 0's
   string            ToString()           const;

//Static class methods
   //rounds to nearest step precision
   static double     RoundToStep(const double number,double step);
   //rounds to the nearest digit
   static double     RoundToDigit(const double number,int digits);
   //rounds up to step precision
   static double     RoundToStepUp(const double number,double step);
   //rounds down to step precision
   static double     RoundToStepDown(const double number,double step);
   //rounds to the ticksize of the current symbol or specified symbol in the param
   static double     RoundToTick(const double number,string symbol=NULL);
   //rounds down to the lot-step of the current symbol or specified symbol in the param.
   //always_return_valid == true: will always return a volume that is <= max and >= min lot size.
   static double     RoundToLots(const double number,string symbol=NULL,bool always_return_valid=true);
   //get the number of digits in a floating point number
   static int        GetDigits(double floating_point);
   //get the floating point value of the specififed number of digits
   static double     GetPoint(int digits);
   //convert double to string by number of digits. Unlike NormalizeDouble this automatically removes trailing 0's
   static string     ToString(double,int);
   //compare two doubles by step
   static bool       IsEqual(double,double,double);
   //compare two doubles by digit. default = 8 digits
   static bool       IsEqual(double,double,int);
   //compare two doubles by step. If step==NULL -> step = SYMBOL_TICK_SIZE on current chart symbol. 
   //Returns: this==other 0; this>other 1; this<other -1;
   static int        Compare(double num1,double num2,double step=NULL);
   //MQL5 TradeRequest: Rounds the price,sl,tp to nearest tick step. Rounds lots down to nearest lot-step
#ifdef __MQL5__
   static void       RoundTradeRequest(MqlTradeRequest &request);
#endif
   //round an entire array
   static void       RoundArrayToStep(double &arr[],double step = NULL);
   //round a collection of doubles
   static void       RoundArrayToStep(CArrayDouble &arr,double step = NULL);
 

//operator overloading
   //assignment
   void              Set(const double value)          { m_value = value;         }
   void              Set(const CDouble &other)        { m_value = other.m_value; }
   void              operator= (const double   value) { m_value = value;         }
   void              operator= (const CDouble &other) { m_value = other.m_value; }
   void              operator+=(const double   value) { m_value+= value;         }
   void              operator+=(const CDouble &other) { m_value+= other.m_value; }
   void              operator-=(const double   value) { m_value-= value;         }
   void              operator-=(const CDouble &other) { m_value-= other.m_value; }
   void              operator*=(const double   value) { m_value*= value;         }
   void              operator*=(const CDouble &other) { m_value*= other.m_value; }
   void              operator/=(const double   value) { m_value/= value;         }
   void              operator/=(const CDouble &other) { m_value/= other.m_value; }
   //arithmatic
   double            operator+ (const double   value) { return RoundToStep(m_value+value,        Step());}
   double            operator+ (const CDouble &other) { return RoundToStep(m_value+other.m_value,Step());}
   double            operator- (const double   value) { return RoundToStep(m_value-value,        Step());}
   double            operator- (const CDouble &other) { return RoundToStep(m_value-other.m_value,Step());}
   double            operator/ (const double   value) { return RoundToStep(m_value/value,        Step());}
   double            operator/ (const CDouble &other) { return RoundToStep(m_value/other.m_value,Step());}
   double            operator* (const double   value) { return RoundToStep(m_value*value,        Step());}
   double            operator* (const CDouble &other) { return RoundToStep(m_value*other.m_value,Step());}
   //boolean
   bool              operator==(const double   value) { return IsEqual(m_value,value,         Step());      }
   bool              operator==(const CDouble &other) { return IsEqual(m_value,other.m_value, Step());      }
   bool              operator!=(const double   value) { return (Compare(m_value,value,        Step())!= 0 );}
   bool              operator!=(const CDouble &other) { return (Compare(m_value,other.m_value,Step())!= 0 );}
   bool              operator>=(const double   value) { return (Compare(m_value,value,        Step())!= -1);}
   bool              operator>=(const CDouble &other) { return (Compare(m_value,other.m_value,Step())!= -1);}
   bool              operator<=(const double   value) { return (Compare(m_value,value,        Step())!= 1 );}
   bool              operator<=(const CDouble &other) { return (Compare(m_value,other.m_value,Step())!= 1 );}
   bool              operator> (const double   value) { return (Compare(m_value,value,        Step())== 1 );}
   bool              operator> (const CDouble &other) { return (Compare(m_value,other.m_value,Step())== 1 );}
   bool              operator< (const double   value) { return (Compare(m_value,value,        Step())== -1);}
   bool              operator< (const CDouble &other) { return (Compare(m_value,other.m_value,Step())== -1);}
   
protected:
   void             _Step(const double);
public:
//Virtual methods
   //compare method compares CDouble objects for searching and sorting
   virtual int       Compare(const CObject *node,const int mode=0)const override;
   virtual int       Type()                                       const override;
   virtual bool      Save(const int file_handle)                        override;
   virtual bool      Load(const int file_handle)                        override;
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDouble::CDouble(const ENUM_PRECISION mode = PRECISION_DEFAULT, const string symbol = NULL)
{
   m_value = 0.0;
   m_symbol = symbol == NULL ? _Symbol : symbol;
   PrecisionMode(mode);
}
//+------------------------------------------------------------------+
//| Copy Constructor
//+------------------------------------------------------------------+
CDouble::CDouble(const CDouble &other)
{
   m_symbol = other.m_symbol;
   m_value = other.m_value;
   m_step = other.m_step;
   m_digits = other.m_digits;
   m_mode = other.m_mode;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDouble::~CDouble()
{
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDouble::Compare(const CObject *node, const int mode = 0) const override
{
   const CDouble *other = node;
   if (this.AsRounded() > other.AsRounded())
      return  1;
   if (this.AsRounded() < other.AsRounded())
      return -1;
   return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDouble::Save(const int file_handle)
{
   if (file_handle == INVALID_HANDLE)
      return (false);
   //start marker
   if (FileWriteLong(file_handle, -1) != sizeof(long))
      return (false);
   if (FileWriteInteger(file_handle, Type()) != INT_VALUE)
      return false;
   uint len = StringLen(m_symbol);
   if (FileWriteInteger(file_handle, len) != INT_VALUE)
      return false;
   if (len > 0)
      len = FileWriteString(file_handle, m_symbol, len);
   if (FileWriteDouble(file_handle, m_value) != sizeof(double))
      return false;
   if (FileWriteInteger(file_handle, m_step, CHAR_VALUE) != CHAR_VALUE)
      return false;
   if (FileWriteInteger(file_handle, m_digits, CHAR_VALUE) != CHAR_VALUE)
      return false;
   if (FileWriteInteger(file_handle, (int)m_mode, INT_VALUE) != INT_VALUE)
      return false;
   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDouble::Load(const int file_handle)
{
   if (file_handle == INVALID_HANDLE)
      return (false);
   if (FileReadLong(file_handle) != -1)
      return (false);
   int type = FileReadInteger(file_handle, INT_VALUE);
   if (type != Type())
      return (false);
   int len = FileReadInteger(file_handle, INT_VALUE);
   m_symbol = (len != 0) ? FileReadString(file_handle, len) : "";
   m_value = FileReadDouble(file_handle);
   m_step = (uchar)FileReadInteger(file_handle, CHAR_VALUE);
   m_digits = (uchar)FileReadInteger(file_handle, CHAR_VALUE);
   m_mode = (ENUM_PRECISION)FileReadInteger(file_handle, INT_VALUE);
   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDouble::Type(void) const override
{
   return TYPE_DOUBLE;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDouble::Step(const double step_or_point)
{
   m_mode = PRECISION_DEFAULT;
   m_digits = (uchar)GetDigits(step_or_point);
   m_step = uchar(step_or_point * pow(10, m_digits));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDouble::_Step(const double step_or_point)
{
   m_digits = uchar(GetDigits(step_or_point));
   m_step = uchar(step_or_point * pow(10, m_digits));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::Step(void) const
{
   return (double)m_step / pow(10, (double)m_digits);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDouble::Digits(const int digits)
{
   m_mode = PRECISION_DEFAULT;
   m_step = (uchar)1;
   m_digits = (uchar)digits;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDouble::Digits(void) const
{
   return (int)m_digits;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDouble::PrecisionMode(const ENUM_PRECISION mode)
{
   m_mode = mode;
   if (mode == PRECISION_LOT_STEP)
   {
      _Step(SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP));
   }
   else if (mode == PRECISION_TICK_SIZE)
   {
      _Step(SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE));
   }
   else
   {
      this.Digits(8);
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_PRECISION CDouble::PrecisionMode(void) const
{
   return m_mode;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CDouble::ToString(void) const
{
   int digits = GetDigits(AsRounded());
   return DoubleToString(AsRounded(), fmin(digits, m_digits));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CDouble::ToStringPrecision(void) const
{
   return DoubleToString(RoundToStep(m_value, Step()), m_digits);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::AsRounded(void) const
{
   return RoundToStep(m_value, Step());
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::AsRoundedUp(void) const
{
   return RoundToStepUp(m_value, Step());
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::AsRoundedDown(void) const
{
   return RoundToStepDown(m_value, Step());
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::AsRoundedTick(void) const
{
   return RoundToTick(m_value, m_symbol);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::AsRoundedLots(bool always_return_valid = true) const
{
   return RoundToLots(m_value, m_symbol, always_return_valid);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::RoundToStep(double number, double step)
{
   return step * NormalizeDouble(number / step, 0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::RoundToDigit(double number, int digits)
{
   return NormalizeDouble(number, digits);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::RoundToStepUp(double number, double step)
{
   return step * ceil(number / step);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::RoundToStepDown(double number, double step)
{
   return step * floor(number / step);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::RoundToTick(double number, string symbol = NULL)
{
   symbol = symbol == NULL ? _Symbol : symbol;
   return RoundToStep(number, SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::RoundToLots(double number, string symbol = NULL, bool always_return_valid = true)
{
   symbol = symbol == NULL ? _Symbol : symbol;
   double min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lots = RoundToStepDown(number, SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));
   if (always_return_valid && lots < min)
      return min;
   if (always_return_valid && lots > max)
      return max;
   return lots;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#ifdef __MQL5__
void CDouble::RoundTradeRequest(MqlTradeRequest &request)
{
   request.price = RoundToTick(request.price,request.symbol);
   request.sl    = RoundToTick(request.sl,request.symbol);
   request.tp    = RoundToTick(request.tp,request.symbol);
   request.volume= RoundToLots(request.volume,request.symbol,false);
}
#endif
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDouble::RoundArrayToStep(double &arr[],double step=NULL)
{
   step = step != NULL ? step : SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   int total = ArraySize(arr);
   for(int i=0;i<total;i++)
      arr[i] = RoundToStep(arr[i],step);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDouble::RoundArrayToStep(CArrayDouble &arr,double step=NULL)
{
   step = step != NULL ? step : SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   int total = arr.Total();
   for(int i=0;i<total;i++)
      arr.Update(i,RoundToStep(arr[i],step));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDouble::IsEqual(double num1, double num2, double step)
{
   return RoundToStep(num1 - num2, step) == 0.0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDouble::IsEqual(double num1, double num2, int digits = 8)
{
   double step = GetPoint(digits);
   return RoundToStep(num1 - num2, step) == 0.0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDouble::Compare(double num1,double num2,double step=NULL)
{
   if(step == NULL)
      step = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double res = RoundToStep(num1-num2,step);
   if(res>0.0)
      return 1;
   if(res<0.0)
      return -1;
   return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CDouble::ToString(double num, int digits = 8)
{
   num = RoundToStep(num, GetPoint(digits));
   return DoubleToString(num, fmin(GetDigits(num), digits));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDouble::GetDigits(double floating_point)
{
   CDouble num = floating_point;
   num.Digits(14);
   int i = 0;
   for (i = 0; num != round(num.AsRawDouble()); num *= 10, i++)
      continue;
   return i;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDouble::GetPoint(int digits)
{
   return 1.0 / pow(10, digits);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//********************************************************************

//********************************************************************

//********************************************************************

//+------------------------------------------------------------------+
//|       CDoubleVector src                                          |
//+------------------------------------------------------------------+
bool CDoubleVector::CreateElement(const int index)
{
   CDouble *dub = new CDouble;
   if (!CheckPointer(dub))
      return false;
   m_data[index] = dub;
   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDoubleVector::Add(const double value)
{
   CDouble *dub = new CDouble;
   dub = value;
   return Add(dub);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDoubleVector::AssignDoubleArray(const double &arr[])
{
   Clear();
   int total = ArraySize(arr);
   for (int i = 0; i < total; i++)
   {
      CDouble *dub = new CDouble;
      dub = arr[i];
      if (!Add(dub))
         return false;
   }
   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDoubleVector::CopyOut(double &arr[])const
{
   int total = ArrayResize(arr,Total());
   for(int i=0;i<total;i++)
      arr[i] = this[i].AsRounded();     
   
   return (ArraySize(arr) == Total());
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDoubleVector::CopyOut(CArrayDouble &arr)const
{
   arr.Clear();
   int total = Total();
   for(int i=0;i<total;i++)
      arr.Add(this[i].AsRounded());    
       
   return (arr.Total() == Total());
}
//+------------------------------------------------------------------+
