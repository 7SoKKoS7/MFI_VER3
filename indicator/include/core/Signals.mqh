#ifndef __MFV_SIGNALS_MQH__
#define __MFV_SIGNALS_MQH__

int MFV_TFIndex(ENUM_TIMEFRAMES tf){
   switch(tf){
      case PERIOD_M5:  return 0;
      case PERIOD_M15: return 1;
      case PERIOD_H1:  return 2;
      case PERIOD_H4:  return 3;
      case PERIOD_D1:  return 4;
      default:         return 2; // H1 fallback
   }
}

int MFV_UpdateAll(MFV_State &st, const string symbol, ENUM_TIMEFRAMES chart_tf, int rates_total, int prev_calculated)
{
   int zzDepth, zzDev, zzBack;
   MFV_ZZ_ParamsForTF(chart_tf, zzDepth, zzDev, zzBack);

   int cnt=0; int idx[512]; double prc[512];
   MFV_ZZ_FindExtrema(symbol, chart_tf, zzDepth, zzDev, zzBack, cnt, idx, prc);

   // PivotEngine stage: process ZigZag extrema and compute Medium pivot
   const int tfIndex = MFV_TFIndex(chart_tf);
   MFV_Pivot_UpdateTF(tfIndex, idx, prc, cnt, st);

   // TODO: Trend → Breakout → Filters → Signals → Draw → Panel
   MFV_Draw_PivotsTF(tfIndex);
   MFV_Panel_ShowPivots(tfIndex, st);
   
   return(rates_total);
}

#endif // __MFV_SIGNALS_MQH__
