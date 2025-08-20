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

void MFV_HLine(const string name, const double price, const int width, const ENUM_LINE_STYLE style, const color clr)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

void MFV_Draw_PivotsTF(const int tfIndex, const MFV_Pivots &pv, bool isOverlay)
{ 
   if(!ShowPivotsOnChart) return;
   
   // Определяем цвета и стили для текущего ТФ
   color hColor = PivotHColor;
   color mColor = PivotMColor;
   color lColor = PivotLColor;
   int lineWidth = PivotLineWidth;
   ENUM_LINE_STYLE lineStyle = PivotLineStyle;
   
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
   
   // Рисуем линии пивотов
   if(pv.hasHigh) {
      string objName = objPrefix + "H";
      MFV_HLine(objName, pv.high, lineWidth, lineStyle, hColor);
   } else {
      ObjectDelete(0, objPrefix + "H");
   }
   
   // для текущего ТФ Mid рисуется, когда Chart_ShowMid_CurrentTF == true и pv.hasMid == true
   if(pv.hasMid && Chart_ShowMid_CurrentTF) {
      string objName = objPrefix + "M";
      MFV_HLine(objName, pv.mid, lineWidth, lineStyle, mColor);
   } else {
      ObjectDelete(0, objPrefix + "M");
   }
   
   if(pv.hasLow) {
      string objName = objPrefix + "L";
      MFV_HLine(objName, pv.low, lineWidth, lineStyle, lColor);
   } else {
      ObjectDelete(0, objPrefix + "L");
   }
}

void MFV_Draw_PivotsOverlay(const int tfIndex, const MFV_Pivots &pv)
{
   if (!pv.hasHigh && !pv.hasLow && !pv.hasMid) return;
   string tf = (tfIndex==0?"M5":tfIndex==1?"M15":tfIndex==2?"H1":tfIndex==3?"H4":"D1");

   // H
   if (pv.hasHigh) {
      string n = StringFormat("MFV_PVT_OVR_%s_H", tf);
      MFV_HLine(n, pv.high, Overlay_LineWidth, Overlay_LineStyle, 
                (tfIndex==0?Overlay_M5_Color:tfIndex==1?Overlay_M15_Color:tfIndex==2?Overlay_H1_Color:tfIndex==3?Overlay_H4_Color:Overlay_D1_Color));
   } else ObjectDelete(0, StringFormat("MFV_PVT_OVR_%s_H", tf));

   // для оверлея Mid рисуется, когда Chart_ShowMid_Overlay == true, PivotsChart_ShowMulti == true, PivotsChart_TFOnly == false и pv.hasMid == true
   if (pv.hasMid && Chart_ShowMid_Overlay && PivotsChart_ShowMulti && !PivotsChart_TFOnly) {
      string n = StringFormat("MFV_PVT_OVR_%s_M", tf);
      MFV_HLine(n, pv.mid, Overlay_LineWidth, Overlay_LineStyle, Panel_TextColor);
   } else ObjectDelete(0, StringFormat("MFV_PVT_OVR_%s_M", tf));

   // L
   if (pv.hasLow) {
      string n = StringFormat("MFV_PVT_OVR_%s_L", tf);
      MFV_HLine(n, pv.low, Overlay_LineWidth, Overlay_LineStyle, 
                (tfIndex==0?Overlay_M5_Color:tfIndex==1?Overlay_M15_Color:tfIndex==2?Overlay_H1_Color:tfIndex==3?Overlay_H4_Color:Overlay_D1_Color));
   } else ObjectDelete(0, StringFormat("MFV_PVT_OVR_%s_L", tf));
}

void MFV_Draw_UpdateChart()
{
   ChartRedraw();
}

#endif // __MFV_DRAW_MQH__
