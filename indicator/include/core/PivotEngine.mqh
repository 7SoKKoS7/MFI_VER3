#ifndef __MFV_PIVOTENGINE_MQH__
#define __MFV_PIVOTENGINE_MQH__

bool MFV_Pivot_UpdateTF(const int tfIndex,
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
      datetime hiTime = iTime(Symbol(), Period(), zzIdx[hiIdx]);
      st.piv[tfIndex].highTime = hiTime;
   }
   if(loIdx >= 0 && loIdx < count) {
      datetime loTime = iTime(Symbol(), Period(), zzIdx[loIdx]);
      st.piv[tfIndex].lowTime = loTime;
   }
   
   // Mid считаем всегда, флаг выставляем явно
   if(st.piv[tfIndex].hasHigh && st.piv[tfIndex].hasLow){
      st.piv[tfIndex].mid    = 0.5*(st.piv[tfIndex].high + st.piv[tfIndex].low);
      st.piv[tfIndex].hasMid = true;            // ← ключевая строка
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
