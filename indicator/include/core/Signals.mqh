#ifndef __MFV_SIGNALS_MQH__
#define __MFV_SIGNALS_MQH__

int MFV_TFIndex(ENUM_TIMEFRAMES tf){
   switch(tf){
      case PERIOD_M5:  return 0;
      case PERIOD_M15: return 1;
      case PERIOD_H1:  return 2;
      case PERIOD_H4:  return 3;
      case PERIOD_D1:  return 4;
      default:         return -1; // Не-whitelist ТФ
   }
}

int MFV_UpdateAll(MFV_State &st, const string symbol, ENUM_TIMEFRAMES chart_tf, int rates_total, int prev_calculated)
{
   const int curIdx = MFV_TFIndex(chart_tf);    // может быть -1 (не из WL)
   const ENUM_TIMEFRAMES WL[5] = { PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1 };

   // 1) ВСЕГДА считаем пивоты для всех WL-TF (даже если текущий TF не из WL)
   for (int i=0; i<5; ++i) {
      int zzDepth, zzDev, zzBack;
      MFV_ZZ_ParamsForTF(WL[i], zzDepth, zzDev, zzBack);
      int cnt=0, idx[512]; double prc[512];
      if (MFV_ZZ_FindExtrema(symbol, WL[i], zzDepth, zzDev, zzBack, cnt, idx, prc))
         MFV_Pivot_UpdateTF(symbol, WL[i], i, idx, prc, cnt, st);
      else {
         st.piv[i].hasHigh=false; st.piv[i].hasLow=false; st.piv[i].hasMid=false;
      }
      
      // Диагностика (когда Mid вдруг «теряется»)
      if(Debug_Log){
         PrintFormat("PIV %s: H?%d L?%d M?%d  H=%.5f L=%.5f M=%.5f",
                    EnumToString(WL[i]), (int)st.piv[i].hasHigh, (int)st.piv[i].hasLow, (int)st.piv[i].hasMid,
                    st.piv[i].high, st.piv[i].low, st.piv[i].mid);
      }
   }

   // 2) Расчет трендов для всех WL-TF
   for(int i=0; i<5; i++){
      MFV_Trend_FromPivots(symbol, WL[i], st.piv[i], st.trends[i],
                           Trend_TolPoints, Trend_TolATRk, DirNow_EpsPct);
   }

   // 3) Расчет пробоев и ретестов для всех WL-TF
   for(int i=0; i<5; i++){
      MFV_Breakout_UpdateTF(symbol, WL[i], i, st.piv[i], st.trends[i], st.breakouts[i]);
   }

   // 3) Рисование
   if (ShowPivotsOnChart) {
      // линии текущего TF рисуем ТОЛЬКО если он из WL и включен режим "только текущий"
      if (curIdx>=0 && PivotsChart_TFOnly)
         MFV_Draw_PivotsTF(curIdx, st.piv[curIdx], false);

      // оверлей всех WL-ТФ (если включен). Если TFOnly=false — поверх добавим остальные.
      if (PivotsChart_ShowMulti) {
         for (int i=0; i<5; ++i) {
            if (!PivotsChart_TFOnly || i!=curIdx)
               MFV_Draw_PivotsOverlay(i, st.piv[i]);  // рисует H/L и, опционально, M
         }
      }
   } else {
      MFV_Draw_ClearAll("MFV_PVT_");
   }

   // Рисование маркеров Breakout для всех WL-TF
   for (int i=0; i<5; ++i) {
      MFV_Draw_BreakoutMarkers(i, st.breakouts[i]);
   }

   // 4) Панель — ВСЕГДА, на любом TF
   MFV_Panel_DrawAll(st, true, true, true, true, true);
   MFV_Draw_UpdateChart();
   return rates_total;
}

#endif // __MFV_SIGNALS_MQH__
