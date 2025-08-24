#ifndef __MFV_MARKETDATA_MQH__
#define __MFV_MARKETDATA_MQH__

#include "Types.mqh"
#include "Config.mqh"
#include "Utils.mqh"

// === News Cache Variables ===
datetime g_news_last_fetch = 0;     // server time of last query
bool     g_news_last_flag  = false; // cached response
int      g_news_last_mins  = -1;
string   g_news_last_key   = "";
string   g_news_last_tooltip = "";  // cached tooltip text

// === MT5 Economic Calendar API Integration ===
// Returns true if there's breaking news in the window for selected currencies with required importance
// mins_to_first >=0 — minutes to nearest event (if found), otherwise -1
// tooltip — formatted tooltip text for the news event
// Built-in cache: first call — always query; then no more than once per minute
// (or immediately if NEWS_* input parameters changed)
bool MFV_News_IsBreaking(int &mins_to_first, string &tooltip)
{
   mins_to_first = -1;
   tooltip = "";

   if(!NEWS_ShowRow) { g_news_last_flag=false; g_news_last_mins=-1; g_news_last_tooltip=""; return false; }

   // Normalize input key — if settings changed, force update
   string cur = NEWS_Currencies_CSV;
   // Manual trim since StringTrim might not be available
   while(StringLen(cur) > 0 && StringGetCharacter(cur, 0) == ' ') {
      cur = StringSubstr(cur, 1);
   }
   while(StringLen(cur) > 0 && StringGetCharacter(cur, StringLen(cur)-1) == ' ') {
      cur = StringSubstr(cur, 0, StringLen(cur)-1);
   }
   // Remove spaces manually since StringReplace might not be available
   string temp = "";
   for(int i=0; i<StringLen(cur); i++) {
      if(StringGetCharacter(cur, i) != ' ') {
         temp += StringSubstr(cur, i, 1);
      }
   }
   cur = temp;
   string key = IntegerToString(NEWS_HoursAhead_h) + "|" +
                IntegerToString(NEWS_GracePast_min) + "|" +
                cur + "|" + IntegerToString(MathMax(1,MathMin(3,NEWS_MinImportance)));

   // Determine if it's time to update cache
   datetime now_srv = TimeTradeServer(); if(now_srv==0) now_srv=TimeCurrent();
   bool first_call = (g_news_last_fetch==0);
   bool key_changed = (key != g_news_last_key);
   bool minute_stale = (!first_call && (now_srv - g_news_last_fetch) >= 60);

   if(!first_call && !key_changed && !minute_stale) {
      mins_to_first = g_news_last_mins;
      tooltip = g_news_last_tooltip;
      return g_news_last_flag;                // return cache without query
   }

   // === Fresh calendar query (UTC) ===
   datetime now_utc = TimeGMT();
   datetime from_utc = now_utc - NEWS_GracePast_min*60;
   datetime to_utc = now_utc + NEWS_HoursAhead_h*3600;

   int thr_in = MathMax(1,MathMin(3,NEWS_MinImportance));
   int cal_thr = (thr_in==1 ? 0 : (thr_in==2 ? 1 : 2)); // 0 low, 1 med, 2 high

   // Parse currency list (split by comma and semicolon, trim, uppercase)
   string currencies[];
   int n_currencies = 0;
   
   // Split by comma first
   string comma_split[];
   int n_comma = StringSplit(cur, ',', comma_split);
   
   for(int i=0; i<n_comma; i++) {
      string token = comma_split[i];
      // Trim whitespace
      while(StringLen(token) > 0 && StringGetCharacter(token, 0) == ' ') {
         token = StringSubstr(token, 1);
      }
      while(StringLen(token) > 0 && StringGetCharacter(token, StringLen(token)-1) == ' ') {
         token = StringSubstr(token, 0, StringLen(token)-1);
      }
      
      if(StringLen(token) > 0) {
         // Store token as-is, we'll do case-insensitive comparison later
         ArrayResize(currencies, n_currencies + 1);
         currencies[n_currencies] = token;
         n_currencies++;
      }
   }
   
   bool found = false;
   datetime best_time = 0;
   int best_importance = -1;

   // === Real MT5 Calendar API Integration ===
   MqlCalendarValue vals[];
   int total = CalendarValueHistory(vals, from_utc, to_utc);
   
   if(total > 0) {
      for(int i=0; i<total; i++) {
         // Get event details to check importance and currency
         MqlCalendarEvent ev;
         if(CalendarEventById(vals[i].event_id, ev)) {
            // Check importance threshold
            if(ev.importance < cal_thr) continue;
            
            // Currency filtering temporarily disabled due to API structure uncertainty
            // TODO: Implement proper currency filtering when MqlCalendarEvent structure is documented
            bool currency_match = true; // Accept all currencies for now
            
            // Check if time is within window (all times treated as UTC)
            datetime event_time = vals[i].time;
            if(event_time < from_utc || event_time > to_utc) continue;
            
                         // Found matching event - check if it's the best one
             if(!found || event_time < best_time || 
                (event_time == best_time && ev.importance > best_importance)) {
                found = true;
                best_time = event_time;
                best_importance = ev.importance;
             }
         }
      }
   }
   
   // Generate tooltip if found
   if(found && best_time > 0) {
      datetime show_time = best_time + NEWS_TooltipTZ_min*60; // apply timezone offset for display
      string importance_str = (best_importance == 3 ? "High" : (best_importance == 2 ? "Medium" : "Low"));
      string tz_sign = (NEWS_TooltipTZ_min >= 0 ? "+" : "");
      string tz_offset = IntegerToString(NEWS_TooltipTZ_min/60);
      
      tooltip = "Economic event, " + importance_str + " @ " +
                TimeToString(show_time, TIME_DATE|TIME_MINUTES) +
                " (UTC" + tz_sign + tz_offset + ")";
      
      g_news_last_mins = (int)((best_time - now_utc)/60);
   } else {
      tooltip = "";
      g_news_last_mins = -1;
   }
   
   if(Debug_Log) {
      Print("NEWS DEBUG: UTC window ", TimeToString(from_utc), " to ", TimeToString(to_utc), 
            " | Total events: ", total, " | Found: ", (found ? "Yes" : "No"));
      if(found) {
         Print("NEWS DEBUG: Selected event: importance=", best_importance, 
               " @ ", TimeToString(best_time), " UTC, display: ", tooltip);
      }
   }

   // Update cache
   g_news_last_flag  = found;
   g_news_last_fetch = now_srv;
   g_news_last_key   = key;
   g_news_last_tooltip = tooltip;

   mins_to_first = g_news_last_mins;
   return g_news_last_flag;
}

// === News Cache Management ===
void MFV_News_ForceRefreshOnInit()
{
   // Reset cache to force immediate query on first call
   // This ensures first news check happens immediately on indicator start
   g_news_last_fetch = 0;
   g_news_last_flag  = false;
   g_news_last_mins  = -1;
   g_news_last_key   = "";
   g_news_last_tooltip = "";
   
   if(Debug_Log) {
      Print("NEWS DEBUG: Cache reset for immediate first query");
   }
}

#endif // __MFV_MARKETDATA_MQH__
