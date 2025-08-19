#property copyright   "MFI_VER3"
#property link        ""
#property version     "1.000"
#property strict
#property indicator_chart_window
#property indicator_plots 1
#property indicator_buffers 1

#include "include/core/Types.mqh"
#include "include/core/Config.mqh"
#include "include/core/State.mqh"
#include "include/core/Utils.mqh"
#include "include/core/MarketData.mqh"
#include "include/core/ZigZagAdapter.mqh"
#include "include/core/PivotEngine.mqh"
#include "include/core/TrendEngine.mqh"
#include "include/core/Breakout.mqh"
#include "include/core/Filters.mqh"
#include "include/core/Signals.mqh"
#include "include/core/Draw.mqh"
#include "include/core/Panel.mqh"
#include "include/core/Logger.mqh"

double _MFV_DummyBuffer[];

int OnInit()
{
   SetIndexBuffer(0,_MFV_DummyBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetString(0,PLOT_LABEL,"MFV Dummy");
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason) {}
int OnCalculate(const int rates_total,const int prev_calculated,const int begin,const double &price[])
{
   return MFV_UpdateAll(g_state, Symbol(), Period(), rates_total, prev_calculated);
}
