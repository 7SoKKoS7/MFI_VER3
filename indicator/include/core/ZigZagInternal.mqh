#ifndef MFV_ZZ_INTERNAL_MQH
#define MFV_ZZ_INTERNAL_MQH

#include "Utils.mqh"

// Единственная внутренняя функция ZigZag. Массивы — по ссылке!
bool MFV_ZZ_FindExtrema(const string symbol, ENUM_TIMEFRAMES tf,
                        int depth, int deviation, int backstep,
                        int &outCount, int &outIdx[], double &outPrice[])
{
   MqlRates r[];
   const int minBars = MathMax(500, depth*10 + backstep + 10);
   if(!MFV_CopyRates(symbol, tf, minBars, r)) {
      if(Debug_Log) Print("MFV.ZZ: Failed to copy rates for ", symbol, " ", EnumToString(tf));
      outCount = 0;
      return false;
   }
   ArraySetAsSeries(r, true);

   const int n = ArraySize(r);
   if(n < depth + backstep + 2) { 
      if(Debug_Log) Print("MFV.ZZ: Insufficient data for ", EnumToString(tf), " (need ", depth + backstep + 2, ", have ", n, ")");
      outCount = 0; 
      return false; 
   }

   // Динамическое расширение выходных массивов
   const int maxExtrema = MathMin(100, n / 10);
   ArrayResize(outIdx, maxExtrema);
   ArrayResize(outPrice, maxExtrema);
   
   // Проверка вместимости массивов
   int cap = MathMin(ArraySize(outIdx), ArraySize(outPrice));
   if(cap <= 0) {
      if(Debug_Log) Print("MFV.ZZ: cap<=0");
      outCount = 0;
      return false;
   }

   int w = 0, lastH = -1, lastL = -1;
   const double dev = deviation * Point();

   for(int i = depth; i < n - backstep; ++i)
   {
      bool isH = true, isL = true;
      const double pH = r[i].high, pL = r[i].low;

      for(int k = 1; k <= depth; ++k)
      {
         // Проверка границ индексов
         if(i-k >= 0 && i+k < n) {
            if(r[i-k].high + dev > pH || r[i+k].high + dev > pH) isH = false;
            if(r[i-k].low  - dev < pL || r[i+k].low  - dev < pL) isL = false;
         }
         if(!isH && !isL) break;
      }

      if(isH){
         if(lastH >= 0 && (lastH - i) <= backstep){ 
            if(r[i].high > r[lastH].high) lastH = i; 
         }
         else {
            lastH = i;
            if(w < cap){ 
               outIdx[w] = lastH; 
               outPrice[w] = r[lastH].high; 
               ++w; 
            }
         }
      }
      if(isL){
         if(lastL >= 0 && (lastL - i) <= backstep){ 
            if(r[i].low < r[lastL].low) lastL = i; 
         }
         else {
            lastL = i;
            if(w < cap){ 
               outIdx[w] = lastL; 
               outPrice[w] = r[lastL].low; 
               ++w; 
            }
         }
      }
   }

   outCount = w;
   if(outCount == 0) {
      if(Debug_Log) Print("MFV.ZZ: No extrema for ", symbol, " ", EnumToString(tf));
      return false;
   }
   
   return true;
}

#endif
