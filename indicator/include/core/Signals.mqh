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
   const int currentTFIndex = MFV_TFIndex(chart_tf);
   if(currentTFIndex < 0) return rates_total;

   // Массив whitelisted TF в фиксированном порядке
   const ENUM_TIMEFRAMES WL[5] = { PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1 };
   
   int totalExtrema = 0;
   int totalOverlays = 0;
   
   // Цикл по всем WL-TF: для каждого
   for(int i = 0; i < 5; ++i) {
      ENUM_TIMEFRAMES tf = WL[i];
      
      // Взять MF-параметры
      int zzDepth, zzDev, zzBack;
      MFV_ZZ_ParamsForTF(tf, zzDepth, zzDev, zzBack);

      // Подготовить локальные массивы
      int idx[512]; 
      double prc[512]; 
      int cnt = 0;
      
      // Вызвать ZigZag
      if(MFV_ZZ_FindExtrema(symbol, tf, zzDepth, zzDev, zzBack, cnt, idx, prc)) {
         // Передать в PivotEngine
         MFV_Pivot_UpdateTF(i, idx, prc, cnt, st);
         totalExtrema += cnt;
         
         // Логировать коротко
         if(Debug_Log) PrintFormat("MFV.ZZ %s: extrema=%d", EnumToString(tf), cnt);
      } else {
         // Очистить флаги пивотов при ошибке
         st.piv[i].hasHigh = false;
         st.piv[i].hasLow = false;
         st.piv[i].hasMid = false;
      }
   }

   // Отрисовка
   if(ShowPivotsOnChart) {
      // Всегда рисовать линии текущего TF
      MFV_Draw_PivotsTF(currentTFIndex, st.piv[currentTFIndex], false);
      
      // Если включен оверлей и не только текущий ТФ
      if(PivotsChart_ShowMulti && !PivotsChart_TFOnly) {
         for(int i = 0; i < 5; ++i) {
            if(i != currentTFIndex) { // Пропускаем текущий ТФ
               MFV_Draw_PivotsOverlay(i, st.piv[i]);
               totalOverlays++;
            }
         }
      }
   } else {
      // Удалить все объекты префикса
      MFV_Draw_ClearAll("MFV_PVT_");
   }
   
   // Логирование отрисовки
   if(Debug_Log) PrintFormat("MFV.DRAW: cur=%s overlays=%d", EnumToString(chart_tf), totalOverlays);
   
   // Обновляем панель
   MFV_Panel_DrawAll(st, Panel_Show_M5, Panel_Show_M15, Panel_Show_H1, Panel_Show_H4, Panel_Show_D1);
   MFV_Draw_UpdateChart();
   
   return rates_total;
}

#endif // __MFV_SIGNALS_MQH__
