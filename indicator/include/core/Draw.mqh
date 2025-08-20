#ifndef __MFV_DRAW_MQH__
#define __MFV_DRAW_MQH__

void MFV_Draw_ClearAll(const string prefix)
{
   // Удалить все объекты с именами, начинающимися с prefix
   for(int i = ObjectsTotal(0, 0, OBJ_HLINE) - 1; i >= 0; --i) {
      string objName = ObjectName(0, i, 0, OBJ_HLINE);
      if(StringFind(objName, prefix) == 0) {
         ObjectDelete(0, objName);
      }
   }
}

void MFV_Draw_PivotsTF(const int tfIndex, const MFV_Pivots &pv, bool isOverlay = false)
{ 
   if(!ShowPivotsOnChart) return;
   
   // Определяем цвета и стили в зависимости от режима
   color hColor, mColor, lColor;
   int lineWidth;
   ENUM_LINE_STYLE lineStyle;
   
   if(!isOverlay) {
      // Основные цвета для текущего ТФ
      hColor = PivotHColor;
      mColor = PivotMColor;
      lColor = PivotLColor;
      lineWidth = PivotLineWidth;
      lineStyle = PivotLineStyle;
   } else {
      // Цвета оверлея в зависимости от ТФ
      switch(tfIndex) {
         case 0: hColor = mColor = lColor = Overlay_M5_Color; break;   // M5
         case 1: hColor = mColor = lColor = Overlay_M15_Color; break;  // M15
         case 2: hColor = mColor = lColor = Overlay_H1_Color; break;   // H1
         case 3: hColor = mColor = lColor = Overlay_H4_Color; break;   // H4
         case 4: hColor = mColor = lColor = Overlay_D1_Color; break;   // D1
         default: return;
      }
      lineWidth = Overlay_LineWidth;
      lineStyle = Overlay_LineStyle;
   }
   
   // Формируем имена объектов
   string tfName;
   switch(tfIndex) {
      case 0: tfName = "M5"; break;
      case 1: tfName = "M15"; break;
      case 2: tfName = "H1"; break;
      case 3: tfName = "H4"; break;
      case 4: tfName = "D1"; break;
      default: return;
   }
   
   string objPrefix = "MFV_PVT_" + Symbol() + "_" + tfName + "_";
   if(isOverlay) objPrefix += "OVL_";
   
   // Проверяем наличие пивотов
   if(!pv.hasHigh && !pv.hasLow && !pv.hasMid) {
      Print("MFV.Draw: no pivots for TF ", tfName, " (skip)");
      // Удаляем старые объекты
      ObjectDelete(0, objPrefix + "H");
      ObjectDelete(0, objPrefix + "M");
      ObjectDelete(0, objPrefix + "L");
      return;
   }
   
   // Рисуем линии пивотов
   if(pv.hasHigh) {
      string objName = objPrefix + "H";
      ObjectDelete(0, objName); // Удаляем старый объект
      ObjectCreate(0, objName, OBJ_HLINE, 0, 0, pv.high);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, hColor);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, lineWidth);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, lineStyle);
      ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   } else {
      ObjectDelete(0, objPrefix + "H");
   }
   
   if(pv.hasMid) {
      string objName = objPrefix + "M";
      ObjectDelete(0, objName); // Удаляем старый объект
      ObjectCreate(0, objName, OBJ_HLINE, 0, 0, pv.mid);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, mColor);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, lineWidth);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, lineStyle);
      ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   } else {
      ObjectDelete(0, objPrefix + "M");
   }
   
   if(pv.hasLow) {
      string objName = objPrefix + "L";
      ObjectDelete(0, objName); // Удаляем старый объект
      ObjectCreate(0, objName, OBJ_HLINE, 0, 0, pv.low);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, lColor);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, lineWidth);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, lineStyle);
      ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   } else {
      ObjectDelete(0, objPrefix + "L");
   }
}

void MFV_Draw_PivotsOverlay(const int tfIndex, const MFV_Pivots &pv)
{
   MFV_Draw_PivotsTF(tfIndex, pv, true);
}

void MFV_Draw_UpdateChart()
{
   ChartRedraw();
}

#endif // __MFV_DRAW_MQH__
