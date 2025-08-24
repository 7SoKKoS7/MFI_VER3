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

   // Проверяем, должен ли существующий пробой быть отфильтрован по текущему режиму подтверждения
   if(bo.hasBreak) {
      bool pass = (BO_ConfirmMode == Confirm_Off) || (BO_ConfirmMode == Confirm_All)
               || (BO_ConfirmMode == Confirm_StrongAndNormal && (bo.strength == BO_Strong || bo.strength == BO_Normal))
               || (BO_ConfirmMode == Confirm_StrongOnly && bo.strength == BO_Strong);
      
      if(!pass) {
         if(Debug_Log) {
            string strengthStr = (bo.strength == BO_Strong ? "Strong" : "Normal");
            string modeStr = (BO_ConfirmMode == Confirm_Off ? "Off" : 
                             BO_ConfirmMode == Confirm_StrongOnly ? "StrongOnly" :
                             BO_ConfirmMode == Confirm_StrongAndNormal ? "StrongAndNormal" : "All");
            PrintFormat("BO CLEAR %s %s: strength=%s mode=%s -> cleared", 
                       symbol, EnumToString(tf), strengthStr, modeStr);
         }
         bo.hasBreak = false;
         bo.rtest = MFV_RTEST_WAIT;
      }
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

   // толеранс как в тренде: max(points, k*ATR14) с минимальным значением
   double atr14 = 0, abuf[];
   ArraySetAsSeries(abuf, true);
   if(CopyBuffer(iATR(symbol, tf, 14), 0, 0, 1, abuf) == 1) atr14 = abuf[0];
   double tol = MathMax(Trend_TolPoints * _Point, Trend_TolATRk * atr14);
   // Минимальный толеранс для видимости зоны
   if(tol < _Point) tol = _Point;

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
      // Вычисляем силу пробоя
      double dist = MathAbs(c1 - breakLevel);
      double atr = 0;
      double atrBuf[];
      ArraySetAsSeries(atrBuf, true);
      if(CopyBuffer(iATR(symbol, tf, 14), 0, 0, 1, atrBuf) == 1) atr = atrBuf[0];
      
      MFV_BOStrength strength = BO_Normal;
      if((dist >= BO_StrongTolK * tol) || (atr > 0 && dist >= BO_StrongATRK * atr)) {
         strength = BO_Strong;
      }
      
      // Применяем фильтр подтверждения
      bool pass = (BO_ConfirmMode == Confirm_Off) || (BO_ConfirmMode == Confirm_All)
               || (BO_ConfirmMode == Confirm_StrongAndNormal && (strength == BO_Strong || strength == BO_Normal))
               || (BO_ConfirmMode == Confirm_StrongOnly && strength == BO_Strong);
      
      if(pass) {
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
         bo.strength = strength;
         bo.tolUsed = tol;
         
         if(Debug_Log) {
            string strengthStr = (strength == BO_Strong ? "Strong" : "Normal");
            string modeStr = (BO_ConfirmMode == Confirm_Off ? "Off" : 
                             BO_ConfirmMode == Confirm_StrongOnly ? "StrongOnly" :
                             BO_ConfirmMode == Confirm_StrongAndNormal ? "StrongAndNormal" : "All");
            PrintFormat("BO NEW %s %s: dir=%d dist=%.5f tol=%.5f atr=%.5f strength=%s mode=%s -> kept", 
                       symbol, EnumToString(tf), bo.dir, dist, tol, atr, strengthStr, modeStr);
         }
         return true;
      } else {
         // Если пробой отфильтрован, очищаем активный пробой для этого TF
         if(bo.hasBreak) {
            bo.hasBreak = false;
            bo.rtest = MFV_RTEST_WAIT;
         }
         
         if(Debug_Log) {
            string strengthStr = (strength == BO_Strong ? "Strong" : "Normal");
            string modeStr = (BO_ConfirmMode == Confirm_Off ? "Off" : 
                             BO_ConfirmMode == Confirm_StrongOnly ? "StrongOnly" :
                             BO_ConfirmMode == Confirm_StrongAndNormal ? "StrongAndNormal" : "All");
            PrintFormat("BO FILTER %s %s: strength=%s mode=%s -> dropped", 
                       symbol, EnumToString(tf), strengthStr, modeStr);
         }
         return false;
      }
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

            // Вычисляем силу пробоя для bootstrap
            double dist = MathAbs(cc[pick] - (up ? H : L));
            double atr = 0;
            double atrBuf[];
            ArraySetAsSeries(atrBuf, true);
            if(CopyBuffer(iATR(symbol, tf, 14), 0, 0, 1, atrBuf) == 1) atr = atrBuf[0];
            
            MFV_BOStrength strength = BO_Normal;
            if((dist >= BO_StrongTolK * tol) || (atr > 0 && dist >= BO_StrongATRK * atr)) {
               strength = BO_Strong;
            }

            // Применяем фильтр подтверждения для bootstrap
            bool pass = (BO_ConfirmMode == Confirm_Off) || (BO_ConfirmMode == Confirm_All)
                     || (BO_ConfirmMode == Confirm_StrongAndNormal && (strength == BO_Strong || strength == BO_Normal))
                     || (BO_ConfirmMode == Confirm_StrongOnly && strength == BO_Strong);
            
            if(pass) {
               bo.hasBreak   = true;
               bo.dir        = up ? +1 : -1;
               bo.level      = up ? H : L;
               bo.barTime    = tt[pick];     // время свечи пробоя
               bo.priceBO    = cc[pick];
               bo.rtest      = MFV_RTEST_WAIT;
               bo.strength   = strength;
               bo.tolUsed    = tol;

               // Calculate barsSinceBO based on closed bars for bootstrap
               datetime t_last = iTime(symbol, tf, 1);          // строго закрытый бар
               int idx_last   = iBarShift(symbol, tf, t_last, true);
               int idx_break  = iBarShift(symbol, tf, bo.barTime, true);

               // защита от -1 и рассинхронизаций
               int barsSince  = 0;
               if (idx_last >= 0 && idx_break >= 0)
                  barsSince = MathMax(0, idx_break - idx_last);

               bo.barsSinceBO = barsSince;

               if (Debug_Log) {
                  string strengthStr = (strength == BO_Strong ? "Strong" : "Normal");
                  string modeStr = (BO_ConfirmMode == Confirm_Off ? "Off" : 
                                   BO_ConfirmMode == Confirm_StrongOnly ? "StrongOnly" :
                                   BO_ConfirmMode == Confirm_StrongAndNormal ? "StrongAndNormal" : "All");
                  PrintFormat("BO BOOTSTRAP %s %s: dir=%d level=%.5f bar=%I64d ageBars=%d strength=%s mode=%s -> kept",
                              symbol, EnumToString(tf), bo.dir, bo.level, (long)bo.barTime, bo.barsSinceBO, strengthStr, modeStr);
               }
            } else {
               if (Debug_Log) {
                  string strengthStr = (strength == BO_Strong ? "Strong" : "Normal");
                  string modeStr = (BO_ConfirmMode == Confirm_Off ? "Off" : 
                                   BO_ConfirmMode == Confirm_StrongOnly ? "StrongOnly" :
                                   BO_ConfirmMode == Confirm_StrongAndNormal ? "StrongAndNormal" : "All");
                  PrintFormat("BO BOOTSTRAP FILTER %s %s: strength=%s mode=%s -> dropped",
                              symbol, EnumToString(tf), strengthStr, modeStr);
               }
            }
         }
      }
   }

   // Если нет активного пробоя - выходим
   if(!bo.hasBreak) return false;

   // IMPROVED (recompute barsSinceBO based on closed bars, not real time)
   if (bo.hasBreak)
   {
      // last closed bar on tf
      datetime t_last = iTime(symbol, tf, 1);          // строго закрытый бар
      int idx_last   = iBarShift(symbol, tf, t_last, true);
      int idx_break  = iBarShift(symbol, tf, bo.barTime, true);

      // защита от -1 и рассинхронизаций
      int barsSince  = 0;
      if (idx_last >= 0 && idx_break >= 0)
         barsSince = MathMax(0, idx_break - idx_last);

      bo.barsSinceBO = barsSince;
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
