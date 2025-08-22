#ifndef __MFV_BREAKOUT_MQH__
#define __MFV_BREAKOUT_MQH__

#include "Config.mqh"
#include "Types.mqh"

// ADDED (helper function to get age limit in seconds for given timeframe)
int BO_AgeLimitSec(ENUM_TIMEFRAMES tf)
{
   switch(tf) {
      case PERIOD_M5:  return BO_BootstrapMaxAgeHours_M5  * 3600;
      case PERIOD_M15: return BO_BootstrapMaxAgeHours_M15 * 3600;
      case PERIOD_H1:  return BO_BootstrapMaxAgeHours_H1  * 3600;
      case PERIOD_H4:  return BO_BootstrapMaxAgeHours_H4  * 3600;
      case PERIOD_D1:  return BO_BootstrapMaxAgeHours_D1  * 3600;
      default:         return 0; // no limit
   }
}

// Вспомогательные функции для корректной работы с временем
datetime BO_TNow(const string s, ENUM_TIMEFRAMES tf)
{
   datetime t[]; ArraySetAsSeries(t, true);
   if (CopyTime(s, tf, 1, 1, t) == 1) return t[0]; // время ПОСЛЕДНЕГО ЗАКРЫТОГО бара TF
   return TimeCurrent();
}

int BO_PeriodSecondsSafe(ENUM_TIMEFRAMES tf)
{
   int ps = PeriodSeconds(tf);
   if (ps > 0) return ps;
   switch(tf){
      case PERIOD_M5:  return 300;
      case PERIOD_M15: return 900;
      case PERIOD_H1:  return 3600;
      case PERIOD_H4:  return 14400;
      case PERIOD_D1:  return 86400;
      default:         return 60;
   }
}

// Обновить состояние пробоя и ретеста для одного TF
bool MFV_Breakout_UpdateTF(const string symbol, ENUM_TIMEFRAMES tf, int tfIndex,
                           const MFV_Pivots &pv, const MFV_TrendInfo &trend,
                           MFV_BreakoutInfo &bo)
{
   // Если нет валидных пивотов - сбрасываем пробой
   if(!pv.hasHigh || !pv.hasLow) {
      bo.hasBreak = false;
      bo.rtest = MFV_RTEST_WAIT;
      return false;
   }

   // Получить Close[1] и Close[2] (два закрытых бара) для детекции пробоя
   double c1, c2;                  // Close[1] и Close[2]
   double cbuf[];
   ArraySetAsSeries(cbuf, true);
   int n = CopyClose(symbol, tf, 1, 2, cbuf);
   if(n < 2) {
      if(Debug_Log) PrintFormat("MFV.BO: Failed to copy Close for %s %s", symbol, EnumToString(tf));
      return false;
   }
   c1 = cbuf[0]; // Close[1] — последний ЗАКРЫТЫЙ
   c2 = cbuf[1]; // Close[2] — предыдущий ЗАКРЫТЫЙ

   double H = pv.high, L = pv.low;
   if(!pv.hasHigh || !pv.hasLow) {
      bo.hasBreak = false;
      return false;
   }

   // толеранс как в тренде: max(points, k*ATR14)
   double atr14 = 0, abuf[];
   ArraySetAsSeries(abuf, true);
   if(CopyBuffer(iATR(symbol, tf, 14), 0, 0, 1, abuf) == 1) atr14 = abuf[0];
   double tol = MathMax(Trend_TolPoints * _Point, Trend_TolATRk * atr14);

   // ВВЕРХ: был по эту сторону/стал по ту
   bool up   = (c2 <= H + tol) && (c1 >  H + tol);
   bool down = (c2 >= L - tol) && (c1 <  L - tol);

   bool newBreak = false;
   int breakDir = 0;
   double breakLevel = 0;

   if(up) {
      newBreak = true;
      breakDir = 1;
      breakLevel = H;
   }
   if(down) {
      newBreak = true;
      breakDir = -1;
      breakLevel = L;
   }

   // Если новый пробой - инициализируем
   if(newBreak) {
      bo.hasBreak = true;
      bo.dir = breakDir;
      bo.level = breakLevel; // якорим к PH/PL
      // время бара пробоя (закрытого) получаем безопасно
      datetime tt[];
      ArraySetAsSeries(tt,true);
      if(CopyTime(symbol, tf, 1, 1, tt) == 1) bo.barTime = tt[0];
      else bo.barTime = TimeCurrent(); // fallback, если копирование не удалось
      bo.priceBO = c1;
      bo.rtest = MFV_RTEST_WAIT;
      bo.barsSinceBO = 0;
      
      if(Debug_Log) {
         PrintFormat("BO %s %s: dir=%d level=%.5f close1=%.5f", 
                    symbol, EnumToString(tf), bo.dir, bo.level, c1);
      }
      return true;
   }

   // ADDED (bootstrap from history if no current breakout)
   if(!newBreak && !bo.hasBreak && BO_BootstrapFromHistory)
   {
      int N = MathMax(50, MathMin(BO_BootstrapLookback, 2000));
      double cc[]; datetime tt[];
      ArraySetAsSeries(cc,true); ArraySetAsSeries(tt,true);
      int gotC = CopyClose(symbol, tf, 1, N, cc);
      int gotT = CopyTime (symbol, tf, 1, N, tt);
      if(gotC>=2 && gotT==gotC)
      {
         // IMPROVED (find MOST RECENT valid cross, respect pivot birth and age limits)
         int ageLimit = BO_AgeLimitSec(tf);
         int pick = -1;
         
         // хотим САМЫЙ НОВЫЙ валидный кросс → идём NEW→OLD: i=1..gotC-1
         for (int i = 1; i < gotC; ++i)  // 0 — самый новый бар, поэтому стартуем с 1
         {
            bool up   = (cc[i]   <= H + tol) && (cc[i-1] >  H + tol);
            bool down = (cc[i]   >= L - tol) && (cc[i-1] <  L - tol);
            if (!(up || down)) continue;

            datetime tBreak = tt[i-1];

            // пробой не раньше «рождения» соответствующего пивота
            if (up   && pv.hasHigh && pv.highTime > 0 && tBreak < pv.highTime) continue;
            if (down && pv.hasLow  && pv.lowTime  > 0 && tBreak < pv.lowTime)  continue;

            // лимит свежести по TF
            if (ageLimit > 0 && (BO_TNow(symbol, tf) - tBreak) > ageLimit) continue;

            pick = i-1;               // бар пробоя
            break;                    // это САМЫЙ НОВЫЙ валидный
         }
         
         if (pick != -1)
         {
            bool up   = (cc[pick+1] <= H + tol) && (cc[pick] >  H + tol);
            bool down = (cc[pick+1] >= L - tol) && (cc[pick] <  L - tol);

            bo.hasBreak   = true;
            bo.dir        = up ? +1 : -1;
            bo.level      = up ? H : L;
            bo.barTime    = tt[pick];     // время свечи пробоя
            bo.priceBO    = cc[pick];
            bo.rtest      = MFV_RTEST_WAIT;

            int ps = BO_PeriodSecondsSafe(tf);
            bo.barsSinceBO = (int)MathMax(0, (BO_TNow(symbol, tf) - bo.barTime) / ps);

            if (Debug_Log)
               PrintFormat("BO BOOTSTRAP %s %s: dir=%d level=%.5f bar=%I64d ageBars=%d",
                           symbol, EnumToString(tf), bo.dir, bo.level, (long)bo.barTime, bo.barsSinceBO);
         }
      }
   }

   // Если нет активного пробоя - выходим
   if(!bo.hasBreak) return false;

   // IMPROVED (recompute barsSinceBO from barTime only if breakout is active)
   if (bo.hasBreak)
   {
      int ps = BO_PeriodSecondsSafe(tf);
      bo.barsSinceBO = (int)MathMax(bo.barsSinceBO, (BO_TNow(symbol, tf) - bo.barTime) / ps);
   }

   // Четкие условия ретеста/провала
   bool touched = (MathAbs(c1 - bo.level) <= tol);               // ретест ОК
   bool invalid = ((bo.dir>0 && c1 < bo.level - tol) ||          // провал до ретеста
                   (bo.dir<0 && c1 > bo.level + tol));

   if(touched)                bo.rtest = MFV_RTEST_OK;
   else if(invalid)           bo.rtest = MFV_RTEST_FAIL;
   else if(bo.barsSinceBO > RTest_MaxBars) bo.rtest = (MFV_RTest)(-1); // "—" тайм-аут
   else                        bo.rtest = MFV_RTEST_WAIT;

   // Если ретест завершен (OK, FAIL или тайм-аут) - сбрасываем пробой
   if(bo.rtest == MFV_RTEST_OK || bo.rtest == MFV_RTEST_FAIL || bo.rtest == (MFV_RTest)(-1)) {
      if(Debug_Log) {
         string status = (bo.rtest==MFV_RTEST_OK?"OK":bo.rtest==MFV_RTEST_FAIL?"FAIL":"TIMEOUT");
         PrintFormat("MFV.BO %s: RTest %s after %d bars", 
                    EnumToString(tf), status, bo.barsSinceBO);
      }
      bo.hasBreak = false; // Сбрасываем пробой после завершения ретеста
   }

   // Диагностика перед рисованием (только при Debug_Log)
   if(Debug_Log && bo.hasBreak)
      PrintFormat("DRAW BO %s %s: t=%I64d level=%.5f dir=%d rtest=%d",
                  symbol, EnumToString(tf), (long)bo.barTime, bo.level, bo.dir, bo.rtest);

   return true;
}

#endif // __MFV_BREAKOUT_MQH__
