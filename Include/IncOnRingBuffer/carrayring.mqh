//+------------------------------------------------------------------+
//|                                                   CArrayRing.mqh |
//|                               Copyright 2012, Konstantin Gruzdev |
//|                            https://login.mql5.com/ru/users/Lizar |
//|                                             Revision 03 Dec 2012 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2012, Konstantin Gruzdev"
#property link        "https://login.mql5.com/ru/users/Lizar"

//+------------------------------------------------------------------+
//| Class CArrayRing                                                 |
//| Appointment: class is designed to work with tne finite ring      |
//|    buffers of data. When the buffer is crowded the oldest        |
//|    buffer element is replaced by the newest element. Herewith,   |
//|    the specified number of end elements are always               |
//|    available.                                                    |
//| Link: http://www.mql5.com/ru/code/1340                           |
//| Remark: it should also be kept in mind that the element indexing |
//|    in the ring buffer is executed as in timeseries.              |
//+------------------------------------------------------------------+
class CArrayRing
  {
private:
   double            m_data[];         // ring buffer of data
   int               m_size;           // buffer size
   int               m_last_pos;       // last buffer element position
   double            m_filling;        // value, which used for the array filling

public:
                     CArrayRing();
                    ~CArrayRing()                  { ArrayFree(m_data);                         }
   //--- buffer initialization method:
   bool              Init(int size, double volue=EMPTY_VALUE);             
   //--- method returns the buffer size:
   int               Size()                        { return m_size-1;                           }
   //--- method changes the ring buffer size:
   bool              Resize(const int size);
   //--- method of adding a new element to the buffer:
   void              Add(const double element); 
   //--- method returns the value of element with the specified index:
   double            At(const int index) const;
   double operator   [](const int index) const     { return(At(index));                         }
   //--- method returns the value of the last element stored in the buffer:
   double            Last() const                  { return(m_data[m_last_pos]);                } 
   //--- method overwrites the value of the last element in the buffer:
   void              Last(const double element)    { m_data[m_last_pos]=element;                }  
   //--- method overwrites the value of element with the specified index:
   bool              Update(const double element,const int index=0);  
  };
//+------------------------------------------------------------------+
//| Constructor.                                                     |
//+------------------------------------------------------------------+
CArrayRing::CArrayRing()
  {
   m_last_pos=0;                          // last element position
   m_filling=EMPTY_VALUE;                 // value for buffer filling
   m_size=ArraySize(m_data);              // get size of the ring buffer
  }

//+------------------------------------------------------------------+
//| Buffer initialization method.                                    |
//+------------------------------------------------------------------+
bool CArrayRing::Init(int size, double volue=EMPTY_VALUE)
  {
   m_last_pos=0;                          // last element position
   m_filling=volue;                       // value for buffer filling
   m_size=ArraySize(m_data);              // get size of the buffer   
   bool result=Resize(size);              // create a buffer with the desired size
   ArrayFill(m_data,0,m_size,m_filling);  // fill the buffer with default values
   return(result);                  
  }  

//+------------------------------------------------------------------+
//| Set the new size of the array.                                   |
//+------------------------------------------------------------------+
bool CArrayRing::Resize(const int new_size)
  {
//--- check
   if(new_size<0) return(false);
//--- increase array size:
   if(new_size>m_size)
     {
      int set_size=ArrayResize(m_data,new_size);
      if(set_size<0) return(false);
      //--- copy elements to restore their order:
      if(set_size>m_size)
        {
         for(int i=m_size-1,j=set_size-1;i>m_last_pos;i--,j--)
           {
            m_data[j]=m_data[i];
            m_data[i]=m_filling;
           }
        }
      m_size=set_size;
      //--- result:
      return(true);      
     }
//--- reduce array size:
   //--- prepare array to reduce the size:
   if(new_size>m_last_pos+1)
      for(int i=m_size-1,j=new_size-1;j>m_last_pos;i--,j--) m_data[j]=m_data[i];
   else
     {
      for(int i=m_last_pos+1-new_size,j=0;i<=m_last_pos;i++,j++) m_data[j]=m_data[i];    
      m_last_pos=new_size-1;
     }
   //--- reduce the size:
   m_size=new_size;
   ArrayResize(m_data,new_size);
//--- result:
   return(true);
  }
  
//+------------------------------------------------------------------+
//| Adding a new element to the buffer.                              |
//+------------------------------------------------------------------+
void CArrayRing::Add(const double element)
  {
   m_last_pos=++m_last_pos%m_size;
   m_data[m_last_pos]=element;
  } 
  
//+------------------------------------------------------------------+
//| Gets the element at the specified index.                         |
//+------------------------------------------------------------------+
double CArrayRing::At(const int index) const
  {
//--- check the index correctness:
   if((index/m_size)==0) 
//--- return the value of element with the specified index:
      return(m_data[(m_size+m_last_pos-index)%m_size]);
//--- if the index is wrong:
   return(DBL_MAX);   
  }  

//+------------------------------------------------------------------+
//| Update the element at the specified position in the array.       |
//+------------------------------------------------------------------+
bool CArrayRing::Update(const double element,const int index=0)
  {
//--- check the index correctness:
   if((index/m_size)==0) 
     {
//--- update
      m_data[(m_size+m_last_pos-index)%m_size]=element;
//--- successful
      return(true);
     }
//--- if the index is wrong:
   return(false);   
  }

    
