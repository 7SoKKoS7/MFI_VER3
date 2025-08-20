#ifndef __MFV_PIVOTENGINE_MQH__
#define __MFV_PIVOTENGINE_MQH__

bool MFV_Pivot_UpdateTF(const int tfIndex,
                        const int &zzIdx[], const double &zzPrice[], const int count,
                        MFV_State &st)
{
   // Если экстремумов мало — чистим флаги и выходим
   if(count < 2) {
      Print("MFV.Pivot: count<2 for TF index ", tfIndex);
      st.piv[tfIndex].hasHigh = false;
      st.piv[tfIndex].hasLow = false;
      st.piv[tfIndex].hasMid = false;
      return false;
   }

   // Берём окно последних K (= min(40, count)) точек ZigZag и считаем H/L
   int K = MathMin(40, count), start = count - K;
   double hi = zzPrice[start], lo = zzPrice[start];
   for(int i = start; i < count; ++i) {
      if(zzPrice[i] > hi) hi = zzPrice[i];
      if(zzPrice[i] < lo) lo = zzPrice[i];
   }

   st.piv[tfIndex].high = hi;  st.piv[tfIndex].hasHigh = true;
   st.piv[tfIndex].low  = lo;  st.piv[tfIndex].hasLow  = true;
   st.piv[tfIndex].mid  = 0.5*(hi+lo); st.piv[tfIndex].hasMid = true;
   return true;
}

#endif // __MFV_PIVOTENGINE_MQH__
