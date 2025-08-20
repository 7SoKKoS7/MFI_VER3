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
   ObjectSetString (0,name,OBJPROP_FONT,Panel_FontName);
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

void MFV_Panel_DrawAll(const MFV_State &st, bool showM5, bool showM15, bool showH1, bool showH4, bool showD1){
   int row = 0;
   int y   = Panel_TopOffsetPx; // отступ вниз от шапки терминала
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
