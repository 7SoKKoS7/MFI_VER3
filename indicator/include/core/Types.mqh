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

struct MFV_Pivots 
{ 
   double high; 
   double low; 
   double mid; 
   bool hasHigh; 
   bool hasLow; 
   bool hasMid; 
};

#endif // __MFV_TYPES_MQH__
