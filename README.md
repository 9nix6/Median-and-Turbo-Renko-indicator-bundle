# MedianRenko.mqh
MQL5 header file for 'Median and Turbo Renko indicator bundle' available for MT5 via MQL5 Market. The class library file simplifies the use of the MT5 MedianRenko indicator when creating a Renko EA for MT5.
The created EA will automatically acquire the settings used on the Renko chart it is applied to, so it is no longer required to clone the indicator's settings used on the chart to the Renko settings that should be used in the EA.

## The files
**MedianRenko.mqh** - The header file for including in the EA code. It contains the definition and implementation of the MedianRenko class

**MedianRenkoSettings.mqh** - This header file is used by the **MedianRenko** class to automatically read the EA settings used on the Renko chart where the EA should be attached.

**ExampleEA.mq5** - An example EA skeleton showing the use of methods included in the MedianRenko class library

## Resources
The robust Renko indicator for MT5 can be downloaded from: https://www.mql5.com/en/market/product/16347

A version for MT4 is available from: http://www.az-invest.eu/median-renko-plug-in-for-metatrader-4
