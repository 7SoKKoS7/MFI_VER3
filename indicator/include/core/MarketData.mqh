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
                 cur + "|" + IntegerToString(MathMax(1,MathMin(3,NEWS_MinImportance))) + "|" +
                 IntegerToString(NEWS_WindowTZ_h) + "|" + IntegerToString(NEWS_TooltipTZ_h);

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

    // === Fresh calendar query (trading server time with window offset) ===
    datetime now_base = now_srv - NEWS_WindowTZ_h*3600;
    datetime from_srv = now_base - NEWS_GracePast_min*60;
    datetime to_srv = now_base + NEWS_HoursAhead_h*3600;

   int thr_in = MathMax(1,MathMin(3,NEWS_MinImportance));
   int cal_thr = (thr_in==1 ? 0 : (thr_in==2 ? 1 : 2)); // 0 low, 1 med, 2 high

       // Parse currency list (split by comma, semicolon, spaces)
    string currencies[];
    int n_currencies = 0;
    
    // Normalize separators: replace ; and spaces with commas
    string normalized = cur;
    // Replace semicolons with commas
    for(int i=0; i<StringLen(normalized); i++) {
       if(StringGetCharacter(normalized, i) == ';') {
          normalized = StringSubstr(normalized, 0, i) + "," + StringSubstr(normalized, i+1);
       }
    }
    
    // Split by comma
    string comma_split[];
    int n_comma = StringSplit(normalized, ',', comma_split);
    
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
          // Manual uppercase
          string upper_token = "";
          for(int j=0; j<StringLen(token); j++) {
             ushort ch = StringGetCharacter(token, j);
             if(ch >= 'a' && ch <= 'z') ch = ch - 32; // to uppercase
             upper_token += StringSubstr(token, j, 1);
          }
          
          ArrayResize(currencies, n_currencies + 1);
          currencies[n_currencies] = upper_token;
          n_currencies++;
       }
    }
   
   bool found = false;
   datetime best_time = 0;
   int best_importance = -1;

       // === Real MT5 Calendar API Integration ===
    // Collect values from all currencies
    MqlCalendarValue values_all[];
    ArrayResize(values_all, 0);
    
    for(int c=0; c<n_currencies; c++) {
       string currency = currencies[c];
       MqlCalendarValue vals[];
       int total = CalendarValueHistory(vals, from_srv, to_srv, NULL, currency);
       
       if(total > 0) {
          int old_size = ArraySize(values_all);
          ArrayResize(values_all, old_size + total);
          ArrayCopy(values_all, vals, old_size, 0, total);
       }
    }
    
    // Process all collected values
    if(ArraySize(values_all) > 0) {
       for(int i=0; i<ArraySize(values_all); i++) {
          // Get event details to check importance
          MqlCalendarEvent ev;
          if(CalendarEventById(values_all[i].event_id, ev)) {
             // Check importance threshold
             if(ev.importance < cal_thr) continue;
             
                           // Check if time is within window and in the future relative to base time
              datetime event_time = values_all[i].time;
              if(event_time < from_srv || event_time > to_srv) continue;
              if(event_time < now_base) continue; // Only future events relative to base
             
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
       datetime show_time = best_time + NEWS_TooltipTZ_h*3600; // apply timezone offset for display
       string importance_str = (best_importance == 3 ? "High" : (best_importance == 2 ? "Medium" : "Low"));
       string tz_sign = (NEWS_TooltipTZ_h >= 0 ? "+" : "");
       string tz_offset = IntegerToString(NEWS_TooltipTZ_h);
       
       tooltip = "Economic event, " + importance_str + " @ " +
                 TimeToString(show_time, TIME_DATE|TIME_MINUTES) +
                 " (UTC" + tz_sign + tz_offset + "h)";
       
       g_news_last_mins = (int)((best_time - now_base)/60);
    } else {
       tooltip = "";
       g_news_last_mins = -1;
    }
   
       if(Debug_Log) {
       Print("NEWS | now_srv=", TimeToString(now_srv), " base=", TimeToString(now_base), 
             " win=[", TimeToString(from_srv), "..", TimeToString(to_srv), "]");
       if(found) {
          datetime show_time = best_time + NEWS_TooltipTZ_h*3600;
          Print("NEWS | pick=", best_importance==3?"High":(best_importance==2?"Medium":"Low"), 
                "@", TimeToString(best_time), " -> show ", TimeToString(show_time), 
                " | CSV=", NEWS_Currencies_CSV, " | MinImp=", NEWS_MinImportance);
       } else {
          Print("NEWS | no events found | CSV=", NEWS_Currencies_CSV, " | MinImp=", NEWS_MinImportance);
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
