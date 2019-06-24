//
// Copyright 2018-19, Artur Zas
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

class CTimeControl
{
   private:
   
      int      startHH;
      int      startMM;
      string   start;
      
      int      endHH;
      int      endMM;
      string   end;
      
      bool     scheduleEnabled;
      
   public:
   
      void SetValidTraingHours(string _from = "0:00", string _to = "0:00");
      bool IsTradingTimeValid();
      bool IsScheduleEnabled() { return scheduleEnabled; };
      void StringToHHMM(string value, int &HH, int &MM);
};

void CTimeControl::SetValidTraingHours(string _from,string _to)
{
   this.start = _from;
   this.end = _to;
   
   StringToHHMM(this.start, this.startHH, this.startMM);
   StringToHHMM(this.end, this.endHH, this.endMM);
   
   if(this.startHH == 0 && this.startMM == 0 && this.endHH == 0 && this.endMM == 0)
   {
      scheduleEnabled = false;
   }
   else
   {
      scheduleEnabled = true;
   }
}

bool CTimeControl::IsTradingTimeValid()
{
   if(scheduleEnabled == false)
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

void CTimeControl::StringToHHMM(string value, int &HH, int &MM) 
{
   MqlDateTime temp;
   TimeToStruct(TimeCurrent(),temp);
   
   datetime fullDateTime = StringToTime((string)temp.year+"."+(string)temp.mon+"."+(string)temp.day+" "+value); 
   TimeToStruct(fullDateTime,temp);
   
   HH = temp.hour;
   MM = temp.min;
}