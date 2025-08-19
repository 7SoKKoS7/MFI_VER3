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

#endif // __MFV_CONFIG_MQH__
