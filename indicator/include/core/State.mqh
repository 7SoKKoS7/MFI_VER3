#ifndef __MFV_STATE_MQH__
#define __MFV_STATE_MQH__
#include "Types.mqh"

struct MFV_State
{
   MFV_Trend trends[5];
   MFV_Pivots piv[5];
   MFV_Reason lastReason[5];
};
static MFV_State g_state;

#endif // __MFV_STATE_MQH__
