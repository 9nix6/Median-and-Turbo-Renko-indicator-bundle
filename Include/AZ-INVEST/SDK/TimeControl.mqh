//
// Copyright 2018, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

class CTimeControl
{
   private:
   
      string start;
      string end;
      
   public:
   
      void SetTValidTraingHours(string _from = "0:00", string _to = "0:00");
      bool IsTradingTimeValid();
};


void CTimeControl::SetTValidTraingHours(string _from,string _to)
{
   this.start = _from;
   this.end   = _to;   
}

bool CTimeControl::IsTradingTimeValid()
{
   if(((this.start == "0") && (this.end == "0")) || 
      ((this.start == "0:00") && (this.end == "0:00")))
         return true;

   datetime now = TimeCurrent();
   
   MqlDateTime temp;
   TimeToStruct(now,temp);
   
   datetime _start = StringToTime((string)temp.year+"."+(string)temp.mon+"."+(string)temp.day+" "+this.start); 
   datetime _end  = StringToTime((string)temp.year+"."+(string)temp.mon+"."+(string)temp.day+" "+this.end); 
   
   if((now >= _start) && (now <= _end))
      return true;
   else
      return false;
}
