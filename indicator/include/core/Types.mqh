#ifndef __MFV_TYPES_MQH__
#define __MFV_TYPES_MQH__

enum MFV_Trend { MFV_Trend_Up=1, MFV_Trend_Down=-1, MFV_Trend_Flat=0 };
enum MFV_SignalClass { MFV_Early, MFV_Normal, MFV_Strong };
enum MFV_Reason { MFV_RC_None, MFV_RC_NoData, MFV_RC_Clinch, MFV_RC_Flat, MFV_RC_Session, MFV_RC_Volume };

#ifndef __MFV_TYPES_TREND_BLOCK__
#define __MFV_TYPES_TREND_BLOCK__

enum MFV_DirNow { MFV_DIRNOW_UNKNOWN=0, MFV_DIRNOW_UP, MFV_DIRNOW_DOWN, MFV_DIRNOW_NEUTRAL };

// Новая структура ИМЕННО с другим именем (НЕ MFV_Trend!)
struct MFV_TrendInfo {
  MFV_Trend  trend;     // существующий enum (Up/Down/Flat)
  MFV_DirNow dirNow;    // Up/Down/Neutral/Unknown
  double     tol_used;  // эффективный допуск для Trend
  double     eps_used;  // эффективная "мертвая зона" для DirNow
  bool       valid;     // есть ли актуальные pivots
};

#endif // __MFV_TYPES_TREND_BLOCK__

#ifndef __MFV_TYPES_BREAKOUT_BLOCK__
#define __MFV_TYPES_BREAKOUT_BLOCK__

enum MFV_RTest { MFV_RTEST_WAIT=0, MFV_RTEST_OK, MFV_RTEST_FAIL };
enum MFV_BOStrength { BO_Weak=0, BO_Normal=1, BO_Strong=2 };

struct MFV_BreakoutInfo {
  bool       hasBreak;    // есть ли активный пробой
  int        dir;         // направление пробоя (1=up, -1=down)
  double     level;       // уровень пробоя (PH или PL)
  datetime   barTime;     // время бара пробоя
  double     priceBO;     // цена на баре пробоя
  MFV_RTest  rtest;       // состояние ретеста
  int        barsSinceBO; // количество баров с момента пробоя
  MFV_BOStrength strength; // сила пробоя (Weak/Normal/Strong)
  double     tolUsed;     // использованный толеранс при пробое
};

#endif // __MFV_TYPES_BREAKOUT_BLOCK__

struct MFV_Pivots 
{ 
   double high; 
   double low; 
   double mid; 
   bool hasHigh; 
   bool hasLow; 
   bool hasMid; 
   datetime highTime; // время рождения PH (когда был подтвержден)
   datetime lowTime;  // время рождения PL (когда был подтвержден)
};

#endif // __MFV_TYPES_MQH__
