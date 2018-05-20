# MedianRenko.mqh
MQL5 header file for 'Median and Turbo Renko indicator bundle' available for MT5 via MQL5 Market. The class library file simplifies the use of the MT5 MedianRenko indicator when creating a Renko EA for MT5.
The created EA will automatically acquire the settings used on the Renko chart it is applied to, so it is no longer required to clone the indicator's settings used on the chart to the Renko settings that should be used in the EA.

## The files
**MedianRenko.mqh** - The header file for including in the EA code. It contains the definition and implementation of the MedianRenko class

**CommonSettings.mqh** & **RenkoSettings.mqh** - These header files are used by the **MedianRenko** class to automatically read the EA settings used on the Renko chart where the EA should be attached.

**MedianRenkoIndicator.mqh** - This helper header file includes a **MedianRenkoIndicator** class which is used to patch MQL5 indicators to work directly on the Renko charts and use the Renko OLHC values for calculation.

**ExampleEA.mq5** - An example EA skeleton showing the use of methods included in the MedianRenko class library

**ExampleEA2.mq5** - An example EA utilizing the Super Trend indicator on Renko to make trading decisions also showing the use of methods included in the MedianRenko class library

**ExampleEA3.mq5** - An example showing the use of additional indicators (included in the Indicators/MedianRenko folder) in your EA. MedianRenko_RSI indicator is used in the example (RSI values are outputted to log).

## Installation

All folders with header files & EA should be placed in the **MQL5** sub-folder of your Metatrader's Data Folder.
This short video will walk you through the installation process: 

[![Installing the renko SDK](http://img.youtube.com/vi/cKZKoUMrMQE/0.jpg)](http://www.youtube.com/watch?v=cKZKoUMrMQE)

## Backtesting your EAs

[![Backtesting an EA on Renko](http://img.youtube.com/vi/00jelr1y200/0.jpg)](https://youtu.be/00jelr1y200)

## Resources
The robust Renko indicator for MT5 can be downloaded from: https://www.mql5.com/en/market/product/16347

A version for MT4 is available from: http://www.az-invest.eu/median-renko-plug-in-for-metatrader-4
