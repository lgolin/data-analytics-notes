# =============================================================================
# STAT9005 — PRACTICAL EXAM TEMPLATE
# Time Series & ARIMA Analysis
# Based on Francisco's walkthrough (Zoom, 27 April) using USAccDeaths
# =============================================================================
# HOW TO USE:
#   1. Replace the dataset (AP <- ...) with whatever the exam gives you.
#   2. Replace the periodicity p (12 monthly, 4 quarterly, etc.).
#   3. Run section by section. Copy each plot/output into the Word answer doc.
#   4. WRITE INTERPRETATION under every output. R only gives numbers/plots —
#      you must explain what they mean for full marks.
# =============================================================================


# -----------------------------------------------------------------------------
# 0. LIBRARIES
# -----------------------------------------------------------------------------
library(tseries)    # adf.test, kpss.test
library(forecast)   # auto.arima, ets, hw, autoplot, checkresiduals
library(astsa)      # acf2, sarima, sarima.for
library(ggplot2)


# -----------------------------------------------------------------------------
# 1. LOAD AND INSPECT THE DATASET
# -----------------------------------------------------------------------------
# If a built-in dataset:
AP <- USAccDeaths              # <-- REPLACE with the exam dataset
p  <- 12                       # <-- REPLACE periodicity (12=monthly, 4=quarterly)

# If reading from a file (e.g. CSV or TXT):
# raw <- read.csv("filename.csv", header = TRUE)
# AP  <- ts(raw$column_name, start = c(YYYY, M), frequency = p)

class(AP)                      # MUST return "ts" — confirm time-series format
start(AP); end(AP); frequency(AP)
summary(AP)


# -----------------------------------------------------------------------------
# 2. DESCRIPTIVE / VISUAL ANALYSIS
# -----------------------------------------------------------------------------
# Plot the series — look for: trend, seasonality, changing variance
autoplot(AP) + ggtitle("Time Series Plot")

# Initial correlogram — confirms what the eye sees
acf2(AP)
# INTERPRET:
#  - Slow decay in ACF  -> trend or long memory  -> need differencing (d=1)
#  - Spikes at p, 2p, 3p -> seasonality -> need seasonal differencing (D=1)


# -----------------------------------------------------------------------------
# 3. DECOMPOSITION (additive vs multiplicative)
# -----------------------------------------------------------------------------
# Additive:   Y = Trend + Seasonal + Residual    (constant seasonal amplitude)
# Multiplic:  Y = Trend * Seasonal * Residual    (amplitude grows with level)

dA  <- decompose(AP, type = "additive")
dAm <- decompose(AP, type = "multiplicative")
autoplot(dA)  + ggtitle("Additive decomposition")
autoplot(dAm) + ggtitle("Multiplicative decomposition")
# INTERPRET:
#  - Compare the residual panels. The decomposition with the more
#    random-looking residuals is the better fit.
#  - If multiplicative is better -> consider taking log later.


# -----------------------------------------------------------------------------
# 4. EXPONENTIAL SMOOTHING (CLASSICAL MODELS)
# -----------------------------------------------------------------------------
# ets() = "auto.arima for classical models"
ets(AP)                 # tells you (Error, Trend, Seasonal): A=additive, M=mult, N=none
autoplot(ets(AP))

# Holt-Winters forecasts (h = 2*p means 2 full cycles ahead)
fcast_add <- hw(AP, seasonal = "additive",       h = 2 * p)
fcast_mul <- hw(AP, seasonal = "multiplicative", h = 2 * p)

plot(fcast_add); plot(fcast_mul)
accuracy(fcast_add)     # RMSE, MAE, MAPE — lower is better
accuracy(fcast_mul)
# INTERPRET: pick the model with the LOWER error metrics.


# -----------------------------------------------------------------------------
# 5. STATIONARITY TESTS — THREE CONDITIONS
# -----------------------------------------------------------------------------
# Stationarity requires:
#   (1) Constant mean       -> fixed by differencing (d=1)  [ARIMA handles]
#   (2) Constant variance   -> fixed by log()      [ARIMA does NOT handle - help it!]
#   (3) Constant covariance -> fixed by seasonal differencing (D=1)

# ADF test: H0 = NOT stationary   -> small p-value (<0.05) means STATIONARY
adf.test(AP, alternative = "stationary")

# KPSS test: H0 = stationary       -> large p-value (>0.05) means STATIONARY
kpss.test(AP)

# Note from Francisco: these tests focus on the MEAN (trend).
# They can say "stationary" even when there is a covariance/seasonality problem.
# Always combine with the plot + correlogram.


# -----------------------------------------------------------------------------
# 6. TRANSFORMATIONS — IN ORDER
# -----------------------------------------------------------------------------
# RULE: always check VARIANCE first. ARIMA cannot fix variance — only log can.

## (a) Stabilise variance with log
logAP <- log(AP)
autoplot(AP)    + ggtitle("Original")
autoplot(logAP) + ggtitle("log()")
# INTERPRET: if the log version has more constant amplitude, USE log(AP).
#            if no improvement, skip the log.

## (b) Remove trend — first difference: Y_t - Y_{t-1}  -> sets d = 1
dAP <- diff(AP)                        # use diff(logAP) instead if log was needed
autoplot(dAP) + ggtitle("First difference (d=1)")
autoplot(decompose(dAP))
adf.test(dAP, alternative = "stationary")
kpss.test(dAP)
acf2(dAP)

## (c) Remove seasonality — seasonal difference at lag p: Y_t - Y_{t-p} -> D = 1
DSAP <- diff(AP, lag = p, differences = 1)
autoplot(DSAP) + ggtitle("Seasonal difference (D=1)")
autoplot(decompose(DSAP))
adf.test(DSAP, alternative = "stationary")
acf2(DSAP)

## (d) Remove BOTH trend and seasonality
dAP   <- diff(AP)                                  # d = 1
DdAP  <- diff(dAP, lag = p, differences = 1)       # D = 1
autoplot(DdAP) + ggtitle("Trend + Seasonal differenced")
autoplot(decompose(DdAP))
adf.test(DdAP, alternative = "stationary")
kpss.test(DdAP)
acf2(DdAP)
# GOAL: a "white-noise looking" series — flat mean, constant variance,
# no obvious pattern in the correlograms.


# -----------------------------------------------------------------------------
# 7. IDENTIFY (p, q) and (P, Q) FROM CORRELOGRAMS
# -----------------------------------------------------------------------------
acf2(DdAP)   # final correlograms of the stationary series
# RULES (apply to both NORMAL part lags 1..p-1 AND SEASONAL part at lags p, 2p, 3p)
#
#   ACF drops sharp after lag k  AND  PACF tails off slowly  -> MA(k)   (q = k)
#   ACF tails off slowly         AND  PACF drops sharp at k  -> AR(k)   (p = k)
#   Both tail off slowly                                     -> ARMA(1,1)
#
# In the exam: if multiple options are visible, PICK ONE and JUSTIFY it.


# -----------------------------------------------------------------------------
# 8. FIT THE MODEL — AUTO.ARIMA (Francisco said USE THIS in the exam, time is tight)
# -----------------------------------------------------------------------------
# If variance was a problem -> auto.arima(log(AP)).  Otherwise auto.arima(AP).
fit_auto     <- auto.arima(AP)
fit_auto_log <- auto.arima(log(AP))   # only if log was needed
fit_auto
# Output reads as: ARIMA(p,d,q)(P,D,Q)[s]   <- this is your model order


# -----------------------------------------------------------------------------
# 9. RESIDUAL DIAGNOSTICS — THE MODEL MUST PASS THESE
# -----------------------------------------------------------------------------
# Residuals must be: random, normally distributed, uncorrelated (independent)

checkresiduals(fit_auto)
# Look for:
#   - Top plot:    residuals scattered randomly around zero (no pattern)
#   - ACF plot:    no significant spikes (all bars inside the blue band)
#   - Histogram:   bell-shaped, fits the normal curve
#   - Ljung-Box test: H0 = independent residuals
#                    p-value > 0.05  ->  GOOD (residuals are independent)

# sarima() gives extra diagnostics — same model, more detail:
# Replace with YOUR identified order:
sarima(AP, p = 0, d = 1, q = 1, P = 0, D = 1, Q = 1, S = p)
# The 4 diagnostic plots:
#   1. Standardised residuals -> should look random
#   2. ACF of residuals       -> all spikes inside blue band
#   3. Normal Q-Q plot        -> points follow the diagonal
#   4. Ljung-Box p-values     -> ALL DOTS ABOVE the blue line (p > 0.05)


# -----------------------------------------------------------------------------
# 10. FORECAST
# -----------------------------------------------------------------------------
# h = 2*p forecasts 2 full cycles ahead (e.g. 24 months)
fore <- forecast(fit_auto, h = 2 * p)
fore
plot(fore)
# INTERPRET:
#  - The dark line = point forecast
#  - The shaded bands = 80% (inner) and 95% (outer) prediction intervals
#  - Bands widen with time -> uncertainty grows further into the future

# If you used log: back-transform with exp()
# fore_log <- forecast(fit_auto_log, h = 2*p)
# fore_log$mean  <- exp(fore_log$mean)
# fore_log$lower <- exp(fore_log$lower)
# fore_log$upper <- exp(fore_log$upper)
# plot(fore_log)


# -----------------------------------------------------------------------------
# 11. (QUESTION 1 — SIMULATION — only if asked)
# -----------------------------------------------------------------------------
# arima.sim simulates a series from given AR/MA coefficients
# Always set seed for reproducibility
set.seed(123)

# AR(1):  y_t = phi * y_{t-1} + e_t
ar1 <- arima.sim(list(ar = c(0.6)), n = 200)
autoplot(ar1); acf2(ar1)
# Expected: PACF cuts off at lag 1, ACF decays slowly

# AR(2)
ar2 <- arima.sim(list(ar = c(0.6, 0.2)), n = 200)
autoplot(ar2); acf2(ar2)

# MA(1):  y_t = theta * e_{t-1} + e_t
ma1 <- arima.sim(list(ma = c(0.7)), n = 200)
autoplot(ma1); acf2(ma1)
# Expected: ACF cuts off at lag 1, PACF decays slowly

# MA(2)
ma2 <- arima.sim(list(ma = c(0.7, 0.2)), n = 200)
autoplot(ma2); acf2(ma2)

# Stationarity check for AR: |phi| < 1 (inside the unit circle)
# arima.sim will throw an error if non-stationary.

# =============================================================================
# END OF TEMPLATE
# =============================================================================
