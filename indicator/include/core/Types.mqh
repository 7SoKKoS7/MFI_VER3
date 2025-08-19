#ifndef __MFV_TYPES_MQH__
#define __MFV_TYPES_MQH__

enum MFV_Trend { MFV_Trend_Up=1, MFV_Trend_Down=-1, MFV_Trend_Flat=0 };
enum MFV_SignalClass { MFV_Early, MFV_Normal, MFV_Strong };
enum MFV_Reason { MFV_RC_None, MFV_RC_NoData, MFV_RC_Clinch, MFV_RC_Flat, MFV_RC_Session, MFV_RC_Volume };

#endif // __MFV_TYPES_MQH__
