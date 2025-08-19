#ifndef __MFV_ZIGZAGINTERNAL_MQH__
#define __MFV_ZIGZAGINTERNAL_MQH__

#include "Utils.mqh"

// Единственная внутренняя функция ZigZag. Массивы — по ссылке!
bool MFV_ZZ_FindExtrema(const string symbol, ENUM_TIMEFRAMES tf,
                        int depth, int deviation, int backstep,
                        int &outCount, int &outIdx[], double &outPrice[])
{
   MqlRates r[]; 
   if(!MFV_CopyRates(symbol, tf, MathMax(500, depth*10), r)) return(false);
   ArraySetAsSeries(r, true);

   const int n = ArraySize(r);
   if(n < depth + backstep + 2) { outCount=0; return(false); }

   const int cap = MathMin(ArraySize(outIdx), ArraySize(outPrice));
   if(cap <= 0) { outCount=0; return(false); }

   int w=0, lastH=-1, lastL=-1;
   const double dev = deviation * Point();

   for(int i=depth; i<n-backstep; ++i)
   {
      bool isH=true, isL=true;
      const double pH=r[i].high, pL=r[i].low;

      for(int k=1; k<=depth; ++k)
      {
         if(r[i-k].high + dev > pH || r[i+k].high + dev > pH) isH=false;
         if(r[i-k].low  - dev < pL || r[i+k].low  - dev < pL) isL=false;
         if(!isH && !isL) break;
      }

      if(isH){
         if(lastH>=0 && (lastH-i)<=backstep){ if(r[i].high>r[lastH].high) lastH=i; }
         else lastH=i;
         if(w<cap){ outIdx[w]=lastH; outPrice[w]=r[lastH].high; ++w; }
      }
      if(isL){
         if(lastL>=0 && (lastL-i)<=backstep){ if(r[i].low<r[lastL].low) lastL=i; }
         else lastL=i;
         if(w<cap){ outIdx[w]=lastL; outPrice[w]=r[lastL].low; ++w; }
      }
   }

   outCount = w;
   return(outCount>0);
}

#endif // __MFV_ZIGZAGINTERNAL_MQH__
