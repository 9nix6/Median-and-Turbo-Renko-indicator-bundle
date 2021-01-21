# MedianRenko.mqh
MQL5 header file for the "Median and Turbo Renko indicator bundle"  available for MT5 via MQL5 Market. The class library file simplifies the MedianRenko indicator usage when creating a Renko EA for MT5. The created EA will automatically acquire the settings used on the Renko chart. It is not required to clone the settings from the indicator to the EA.

## The files
**MedianRenko.mqh** - The header file for including in the EA code. It contains the definition and implementation of the MedianRenko class

**CommonSettings.mqh** & **RenkoSettings.mqh** - These header files are used by the **MedianRenko** class to automatically read the EA settings used on the Renko chart where the EA should be attached.

**MedianRenkoIndicator.mqh** - This helper header file includes a **MedianRenkoIndicator** class which is used to patch MQL5 indicators to work directly on the Renko charts and use the Renko OLHC values for calculation.

**ExampleEA.mq5** - An example EA skeleton showing the use of methods included in the MedianRenko class library

**ExampleEA2.mq5** - An example EA utilizing the Super Trend indicator on Renko to make trading decisions also showing the use of methods included in the MedianRenko class library

**ExampleEA3.mq5** - An example showing the use of additional indicators (included in the Indicators/MedianRenko folder) in your EA. MedianRenko_RSI indicator is used in the example (RSI values are outputted to log).

**2MA_Cross.mq5** - A fully functioning EA that places trades based on a 2 MA cross signal. Fixed stop loss and take profit levels can be set as well as valid trading hours.

**PriceMA_Cross.mq5** - A fully functional EA that places trades on price & MA cross signals. Both a fixed stop loss and take profit levels can be set as well as valid trading hours.

**Renko_EA** - Robust EA for automated trading on renko charts. The EA uses the most commonly used renko trading signals. The settings enable very flexible entry & exit signals as well as an optional trailing stop.

## Installation

All folders with header files & EA should be placed in the **MQL5** sub-folder of your Metatrader's Data Folder.
This short video will walk you through the installation process: 

[![Installing the renko SDK](http://img.youtube.com/vi/cKZKoUMrMQE/0.jpg)](http://www.youtube.com/watch?v=cKZKoUMrMQE)

## Backtesting your EAs

[![Backtesting an EA on Renko](http://img.youtube.com/vi/00jelr1y200/0.jpg)](https://youtu.be/00jelr1y200)

## Resources
The robust Renko indicator already bundled with the EAs and additional idicators can be downloaded from https://www.az-invest.eu/ultimate-renko-indicator-generator-for-metatrader-5

A version for MT4 is available from https://www.az-invest.eu/median-renko-plug-in-for-metatrader-4

## Disclaimer:

All of the EAs and indicators presented in this repository are solely for educational and informational purposes and should not be regarded as advice or an invitation to trade. 
Application of the techniques, ideas, and suggestions presented in the videos and files of this repository is done at the user’s sole discretion and risk. 
