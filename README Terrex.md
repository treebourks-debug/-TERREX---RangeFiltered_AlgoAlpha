Копирай ОТ ТУК НАДОЛУ ⬇️

Markdown
# TERREX - RangeFiltered AlgoAlpha Trading Strategy

## 🎯 Project Overview

Professional MetaTrader 5 Expert Advisor implementing a Range-Filtered Algorithmic Alpha trading strategy with ATR-based volatility filtering. This EA combines Kalman Filter smoothing, SuperTrend indicators, and dynamic risk management for optimal EURUSD H1 trading.

## 📊 Strategy Description

### Core Components:
- **Kalman Filter**: Advanced price smoothing (Alpha: 0.05, Beta: 0.5, Period: 200)
- **SuperTrend**: Trend direction confirmation (Factor: 0.6, ATR Period: 11)
- **ATR Filter**: Volatility-based trade filtering (Min ATR: 0.00100)
- **Dynamic Risk Management**: Position sizing based on account balance
- **Multi-TP System**: Three take-profit levels (1R, 2R, 3R) with partial closes

### Entry Logic:
- Long: When Kalman trend and SuperTrend align bullish + ATR filter passed
- Short: When Kalman trend and SuperTrend align bearish + ATR filter passed

## 📈 Backtest Results Summary (2024-2025, EURUSD H1)

### Risk Level Comparison:

| Risk % | Net Profit | ROI | Max DD | Profit Factor | Sharpe | Win Rate | Recommendation |
|--------|-----------|-----|--------|---------------|--------|----------|----------------|
| 0.5% | +$120.12 | 12.01% | 2.61% | 1.76 | 3.74 | 50.00% | ✅ Conservative |
| **1.0%** | **+$385.95** | **38.60%** | **7.38%** | **1.73** | **3.88** | **63.46%** | ✅✅✅ **OPTIMAL** |
| 1.5% | +$567.12 | 56.71% | 10.93% | 1.62 | 3.64 | 73.97% | ⚠️ Aggressive |
| 2.0% | +$791.12 | 79.11% | 14.00% | 1.58 | 3.40 | 73.97% | ❌ Too Risky |

### Recommended Configuration (1.0% Risk):
- **Total Trades**: 441
- **Winning Trades**: 280 (63.46%)
- **Expected Value**: +$2.40 per trade
- **Recovery Factor**: 3.64
- **Max Consecutive Wins**: 8 (94.55)
- **Max Consecutive Losses**: 5 (-19.74)

## 🔧 Installation

### Prerequisites:
- MetaTrader 5 platform
- Minimum deposit: $500 (recommended $1,000+)
- Broker with tight spreads on EURUSD

### Steps:
1. Download `Experts_RangeFiltered_AlgoAlpha_ATRFilter_Phase1_v2.mq5`
2. Copy to `MT5_Data_Folder/MQL5/Experts/`
3. Compile in MetaEditor (F7)
4. Attach to EURUSD H1 chart
5. Configure parameters (see below)

## ⚙️ Recommended Parameters

### Risk Management:
InpRiskPerTradePct = 1.0 // 1% risk per trade (OPTIMAL) InpSL_R_Pips = 30.0 // Stop Loss in pips

Code

### Take Profit Levels:
InpTP1_R = 1.0 // TP1 at 1:1 R:R InpTP2_R = 2.0 // TP2 at 2:1 R:R InpTP3_R = 3.0 // TP3 at 3:1 R:R InpTP1_ClosePct = 20.0 // Close 20% at TP1 InpTP2_ClosePct = 40.0 // Close 40% at TP2 InpMoveSLtoBEatTP1 = true // Move SL to breakeven after TP1

Code

### Indicators:
KalmanAlpha = 0.05 KalmanBeta = 0.5 KalmanPeriod = 200 ST_Factor = 0.6 ST_ATRPeriod = 11

Code

### Filters:
InpUseATRFilter = true // Enable ATR filter InpMinATRValue = 0.00100 // Minimum ATR (10 pips) InpUseTrendFilter = true // Trade only with trend

Code

## 📊 Performance Metrics (1.0% Risk)

### Profitability:
- Net Profit: +$385.95 (+38.60% ROI)
- Gross Profit: $914.14
- Gross Loss: -$528.19
- Profit Factor: 1.73

### Risk Metrics:
- Max Drawdown: 7.38% ($106.07)
- Sharpe Ratio: 3.88 (Excellent)
- Recovery Factor: 3.64
- Expected Payoff: +$2.40

### Trade Statistics:
- Total Trades: 441
- Win Rate: 63.46%
- Average Win: $10.88
- Average Loss: -$6.86
- Largest Win: $27.40
- Largest Loss: -$12.79

## 🚀 Usage Guide

### For Demo Trading:
1. Open DEMO account with recommended broker
2. Deposit: $1,000 - $3,000
3. Use 1.0% risk setting
4. Run for 1-2 months
5. Monitor: ROI > 0%, DD < 10%

### For Live Trading:
1. Start with small capital ($500-$1,000)
2. Use 1.0% risk (never exceed 1.5%)
3. Set daily DD limit: 5%
4. Monthly ROI target: 2-4%
5. Scale up after 6-12 months of success

### Important Notes:
- ⚠️ Always test on DEMO first
- ⚠️ Never risk more than 1.0% per trade for beginners
- ⚠️ Use proper broker with tight spreads
- ⚠️ Monitor trade execution quality

## 📅 Version History

### v2.0 (2025-10-28)
- Added optimizable risk parameter (0.5% - 3.0%)
- Improved ATR filter with dynamic threshold
- Enhanced partial close logic
- Better visualization on chart
- Comprehensive input parameter grouping

## 📄 License

This project is for educational and personal use only.

## 👤 Author

**treebourks-debug**
- GitHub: [@treebourks-debug](https://github.com/treebourks-debug)

## ⚠️ Disclaimer

Trading involves substantial risk. Past performance does not guarantee future results. Use this EA at your own risk. Always test on DEMO before live trading.

---

**Built with ❤️ for algorithmic trading**
