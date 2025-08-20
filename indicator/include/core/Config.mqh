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

// === Pivots Visualization ===
input bool  ShowPivotsOnChart     = true;   // рисовать H/M/L текущего TF
input bool  PivotsChart_TFOnly    = true;   // если true — рисуем только текущий TF
input bool  PivotsChart_ShowMulti = false;  // если true — поверх текущего TF рисуем whitelist TF

// Панель — какие TF отображать
input bool Panel_Show_M5  = true;
input bool Panel_Show_M15 = true;
input bool Panel_Show_H1  = true;
input bool Panel_Show_H4  = true;
input bool Panel_Show_D1  = true;

// === Panel look & feel ===
input int   Panel_FontSize      = 11;          // размер шрифта панели по умолчанию
input color Panel_TextColor     = clrWhite;    // цвет текста панели
input int   Panel_TopOffsetPx   = 26;          // отступ от верхнего левого угла, чтобы не перекрывать служебный заголовок
input int   Panel_LineSpacingPx = 4;           // дополнительный межстрочный интервал (px)

// === Debug ===
input bool  Debug_Log = false;                 // печатать диагностику в "Эксперты"

// Цвета текущего TF
input color PivotHColor = clrRed;
input color PivotMColor = clrDarkGray;
input color PivotLColor = clrLime;
input int   PivotLineWidth  = 1;
input ENUM_LINE_STYLE PivotLineStyle = STYLE_DASHDOT;

// Цвета оверлея (если PivotsChart_ShowMulti=true)
input color Overlay_M5_Color  = clrDodgerBlue;
input color Overlay_M15_Color = clrDeepPink;
input color Overlay_H1_Color  = clrOrange;
input color Overlay_H4_Color  = clrMediumSeaGreen;
input color Overlay_D1_Color  = clrViolet;
input int   Overlay_LineWidth  = 1;
input ENUM_LINE_STYLE Overlay_LineStyle = STYLE_DOT;

#endif // __MFV_CONFIG_MQH__
