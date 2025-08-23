#ifndef __MFV_DRAW_MQH__
#define __MFV_DRAW_MQH__

// === HELPER FUNCTIONS ===

// безопасные секунды периода
int PSafe(ENUM_TIMEFRAMES tf){
   int ps = PeriodSeconds(tf);
   if(ps>0) return ps;
   switch(tf){
      case PERIOD_M5:  return 300;
      case PERIOD_M15: return 900;
      case PERIOD_H1:  return 3600;
      case PERIOD_H4:  return 14400;
      case PERIOD_D1:  return 86400;
      default:         return 60;
   }
}

// получить код TF для имен объектов
string TFCode(ENUM_TIMEFRAMES tf){
   switch(tf){
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      default:         return IntegerToString((int)tf);
   }
}

// === TOOLTIP UTILITIES ===

// форматирование цены
string MFV_FmtPrice(double p, int digits) {
   return DoubleToString(NormalizeDouble(p, digits), digits);
}

// установка tooltip
void MFV_SetTooltip(const string name, const string tip) {
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tip);
}

// tooltip для пивотов
string MFV_Tip_Pivot(ENUM_TIMEFRAMES tf, char kind, double price, bool overlay) {
   string kindStr = (kind=='H' ? "High" : kind=='M' ? "Mid" : "Low");
   string overlayStr = (overlay ? " (overlay)" : "");
   return "Pivot " + TFCode(tf) + " — " + kindStr + overlayStr + " | " + MFV_FmtPrice(price, _Digits);
}

// tooltip для пробоев
string MFV_Tip_Breakout(const MFV_BreakoutInfo &bo, ENUM_TIMEFRAMES tf, int digits) {
   string arrow = (bo.dir > 0 ? "↑" : "↓");
   string strength = (bo.strength == BO_Strong ? "STR" : "NRM");
   string tolPips = DoubleToString(bo.tolUsed/_Point, 1);
   return "Breakout " + TFCode(tf) + " " + arrow + " " + strength + " | " + 
          MFV_FmtPrice(bo.level, digits) + " | bars=" + IntegerToString(bo.barsSinceBO) + 
          " | tol=" + tolPips;
}

// tooltip для зон ретеста
string MFV_Tip_Retest(const MFV_BreakoutInfo &bo, ENUM_TIMEFRAMES tf, int digits) {
   if(bo.rtest == MFV_RTEST_WAIT) {
      string direction = (bo.dir > 0 ? "↓" : "↑"); // противоположно пробою
      string tolPips = DoubleToString(bo.tolUsed/_Point, 1);
      int remainingBars = RTest_MaxBars - bo.barsSinceBO;
      return "Retest zone " + TFCode(tf) + " " + direction + " (waiting) | " + 
             MFV_FmtPrice(bo.level, digits) + " ± " + tolPips + " | expires in " + 
             IntegerToString(remainingBars) + " bars";
   } else {
      return "Retest zone " + TFCode(tf) + " — done @ " + 
             TimeToString(bo.barTime, TIME_DATE|TIME_MINUTES);
   }
}

// получить цвет для TF (для призраков)
color TFColor(ENUM_TIMEFRAMES tf){
   switch(tf){
      case PERIOD_M5:  return RTest_TFColor_M5;
      case PERIOD_M15: return RTest_TFColor_M15;
      case PERIOD_H1:  return RTest_TFColor_H1;
      case PERIOD_H4:  return RTest_TFColor_H4;
      case PERIOD_D1:  return RTest_TFColor_D1;
      default:         return RTest_TFColor_H1;
   }
}

// получить родительский TF
ENUM_TIMEFRAMES ParentTF(ENUM_TIMEFRAMES tf){
   switch(tf){
      case PERIOD_M5:  return PERIOD_M15;
      case PERIOD_M15: return PERIOD_H1;
      case PERIOD_H1:  return PERIOD_H4;
      case PERIOD_H4:  return PERIOD_D1;
      case PERIOD_D1:  return PERIOD_D1; // D1 - самый старший
      default:         return tf;
   }
}

// проверка вложенности зон
bool ZoneInsideSameDir(const MFV_BreakoutInfo &a, ENUM_TIMEFRAMES tfa,
                       const MFV_BreakoutInfo &b, ENUM_TIMEFRAMES tfb){
   if(tfa==tfb) return false;
   if(!a.hasBreak || !b.hasBreak) return false;
   if(a.dir!=b.dir) return false;
   
   // Вычисляем границы зон
   double aTop, aBot, bTop, bBot;
   
   // Зона A
   double tolA = (RTest_ZoneK>0 ? a.tolUsed*RTest_ZoneK : (RTest_ZonePts>0 ? RTest_ZonePts*_Point : a.tolUsed));
   if(a.dir>0){ aTop=a.level; aBot=a.level - tolA; }
   else       { aTop=a.level + tolA; aBot=a.level; }
   if(aTop<aBot){ double t=aTop; aTop=aBot; aBot=t; }
   
   // Зона B
   double tolB = (RTest_ZoneK>0 ? b.tolUsed*RTest_ZoneK : (RTest_ZonePts>0 ? RTest_ZonePts*_Point : b.tolUsed));
   if(b.dir>0){ bTop=b.level; bBot=b.level - tolB; }
   else       { bTop=b.level + tolB; bBot=b.level; }
   if(bTop<bBot){ double t=bTop; bTop=bBot; bBot=t; }
   
   // Родитель должен быть заметно выше: иначе не считаем «вложенностью»
   if( (bTop-bBot) <= (aTop-aBot)*1.02 ) return false;
   return (aTop<=bTop && aBot>=bBot);
}

// проверка вложенности в любой родительский TF
bool InsideAnyParentSameDir(ENUM_TIMEFRAMES zone_tf, const MFV_BreakoutInfo &zone_bo, const MFV_State &st){
   ENUM_TIMEFRAMES WL[] = {PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1};
   int zoneIndex = -1;
   for(int i = 0; i < 5; i++) {
      if(WL[i] == zone_tf) { zoneIndex = i; break; }
   }
   if(zoneIndex == -1) return false;
   
   // Проверяем все старшие TF
   for(int i = zoneIndex + 1; i < 5; i++) {
      if(st.breakouts[i].hasBreak && st.breakouts[i].rtest == MFV_RTEST_WAIT) {
         if(ZoneInsideSameDir(zone_bo, zone_tf, st.breakouts[i], WL[i])) {
            return true;
         }
      }
   }
   return false;
}

// === CLEAR FUNCTIONS ===

void MFV_Draw_ClearAll(const string prefix)
{
   // Удалить все объекты с именами, начинающимися с prefix
   for(int i = ObjectsTotal(0, 0, OBJ_HLINE) - 1; i >= 0; --i) {
      string objName = ObjectName(0, i, 0, OBJ_HLINE);
      if(StringFind(objName, prefix) == 0) {
         ObjectDelete(0, objName);
      }
   }
   
   // Удалить все прямоугольники и ярлыки зон ретеста
   for(int i = ObjectsTotal(0, 0, OBJ_RECTANGLE) - 1; i >= 0; --i) {
      string objName = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if(StringFind(objName, prefix) == 0 && StringFind(objName, "ZRECT_") >= 0) {
         ObjectDelete(0, objName);
      }
   }
   for(int i = ObjectsTotal(0, 0, OBJ_TEXT) - 1; i >= 0; --i) {
      string objName = ObjectName(0, i, 0, OBJ_TEXT);
      if(StringFind(objName, prefix) == 0 && StringFind(objName, "ZLBL_") >= 0) {
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
      MFV_SetTooltip(objName, MFV_Tip_Pivot((ENUM_TIMEFRAMES)(tfIndex==0?PERIOD_M5:tfIndex==1?PERIOD_M15:tfIndex==2?PERIOD_H1:tfIndex==3?PERIOD_H4:PERIOD_D1), 'H', pv.high, false));
   } else {
      ObjectDelete(0, objPrefix + "H");
   }
   
   // для текущего ТФ Mid рисуется, когда Chart_ShowMid_CurrentTF == true и pv.hasMid == true
   if(pv.hasMid && Chart_ShowMid_CurrentTF) {
      string objName = objPrefix + "M";
      MFV_HLine(objName, pv.mid, lineWidth, lineStyle, mColor);
      MFV_SetTooltip(objName, MFV_Tip_Pivot((ENUM_TIMEFRAMES)(tfIndex==0?PERIOD_M5:tfIndex==1?PERIOD_M15:tfIndex==2?PERIOD_H1:tfIndex==3?PERIOD_H4:PERIOD_D1), 'M', pv.mid, false));
   } else {
      ObjectDelete(0, objPrefix + "M");
   }
   
   if(pv.hasLow) {
      string objName = objPrefix + "L";
      MFV_HLine(objName, pv.low, lineWidth, lineStyle, lColor);
      MFV_SetTooltip(objName, MFV_Tip_Pivot((ENUM_TIMEFRAMES)(tfIndex==0?PERIOD_M5:tfIndex==1?PERIOD_M15:tfIndex==2?PERIOD_H1:tfIndex==3?PERIOD_H4:PERIOD_D1), 'L', pv.low, false));
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
      MFV_SetTooltip(n, MFV_Tip_Pivot((ENUM_TIMEFRAMES)(tfIndex==0?PERIOD_M5:tfIndex==1?PERIOD_M15:tfIndex==2?PERIOD_H1:tfIndex==3?PERIOD_H4:PERIOD_D1), 'H', pv.high, true));
   } else ObjectDelete(0, StringFormat("MFV_PVT_OVR_%s_H", tf));

   // для оверлея Mid рисуется, когда Chart_ShowMid_Overlay == true, PivotsChart_ShowMulti == true, PivotsChart_TFOnly == false и pv.hasMid == true
   if (pv.hasMid && Chart_ShowMid_Overlay && PivotsChart_ShowMulti && !PivotsChart_TFOnly) {
      string n = StringFormat("MFV_PVT_OVR_%s_M", tf);
      MFV_HLine(n, pv.mid, Overlay_LineWidth, Overlay_LineStyle, Panel_TextColor);
      MFV_SetTooltip(n, MFV_Tip_Pivot((ENUM_TIMEFRAMES)(tfIndex==0?PERIOD_M5:tfIndex==1?PERIOD_M15:tfIndex==2?PERIOD_H1:tfIndex==3?PERIOD_H4:PERIOD_D1), 'M', pv.mid, true));
   } else ObjectDelete(0, StringFormat("MFV_PVT_OVR_%s_M", tf));

   // L
   if (pv.hasLow) {
      string n = StringFormat("MFV_PVT_OVR_%s_L", tf);
      MFV_HLine(n, pv.low, Overlay_LineWidth, Overlay_LineStyle, 
                (tfIndex==0?Overlay_M5_Color:tfIndex==1?Overlay_M15_Color:tfIndex==2?Overlay_H1_Color:tfIndex==3?Overlay_H4_Color:Overlay_D1_Color));
      MFV_SetTooltip(n, MFV_Tip_Pivot((ENUM_TIMEFRAMES)(tfIndex==0?PERIOD_M5:tfIndex==1?PERIOD_M15:tfIndex==2?PERIOD_H1:tfIndex==3?PERIOD_H4:PERIOD_D1), 'L', pv.low, true));
   } else ObjectDelete(0, StringFormat("MFV_PVT_OVR_%s_L", tf));
}

void MFV_Draw_UpdateChart()
{
   ChartRedraw();
}

// === RETEST ZONE DRAWING ===

// единая функция отрисовки зоны ретеста
void MFV_Draw_RetestZone(const string prefix, const string symbol, 
                        const ENUM_TIMEFRAMES chart_tf, const ENUM_TIMEFRAMES zone_tf,
                        const MFV_BreakoutInfo &bo, const MFV_State &st)
{
   // Если !bo.hasBreak ИЛИ (bo.rtest!=MFV_RTEST_WAIT) → удалить nameRect и nameLbl, return
   if(!bo.hasBreak || bo.rtest != MFV_RTEST_WAIT) {
      string nameRect = prefix + "ZRECT_" + TFCode(zone_tf);
      string nameLbl = prefix + "ZLBL_" + TFCode(zone_tf);
      ObjectDelete(0, nameRect);
      ObjectDelete(0, nameLbl);
      return;
   }

   // one-sided height
   double tol = (RTest_ZoneK>0 ? bo.tolUsed*RTest_ZoneK
                               : (RTest_ZonePts>0 ? RTest_ZonePts*_Point : bo.tolUsed));
   double yTop, yBot;
   if(bo.dir>0){ yTop=bo.level; yBot=bo.level - tol; }
   else        { yTop=bo.level + tol; yBot=bo.level; }
   if(yTop<yBot) { double t=yTop; yTop=yBot; yBot=t; }

   // time span per ZONE TF
   datetime t1=bo.barTime;
   int ps=PSafe(zone_tf);
   datetime t2=(datetime)((long)t1 + (long)RTest_MaxBars*(long)ps);
   if(t2<=t1) t2=(datetime)((long)t1 + (long)ps);

   // overlay policy
   bool drawFilled = (zone_tf==chart_tf);
   bool drawGhost  = (zone_tf!=chart_tf) &&
                     (RTest_OverlayMode==RTest_AllGhosted ||
                      (RTest_OverlayMode==RTest_CurrentPlusParent && zone_tf==ParentTF(chart_tf)));

   // collapse only for ghosts
   if(drawGhost && RTest_CollapseNested){
      if(InsideAnyParentSameDir(zone_tf, bo, st)) {
         drawGhost = false;
      }
   }

   // Имена объектов С УЧЁТОМ TF ЗОНЫ
   string nameRect = prefix + "ZRECT_" + TFCode(zone_tf);
   string nameLbl = prefix + "ZLBL_" + TFCode(zone_tf);

   // Создаем/обновляем прямоугольник
   if(ObjectFind(0, nameRect) < 0)
      ObjectCreate(0, nameRect, OBJ_RECTANGLE, 0, t1, yTop, t2, yBot);
   else {
      ObjectMove(0, nameRect, 0, t1, yTop);
      ObjectMove(0, nameRect, 1, t2, yBot);
   }

   if(drawFilled){
      // Заливка: OBJ_RECTANGLE, FILL=true, BACK=false, COLOR = ARGB(dirUp?RTest_RectColorUp:RTest_RectColorDn, RTest_RectAlpha), WIDTH=RTest_RectBorderW
      ObjectSetInteger(0, nameRect, OBJPROP_FILL, true);
      ObjectSetInteger(0, nameRect, OBJPROP_BACK, false);
      ObjectSetInteger(0, nameRect, OBJPROP_COLOR, (color)ColorToARGB(
         bo.dir > 0 ? RTest_RectColorUp : RTest_RectColorDn, (uchar)RTest_RectAlpha));
      ObjectSetInteger(0, nameRect, OBJPROP_WIDTH, RTest_RectBorderW);
      ObjectSetInteger(0, nameRect, OBJPROP_STYLE, RTest_RectBorderStyle);
      ObjectSetInteger(0, nameRect, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nameRect, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, nameRect, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      
      // ADDED: Tooltip for retest zone
      MFV_SetTooltip(nameRect, MFV_Tip_Retest(bo, zone_tf, _Digits));
      
      // Удаляем ярлык для основной зоны
      ObjectDelete(0, nameLbl);
   }else if(drawGhost){
      // Призрак: OBJ_RECTANGLE, FILL=false, BACK=true, COLOR = ARGB(TFColor(zone_tf), RTest_GhostAlpha), WIDTH=1, STYLE=STYLE_DOT
      ObjectSetInteger(0, nameRect, OBJPROP_FILL, false);
      ObjectSetInteger(0, nameRect, OBJPROP_BACK, true);
      ObjectSetInteger(0, nameRect, OBJPROP_COLOR, (color)ColorToARGB(TFColor(zone_tf), (uchar)RTest_GhostAlpha));
      ObjectSetInteger(0, nameRect, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, nameRect, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, nameRect, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nameRect, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, nameRect, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      
      // ADDED: Tooltip for ghost retest zone
      MFV_SetTooltip(nameRect, MFV_Tip_Retest(bo, zone_tf, _Digits));
      
      // Добавить ярлык: OBJ_TEXT nameLbl в точке (t2, yTop), TEXT=TFCode(zone_tf), FONTSIZE>=10, COLOR=TFColor(zone_tf), ANCHOR=ANCHOR_LEFT_UPPER, BACK=true, SELECTABLE=false
      if(ObjectFind(0, nameLbl) < 0)
         ObjectCreate(0, nameLbl, OBJ_TEXT, 0, t2, yTop);
      else
         ObjectMove(0, nameLbl, 0, t2, yTop);
      
      ObjectSetString(0, nameLbl, OBJPROP_TEXT, TFCode(zone_tf));
      ObjectSetInteger(0, nameLbl, OBJPROP_FONTSIZE, MathMax(10, BO_ArrowFontSize));
      ObjectSetInteger(0, nameLbl, OBJPROP_COLOR, TFColor(zone_tf));
      ObjectSetInteger(0, nameLbl, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, nameLbl, OBJPROP_BACK, true);
      ObjectSetInteger(0, nameLbl, OBJPROP_SELECTABLE, false);
   }else{
      // Не рисуем ничего, удаляем объекты
      ObjectDelete(0, nameRect);
      ObjectDelete(0, nameLbl);
   }

   // ЛОГ
   if(Debug_Log) {
      PrintFormat("ZRECT tf=%s chart=%s dir=%d filled=%d ghost=%d t1=%I64d t2=%I64d yTop=%.5f yBot=%.5f",
         TFCode(zone_tf), TFCode(chart_tf), bo.dir, (int)drawFilled, (int)drawGhost,
         (long)t1, (long)t2, yTop, yBot);
   }
}

// рисуем все зоны ретеста с учетом режима наложения
void MFV_Draw_AllRetestZones(const MFV_State &st, const string symbol, const ENUM_TIMEFRAMES chart_tf)
{
   if(!RTest_DrawZoneRect) return;

   // Whitelist TF array
   ENUM_TIMEFRAMES WL[] = {PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1};
   
   // Внутри Draw-оркестратора пробегать WL {M5,M15,H1,H4,D1} и вызывать MFV_Draw_RetestZone
   for(int i = 0; i < 5; i++) {
      string prefix = "MFV_BO_" + symbol + "_" + TFCode(WL[i]) + "_";
      // chart_tf — это именно таймфрейм окна, а не WL[i]
      MFV_Draw_RetestZone(prefix, symbol, chart_tf, WL[i], st.breakouts[i], st);
   }
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
      // Удаляем зоны ретеста (теперь обрабатываются централизованно)
      string tfName = (tfIndex==0?"M5":tfIndex==1?"M15":tfIndex==2?"H1":tfIndex==3?"H4":"D1");
      ObjectDelete(0, prefix + "ZRECT_" + tfName);
      ObjectDelete(0, prefix + "ZLBL_" + tfName);
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
   
   // ADDED: Tooltip for breakout arrow
   MFV_SetTooltip(nameArrow, MFV_Tip_Breakout(bo, (ENUM_TIMEFRAMES)(tfIndex==0?PERIOD_M5:tfIndex==1?PERIOD_M15:tfIndex==2?PERIOD_H1:tfIndex==3?PERIOD_H4:PERIOD_D1), _Digits));

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

// === RETEST BOX DRAWING ===

// Удаление зоны ретеста для TF
void MFV_Delete_RetestBox(ENUM_TIMEFRAMES tf) {
   ObjectDelete(0, "MFV_RTB_" + TFCode(tf));
}

// Форматирование пипсов с улучшенной точностью
string MFV_FmtPips(double tol) {
   double pips = tol/_Point;
   if(pips < 0.1) {
      return DoubleToString(pips, 2) + " (~" + DoubleToString(tol, _Digits) + ")";
   } else if(pips < 1.0) {
      return DoubleToString(pips, 1) + " (~" + DoubleToString(tol, _Digits) + ")";
   } else {
      return DoubleToString(pips, 1);
   }
}

// Рисует/обновляет/удаляет зону ретеста для ТЕКУЩЕГО chart_tf
void MFV_Draw_RetestBox(MFV_State &st, const string symbol, ENUM_TIMEFRAMES chart_tf)
{
   // Определить индекс по whitelist {M5,M15,H1,H4,D1} для chart_tf
   int tfIndex = -1;
   switch(chart_tf) {
      case PERIOD_M5:  tfIndex = 0; break;
      case PERIOD_M15: tfIndex = 1; break;
      case PERIOD_H1:  tfIndex = 2; break;
      case PERIOD_H4:  tfIndex = 3; break;
      case PERIOD_D1:  tfIndex = 4; break;
      default: return; // Не из whitelist
   }
   
   MFV_BreakoutInfo bo = st.breakouts[tfIndex];
   
   // Guard-условия
   if(!bo.hasBreak) {
      MFV_Delete_RetestBox(chart_tf);
      return;
   }
   
   if(bo.rtest != MFV_RTEST_WAIT || bo.barsSinceBO > RTest_MaxBars) {
      MFV_Delete_RetestBox(chart_tf);
      return;
   }
   
   // Геометрия прямоугольника
   double top, bottom;
   if(bo.dir == 1) { // пробой ↑
      top = bo.level;
      bottom = bo.level - bo.tolUsed;
   } else { // пробой ↓
      bottom = bo.level;
      top = bo.level + bo.tolUsed;
   }
   
   datetime left = bo.barTime;
   datetime right = left + (datetime)(RTest_MaxBars * PeriodSeconds(chart_tf));
   
   // Визуальный минимум высоты
   double price_per_px = (ChartGetDouble(0, CHART_PRICE_MAX) - ChartGetDouble(0, CHART_PRICE_MIN)) / 
                        (double)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   double min_price = price_per_px * RTest_DrawMinPx;
   
   if((top - bottom) < min_price) {
      double expand = (min_price - (top - bottom)) / 2.0;
      if(bo.dir == 1) { // пробой ↑, расширяем вниз
         bottom -= expand;
      } else { // пробой ↓, расширяем вверх
         top += expand;
      }
   }
   
   // Создать/обновить прямоугольник
   string objName = "MFV_RTB_" + TFCode(chart_tf);
   
   if(ObjectFind(0, objName) < 0) {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, left, top, right, bottom);
   } else {
      ObjectMove(0, objName, 0, left, top);
      ObjectMove(0, objName, 1, right, bottom);
   }
   
   // Настройки прямоугольника
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, RTest_RectBack);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, (color)ColorToARGB(
      bo.dir > 0 ? RTest_RectColorUp : RTest_RectColorDn, (uchar)RTest_RectAlpha));
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, RTest_RectBorderW);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, RTest_RectBorderStyle);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, objName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   
   // Tooltip
   string direction = (bo.dir > 0 ? "↓" : "↑");
   string tooltip = "Retest zone " + TFCode(chart_tf) + " " + direction + 
                   " | level=" + MFV_FmtPrice(bo.level, _Digits) + 
                   " tol=" + MFV_FmtPips(bo.tolUsed) + 
                   " | left=" + IntegerToString(RTest_MaxBars - bo.barsSinceBO) + " bars";
   ObjectSetString(0, objName, OBJPROP_TOOLTIP, tooltip);
}

#endif // __MFV_DRAW_MQH__
