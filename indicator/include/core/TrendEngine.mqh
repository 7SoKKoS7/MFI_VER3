#ifndef __MFV_TRENDENGINE_MQH__
#define __MFV_TRENDENGINE_MQH__

#include "Config.mqh"
#include "Types.mqh"

bool MFV_Trend_FromPivots(const string sym, ENUM_TIMEFRAMES tf,
                          const MFV_Pivots &pv,
                          MFV_TrendInfo &outT,
                          const int tolPoints, const double tolATRk,
                          const double dirNowEpsPct)
{
  outT.valid = (pv.hasHigh && pv.hasLow); // Mid можно восстанавливать как (H+L)/2 при отсутствии флага
  if(!outT.valid) { outT.trend=MFV_Trend_Flat; outT.dirNow=MFV_DIRNOW_UNKNOWN; return false; }

  const double H = pv.high;
  const double L = pv.low;
  const double M = pv.hasMid ? pv.mid : 0.5*(H+L);

  // Толеранс для Trend: max(points, k*ATR14)
  double atr14 = 0.0;
  double atr[];
  ArraySetAsSeries(atr, true);
  int copied = CopyBuffer(iATR(sym, tf, 14), 0, 0, 2, atr);
  if(copied >= 1) atr14 = atr[0];
  
  double tol = MathMax(tolPoints*Point(), tolATRk * atr14);
  outT.tol_used = tol;

  // Epsilon для DirNow
  const double rng = MathMax(H-L, _Point);
  const double eps = dirNowEpsPct * rng;
  outT.eps_used = eps;

  // Получить цены: Close[1] и Close[0] через безопасный CopyClose
  double c1=0, c0=0;
  double close[];
  ArraySetAsSeries(close, true);
  int copied_close = CopyClose(sym, tf, 1, 2, close);
  if(copied_close < 2) {
    outT.valid = false;
    return false;
  }
  c1 = close[1]; // Close[1] - закрытый бар
  c0 = close[0]; // Close[0] - текущий бар

  // Trend по закрытому бару
  if(c1 > H + tol)      outT.trend = MFV_Trend_Up;
  else if(c1 < L - tol) outT.trend = MFV_Trend_Down;
  else                  outT.trend = MFV_Trend_Flat;

  // Direction-Now по текущему бару и Mid
  if(c0 > M + eps)      outT.dirNow = MFV_DIRNOW_UP;
  else if(c0 < M - eps) outT.dirNow = MFV_DIRNOW_DOWN;
  else                  outT.dirNow = MFV_DIRNOW_NEUTRAL;

  if(Debug_Log) {
    PrintFormat("MFV.Trend: %s %s - Trend:%d DirNow:%d C1:%.5f C0:%.5f Tol:%.5f Eps:%.5f", 
                sym, EnumToString(tf), outT.trend, outT.dirNow, c1, c0, tol, eps);
  }

  return true;
}

#endif // __MFV_TRENDENGINE_MQH__
