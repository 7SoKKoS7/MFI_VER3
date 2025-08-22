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
