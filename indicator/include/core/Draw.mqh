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

void MFV_Draw_BreakoutMarkers(const int tfIndex, const MFV_BreakoutInfo &bo)
{
   // Если нет пробоя — удалить прежние объекты этого TF и выйти
   string tfName = (tfIndex==0?"M5":tfIndex==1?"M15":tfIndex==2?"H1":tfIndex==3?"H4":"D1");
   string prefix = "MFV_BO_" + Symbol() + "_" + tfName + "_";
   string nameArrow  = prefix + "AR";
   string nameStatus = prefix + "ST";

   if(!bo.hasBreak || bo.barTime==0 || bo.level==0.0){
      ObjectDelete(0, nameArrow);
      ObjectDelete(0, nameStatus);
      ObjectDelete(0, prefix + "STR"); // удаляем индикатор силы
      return;
   }

   // 1) Стрелка — OBJ_TEXT в координатах (время пробоя, уровень пробоя)
   if(ObjectFind(0, nameArrow) < 0)
      ObjectCreate(0, nameArrow, OBJ_TEXT, 0, bo.barTime, bo.level);
   else
      ObjectMove(0, nameArrow, 0, bo.barTime, bo.level);

   const string ch = (bo.dir>0 ? "↑" : "↓"); // компактная стрелка
   ObjectSetString (0, nameArrow,  OBJPROP_TEXT,      ch);
   ObjectSetInteger(0, nameArrow,  OBJPROP_FONTSIZE,  BO_ArrowFontSize);
   ObjectSetInteger(0, nameArrow,  OBJPROP_COLOR,     (bo.dir>0?BO_ArrowColorUp:BO_ArrowColorDn));
   ObjectSetInteger(0, nameArrow,  OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, nameArrow,  OBJPROP_BACK,      false);
   ObjectSetInteger(0, nameArrow,  OBJPROP_ANCHOR,    ANCHOR_CENTER);

   // 1.5) Индикатор силы — маленький текст рядом со стрелкой
   string nameStrength = prefix + "STR";
   string strengthText = "";
   if(bo.strength == BO_Strong) strengthText = "S";
   else if(bo.strength == BO_Normal) strengthText = "N";
   
   if(strengthText != "") {
      if(ObjectFind(0, nameStrength) < 0)
         ObjectCreate(0, nameStrength, OBJ_TEXT, 0, bo.barTime, bo.level);
      else
         ObjectMove(0, nameStrength, 0, bo.barTime, bo.level);
      
      ObjectSetString (0, nameStrength, OBJPROP_TEXT,      strengthText);
      ObjectSetInteger(0, nameStrength, OBJPROP_FONTSIZE,  MathMax(6, BO_ArrowFontSize-2));
      ObjectSetInteger(0, nameStrength, OBJPROP_COLOR,     (bo.dir>0?BO_ArrowColorUp:BO_ArrowColorDn));
      ObjectSetInteger(0, nameStrength, OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0, nameStrength, OBJPROP_BACK,      false);
      ObjectSetInteger(0, nameStrength, OBJPROP_ANCHOR,    ANCHOR_LEFT_UPPER);
   } else {
      ObjectDelete(0, nameStrength);
   }

   // 2) Статус ретеста — компактный символ рядом, со смещением по цене
   //    WAIT: …   OK: ✓   FAIL: ✗   NONE: — (тайм-аут без ретеста)
   double yOff = (BO_StatusYOffsetPoints>0 ? BO_StatusYOffsetPoints*Point() : 0);
   double y    = bo.level + (bo.dir>0 ? +yOff : -yOff);

   if(ObjectFind(0, nameStatus) < 0)
      ObjectCreate(0, nameStatus, OBJ_TEXT, 0, bo.barTime, y);
   else
      ObjectMove(0, nameStatus, 0, bo.barTime, y);

   string st;
   color  sc;
   switch(bo.rtest){
      case MFV_RTEST_OK:   st="✓"; sc=BO_StatusColorOK;   break;
      case MFV_RTEST_FAIL: st="✗"; sc=BO_StatusColorFAIL; break;
      case MFV_RTEST_WAIT: st="…"; sc=BO_StatusColorWAIT; break;
      case (MFV_RTest)(-1): st="—"; sc=BO_StatusColorNONE; break; // тайм-аут
      default:             st="?"; sc=BO_StatusColorNONE; break; // неизвестный статус
   }
   ObjectSetString (0, nameStatus, OBJPROP_TEXT,      st);
   ObjectSetInteger(0, nameStatus, OBJPROP_FONTSIZE,  MathMax(8, BO_ArrowFontSize-1));
   ObjectSetInteger(0, nameStatus, OBJPROP_COLOR,     sc);
   ObjectSetInteger(0, nameStatus, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, nameStatus, OBJPROP_BACK,      false);
   ObjectSetInteger(0, nameStatus, OBJPROP_ANCHOR,    ANCHOR_CENTER);
}

void MFV_Draw_ClearBreakoutMarkers(const string prefix)
{
   // Удалить все объекты Breakout с именами, начинающимися с prefix
   for(int i = ObjectsTotal(0, 0, OBJ_TEXT) - 1; i >= 0; --i) {
      string objName = ObjectName(0, i, 0, OBJ_TEXT);
      if(StringFind(objName, prefix) == 0) {
         ObjectDelete(0, objName);
      }
   }
}

#endif // __MFV_DRAW_MQH__
