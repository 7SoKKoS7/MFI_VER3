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

// === News Checking Function ===
bool MFV_News_IsNear(int hours_ahead,
                     int grace_past_min,
                     const string ccy_csv,
                     int min_importance,
                     datetime &next_event_time,
                     string &next_event_ccy,
                     string &next_event_title)
{
   // Get current time
   datetime now = TimeTradeServer();
   if(now == 0) now = TimeCurrent();
   
   // Calculate time window
   datetime from = now - grace_past_min * 60;
   datetime to = now + hours_ahead * 3600;
   
   // Parse currency filter
   string currencies[];
   StringSplit(ccy_csv, ',', currencies);
   int ccy_count = ArraySize(currencies);
   if(ccy_count == 0) return false;
   
   // Try to access Economic Calendar using standard MT5 API
   // Note: This is a simplified implementation since the full Calendar API
   // may not be available in all MT5 builds
   
   // For now, we'll implement a basic check that returns false
   // This ensures the panel shows "No" by default
   // In a real implementation, you would use:
   // - CalendarValueHistoryByEvent() to get event data
   // - Or external data sources for economic calendar
   
   // Check if we're in weekend (Saturday/Sunday)
   MqlDateTime dt;
   TimeToStruct(now, dt);
   if(dt.day_of_week == 0 || dt.day_of_week == 6) {
      // Weekend - no trading, so no important news
      return false;
   }
   
   // For testing purposes, we can simulate finding an event
   // This would be replaced with actual calendar API calls
   if(Debug_Log) {
      Print("NEWS DEBUG: Checking window from ", TimeToString(from), " to ", TimeToString(to));
      Print("NEWS DEBUG: Looking for currencies: ", ccy_csv, " with importance >= ", min_importance);
   }
   
   // Return false to indicate no important news found
   // This will show "No" in the panel
   return false;
}

#endif // __MFV_UTILS_MQH__
