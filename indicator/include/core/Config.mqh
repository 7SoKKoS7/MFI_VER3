#ifndef __MFV_CONFIG_MQH__
#define __MFV_CONFIG_MQH__

// === BASIC / PANEL ===
input string __SEC0 = "=== BASIC / PANEL ===";

input bool UseRussian = true;
input int  AtrPeriodH1 = 14;

// === ZigZag (MF preset, per TF) — ADVANCED (moved to const) ===
input string __SEC_ZZ = "=== ZigZag (MF preset, per TF) — ADVANCED (moved to const) ===";

input bool ZZ_UseMF_Preset = true;  // true: использовать пресет MF по ТФ

// Рекомендуемые MF-настройки (можно менять из свойств индикатора)
// NOTE: These parameters moved to constants to simplify UI. Edit values here if needed.
static const int ZZ_MF_M5_Depth      = 12;
static const int ZZ_MF_M5_Deviation  = 5;
static const int ZZ_MF_M5_Backstep   = 3;

static const int ZZ_MF_M15_Depth     = 12;
static const int ZZ_MF_M15_Deviation = 5;
static const int ZZ_MF_M15_Backstep  = 3;

static const int ZZ_MF_H1_Depth      = 24;
static const int ZZ_MF_H1_Deviation  = 5;
static const int ZZ_MF_H1_Backstep   = 3;

static const int ZZ_MF_H4_Depth      = 48;
static const int ZZ_MF_H4_Deviation  = 5;
static const int ZZ_MF_H4_Backstep   = 3;

static const int ZZ_MF_D1_Depth      = 60;
static const int ZZ_MF_D1_Deviation  = 5;
static const int ZZ_MF_D1_Backstep   = 3;

// Ручной режим (если ZZ_UseMF_Preset=false)
static const int ZZ_Manual_Depth     = 12;
static const int ZZ_Manual_Deviation = 5;
static const int ZZ_Manual_Backstep  = 3;

// === Trend & Direction (panel) ===
input bool   Panel_Show_Trend   = true;
input bool   Panel_Show_DirNow  = true;

// Параметры допусков
input int    Trend_TolPoints    = 5;     // минимальный допуск в пунктах (минимум 1-5 для видимости)
input double Trend_TolATRk      = 0.25;  // k для k*ATR(14)
input double DirNow_EpsPct      = 0.10;  // dead-zone как доля (H-L)

// === Breakout & Retest (panel) ===
input bool   Panel_ShowBreakout = true;  // показывать строку Breakout
input bool   Panel_ShowRTest    = true;  // показывать строку Retest
input int    RTest_MaxBars      = 10;    // максимальное количество баров для ретеста

// === NEWS (calendar) ===
input string __SEC_NEWS = "=== NEWS (calendar) ===";

input bool   NEWS_ShowRow        = true;        // show "Breaking news" row
input int    NEWS_HoursAhead_h   = 3;           // hours ahead (future window)
input int    NEWS_GracePast_min  = 0;           // grace to past (minutes)
input string NEWS_Currencies_CSV = "EUR,USD";   // currency filter
input int    NEWS_MinImportance  = 3;           // 1=All, 2=Medium+High, 3=High only (threshold, inclusive)
input int    NEWS_WindowTZ_h     = 0;           // сдвиг СРАВНЕНИЯ окна (часы; +1 если сервер «спешит» на час)
input int    NEWS_TooltipTZ_h    = 0;           // сдвиг ТОЛЬКО ОТОБРАЖЕНИЯ (часы; +1 чтобы совпадать с календарём)

// === Breakout & Retest — ADVANCED (moved to const) ===
input string __SEC_BRK = "=== Breakout & Retest — ADVANCED (moved to const) ===";

// NOTE: Advanced breakout parameters moved to constants. Edit values here if needed.

// === Breakout bootstrap from history ===
static const bool BO_BootstrapFromHistory = true;   // искать последний реальный пробой в истории
static const int  BO_BootstrapLookback    = 300;    // сколько закрытых баров просканировать
static const bool BO_BootstrapOnlyRecent  = true;   // только недавние пробои (по MaxAgeHours)

// Максимальный возраст пробоя для bootstrap (в часах)
static const int BO_BootstrapMaxAgeHours_M5  = 6;   // 6 часов для M5
static const int BO_BootstrapMaxAgeHours_M15 = 12;  // 12 часов для M15
static const int BO_BootstrapMaxAgeHours_H1  = 48;  // 48 часов для H1
static const int BO_BootstrapMaxAgeHours_H4  = 168; // 168 часов (7 дней) для H4
static const int BO_BootstrapMaxAgeHours_D1  = 720; // 720 часов (30 дней) для D1

// === Breakout markers look & feel ===
static const int   BO_ArrowFontSize      = 10;  // размер стрелки пробоя (OBJ_TEXT), по умолчанию меньше
input color BO_ArrowColorUp       = clrLime;
input color BO_ArrowColorDn       = clrRed;
static const int   BO_StatusYOffsetPoints= 10;  // смещение статуса ретеста по цене (в пунктах) от уровня пробоя
static const color BO_StatusColorOK      = clrLime;
static const color BO_StatusColorFAIL    = clrRed;
static const color BO_StatusColorWAIT    = clrSilver;
static const color BO_StatusColorNONE    = clrDarkGray; // "—" нет ретеста по тайм-ауту

// === Breakout Strength & Confirmation ===
enum ConfirmMode { Confirm_Off, Confirm_StrongOnly, Confirm_StrongAndNormal, Confirm_All };
static const ConfirmMode BO_ConfirmMode = Confirm_StrongAndNormal;  // режим подтверждения пробоев
static const double BO_StrongTolK = 2.0;    // множитель толеранса для сильного пробоя
static const double BO_StrongATRK = 0.50;   // множитель ATR для сильного пробоя

// === Retest Zone Drawing ===
static const double RTest_ZoneK = 1.0;         // множитель к tolUsed для высоты зоны
static const int    RTest_ZonePts = 0;         // фикс. высота в пунктах, если ZoneK==0
static const int    RTest_DrawMinPx = 12;      // минимальная высота зоны в пикселях (только визуально)

// === Retest Zone Rectangle ===
static const bool   RTest_DrawZoneRect   = true;   // рисовать зону ретеста как прямоугольник
static const color  RTest_RectColorUp    = clrDodgerBlue;  // цвет для пробоя вверх
static const color  RTest_RectColorDn    = clrTomato;      // цвет для пробоя вниз
static const int    RTest_RectAlpha      = 35;     // прозрачность 0..255
static const bool   RTest_RectBack       = true;   // рисовать за графиком
static const int    RTest_RectBorderW    = 1;      // ширина границы
static const int    RTest_RectBorderStyle= STYLE_DOT; // стиль границы

// === Multi-TF Retest Zone Overlay ===
enum RTestOverlayMode { RTest_CurrentOnly, RTest_CurrentPlusParent, RTest_AllGhosted };
static const RTestOverlayMode RTest_OverlayMode = RTest_CurrentPlusParent;  // режим наложения зон ретеста
static const bool  RTest_CollapseNested = true;     // скрывать зону младшего TF, если она полностью внутри старшего и того же направления
static const int   RTest_GhostAlpha     = 20;       // альфа «призраков»

// Цвета контуров по TF (для призраков)
static const color RTest_TFColor_M5  = clrDeepSkyBlue;
static const color RTest_TFColor_M15 = clrMediumPurple;
static const color RTest_TFColor_H1  = clrLimeGreen;
static const color RTest_TFColor_H4  = clrOrange;
static const color RTest_TFColor_D1  = clrTomato;

// === Panel look & feel ===
static const string Panel_FontName    = "Consolas";    // моноширинный для ровных колонок
input int   Panel_FontSize      = 11;        // 8..28
static const color Panel_TextColor     = clrWhite;
static const int   Panel_TopOffsetPx   = 26;        // от бордюра терминала
static const int   Panel_LineSpacingPx = 4;         // доп. межстрочный интервал
input bool  Panel_ShowMid       = true;      // показывать M=... в строках панели
static const bool  Panel_ShowEarly     = false;     // eH/eL для текущего ТФ (опц.)

// === Chart drawing ===
input bool  ShowPivotsOnChart        = true;
static const bool  PivotsChart_TFOnly       = true;   // только текущий ТФ
static const bool  PivotsChart_ShowMulti    = true;   // overlay всех WL-ТФ
static const bool  Chart_ShowMid_CurrentTF  = true;   // Mid для текущего ТФ
static const bool  Chart_ShowMid_Overlay    = false;  // Mid для overlay

// Цвета текущего TF
input color PivotHColor = clrRed;
input color PivotMColor = clrDarkGray;
input color PivotLColor = clrLime;
static const int   PivotLineWidth = 1;
static const ENUM_LINE_STYLE PivotLineStyle = STYLE_DASHDOT;

// Цвета оверлея (если PivotsChart_ShowMulti=true)
static const color Overlay_M5_Color  = clrDodgerBlue;
static const color Overlay_M15_Color = clrDeepPink;
static const color Overlay_H1_Color  = clrOrange;
static const color Overlay_H4_Color  = clrMediumSeaGreen;
static const color Overlay_D1_Color  = clrViolet;
static const int   Overlay_LineWidth  = 1;
static const ENUM_LINE_STYLE Overlay_LineStyle = STYLE_DOT;

// === Misc/Diagnostics — ADVANCED (moved to const) ===
input string __SEC_MISC = "=== Misc/Diagnostics — ADVANCED (moved to const) ===";

// NOTE: Advanced parameters moved to constants. Edit values here if needed.

// === Early pivot (только текущий TF) ===
static const bool  EP_Enable          = false;
static const bool  EP_OnCurrentTFOnly = true;    // зафиксировать «только текущий ТФ»
static const int   EP_MinRetracePips  = 0;       // если >0 — порог в пунктах
static const double EP_MinRetraceATR  = 0.25;    // если >0 — порог = k*ATR(14)
static const color EP_H_Color         = clrDodgerBlue;
static const color EP_L_Color         = clrDeepPink;
static const ENUM_LINE_STYLE EP_LineStyle = STYLE_DOT;
static const int   EP_LineWidth       = 1;

// === Labels ===
static const bool   Label_Compact        = true;    // компактный формат
static const bool   Label_ShowPrice      = true;    // показывать цену
static const bool   Label_ShowSymbol     = false;   // добавлять тикер (обычно не нужно)
static const string Label_DateFmt        = "yyyy-MM-dd HH:mm"; // формат времени в подсказках (если требуется)
static const string Label_Lang           = "EN";    // "EN" или "RU" (минимальный i18n)



// === Debug ===
input bool  Debug_Log          = false;   // Печать в «Эксперты» только при true

#endif // __MFV_CONFIG_MQH__
