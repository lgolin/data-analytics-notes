# PRACTICAL EXAM — ANSWER TEMPLATE

**Name:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ **Student ID:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ **Date:** Tuesday 5 May 2026 **Module:** STAT9005 Time Series Analysis **Lecturer:** Francisco Hernández

> **How to use this skeleton in the exam**
>
> Open this in Word at the start of the exam. Each section below tells you what to paste from RStudio and what sentence(s) to write underneath. Replace the bracketed `[...]` placeholders with your actual results. Delete any section that is not asked.

------------------------------------------------------------------------

## QUESTION 1 — Simulation

### 1.1 Generate the process

``` r
set.seed(123)
sim <- arima.sim(list(ar = c(...)), n = 200)   # or list(ma = c(...))
autoplot(sim)
```

**\[Paste the time-series plot here\]**

**Interpretation:** The simulated series shows \[a constant mean / drifting mean\] around \[value\], with \[constant / changing\] variance. Visually it looks \[stationary / non-stationary\].

### 1.2 Identify the process from correlograms

``` r
acf2(sim)
```

**\[Paste ACF and PACF plots here\]**

**Interpretation:** The ACF \[decays slowly / cuts off after lag k\]; the PACF \[decays slowly / cuts off after lag k\]. By the AR/MA identification rules:

- If ACF cuts off and PACF decays → **MA(k)**
- If PACF cuts off and ACF decays → **AR(k)**
- If both decay → **ARMA(1,1)**

Therefore the underlying process is **\[AR(?) / MA(?) / ARMA(?,?)\]**.

### 1.3 Confirm with auto.arima

``` r
auto.arima(sim)
```

**\[Paste output here\]**

**Interpretation:** `auto.arima()` returns ARIMA(\[p\],\[d\],\[q\]), which \[matches / does not match\] my visual identification. If different, the auto result is preferred because it is selected by AIC.

------------------------------------------------------------------------

## QUESTION 2 — Data Analysis

### 2.1 Load the dataset and confirm format

``` r
AP <- ...                       # the dataset given in the exam
class(AP)                       # must be "ts"
start(AP); end(AP); frequency(AP)
summary(AP)
```

**\[Paste output here\]**

**Interpretation:** The dataset runs from \[start\] to \[end\] with periodicity p = \[12 / 4 / ...\]. Mean = \[...\], min = \[...\], max = \[...\].

------------------------------------------------------------------------

### 2.2 Plot the series

``` r
autoplot(AP) + ggtitle("...")
```

**\[Paste plot here\]**

**Interpretation:** From the plot I can observe:

- **Trend:** \[increasing / decreasing / no clear trend\]
- **Seasonality:** \[present / absent\], with period \[p\]
- **Variance:** \[constant / increasing with the level\]

This suggests we will need \[d=1 / log + d=1 / d=1 + D=1 / etc.\].

------------------------------------------------------------------------

### 2.3 Initial correlogram

``` r
acf2(AP)
```

**\[Paste correlograms here\]**

**Interpretation:** The ACF shows \[slow decay / spikes at lags 12, 24, 36\], confirming the \[trend / seasonal\] component seen in the plot.

------------------------------------------------------------------------

### 2.4 Decomposition

``` r
autoplot(decompose(AP, "additive"))
autoplot(decompose(AP, "multiplicative"))
```

**\[Paste both decompositions here\]**

**Interpretation:** The \[additive / multiplicative\] decomposition produces more random-looking residuals, so it is the better fit. This suggests the seasonal amplitude is \[constant / proportional to the level\], which means we \[do not / do\] need to take logs.

------------------------------------------------------------------------

### 2.5 Classical (Holt-Winters) models

``` r
ets(AP)
fcast_add <- hw(AP, seasonal = "additive",       h = 2*p)
fcast_mul <- hw(AP, seasonal = "multiplicative", h = 2*p)
accuracy(fcast_add); accuracy(fcast_mul)
```

**\[Paste accuracy table here\]**

**Interpretation:** `ets()` selects \[model code\]. Comparing the additive and multiplicative Holt-Winters by RMSE: additive = \[...\], multiplicative = \[...\]. The \[additive / multiplicative\] model has the lower error and is preferred.

------------------------------------------------------------------------

### 2.6 Stationarity tests on the original series

``` r
adf.test(AP, alternative = "stationary")
kpss.test(AP)
```

**\[Paste both outputs here\]**

**Interpretation:**

- **ADF test:** H₀ = non-stationary. p-value = \[...\]. Since p \[\< / \>\] 0.05, we \[reject / fail to reject\] H₀ → series is \[stationary / non-stationary\] in the mean.
- **KPSS test:** H₀ = stationary. p-value = \[...\]. Since p \[\< / \>\] 0.05, we \[reject / fail to reject\] H₀ → series is \[stationary / non-stationary\] in the mean.

The two tests focus on the mean only; the correlogram still shows seasonal spikes, so we still need to address seasonality.

------------------------------------------------------------------------

### 2.7 Transformations

#### Step 1 — Stabilise variance with log

``` r
logAP <- log(AP)
autoplot(logAP)
```

**\[Paste plot here\]**

**Interpretation:** The log series shows \[more / no\] improvement in variance compared with the original. Therefore I \[will / will not\] use the log transformation.

#### Step 2 — Remove trend (first difference, d = 1)

``` r
dAP <- diff(AP)              # or diff(logAP) if log was needed
autoplot(dAP)
adf.test(dAP); kpss.test(dAP)
```

**\[Paste plot and tests here\]**

**Interpretation:** After first differencing, the mean is \[now constant / still drifting\]. ADF p-value = \[...\], KPSS p-value = \[...\] — both confirm stationarity in the mean. → **d = 1**.

#### Step 3 — Remove seasonality (seasonal difference, D = 1)

``` r
DdAP <- diff(dAP, lag = p, differences = 1)
autoplot(DdAP)
acf2(DdAP)
```

**\[Paste plot and correlograms here\]**

**Interpretation:** After seasonal differencing at lag p = \[...\], the seasonal spikes have disappeared from the correlogram and the series now looks like white noise. → **D = 1**.

------------------------------------------------------------------------

### 2.8 Identify model orders (p, q) and (P, Q)

**\[Paste final acf2 here\]**

**Interpretation:**

- **Normal part (lags 1, 2, …):** ACF \[behaviour\], PACF \[behaviour\] → suggests \[AR(?) / MA(?) / ARMA(?,?)\] → **p = \[...\], q = \[...\]**
- **Seasonal part (lags p, 2p, …):** ACF \[behaviour\], PACF \[behaviour\] → suggests \[SAR(?) / SMA(?)\] → **P = \[...\], Q = \[...\]**

Two plausible options visible: \[list them\]. I select **SARIMA(\[p\],\[d\],\[q\])(\[P\],\[D\],\[Q\])\[s\]** because \[reason — e.g., the PACF cut-off at lag 1 is sharper than the ACF cut-off\].

------------------------------------------------------------------------

### 2.9 Fit with auto.arima

``` r
fit_auto <- auto.arima(AP)        # or auto.arima(log(AP))
fit_auto
```

**\[Paste output here\]**

**Interpretation:** `auto.arima()` selects ARIMA(\[p\],\[d\],\[q\])(\[P\],\[D\],\[Q\])\[s\] using AIC. This \[confirms / differs from\] my manual identification. The coefficients are: \[list θ, Θ, φ, Φ values with their standard errors\].

------------------------------------------------------------------------

### 2.10 Residual diagnostics

``` r
checkresiduals(fit_auto)
sarima(AP, p, d, q, P, D, Q, S = p)   # use the orders from auto.arima
```

**\[Paste both diagnostic plots here\]**

**Interpretation:**

- **Residual time plot:** scattered randomly around zero with no obvious pattern ✓
- **Residual ACF:** all spikes within the blue band ✓ → no remaining autocorrelation
- **Histogram / Q-Q plot:** roughly bell-shaped, points close to the diagonal ✓ → residuals approximately normal
- **Ljung-Box test:** p-value = \[...\]. Since p \> 0.05, we fail to reject H₀ (residuals are independent) ✓
- **Ljung-Box dots in `sarima()`:** all dots are above the blue line ✓

The model passes all diagnostic checks and is **accepted**.

------------------------------------------------------------------------

### 2.11 Forecast (h = 2 × p)

``` r
fore <- forecast(fit_auto, h = 2 * p)
fore
plot(fore)
```

**\[Paste forecast plot and table here\]**

**Interpretation:** The forecast for the next \[2p\] periods continues the existing trend and seasonal pattern. The 80% and 95% prediction intervals widen with the forecast horizon, reflecting growing uncertainty further ahead. The point forecast at horizon h = \[...\] is \[...\] with a 95% interval of \[lower, upper\].

*If log was used:* All values were back-transformed with `exp()` to return to the original scale.

------------------------------------------------------------------------

## Final declaration (REQUIRED on submission)

> "The work submitted is my own. I have not obtained unfair assistance via use of the internet or a third party in the completion of this examination. I confirm that I have read and understood the instructions and the policy concerning academic honesty."

**Signed:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ **Date:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

------------------------------------------------------------------------

## Submission checklist (last 5 minutes)

- [ ] Word doc saved (Ctrl+S)
- [ ] Word doc exported to **PDF** (File → Export → PDF)
- [ ] PDF + the `.R` script uploaded to Canvas
- [ ] Submission confirmed (check the green tick on Canvas)
- [ ] Camera was on the entire time
