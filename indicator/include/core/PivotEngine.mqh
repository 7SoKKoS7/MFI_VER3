#ifndef __MFV_PIVOTENGINE_MQH__
#define __MFV_PIVOTENGINE_MQH__

bool MFV_Pivot_UpdateTF(const string symbol, ENUM_TIMEFRAMES tf, const int tfIndex,
                        const int &zzIdx[], const double &zzPrice[], const int count,
                        MFV_State &st)
{
   // В начале обновления ТФ сбрасываем флаги
   st.piv[tfIndex].hasHigh = false;
   st.piv[tfIndex].hasLow  = false;
   st.piv[tfIndex].hasMid  = false;

   // Если экстремумов мало — чистим флаги и выходим
   if(count < 2) {
      if(Debug_Log) Print("MFV.Pivot: count<2 for TF index ", tfIndex);
      return false;
   }

   // Берём окно последних K (= min(40, count)) точек ZigZag и считаем H/L
   int K = MathMin(40, count), start = count - K;
   double hi = zzPrice[start], lo = zzPrice[start];
   int hiIdx = start, loIdx = start; // индексы для определения времени рождения
   
   for(int i = start; i < count; ++i) {
      if(zzPrice[i] > hi) { hi = zzPrice[i]; hiIdx = i; }
      if(zzPrice[i] < lo) { lo = zzPrice[i]; loIdx = i; }
   }

   st.piv[tfIndex].high = hi;  st.piv[tfIndex].hasHigh = true;
   st.piv[tfIndex].low  = lo;  st.piv[tfIndex].hasLow  = true;
   
   // ADDED (set pivot birth times)
   // Получаем время рождения пивотов из индексов ZigZag
   if(hiIdx >= 0 && hiIdx < count) {
      datetime hiTime = iTime(symbol, tf, zzIdx[hiIdx]);
      st.piv[tfIndex].highTime = hiTime;
   }
   if(loIdx >= 0 && loIdx < count) {
      datetime loTime = iTime(symbol, tf, zzIdx[loIdx]);
      st.piv[tfIndex].lowTime = loTime;
   }
   
   // Mid считаем всегда, флаг выставляем явно
   if(st.piv[tfIndex].hasHigh && st.piv[tfIndex].hasLow){
      st.piv[tfIndex].mid    = 0.5*(st.piv[tfIndex].high + st.piv[tfIndex].low);
      st.piv[tfIndex].hasMid = true;            // ← ключевая строка
   }
   
   // ADDED: Диагностический самотест пивотов
   if (Debug_Log) {
      const string tfc = TFCode(tf); // уже есть в Draw.mqh
      // 1) Что видит ZigZag на этом TF (последние 5 экстремумов)
      PrintFormat("PVT CHECK %s: ZZ cnt=%d | last idx=%d | last price=%.6f | last time=%s",
                  tfc, count, (count>0? zzIdx[0]:-1),
                  (count>0? zzPrice[0]:0.0),
                  (count>0? TimeToString(iTime(symbol, tf, zzIdx[0])):"n/a"));

      // 2) Текущее состояние пивотов по TF
      PrintFormat("PVT CHECK %s: H=%.6f (t=%s) | M=%.6f | L=%.6f (t=%s)",
                  tfc,
                  st.piv[tfIndex].high, TimeToString(st.piv[tfIndex].highTime),
                  st.piv[tfIndex].mid,
                  st.piv[tfIndex].low,  TimeToString(st.piv[tfIndex].lowTime));

      // 3) Возраст пивотов в барах TF
      datetime t_last = iTime(symbol, tf, 1); // время последнего ЗАКРЫТОГО бара
      int ageH = (st.piv[tfIndex].highTime>0 ? (int)MathFloor((t_last - st.piv[tfIndex].highTime)/PeriodSeconds(tf)) : -1);
      int ageL = (st.piv[tfIndex].lowTime >0 ? (int)MathFloor((t_last - st.piv[tfIndex].lowTime )/PeriodSeconds(tf)) : -1);
      PrintFormat("PVT CHECK %s: ageH=%d bars | ageL=%d bars", tfc, ageH, ageL);

      // 4) Триггеры проблем — печатаем короткую причину
      if (count < 2)
         PrintFormat("PVT WARN %s: insufficient ZZ extrema for pivot update", tfc);
      if (st.piv[tfIndex].highTime>0 && st.piv[tfIndex].lowTime>0 && st.piv[tfIndex].highTime==st.piv[tfIndex].lowTime)
         PrintFormat("PVT WARN %s: highTime==lowTime (check classification)", tfc);
   }
   
   return true;
}

void MFV_Early_Draw(const int tfIndex, const int &zzIdx[], const double &zzPrice[], const int count)
{
   if(!EP_Enable || count < 2) return;
   
   // Получить последний swing-экстремум
   int lastIdx = zzIdx[count - 1];
   double lastPrice = zzPrice[count - 1];
   
   // Определить порог
   double threshold = 0;
   if(EP_MinRetracePips > 0) {
      threshold = EP_MinRetracePips * Point();
   } else if(EP_MinRetraceATR > 0) {
      threshold = EP_MinRetraceATR * iATR(Symbol(), Period(), 14);
   }
   
   if(threshold <= 0) return;
   
   // Получить текущую цену (Close[1] для no repaint)
   double currentPrice = iClose(Symbol(), Period(), 1);
   
   // Проверить ретрейсмент
   bool isRetrace = false;
   if(lastPrice > currentPrice) {
      // Последний экстремум был High, проверяем ретрейсмент вниз
      if((lastPrice - currentPrice) >= threshold) {
         isRetrace = true;
      }
   } else {
      // Последний экстремум был Low, проверяем ретрейсмент вверх
      if((currentPrice - lastPrice) >= threshold) {
         isRetrace = true;
      }
   }
   
   if(!isRetrace) return;
   
   // Рисуем Early линию
   string tfName;
   switch(tfIndex) {
      case 0: tfName = "M5"; break;
      case 1: tfName = "M15"; break;
      case 2: tfName = "H1"; break;
      case 3: tfName = "H4"; break;
      case 4: tfName = "D1"; break;
      default: return;
   }
   
   string objName = "MFV_PVT_" + Symbol() + "_" + tfName + "_EP";
   ObjectDelete(0, objName);
   ObjectCreate(0, objName, OBJ_HLINE, 0, 0, lastPrice);
   
   color epColor = (lastPrice > currentPrice) ? EP_H_Color : EP_L_Color;
   ObjectSetInteger(0, objName, OBJPROP_COLOR, epColor);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, EP_LineWidth);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, EP_LineStyle);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
}

#endif // __MFV_PIVOTENGINE_MQH__
