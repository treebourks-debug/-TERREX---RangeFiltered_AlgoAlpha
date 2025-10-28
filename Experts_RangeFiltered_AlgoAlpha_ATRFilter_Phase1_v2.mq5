//+------------------------------------------------------------------+
//|      Experts_RangeFiltered_AlgoAlpha_ATRFilter_Phase1_v2.mq5    |
//|  EA с ATR Filter - Phase 1 + Optimizable Risk Parameter         |
//|  Modified: 2025-10-28                                            |
//|  Author: treebourks-debug                                        |
//|  Repository: github.com/treebourks-debug/-TERREX---RangeFiltered_AlgoAlpha |
//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>
CTrade Trade;

input ulong InpMagic = 777001;

// ═══════════════════════════════════════════════════════════════
// RISK MANAGEMENT - OPTIMIZABLE
// ═══════════════════════════════════════════════════════════════
input group "=== RISK MANAGEMENT ==="
input double InpRiskPerTradePct = 1.0;  // Risk per trade (%) - START=0.5 STEP=0.5 STOP=3.0
input double InpSL_R_Pips = 30.0;       // Stop Loss (pips) - START=30 STEP=10 STOP=100

input group "=== TAKE PROFIT ==="
input double InpTP1_R = 1.0;  // TP1 R:R - START=1.0 STEP=0.5 STOP=3.0
input double InpTP2_R = 2.0;  // TP2 R:R - START=2.0 STEP=1.0 STOP=5.0
input double InpTP3_R = 3.0;  // TP3 R:R - START=3.0 STEP=1.0 STOP=8.0

input group "=== PARTIAL CLOSE ==="
input bool InpPartialClose = true;
input double InpTP1_ClosePct = 20.0;
input double InpTP2_ClosePct = 40.0;
input bool InpMoveSLtoBEatTP1 = true;

input group "=== INDICATORS ==="
input double KalmanAlpha = 0.05;
input double KalmanBeta = 0.5;
input int KalmanPeriod = 200;
input double DevMultiplier = 1.6;
input double ST_Factor = 0.6;
input int ST_ATRPeriod = 11;

input group "=== FILTERS ==="
input bool InpUseTrendFilter = true;

input group "=== ATR FILTER ==="
input bool InpUseATRFilter = true;
input int InpATRPeriod = 14;
input double InpMinATRValue = 0.00100;
input bool InpATRUseDynamic = false;
input double InpATRDynamicMult = 1.2;
input int InpATRAvgBars = 50;

input group "=== DISPLAY ==="
input bool InpShowFilterInfo = true;
input color TP_Color = clrLime;
input int TP_Width = 2;
input ENUM_LINE_STYLE TP_Style = STYLE_SOLID;

// ===================== GLOBALS =====================================
double iCloseF[], iHighF[], iLowF[], kF[], atrF[], dirF[], upperF[], lowerF[];
int trendF[], ktrendF[];
int LWMA_Period = 200;
double g_k_cache = 0, g_upper_cache = 0, g_lower_cache = 0;
int g_trend_cache = 0, g_ktrend_cache = 0;
ulong gTicket = 0;
bool gTP1Drawn = false, gTP2Drawn = false, gTP3Drawn = false;
bool gTP1Hit = false, gTP2Hit = false, gTP3Hit = false;
int lastBar = -1, lastProd = 999;
int g_atrHandle = INVALID_HANDLE;
double g_lastATRValue = 0, g_lastATRThreshold = 0;
int g_atrBlockCount = 0, g_atrPassCount = 0;

// ===================== INDICATOR FUNCTIONS =========================
double TR(double hi, double lo, double prevClose) {
   return MathMax(hi - lo, MathMax(fabs(hi - prevClose), fabs(lo - prevClose)));
}

void CalcATR(const int total, const int p, const double &hi[], const double &lo[], const double &cl[], double &out[]) {
   ArrayResize(out, total);
   if (total == 0) return;
   double sum = 0;
   int init = MathMin(p, total);
   for (int j = 0; j < init; j++) {
      double tr = (j == 0 ? hi[0] - lo[0] : TR(hi[j], lo[j], cl[j - 1]));
      sum += tr;
      out[j] = (j < p - 1 ? 0.0 : sum / p);
   }
   for (int j = p; j < total; j++) {
      double tr = TR(hi[j], lo[j], cl[j - 1]);
      out[j] = (out[j - 1] * (p - 1) + tr) / p;
   }
}

void CalcLWMA(const int total, const int p, const double &src[], double &out[]) {
   ArrayResize(out, total);
   if (p <= 1 || total < p) {
      for (int j = 0; j < total; j++) out[j] = src[j];
      return;
   }
   int wSum = p * (p + 1) / 2;
   double acc = 0, wacc = 0;
   for (int j = 0; j < p; j++) {
      acc += src[j];
      wacc += src[j] * (j + 1);
   }
   out[p - 1] = wacc / wSum;
   for (int j = p; j < total; j++) {
      wacc = wacc + p * src[j] - acc;
      acc = acc + src[j] - src[j - p];
      out[j] = wacc / wSum;
   }
}

void CalcKalman(const int total, const double &src[], double a, double b, int per, double &out[]) {
   ArrayResize(out, total);
   double v1 = src[0], v2 = 1.0, v3 = a * per, v4 = 0.0, v5 = src[0];
   out[0] = src[0];
   for (int j = 1; j < total; j++) {
      v5 = v1;
      v4 = v2 / (v2 + v3);
      v1 = v5 + v4 * (src[j] - v5);
      v2 = (1.0 - v4) * v2 + b / (double)per;
      out[j] = v1;
   }
}

void CalcSuperTrendK(const int total, const double &k[], const double &atr[], double factor, double &dir[]) {
   ArrayResize(dir, total);
   double prevUB = 0, prevLB = 0, prevST = 0, _dir = -1;
   for (int j = 0; j < total; j++) {
      double ub = k[j] + factor * atr[j];
      double lb = k[j] - factor * atr[j];
      if (j > 0) {
         lb = (lb > prevLB || k[j - 1] < prevLB) ? lb : prevLB;
         ub = (ub < prevUB || k[j - 1] > prevUB) ? ub : prevUB;
      }
      if (j == 0) _dir = -1;
      else if (prevST == prevUB) _dir = (k[j] > ub ? -1 : 1);
      else _dir = (k[j] < lb ? 1 : -1);
      dir[j] = _dir;
      prevUB = ub;
      prevLB = lb;
      prevST = (_dir == -1 ? lb : ub);
   }
}

bool BuildIndicatorState(int bars, double &k_last, int &trend_last, int &ktrend_last, double &upper_last, double &lower_last) {
   int total = bars, minBars = LWMA_Period + ST_ATRPeriod + 10;
   if (total < minBars) return false;
   MqlRates rates[];
   int copied = CopyRates(_Symbol, _Period, 0, total, rates);
   if (copied <= 0 || copied < minBars) return false;
   ArraySetAsSeries(rates, true);
   ArrayResize(iCloseF, copied);
   ArrayResize(iHighF, copied);
   ArrayResize(iLowF, copied);
   for (int j = 0; j < copied; j++) {
      int si = copied - 1 - j;
      iCloseF[j] = rates[si].close;
      iHighF[j] = rates[si].high;
      iLowF[j] = rates[si].low;
   }
   CalcKalman(copied, iCloseF, KalmanAlpha, KalmanBeta, KalmanPeriod, kF);
   CalcATR(copied, ST_ATRPeriod, iHighF, iLowF, iCloseF, atrF);
   double rangeF[], wmaF[];
   ArrayResize(rangeF, copied);
   for (int j = 0; j < copied; j++) rangeF[j] = iHighF[j] - iLowF[j];
   CalcLWMA(copied, LWMA_Period, rangeF, wmaF);
   ArrayResize(upperF, copied);
   ArrayResize(lowerF, copied);
   for (int j = 0; j < copied; j++) {
      upperF[j] = kF[j] + DevMultiplier * wmaF[j];
      lowerF[j] = kF[j] - DevMultiplier * wmaF[j];
   }
   CalcSuperTrendK(copied, kF, atrF, ST_Factor, dirF);
   ArrayResize(trendF, copied);
   ArrayResize(ktrendF, copied);
   for (int j = 0; j < copied; j++) {
      int t = 0;
      if (iCloseF[j] > upperF[j]) t = 1;
      else if (iCloseF[j] < lowerF[j]) t = -1;
      trendF[j] = t;
      int kt = 0;
      if (dirF[j] < 0) kt = 1;
      else if (dirF[j] > 0) kt = -1;
      ktrendF[j] = kt;
   }
   int j = copied - 1;
   k_last = kF[j];
   trend_last = trendF[j];
   ktrend_last = ktrendF[j];
   upper_last = upperF[j];
   lower_last = lowerF[j];
   return true;
}

double CalculateAverageATR() {
   if (g_atrHandle == INVALID_HANDLE) return 0;
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   int copied = CopyBuffer(g_atrHandle, 0, 0, InpATRAvgBars, atrBuffer);
   if (copied <= 0) return 0;
   double sum = 0;
   for (int i = 0; i < copied; i++) sum += atrBuffer[i];
   return sum / copied;
}

bool CheckATRFilter() {
   if (!InpUseATRFilter) return true;
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   if (CopyBuffer(g_atrHandle, 0, 0, 1, atrBuffer) <= 0) return false;
   double currentATR = atrBuffer[0];
   g_lastATRValue = currentATR;
   double threshold = InpATRUseDynamic ? CalculateAverageATR() * InpATRDynamicMult : InpMinATRValue;
   g_lastATRThreshold = threshold;
   if (currentATR < threshold) {
      g_atrBlockCount++;
      return false;
   }
   g_atrPassCount++;
   return true;
}

void DisplayFilterInfo() {
   if (!InpShowFilterInfo) return;
   string info = "═══ ATR FILTER (Phase 1) ═══\n\n";
   if (InpUseATRFilter) {
      info += "📊 ATR: " + DoubleToString(g_lastATRValue, 5) + " / " + DoubleToString(g_lastATRThreshold, 5);
      info += " " + (g_lastATRValue >= g_lastATRThreshold ? "✅" : "🚫") + "\n";
      if (g_atrPassCount + g_atrBlockCount > 0)
         info += "  " + IntegerToString(g_atrPassCount) + "/" + IntegerToString(g_atrPassCount + g_atrBlockCount) + 
                 " (" + DoubleToString(100.0 * g_atrPassCount / (g_atrPassCount + g_atrBlockCount), 1) + "%)\n\n";
   }
   info += "💰 RISK: " + DoubleToString(InpRiskPerTradePct, 2) + "% | SL: " + DoubleToString(InpSL_R_Pips, 1) + " pips\n";
   Comment(info);
}

string MakeTag(const string base) { return base + "#" + (string)gTicket; }

void DeleteTPVisuals() {
   string t1 = MakeTag("TP1"), t2 = MakeTag("TP2"), t3 = MakeTag("TP3");
   if (ObjectFind(0, t1) >= 0) ObjectDelete(0, t1);
   if (ObjectFind(0, t2) >= 0) ObjectDelete(0, t2);
   if (ObjectFind(0, t3) >= 0) ObjectDelete(0, t3);
   if (ObjectFind(0, t1 + "LBL") >= 0) ObjectDelete(0, t1 + "LBL");
   if (ObjectFind(0, t2 + "LBL") >= 0) ObjectDelete(0, t2 + "LBL");
   if (ObjectFind(0, t3 + "LBL") >= 0) ObjectDelete(0, t3 + "LBL");
   gTP1Drawn = gTP2Drawn = gTP3Drawn = false;
}

void DrawTPLine(const string tag, const string lbl, double price, color clr) {
   datetime t0 = iTime(_Symbol, _Period, 0);
   if (ObjectFind(0, tag) < 0) {
      ObjectCreate(0, tag, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, tag, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, tag, OBJPROP_STYLE, TP_Style);
      ObjectSetInteger(0, tag, OBJPROP_WIDTH, TP_Width);
   } else ObjectSetDouble(0, tag, OBJPROP_PRICE, price);
   string ltag = tag + "LBL";
   if (ObjectFind(0, ltag) < 0) {
      ObjectCreate(0, ltag, OBJ_TEXT, 0, t0, price);
      ObjectSetString(0, ltag, OBJPROP_TEXT, StringSubstr(tag, 0, 3));
      ObjectSetInteger(0, ltag, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, ltag, OBJPROP_FONTSIZE, 8);
   } else {
      ObjectSetDouble(0, ltag, OBJPROP_PRICE, price);
      ObjectSetInteger(0, ltag, OBJPROP_TIME, t0);
   }
}

bool HasPosition(ulong &ticket, double &vol, double &price, double &sl, double &tp, ENUM_POSITION_TYPE &ptype) {
   if (!PositionSelect(_Symbol)) return false;
   ticket = PositionGetInteger(POSITION_TICKET);
   vol = PositionGetDouble(POSITION_VOLUME);
   price = PositionGetDouble(POSITION_PRICE_OPEN);
   sl = PositionGetDouble(POSITION_SL);
   tp = PositionGetDouble(POSITION_TP);
   ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   return true;
}

double Pip() {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if (digits == 3 || digits == 5) return point * 10.0;
   return point;
}

void CalcSLTPLevels(ENUM_POSITION_TYPE type, double entry, double &sl, double &tp1, double &tp2, double &tp3) {
   double pip = Pip();
   double R = InpSL_R_Pips * pip;
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if (type == POSITION_TYPE_BUY) {
      sl = NormalizeDouble(entry - R, digits);
      tp1 = NormalizeDouble(entry + InpTP1_R * R, digits);
      tp2 = NormalizeDouble(entry + InpTP2_R * R, digits);
      tp3 = NormalizeDouble(entry + InpTP3_R * R, digits);
   } else {
      sl = NormalizeDouble(entry + R, digits);
      tp1 = NormalizeDouble(entry - InpTP1_R * R, digits);
      tp2 = NormalizeDouble(entry - InpTP2_R * R, digits);
      tp3 = NormalizeDouble(entry - InpTP3_R * R, digits);
   }
}

bool PartialClose(ulong ticket, double closePct) {
   if (closePct <= 0) return true;
   if (!PositionSelectByTicket(ticket)) return false;
   double vol = PositionGetDouble(POSITION_VOLUME);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double lot = MathFloor((vol * (closePct / 100.0)) / step) * step;
   if (lot < minVol) return true;
   if (lot >= vol) return Trade.PositionClose(ticket);
   return Trade.PositionClosePartial(ticket, lot);
}

void CheckEntries() {
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if (lastBar == (int)currentBarTime) return;
   ulong t; double v, p, sl, tp; ENUM_POSITION_TYPE pt;
   if (HasPosition(t, v, p, sl, tp, pt)) {
      int bars = MathMin(300, iBars(_Symbol, _Period));
      if (BuildIndicatorState(bars, g_k_cache, g_trend_cache, g_ktrend_cache, g_upper_cache, g_lower_cache))
         lastProd = g_trend_cache * g_ktrend_cache;
      lastBar = (int)currentBarTime;
      if (InpShowFilterInfo) DisplayFilterInfo();
      return;
   }
   int bars = MathMin(300, iBars(_Symbol, _Period));
   if (!BuildIndicatorState(bars, g_k_cache, g_trend_cache, g_ktrend_cache, g_upper_cache, g_lower_cache)) return;
   int prod = g_trend_cache * g_ktrend_cache;
   lastBar = (int)currentBarTime;
   if (!CheckATRFilter()) {
      lastProd = prod;
      DisplayFilterInfo();
      return;
   }
   if (lastProd <= 0 && prod > 0) {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double currentClose = iClose(_Symbol, _Period, 0);
      if (InpUseTrendFilter && currentClose < g_k_cache) { lastProd = prod; return; }
      double sl_, tp1, tp2, tp3;
      CalcSLTPLevels(POSITION_TYPE_BUY, ask, sl_, tp1, tp2, tp3);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskCash = balance * InpRiskPerTradePct / 100.0;
      double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if (tickVal <= 0) tickVal = 1.0;
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double stopDistance = MathAbs(ask - sl_);
      double vol = riskCash / (stopDistance / point * tickVal);
      double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double stepVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      vol = MathFloor(vol / stepVol) * stepVol;
      vol = MathMax(minVol, MathMin(maxVol, vol));
      Trade.SetExpertMagicNumber(InpMagic);
      Trade.SetDeviationInPoints(50);
      if (Trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, vol, ask, sl_, 0, "ATR BUY")) {
         gTicket = Trade.ResultOrder();
         gTP1Drawn = gTP2Drawn = gTP3Drawn = false;
         gTP1Hit = gTP2Hit = gTP3Hit = false;
         DrawTPLine(MakeTag("TP1"), MakeTag("TP1LBL"), tp1, TP_Color);
         gTP1Drawn = true;
      }
   } else if (lastProd >= 0 && prod < 0) {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double currentClose = iClose(_Symbol, _Period, 0);
      if (InpUseTrendFilter && currentClose > g_k_cache) { lastProd = prod; return; }
      double sl_, tp1, tp2, tp3;
      CalcSLTPLevels(POSITION_TYPE_SELL, bid, sl_, tp1, tp2, tp3);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskCash = balance * InpRiskPerTradePct / 100.0;
      double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if (tickVal <= 0) tickVal = 1.0;
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double stopDistance = MathAbs(sl_ - bid);
      double vol = riskCash / (stopDistance / point * tickVal);
      double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double stepVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      vol = MathFloor(vol / stepVol) * stepVol;
      vol = MathMax(minVol, MathMin(maxVol, vol));
      Trade.SetExpertMagicNumber(InpMagic);
      Trade.SetDeviationInPoints(50);
      if (Trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, vol, bid, sl_, 0, "ATR SELL")) {
         gTicket = Trade.ResultOrder();
         gTP1Drawn = gTP2Drawn = gTP3Drawn = false;
         gTP1Hit = gTP2Hit = gTP3Hit = false;
         DrawTPLine(MakeTag("TP1"), MakeTag("TP1LBL"), tp1, TP_Color);
         gTP1Drawn = true;
      }
   }
   lastProd = prod;
   DisplayFilterInfo();
}

void ManageOpenPosition() {
   ulong ticket; double vol, entry, sl, tp; ENUM_POSITION_TYPE type;
   if (!HasPosition(ticket, vol, entry, sl, tp, type)) {
      if (gTicket != 0) { DeleteTPVisuals(); gTicket = 0; }
      return;
   }
   if (ticket != gTicket) {
      DeleteTPVisuals();
      gTicket = ticket;
      gTP1Drawn = gTP2Drawn = gTP3Drawn = false;
      gTP1Hit = gTP2Hit = gTP3Hit = false;
   }
   double tp1, tp2, tp3, slCalc;
   CalcSLTPLevels(type, entry, slCalc, tp1, tp2, tp3);
   if (!gTP1Drawn) { DrawTPLine(MakeTag("TP1"), MakeTag("TP1LBL"), tp1, TP_Color); gTP1Drawn = true; }
   double price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if (!gTP1Hit) {
      bool hit = (type == POSITION_TYPE_BUY) ? (price >= tp1) : (price <= tp1);
      if (hit) {
         if (InpPartialClose) PartialClose(ticket, InpTP1_ClosePct);
         if (InpMoveSLtoBEatTP1) Trade.PositionModify(ticket, entry, 0.0);
         gTP1Hit = true;
         DrawTPLine(MakeTag("TP2"), MakeTag("TP2LBL"), tp2, TP_Color); gTP2Drawn = true;
      }
   } else if (!gTP2Hit) {
      bool hit = (type == POSITION_TYPE_BUY) ? (price >= tp2) : (price <= tp2);
      if (hit) {
         if (InpPartialClose) PartialClose(ticket, InpTP2_ClosePct);
         gTP2Hit = true;
         DrawTPLine(MakeTag("TP3"), MakeTag("TP3LBL"), tp3, TP_Color); gTP3Drawn = true;
      }
   } else if (!gTP3Hit) {
      bool hit = (type == POSITION_TYPE_BUY) ? (price >= tp3) : (price <= tp3);
      if (hit) {
         if (Trade.PositionClose(ticket)) { gTP3Hit = true; DeleteTPVisuals(); gTicket = 0; }
      }
   }
}

int OnInit() {
   Trade.SetExpertMagicNumber(InpMagic);
   lastProd = 999; lastBar = -1;
   if (InpUseATRFilter) {
      g_atrHandle = iATR(_Symbol, _Period, InpATRPeriod);
      if (g_atrHandle == INVALID_HANDLE) { Print("❌ ATR init failed!"); return INIT_FAILED; }
      g_atrBlockCount = 0; g_atrPassCount = 0;
   }
   Print("═══════════════════════════════════════════════");
   Print(" PHASE 1 - ATR FILTER | ", _Symbol, " ", EnumToString(_Period));
   Print(" 💰 RISK: ", DoubleToString(InpRiskPerTradePct, 2), "% | SL: ", InpSL_R_Pips, " pips");
   Print(" 📊 ATR: ", (InpUseATRFilter ? "ON" : "OFF"));
   Print("═══════════════════════════════════════════════");
   return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   DeleteTPVisuals();
   if (g_atrHandle != INVALID_HANDLE) { IndicatorRelease(g_atrHandle); g_atrHandle = INVALID_HANDLE; }
   if (InpUseATRFilter && (g_atrPassCount + g_atrBlockCount) > 0) {
      Print("ATR Stats: ", g_atrPassCount, "/", g_atrPassCount + g_atrBlockCount,
            " (", DoubleToString(100.0 * g_atrPassCount / (g_atrPassCount + g_atrBlockCount), 1), "%)");
   }
   Comment("");
}

void OnTick() {
   ManageOpenPosition();
   CheckEntries();
}
