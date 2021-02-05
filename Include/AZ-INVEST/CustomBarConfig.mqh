#define ULTIMATE_RENKO_LICENSE
//#define RANGEBARS_LICENSE
//#define SECONDSCHART_LICENSE
//#define TICKCHART_LICENSE
//#define VOLUMECHART_LICENSE

#ifdef TICKCHART_LICENSE
   #include <AZ-INVEST/SDK/TickChartIndicator.mqh>
   #define AZINVEST_CCI TickChartIndicator
#endif 

#ifdef RANGEBARS_LICENSE
   #include <AZ-INVEST/SDK/RangeBarIndicator.mqh>
   #define AZINVEST_CCI RangeBarIndicator
#endif 

#ifdef ULTIMATE_RENKO_LICENSE
   #include <AZ-INVEST/SDK/MedianRenkoIndicator.mqh>
   #define AZINVEST_CCI MedianRenkoIndicator
#endif 

#ifdef SECONDSCHART_LICENSE
   #include <AZ-INVEST/SDK/SecondsChartIndicator.mqh>
   #define AZINVEST_CCI SecondsChartIndicator
#endif 

#ifdef VOLUMECHART_LICENSE
   #include <AZ-INVEST/SDK/VolumeChartIndicator.mqh>
   #define AZINVEST_CCI VolumeChartIndicator
#endif

#ifdef AZINVEST_CCI
   AZINVEST_CCI customChartIndicator;
#endif

