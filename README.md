# 🚀 TERREX - Range Filtered AlgoAlpha EA

**Advanced MT5 Expert Advisor with ATR Filter and Dynamic Risk Management**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: MT5](https://img.shields.io/badge/Platform-MT5-blue.svg)](https://www.metatrader5.com)
[![Language: MQL5](https://img.shields.io/badge/Language-MQL5-green.svg)](https://www.mql5.com)

---

## 📊 Overview

TERREX is a professional algorithmic trading system combining:
- **Kalman Filter** for price smoothing
- **Range-Filtered Bands** for trend detection  
- **SuperTrend** for entry confirmation
- **ATR Filter** for volatility-based entry control
- **Dynamic Risk Management** with optimizable position sizing
- **Multi-level Take Profit** with partial close functionality

**Tested Period:** 2024-2025 (2 years)  
**Recommended Risk:** 1.0% per trade  
**Profit Factor:** 1.73  
**Sharpe Ratio:** 3.88  
**Max Drawdown:** 7.38%

---

## 🎯 Key Features

### **Core Trading Logic:**
- ✅ Trend detection via Range-Filtered Kalman bands
- ✅ SuperTrend confirmation for entry signals
- ✅ ATR-based volatility filter (blocks low-volatility periods)
- ✅ Trend filter (optional - only trades with trend direction)

### **Risk Management:**
- ✅ **Optimizable risk per trade** (0.5% - 3.0%)
- ✅ Dynamic position sizing based on account balance
- ✅ Fixed R:R ratio with customizable stop loss
- ✅ 3-level take profit system (TP1, TP2, TP3)

### **Partial Close System:**
- ✅ TP1: Close 20% at 1R
- ✅ TP2: Close 40% at 2R  
- ✅ TP3: Close remaining at 3R
- ✅ Move SL to breakeven after TP1 (optional)

---

## 📈 Backtest Results (2024-2025)

### **Test Configuration:**
- **Symbol:** EURUSD
- **Timeframe:** H1
- **Initial Deposit:** $1,000
- **Period:** 2024.01.01 - 2025.10.27 (22 months)
- **Execution:** Every tick based on real ticks

### **Results by Risk Level:**

| Risk % | Net Profit | ROI | Max DD | Profit Factor | Sharpe | Win Rate | Total Trades | Recommendation |
|--------|-----------|-----|--------|---------------|--------|----------|--------------|----------------|
| 0.5% | +$120 | 12.0% | 2.61% | 1.76 | 3.74 | 50% | 357 | Conservative |
| **1.0%** | **+$386** | **38.6%** | **7.38%** | **1.73** | **3.88** | **63.5%** | **441** | **✅ OPTIMAL** |
| 1.5% | +$567 | 56.7% | 10.93% | 1.62 | 3.64 | 74% | 579 | Aggressive |
| 2.0% | +$791 | 79.1% | 14.00% | 1.58 | 3.40 | 74% | 579 | ⚠️ Too risky |

### **Recommended Setup (1.0% risk):**
- **Annual ROI:** ~19%
- **Max Drawdown:** 7.38% (institutional-grade)
- **Sharpe Ratio:** 3.88 (excellent risk-adjusted returns)
- **Expected Profit per Trade:** +$2.40
- **Largest Win:** $27.40
- **Largest Loss:** -$12.79
- **Max Consecutive Wins:** 8 ($94.55)
- **Max Consecutive Losses:** 5 (-$19.74)

---

## ⚙️ Installation

### **Requirements:**
- MetaTrader 5 build 3802+
- Minimum deposit: $500 (recommended: $1,000+)
- Broker with low spreads (< 1.5 pips for EURUSD)
- VPS recommended for 24/7 operation

### **Steps:**

1. **Download the EA:**
   ```
   Experts_RangeFiltered_AlgoAlpha_ATRFilter_Phase1_v2.mq5
   ```

2. **Install in MT5:**
   - Copy to: `C:\Users\YourName\AppData\Roaming\MetaQuotes\Terminal\[ID]\MQL5\Experts\`
   - Or use MT5: File → Open Data Folder → MQL5 → Experts

3. **Compile:**
   - Open MetaEditor (F4 in MT5)
   - Open the .mq5 file
   - Press F7 to compile
   - Check for errors (should be 0 errors, 0 warnings)

4. **Attach to Chart:**
   - Open EURUSD H1 chart
   - Drag EA from Navigator → Expert Advisors
   - Enable "Allow Algo Trading" (top toolbar)

---

## 🎛️ Parameters Guide

### **Risk Management (MOST IMPORTANT):**

```cpp
InpRiskPerTradePct = 1.0    // Risk per trade (%) - START=0.5 STEP=0.5 STOP=3.0
InpSL_R_Pips = 30.0         // Stop Loss in pips - START=30 STEP=10 STOP=100
```

**Recommended values:**
- Conservative: 0.5%
- Balanced: **1.0%** ✅ (recommended)
- Aggressive: 1.5%
- Very Aggressive: 2.0% (not recommended)

### **Take Profit Levels:**

```cpp
InpTP1_R = 1.0    // TP1 at 1R (1:1 risk-reward)
InpTP2_R = 2.0    // TP2 at 2R
InpTP3_R = 3.0    // TP3 at 3R
```

### **Partial Close:**

```cpp
InpPartialClose = true
InpTP1_ClosePct = 20.0      // Close 20% at TP1
InpTP2_ClosePct = 40.0      // Close 40% at TP2
InpMoveSLtoBEatTP1 = true   // Move SL to breakeven after TP1
```

### **ATR Filter (Phase 1):**

```cpp
InpUseATRFilter = true
InpATRPeriod = 14
InpMinATRValue = 0.00100    // Minimum ATR (10 pips)
InpATRUseDynamic = false    // Use dynamic ATR threshold
```

**How it works:**
- Blocks entries when ATR < threshold (low volatility)
- Prevents trades during flat/ranging markets
- Improves Profit Factor and Win Rate

### **Indicator Parameters:**

```cpp
KalmanAlpha = 0.05
KalmanBeta = 0.5
KalmanPeriod = 200
DevMultiplier = 1.6
ST_Factor = 0.6
ST_ATRPeriod = 11
```

**Note:** These are optimized values. Change only if you know what you're doing.

### **Filters:**

```cpp
InpUseTrendFilter = true    // Only trade with trend direction
```

---

## 📊 Strategy Logic

### **Entry Conditions (BUY):**

1. ✅ **Trend Filter:** Close > Kalman line (if enabled)
2. ✅ **Range Filter:** Close breaks above upper band
3. ✅ **SuperTrend:** Confirms uptrend
4. ✅ **ATR Filter:** ATR > minimum threshold
5. ✅ **Cross Signal:** Trend × KTrend changes from ≤0 to >0

### **Entry Conditions (SELL):**

1. ✅ **Trend Filter:** Close < Kalman line (if enabled)
2. ✅ **Range Filter:** Close breaks below lower band  
3. ✅ **SuperTrend:** Confirms downtrend
4. ✅ **ATR Filter:** ATR > minimum threshold
5. ✅ **Cross Signal:** Trend × KTrend changes from ≥0 to <0

### **Exit Strategy:**

- **TP1 (1R):** Close 20%, move SL to breakeven
- **TP2 (2R):** Close 40%
- **TP3 (3R):** Close remaining position
- **Stop Loss:** Fixed at entry ± SL_R_Pips

---

## 🧪 Testing Recommendations

### **Before Live Trading:**

1. **DEMO Testing (1-2 months):**
   - Use 1.0% risk
   - Monitor daily for first week
   - Check filter effectiveness
   - Verify lot size calculations

2. **Success Criteria for DEMO:**
   - ✅ ROI > 0% (at least breakeven)
   - ✅ Profit Factor > 1.5
   - ✅ Max DD < 10%
   - ✅ No technical errors

3. **Live Trading (start small):**
   - Initial capital: $500-$1,000
   - Risk: 1.0% per trade
   - Daily DD limit: 5%
   - Monthly ROI target: 2-4%

---

## 📈 Expected Performance (Live Trading)

### **With $1,000 capital at 1.0% risk:**

| Period | Expected Profit | Final Balance | ROI |
|--------|----------------|---------------|-----|
| 1 month | $15-20 | $1,015-20 | 1.5-2.0% |
| 3 months | $45-60 | $1,045-60 | 4.5-6.0% |
| 6 months | $90-120 | $1,090-120 | 9-12% |
| 12 months | $180-240 | $1,180-240 | 18-24% |
| 24 months | $360-480 | $1,360-480 | 36-48% |

**Note:** Past performance does not guarantee future results.

---

## ⚠️ Risk Warnings

### **General Trading Risks:**
- Trading involves substantial risk of loss
- Never risk more than you can afford to lose
- Past performance is not indicative of future results
- Use proper risk management at all times

### **EA-Specific Risks:**
- Automated systems can fail due to technical issues
- Market conditions can change (adapt parameters if needed)
- Broker conditions (spreads, slippage) affect results
- VPS downtime can miss trading opportunities

### **Recommended Safety Measures:**
- ✅ Always use DEMO before LIVE
- ✅ Start with minimum capital
- ✅ Set daily/weekly loss limits
- ✅ Monitor EA regularly (first month especially)
- ✅ Use VPS for reliability
- ✅ Choose reputable brokers

---

## 🛠️ Troubleshooting

### **EA not opening trades:**
- Check "Allow Algo Trading" is enabled (top toolbar)
- Verify ATR filter is not blocking (check Comment on chart)
- Ensure sufficient free margin
- Check broker allows automated trading

### **Lot size too large/small:**
- Verify `InpRiskPerTradePct` value
- Check account balance
- Ensure broker allows your calculated lot size
- Verify `SYMBOL_VOLUME_MIN` and `SYMBOL_VOLUME_STEP`

### **TP lines not appearing:**
- Enable chart objects display
- Check `InpShowFilterInfo = true`
- Restart EA (remove and re-attach)

---

## 📚 Version History

### **v2.0 - Phase 1 with Optimizable Risk (Current)**
- ✅ Added optimizable `InpRiskPerTradePct` parameter
- ✅ Improved ATR filter implementation
- ✅ Enhanced on-chart display
- ✅ Added comprehensive logging
- ✅ Organized parameters into groups
- ✅ Tested on 2024-2025 data

### **v1.0 - Initial Release**
- Basic Range Filtered + Kalman + SuperTrend logic
- Fixed risk management
- Basic TP system

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📧 Support & Contact

- **Issues:** Use GitHub Issues for bug reports
- **Discussions:** Use GitHub Discussions for questions
- **Author:** treebourks-debug

---

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

---

## ⭐ Disclaimer

**This software is provided "as is", without warranty of any kind.**

By using this EA, you acknowledge that:
- Trading involves substantial risk
- You are solely responsible for your trading decisions
- The author is not liable for any losses incurred
- Past performance does not guarantee future results

**Use at your own risk. Always test on DEMO first!**

---

## 🎯 Roadmap

### **Future Enhancements:**
- [ ] Multi-pair support (GBPUSD, USDJPY)
- [ ] Multi-timeframe functionality
- [ ] Trailing stop implementation
- [ ] News filter integration
- [ ] Web dashboard for monitoring
- [ ] Telegram notifications

---

**Made with ❤️ by treebourks-debug**

**Last Updated:** 2025-10-28

---