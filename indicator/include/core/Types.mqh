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
  
  // Конструкторы
  MFV_TrendInfo() {
    trend = MFV_Trend_Flat;
    dirNow = MFV_DIRNOW_UNKNOWN;
    tol_used = 0.0;
    eps_used = 0.0;
    valid = false;
  }
  
  MFV_TrendInfo(const MFV_TrendInfo& other) {
    trend = other.trend;
    dirNow = other.dirNow;
    tol_used = other.tol_used;
    eps_used = other.eps_used;
    valid = other.valid;
  }
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
  
  // Конструкторы
  MFV_BreakoutInfo() {
    hasBreak = false;
    dir = 0;
    level = 0.0;
    barTime = 0;
    priceBO = 0.0;
    rtest = MFV_RTEST_WAIT;
    barsSinceBO = 0;
    strength = BO_Weak;
    tolUsed = 0.0;
  }
  
  MFV_BreakoutInfo(const MFV_BreakoutInfo& other) {
    hasBreak = other.hasBreak;
    dir = other.dir;
    level = other.level;
    barTime = other.barTime;
    priceBO = other.priceBO;
    rtest = other.rtest;
    barsSinceBO = other.barsSinceBO;
    strength = other.strength;
    tolUsed = other.tolUsed;
  }
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
   
   // Конструкторы
   MFV_Pivots() {
     high = 0.0;
     low = 0.0;
     mid = 0.0;
     hasHigh = false;
     hasLow = false;
     hasMid = false;
     highTime = 0;
     lowTime = 0;
   }
   
   MFV_Pivots(const MFV_Pivots& other) {
     high = other.high;
     low = other.low;
     mid = other.mid;
     hasHigh = other.hasHigh;
     hasLow = other.hasLow;
     hasMid = other.hasMid;
     highTime = other.highTime;
     lowTime = other.lowTime;
   }
};

#endif // __MFV_TYPES_MQH__
