//
// Copyright 2018-2021, Artur Zas
// GNU General Public License v3.0 -> https://github.com/9nix6/Median-and-Turbo-Renko-indicator-bundle/blob/master/LICENSE
// https://www.az-invest.eu 
// https://www.mql5.com/en/users/arturz
//

class CTimeControl
{
   private:
   
      int      scheduleID;
      
      int      startHH;
      int      startMM;
      string   start;
      datetime startOfSession;
      
      int      endHH;
      int      endMM;
      string   end;
      datetime endOfSession;
      
      bool     scheduleEnabled;
      
   public:
   
      CTimeControl(int id = 0) { scheduleID = id; };
      
      void SetValidTraingHours(string _from = "0:00", string _to = "0:00");
      void SetValidTraingHours(bool _unused, string _timeSpan = "0:00-0:00");
      bool IsTradingTimeValid();
      bool IsScheduleEnabled() { return scheduleEnabled; };
      void UpdateSessionDateTime(int addSecods = 0); 
      datetime GetSessionStartTime() { return startOfSession; };
      datetime GetSessionEndTime() { return endOfSession; };
      void MoveSessionStartToNow();
      string ToString();
      
   private:
   
      void StringToHHMM(string value, int &HH, int &MM);
      bool StringToHHMMRange(string value, int &startHH, int &startMM, string& _start, int &endHH, int &endMM, string& _end);
      void SetScheduleState();    
};

void CTimeControl::SetValidTraingHours(string _from, string _to)
{
   this.start = _from;
   this.end = _to;
   
   StringToHHMM(this.start, this.startHH, this.startMM);
   StringToHHMM(this.end, this.endHH, this.endMM);
   UpdateSessionDateTime();
   
   SetScheduleState();      
}

void CTimeControl::MoveSessionStartToNow()
{
   datetime now = TimeCurrent();
   
   MqlDateTime temp;
   TimeToStruct(now,temp);
   
   startHH = temp.hour;
   startMM = temp.min;
   start = StringFormat("%02d:%02d", startHH, startMM);

   UpdateSessionDateTime(temp.sec + 1);      
}

void CTimeControl::UpdateSessionDateTime(int addSecods = 0)
{
   datetime now = TimeCurrent();
   
   MqlDateTime temp;
   TimeToStruct(now,temp);
   
   if(addSecods > 0)
   {
      string startTimeTemp = StringFormat("%s:%02d", this.start, addSecods);
      startOfSession = StringToTime((string)temp.year+"."+(string)temp.mon+"."+(string)temp.day+" "+startTimeTemp);       
   }
   else
   {
      startOfSession = StringToTime((string)temp.year+"."+(string)temp.mon+"."+(string)temp.day+" "+this.start); 
   }
      
   endOfSession = StringToTime((string)temp.year+"."+(string)temp.mon+"."+(string)temp.day+" "+this.end);
}

void CTimeControl::SetValidTraingHours(bool _unused, string _timeSpan = "0:00-0:00")
{
   if(!StringToHHMMRange(_timeSpan,  this.startHH, this.startMM, this.start, this.endHH, this.endMM, this.end))
      return;
   
   UpdateSessionDateTime();
   SetScheduleState();      
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
   
   if(_start <= now && now <= _end)
      return true;
   else
      return false;
}

string CTimeControl::ToString()
{
   string tradingScheduleName = "Trading schedule ";
   
   tradingScheduleName += (scheduleID != 0) 
      ? (string)scheduleID+" "
      : "";
      
   if(IsScheduleEnabled())
   {
      return tradingScheduleName+"ON ("+this.start+" to "+this.end+") | trading "+(IsTradingTimeValid()
      ? "enabled"
      : "disabled");
   }
   else
   {
      return tradingScheduleName+"NOT USED";
   }                     
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

bool CTimeControl::StringToHHMMRange(string value, int &_startHH, int &_startMM, string& _start, int &_endHH, int &_endMM, string& _end) 
{
   string result[];   
   int count = StringSplit(value, '-', result);
   if(count != 2)
      return false;

   MqlDateTime temp;
   TimeToStruct(TimeCurrent(),temp);
   
   // Start time
   _start = result[0];
   datetime fullDateTime = StringToTime((string)temp.year+"."+(string)temp.mon+"."+(string)temp.day+" "+_start); 
   TimeToStruct(fullDateTime,temp);
   
   startHH = temp.hour;
   startMM = temp.min;
   
   // End time
   TimeToStruct(TimeCurrent(),temp);
   _end = result[1];
   fullDateTime = StringToTime((string)temp.year+"."+(string)temp.mon+"."+(string)temp.day+" "+_end); 
   TimeToStruct(fullDateTime,temp);
   
   endHH = temp.hour;
   endMM = temp.min;   
   
   return true;
}

void CTimeControl::SetScheduleState()
{
   if(this.startHH == 0 && this.startMM == 0 && this.endHH == 0 && this.endMM == 0)
   {
      scheduleEnabled = false;
   }
   else
   {
      scheduleEnabled = true;
   }    
}
