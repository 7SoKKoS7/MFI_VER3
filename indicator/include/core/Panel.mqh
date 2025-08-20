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
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,8);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
   }
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,Panel_FontSize);
   ObjectSetString (0,name,OBJPROP_FONT,"Tahoma");
   ObjectSetInteger(0,name,OBJPROP_COLOR,Panel_TextColor);
   ObjectSetString (0,name,OBJPROP_TEXT,text);
}

string MFV_PivotLine(const string tfName, const MFV_Pivots &pv){
   if(!(pv.hasHigh || pv.hasLow)) return "Pivot "+tfName+": (no data)";
   string h = pv.hasHigh ? DoubleToString(pv.high,_Digits) : "—";
   string m = pv.hasMid  ? DoubleToString(pv.mid, _Digits) : "—";
   string l = pv.hasLow  ? DoubleToString(pv.low, _Digits) : "—";
   return "Pivot "+tfName+": H="+h+" | M="+m+" | L="+l;
}

void MFV_Panel_DrawAll(const MFV_State &st, const bool showM5, const bool showM15, const bool showH1,
                       const bool showH4, const bool showD1){
   int row = 0;
   int y   = Panel_TopOffsetPx; // отступ вниз от шапки терминала
   MFV_Panel_PutRow(row++,"=== MFV Pivots ===", y);
   y += Panel_FontSize + Panel_LineSpacingPx;

   if(showM5)  { MFV_Panel_PutRow(row, MFV_PivotLine("M5",  st.piv[0]), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }
   if(showM15) { MFV_Panel_PutRow(row, MFV_PivotLine("M15", st.piv[1]), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }
   if(showH1)  { MFV_Panel_PutRow(row, MFV_PivotLine("H1",  st.piv[2]), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }
   if(showH4)  { MFV_Panel_PutRow(row, MFV_PivotLine("H4",  st.piv[3]), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }
   if(showD1)  { MFV_Panel_PutRow(row, MFV_PivotLine("D1",  st.piv[4]), y);  row++; y += Panel_FontSize + Panel_LineSpacingPx; }

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
   MFV_Panel_DrawAll(st, Panel_Show_M5, Panel_Show_M15, Panel_Show_H1, Panel_Show_H4, Panel_Show_D1);
}

#endif // __MFV_PANEL_MQH__
