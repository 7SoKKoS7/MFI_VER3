#ifndef __MFV_PANEL_MQH__
#define __MFV_PANEL_MQH__

#include "Config.mqh"
#include "Types.mqh"
#include "State.mqh"

string MFV_Panel_RowName(const int row){ return "MFV_PANEL_ROW_"+(string)row; }

void MFV_Panel_ClearUnused(const int used_rows){
   // Удаляем хвост старых строк, чтобы не оставались артефакты
   for(int r=used_rows; r<50; ++r){
      const string nm = MFV_Panel_RowName(r);
      if(ObjectFind(0,nm)>=0) ObjectDelete(0,nm);
   }
}

void MFV_Panel_PutRow(const int row, const string text, const int y){
   const string name = MFV_Panel_RowName(row);
   if(ObjectFind(0,name)<0){
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,5);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
   }
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,Panel_FontSize);
   ObjectSetString (0,name,OBJPROP_FONT,"Consolas"); // Force monospaced font
   ObjectSetInteger(0,name,OBJPROP_COLOR,Panel_TextColor);
   ObjectSetString (0,name,OBJPROP_TEXT,text);
}

// моноширинный шрифт уже есть (Consolas). Делаем унифицированные ярлыки:
string TF3[5] = { "M5 ", "M15", "H1 ", "H4 ", "D1 " }; // всегда 3 символа

string MFV_PivotLine(const string tf3, const MFV_Pivots &pv, const bool showMid){
   string m = (showMid && pv.hasMid) ? StringFormat(" | M=%.5f", pv.mid) : "";
   if(pv.hasHigh && pv.hasLow)
      return StringFormat("Pivot %s: H=%.5f%s | L=%.5f", tf3, pv.high, m, pv.low);
   return StringFormat("Pivot %s: (no data)", tf3);
}

// Legacy helper functions (kept for compatibility)
string MFV_ArrowTrend(MFV_Trend t) {
  if(t==MFV_Trend_Up)   return "↑";
  if(t==MFV_Trend_Down) return "↓";
  return "-";
}

string MFV_ArrowDirNow(MFV_DirNow d){
  if(d==MFV_DIRNOW_UP)   return "↑";
  if(d==MFV_DIRNOW_DOWN) return "↓";
  if(d==MFV_DIRNOW_NEUTRAL) return "=";
  return "?";
}

string MFV_ArrowBreakout(int dir) {
  if(dir > 0) return "↑";
  if(dir < 0) return "↓";
  return "-";
}

string MFV_ArrowRTest(MFV_RTest rt) {
  if(rt == MFV_RTEST_OK) return "✓";
  if(rt == MFV_RTEST_FAIL) return "✗";
  if(rt == MFV_RTEST_WAIT) return "…";
  return "?";
}

// Helper functions for fixed-width alignment
string PadRight(const string s, const int w) {
   string result = s;
   while(StringLen(result) < w) result += " ";
   return StringSubstr(result, 0, w); // ensure exact width
}

string Cell2_BO(const MFV_BreakoutInfo &bo) {
   if(!bo.hasBreak) return "- ";
   string a = (bo.dir>0) ? "↑" : "↓";
   if(bo.strength == BO_Strong) return a + "S";
   if(bo.strength == BO_Normal) return a + "N";
   return a + " ";
}

string Cell2_Trend(const MFV_TrendInfo &tr) {
   if(!tr.valid) return "? ";
   if(tr.trend == MFV_Trend_Up) return "↑ ";
   if(tr.trend == MFV_Trend_Down) return "↓ ";
   return "- "; // Flat
}

string Cell2_Now(const MFV_TrendInfo &tr) {
   if(!tr.valid) return "? ";
   if(tr.dirNow == MFV_DIRNOW_UP) return "↑ ";
   if(tr.dirNow == MFV_DIRNOW_DOWN) return "↓ ";
   if(tr.dirNow == MFV_DIRNOW_NEUTRAL) return "= ";
   return "? ";
}

string Cell2_RTest(const MFV_BreakoutInfo &bo) {
   if(!bo.hasBreak) return "- ";
   if(bo.rtest == MFV_RTEST_OK) return "✓ ";
   if(bo.rtest == MFV_RTEST_FAIL) return "✗ ";
   if(bo.rtest == MFV_RTEST_WAIT) return "… ";
   return "? ";
}

string Col(const string tf3, const string cell2) {
   return tf3 + " " + cell2; // "M5 " + " " + "↑S" = 6 chars total
}

void MFV_Panel_DrawAll(const MFV_State &st, bool showM5, bool showM15, bool showH1, bool showH4, bool showD1){
   int row = 0;
   int y   = Panel_TopOffsetPx; // отступ вниз от шапки терминала

   // 1) Сначала Trend и DirectionNow
   if(Panel_Show_Trend) {
      string trendLine = "Trend:  " + Col(TF3[0], Cell2_Trend(st.trends[0])) + " " + 
                                      Col(TF3[1], Cell2_Trend(st.trends[1])) + " " +
                                      Col(TF3[2], Cell2_Trend(st.trends[2])) + " " +
                                      Col(TF3[3], Cell2_Trend(st.trends[3])) + " " +
                                      Col(TF3[4], Cell2_Trend(st.trends[4]));
      MFV_Panel_PutRow(row++, trendLine, y);
      y += Panel_FontSize + Panel_LineSpacingPx;
   }
   
   if(Panel_Show_DirNow) {
      string dirNowLine = "Now:    " + Col(TF3[0], Cell2_Now(st.trends[0])) + " " + 
                                       Col(TF3[1], Cell2_Now(st.trends[1])) + " " +
                                       Col(TF3[2], Cell2_Now(st.trends[2])) + " " +
                                       Col(TF3[3], Cell2_Now(st.trends[3])) + " " +
                                       Col(TF3[4], Cell2_Now(st.trends[4]));
      MFV_Panel_PutRow(row++, dirNowLine, y);
      y += Panel_FontSize + Panel_LineSpacingPx;
   }

   // 2) Breakout и Retest
   if(Panel_ShowBreakout) {
      string breakoutLine = "BO:     " + Col(TF3[0], Cell2_BO(st.breakouts[0])) + " " + 
                                         Col(TF3[1], Cell2_BO(st.breakouts[1])) + " " +
                                         Col(TF3[2], Cell2_BO(st.breakouts[2])) + " " +
                                         Col(TF3[3], Cell2_BO(st.breakouts[3])) + " " +
                                         Col(TF3[4], Cell2_BO(st.breakouts[4]));
      MFV_Panel_PutRow(row++, breakoutLine, y);
      y += Panel_FontSize + Panel_LineSpacingPx;
   }

   if(Panel_ShowRTest) {
      string rtestLine = "RTest:  " + Col(TF3[0], Cell2_RTest(st.breakouts[0])) + " " + 
                                      Col(TF3[1], Cell2_RTest(st.breakouts[1])) + " " +
                                      Col(TF3[2], Cell2_RTest(st.breakouts[2])) + " " +
                                      Col(TF3[3], Cell2_RTest(st.breakouts[3])) + " " +
                                      Col(TF3[4], Cell2_RTest(st.breakouts[4]));
      MFV_Panel_PutRow(row++, rtestLine, y);
      y += Panel_FontSize + Panel_LineSpacingPx;
   }

   // 2) Потом Pivots
   MFV_Panel_PutRow(row++,"=== MFV Pivots ===", y);
   y += Panel_FontSize + Panel_LineSpacingPx;

   // Панель должна собирать все 5 строк по whitelist (M5, M15, H1, H4, D1) всегда
   if(showM5)  { MFV_Panel_PutRow(row, MFV_PivotLine(TF3[0], st.piv[0], Panel_ShowMid), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }
   if(showM15) { MFV_Panel_PutRow(row, MFV_PivotLine(TF3[1], st.piv[1], Panel_ShowMid), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }
   if(showH1)  { MFV_Panel_PutRow(row, MFV_PivotLine(TF3[2], st.piv[2], Panel_ShowMid), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }
   if(showH4)  { MFV_Panel_PutRow(row, MFV_PivotLine(TF3[3], st.piv[3], Panel_ShowMid), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }
   if(showD1)  { MFV_Panel_PutRow(row, MFV_PivotLine(TF3[4], st.piv[4], Panel_ShowMid), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }

   MFV_Panel_ClearUnused(row);
   ChartRedraw();
}

// вызывать на деинициализации индикатора
void MFV_Panel_Destroy(){
   MFV_Panel_ClearUnused(0);
}

// Совместимость со старым кодом
void MFV_Panel_Clear()
{
   MFV_Panel_Destroy();
}

void MFV_Panel_ShowPivots(const int tfIndex, const MFV_State &st)
{
   // Эта функция теперь не используется, заменена на MFV_Panel_DrawAll
}

void MFV_Panel_ShowAllPivots(const MFV_State &st)
{
   MFV_Panel_DrawAll(st, true, true, true, true, true);
}

#endif // __MFV_PANEL_MQH__
