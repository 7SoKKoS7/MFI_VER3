#ifndef __MFV_UTILS_MQH__
#define __MFV_UTILS_MQH__

// === ZigZag Parameter Utility ===
void MFV_ZZ_ParamsForTF(const ENUM_TIMEFRAMES tf, int &depth, int &deviation, int &backstep)
{
   if(!ZZ_UseMF_Preset){ depth=ZZ_Manual_Depth; deviation=ZZ_Manual_Deviation; backstep=ZZ_Manual_Backstep; return; }
   switch(tf)
   {
      case PERIOD_M5:   depth=ZZ_MF_M5_Depth;  deviation=ZZ_MF_M5_Deviation;  backstep=ZZ_MF_M5_Backstep;  break;
      case PERIOD_M15:  depth=ZZ_MF_M15_Depth; deviation=ZZ_MF_M15_Deviation; backstep=ZZ_MF_M15_Backstep; break;
      case PERIOD_H1:   depth=ZZ_MF_H1_Depth;  deviation=ZZ_MF_H1_Deviation;  backstep=ZZ_MF_H1_Backstep;  break;
      case PERIOD_H4:   depth=ZZ_MF_H4_Depth;  deviation=ZZ_MF_H4_Deviation;  backstep=ZZ_MF_H4_Backstep;  break;
      case PERIOD_D1:   depth=ZZ_MF_D1_Depth;  deviation=ZZ_MF_D1_Deviation;  backstep=ZZ_MF_D1_Backstep;  break;
      default:          depth=ZZ_Manual_Depth; deviation=ZZ_Manual_Deviation; backstep=ZZ_Manual_Backstep; break;
   }
}

// === Safe Rate Reader ===
bool MFV_CopyRates(const string symbol, ENUM_TIMEFRAMES tf, int minBars, MqlRates &rates[])
{
   ArrayFree(rates);
   int c = CopyRates(symbol, tf, 0, minBars, rates);
   if(c <= 0) return(false);
   ArraySetAsSeries(rates, true);
   return(true);
}

#endif // __MFV_UTILS_MQH__
