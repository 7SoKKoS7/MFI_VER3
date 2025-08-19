#ifndef __MFV_SIGNALS_MQH__
#define __MFV_SIGNALS_MQH__

int MFV_UpdateAll(MFV_State &st, const string symbol, ENUM_TIMEFRAMES chart_tf, int rates_total, int prev_calculated)
{
   int zzDepth, zzDev, zzBack;
   MFV_ZZ_ParamsForTF(chart_tf, zzDepth, zzDev, zzBack);

   int cnt=0; int idx[512]; double prc[512];
   MFV_ZZ_FindExtrema(symbol, chart_tf, zzDepth, zzDev, zzBack, cnt, idx, prc);

   // PivotEngine stage: process ZigZag extrema and compute Medium pivot
   int tfIndex = 0; // TODO: map chart_tf to index (M5=0, M15=1, H1=2, H4=3, D1=4)
   MFV_Pivot_UpdateTF(tfIndex, idx, prc, cnt, st);

   // TODO: Trend → Breakout → Filters → Signals → Draw → Panel
   MFV_Draw_PivotsTF(tfIndex);
   MFV_Panel_ShowPivots(tfIndex, st);
   
   return(rates_total);
}

#endif // __MFV_SIGNALS_MQH__
