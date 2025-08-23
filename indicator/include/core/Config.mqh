#ifndef __MFV_CONFIG_MQH__
#define __MFV_CONFIG_MQH__

input bool UseRussian = true;
input int  AtrPeriodH1 = 14;

// === ZigZag (MF Preset) ===
input bool ZZ_UseMF_Preset = true;  // true: использовать пресет MF по ТФ

// Рекомендуемые MF-настройки (можно менять из свойств индикатора)
input int ZZ_MF_M5_Depth      = 12;
input int ZZ_MF_M5_Deviation  = 5;
input int ZZ_MF_M5_Backstep   = 3;

input int ZZ_MF_M15_Depth     = 12;
input int ZZ_MF_M15_Deviation = 5;
input int ZZ_MF_M15_Backstep  = 3;

input int ZZ_MF_H1_Depth      = 24;
input int ZZ_MF_H1_Deviation  = 5;
input int ZZ_MF_H1_Backstep   = 3;

input int ZZ_MF_H4_Depth      = 48;
input int ZZ_MF_H4_Deviation  = 5;
input int ZZ_MF_H4_Backstep   = 3;

input int ZZ_MF_D1_Depth      = 60;
input int ZZ_MF_D1_Deviation  = 5;
input int ZZ_MF_D1_Backstep   = 3;

// Ручной режим (если ZZ_UseMF_Preset=false)
input int ZZ_Manual_Depth     = 12;
input int ZZ_Manual_Deviation = 5;
input int ZZ_Manual_Backstep  = 3;

// === Trend & Direction (panel) ===
input bool   Panel_Show_Trend   = true;
input bool   Panel_Show_DirNow  = true;

// Параметры допусков
input int    Trend_TolPoints    = 0;     // минимальный допуск в пунктах
input double Trend_TolATRk      = 0.25;  // k для k*ATR(14)
input double DirNow_EpsPct      = 0.10;  // dead-zone как доля (H-L)

// === Breakout & Retest (panel) ===
input bool   Panel_ShowBreakout = true;  // показывать строку Breakout
input bool   Panel_ShowRTest    = true;  // показывать строку Retest
input int    RTest_MaxBars      = 10;    // максимальное количество баров для ретеста

// === Breakout bootstrap from history ===
input bool BO_BootstrapFromHistory = true;   // искать последний реальный пробой в истории
input int  BO_BootstrapLookback    = 300;    // сколько закрытых баров просканировать
input bool BO_BootstrapOnlyRecent  = true;   // только недавние пробои (по MaxAgeHours)

// Максимальный возраст пробоя для bootstrap (в часах)
input int BO_BootstrapMaxAgeHours_M5  = 6;   // 6 часов для M5
input int BO_BootstrapMaxAgeHours_M15 = 12;  // 12 часов для M15
input int BO_BootstrapMaxAgeHours_H1  = 48;  // 48 часов для H1
input int BO_BootstrapMaxAgeHours_H4  = 168; // 168 часов (7 дней) для H4
input int BO_BootstrapMaxAgeHours_D1  = 720; // 720 часов (30 дней) для D1

// === Breakout markers look & feel ===
input int   BO_ArrowFontSize      = 10;  // размер стрелки пробоя (OBJ_TEXT), по умолчанию меньше
input color BO_ArrowColorUp       = clrLime;
input color BO_ArrowColorDn       = clrRed;
input int   BO_StatusYOffsetPoints= 10;  // смещение статуса ретеста по цене (в пунктах) от уровня пробоя
input color BO_StatusColorOK      = clrLime;
input color BO_StatusColorFAIL    = clrRed;
input color BO_StatusColorWAIT    = clrSilver;
input color BO_StatusColorNONE    = clrDarkGray; // "—" нет ретеста по тайм-ауту

// === Breakout Strength & Confirmation ===
enum ConfirmMode { Confirm_Off, Confirm_StrongOnly, Confirm_StrongAndNormal, Confirm_All };
input ConfirmMode BO_ConfirmMode = Confirm_StrongAndNormal;  // режим подтверждения пробоев
input double BO_StrongTolK = 2.0;    // множитель толеранса для сильного пробоя
input double BO_StrongATRK = 0.50;   // множитель ATR для сильного пробоя

// === Retest Zone Drawing ===
input double RTest_ZoneK = 1.0;         // множитель к tolUsed для высоты зоны
input int    RTest_ZonePts = 0;         // фикс. высота в пунктах, если ZoneK==0

// === Retest Zone Rectangle ===
input bool   RTest_DrawZoneRect   = true;   // рисовать зону ретеста как прямоугольник
input color  RTest_RectColorUp    = clrDodgerBlue;  // цвет для пробоя вверх
input color  RTest_RectColorDn    = clrTomato;      // цвет для пробоя вниз
input int    RTest_RectAlpha      = 35;     // прозрачность 0..255
input bool   RTest_RectBack       = true;   // рисовать за графиком
input int    RTest_RectBorderW    = 1;      // ширина границы
input int    RTest_RectBorderStyle= STYLE_DOT; // стиль границы

// === Multi-TF Retest Zone Overlay ===
enum RTestOverlayMode { RTest_CurrentOnly, RTest_CurrentPlusParent, RTest_AllGhosted };
input RTestOverlayMode RTest_OverlayMode = RTest_CurrentPlusParent;  // режим наложения зон ретеста
input bool  RTest_CollapseNested = true;     // скрывать зону младшего TF, если она полностью внутри старшего и того же направления
input int   RTest_GhostAlpha     = 20;       // альфа «призраков»

// Цвета контуров по TF (для призраков)
input color RTest_TFColor_M5  = clrDeepSkyBlue;
input color RTest_TFColor_M15 = clrMediumPurple;
input color RTest_TFColor_H1  = clrLimeGreen;
input color RTest_TFColor_H4  = clrOrange;
input color RTest_TFColor_D1  = clrTomato;

// === Panel look & feel ===
input string Panel_FontName    = "Consolas";    // моноширинный для ровных колонок
input int   Panel_FontSize      = 11;        // 8..28
input color Panel_TextColor     = clrWhite;
input int   Panel_TopOffsetPx   = 26;        // от бордюра терминала
input int   Panel_LineSpacingPx = 4;         // доп. межстрочный интервал
input bool  Panel_ShowMid       = true;      // показывать M=... в строках панели
input bool  Panel_ShowEarly     = false;     // eH/eL для текущего ТФ (опц.)

// === Chart drawing ===
input bool  ShowPivotsOnChart        = true;
input bool  PivotsChart_TFOnly       = true;   // только текущий ТФ
input bool  PivotsChart_ShowMulti    = false;  // overlay всех WL-ТФ
input bool  Chart_ShowMid_CurrentTF  = true;   // Mid для текущего ТФ
input bool  Chart_ShowMid_Overlay    = false;  // Mid для overlay

// Цвета текущего TF
input color PivotHColor = clrRed;
input color PivotMColor = clrDarkGray;
input color PivotLColor = clrLime;
input int   PivotLineWidth = 1;
input ENUM_LINE_STYLE PivotLineStyle = STYLE_DASHDOT;

// Цвета оверлея (если PivotsChart_ShowMulti=true)
input color Overlay_M5_Color  = clrDodgerBlue;
input color Overlay_M15_Color = clrDeepPink;
input color Overlay_H1_Color  = clrOrange;
input color Overlay_H4_Color  = clrMediumSeaGreen;
input color Overlay_D1_Color  = clrViolet;
input int   Overlay_LineWidth  = 1;
input ENUM_LINE_STYLE Overlay_LineStyle = STYLE_DOT;

// === Early pivot (только текущий TF) ===
input bool  EP_Enable          = false;
input bool  EP_OnCurrentTFOnly = true;    // зафиксировать «только текущий ТФ»
input int   EP_MinRetracePips  = 0;       // если >0 — порог в пунктах
input double EP_MinRetraceATR  = 0.25;    // если >0 — порог = k*ATR(14)
input color EP_H_Color         = clrDodgerBlue;
input color EP_L_Color         = clrDeepPink;
input ENUM_LINE_STYLE EP_LineStyle = STYLE_DOT;
input int   EP_LineWidth       = 1;

// === Debug ===
input bool  Debug_Log          = false;   // Печать в «Эксперты» только при true

#endif // __MFV_CONFIG_MQH__
