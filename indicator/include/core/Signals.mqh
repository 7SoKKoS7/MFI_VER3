#ifndef __MFV_SIGNALS_MQH__
#define __MFV_SIGNALS_MQH__

int MFV_UpdateAll(MFV_State &st, const string symbol, ENUM_TIMEFRAMES chart_tf, int rates_total, int prev_calculated)
{
   int zzDepth, zzDev, zzBack;
   MFV_ZZ_ParamsForTF(chart_tf, zzDepth, zzDev, zzBack);

   int cnt=0; int idx[512]; double prc[512];
   MFV_ZZ_FindExtrema(symbol, chart_tf, zzDepth, zzDev, zzBack, cnt, idx, prc);

   // TODO: PivotEngine → Trend → Breakout → Filters → Signals → Draw → Panel
   return(rates_total);
}

#endif // __MFV_SIGNALS_MQH__
