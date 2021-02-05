//------------------------------------------------------------------

   #property copyright "mladen"
   #property link      "www.forex-tsd.com"

// Inserted by Ale: rebound arrows and TMA angle caution

//------------------------------------------------------------------

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   6

#property indicator_label1  "Centered TMA"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLightSkyBlue,clrPink
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "Centered TMA upper band"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLightSkyBlue
#property indicator_style2  STYLE_DOT
#property indicator_label3  "Centered TMA lower band"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrPink
#property indicator_style3  STYLE_DOT
// ** inserted code:
#property indicator_label4  "Rebound down"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrPink
#property indicator_width4  2
#property indicator_label5  "Rebound up"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrLightSkyBlue
#property indicator_width5  2
#property indicator_label6  "Centered TMA angle caution"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrGold
#property indicator_width6  3
// **

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+oprn+close)/4
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage   // Heiken ashi average
};

//
//
//
//
//

input int       HalfLength    = 12;       // Centered TMA half period
input enPrices  Price         = pr_weighted; // Price to use
input int       AtrPeriod     = 100;      // Average true range period 
input double    AtrMultiplier = 2;        // Average true range multiplier
// ** inserted code:
input int				TMAangle			= 4;				// Centered TMA angle caution. In pips
// **

//
//
//
//
//

double tmac[];
double tmau[];
double tmad[];
double colorBuffer[];
// ** inserted code:
double
	ReboundD[], ReboundU[],
	Caution[]
;
// **

//

#include <AZ-INVEST/CustomBarConfig.mqh>

//

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,tmac,INDICATOR_DATA); 
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(2,tmau,INDICATOR_DATA); 
   SetIndexBuffer(3,tmad,INDICATOR_DATA); 
// ** inserted code:
	SetIndexBuffer(4,ReboundD,INDICATOR_DATA); PlotIndexSetInteger(3, PLOT_ARROW, 226);
	SetIndexBuffer(5,ReboundU,INDICATOR_DATA); PlotIndexSetInteger(4, PLOT_ARROW, 225);
	SetIndexBuffer(6,Caution,INDICATOR_DATA); PlotIndexSetInteger(5, PLOT_ARROW, 251);
// **

   //
   //
   //
   //
   //
            
   IndicatorSetString(INDICATOR_SHORTNAME," TMA centered ("+string(HalfLength)+")");
   return(0);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double prices[];

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   //
   //
   
   if(!customChartIndicator.OnCalculate(rates_total,prev_calculated,time,close))
      return(0);
   
   if(!customChartIndicator.BufferSynchronizationCheck(close))
      return(0);
      
   int _prev_calculated = customChartIndicator.GetPrevCalculated();

   //
   //
   //

   if (ArraySize(prices)!=rates_total) ArrayResize(prices,rates_total);
   for (int i=(int)MathMax(_prev_calculated-1,         0); i<rates_total; i++) prices[i] = getPrice(Price,customChartIndicator.Open,customChartIndicator.Close,customChartIndicator.High,customChartIndicator.Low,i,rates_total);
   for (int i=(int)MathMax(_prev_calculated-HalfLength,0); i<rates_total; i++)
   {
      double atr = 0;
         for (int j=0; j<AtrPeriod && (i-j-11)>=0; j++) atr += MathMax(customChartIndicator.High[i-j-10],customChartIndicator.Close[i-j-11])-MathMin(customChartIndicator.Low[i-j-10],customChartIndicator.Close[i-j-11]);
                                                        atr /= AtrPeriod;
      
      double sum  = (HalfLength+1)*prices[i];
      double sumw = (HalfLength+1);
      for(int j=1, k=HalfLength; j<=HalfLength; j++, k--)
      {
         if ((i-j)>=0)
         {
            sum  += k*prices[i-j];
            sumw += k;
         }            
         if ((i+j)<rates_total)
         {
            sum  += k*prices[i+j];
            sumw += k;
         }
      }
      tmac[i] = sum/sumw;   
      if (i>0)
      {
         colorBuffer[i] = colorBuffer[i-1];
           if (tmac[i] > tmac[i-1]) colorBuffer[i]= 0;
           if (tmac[i] < tmac[i-1]) colorBuffer[i]= 1;
      }                     
      tmau[i] = tmac[i]+AtrMultiplier*atr;
      tmad[i] = tmac[i]-AtrMultiplier*atr;


// ** inserted code:
		ReboundD[i] = ReboundU[i] = Caution[i] = EMPTY_VALUE;
		
		if(i > 0) {
			if(customChartIndicator.High[i-1] > tmau[i-1] && customChartIndicator.Close[i-1] > customChartIndicator.Open[i-1] && customChartIndicator.Close[i] < customChartIndicator.Open[i]) {
				ReboundD[i] = customChartIndicator.High[i] + AtrMultiplier*atr/2;
				if(tmac[i] - tmac[i-1] > TMAangle*_Point) Caution[i] = ReboundD[i] + 10*_Point;
			}
			if(low[i-1] < tmad[i-1] && customChartIndicator.Close[i-1] < customChartIndicator.Open[i-1] && customChartIndicator.Close[i] > customChartIndicator.Open[i]) {
				ReboundU[i] = customChartIndicator.Low[i] - AtrMultiplier*atr/2;
				if(tmac[i-1] - tmac[i] > TMAangle*_Point) Caution[i] = ReboundU[i] - 10*_Point;
			}
		}
// **

   }
	
   return(rates_total);
}



//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//


double workHa[][4];
double getPrice(enPrices price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars)
{
  if (price>=pr_haclose && price<=pr_haaverage)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars);

         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][2] + workHa[i-1][3])/2.0;
         else   haOpen  = open[i]+close[i];
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][0] = haLow;  workHa[i][1] = haHigh; } 
         else                 { workHa[i][0] = haHigh; workHa[i][1] = haLow;  } 
                                workHa[i][2] = haOpen;
                                workHa[i][3] = haClose;
         //
         //
         //
         //
         //
         
         switch (price)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (price)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
   }
   return(0);
}