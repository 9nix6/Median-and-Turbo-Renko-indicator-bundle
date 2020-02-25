// RSI on Buffer

int RsiOnBuffer(const int rates_total,const int prev_calculated,const int begin,
                       const int period,const double& price[],double& rsiBuffer[], double &posBuffer[], double &negBuffer[])
{
   int i, pos;
   double diff;
   
//--- check for data
   if(period<=1 || rates_total-begin<period) return(0);
//--- save as_series flags
   bool as_series_price=ArrayGetAsSeries(price);
   bool as_series_rsibuffer=ArrayGetAsSeries(rsiBuffer);
   bool as_series_posbuffer=ArrayGetAsSeries(posBuffer);
   bool as_series_negbuffer=ArrayGetAsSeries(negBuffer);
   
   if(as_series_price)  ArraySetAsSeries(price,false);
   if(as_series_rsibuffer) ArraySetAsSeries(rsiBuffer,false);
   if(as_series_posbuffer) ArraySetAsSeries(posBuffer,false);
   if(as_series_negbuffer) ArraySetAsSeries(negBuffer,false);

//--- preliminary calculations
   pos=prev_calculated-1;
   if(pos<=period)
   {
      //--- first RSIPeriod values of the indicator are not calculated
      rsiBuffer[0]=0.0;
      posBuffer[0]=0.0;
      negBuffer[0]=0.0;
      double sump=0.0;
      double sumn=0.0;
      for(i=1; i<=period; i++)
      {
         rsiBuffer[i]=0.0;
         posBuffer[i]=0.0;
         negBuffer[i]=0.0;
         diff=price[i]-price[i-1];
         if(diff>0)
            sump+=diff;
         else
            sumn-=diff;
      }
      //--- calculate first visible value
      posBuffer[period]=sump/period;
      negBuffer[period]=sumn/period;
      if(negBuffer[period]!=0.0)
         rsiBuffer[period]=100.0-(100.0/(1.0+posBuffer[period]/negBuffer[period]));
      else
      {
         if(posBuffer[period]!=0.0)
            rsiBuffer[period]=100.0;
         else
            rsiBuffer[period]=50.0;
      }
      //--- prepare the position value for main calculation
      pos=period+1;
   }   
//--- the main loop of calculations
   for(i=pos; i<rates_total && !IsStopped(); i++)
   {
      diff=price[i]-price[i-1];
      posBuffer[i]=(posBuffer[i-1]*(period-1)+(diff>0.0?diff:0.0))/period;
      negBuffer[i]=(negBuffer[i-1]*(period-1)+(diff<0.0?-diff:0.0))/period;
      if(negBuffer[i]!=0.0)
         rsiBuffer[i]=100.0-100.0/(1+posBuffer[i]/negBuffer[i]);
      else
      {
         if(posBuffer[i]!=0.0)
            rsiBuffer[i]=100.0;
         else
            rsiBuffer[i]=50.0;
      }
   }
//--- restore as_series flags
   if(as_series_price)  ArraySetAsSeries(price,true);
   if(as_series_rsibuffer) ArraySetAsSeries(rsiBuffer,true);
   if(as_series_posbuffer) ArraySetAsSeries(posBuffer,true);
   if(as_series_negbuffer) ArraySetAsSeries(negBuffer,true);
//---
    return(rates_total);   
}

//+------------------------------------------------------------------+
