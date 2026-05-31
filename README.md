# ggadjustedforest

<!-- badges: start -->
<!-- badges: end -->

**ggadjustedforest** creates publication-quality forest plots and effect-size
tables that display *only* the unadjusted and adjusted estimates for a
user-specified exposure variable of interest — hiding confounder coefficients
by design, in accordance with causal inference principles (the "Table 2
fallacy", Westreich & Greenland 2013).

## Motivation

When the estimand of interest is the effect of a single exposure variable,
reporting confounder coefficients alongside it is misleading: those
coefficients are not identified under the causal model and depend on the full
causal structure. `ggadjustedforest` makes it easy to present the exposure
effect cleanly, before and after adjustment.

## Installation

```r
# Install from local source (CRAN submission pending)
install.packages("path/to/ggadjustedforest", repos = NULL, type = "source")
```

## Quick start

```r
library(ggadjustedforest)

data(mtcars)
mtcars$am <- as.integer(mtcars$am)

# Non-cumulative: Unadjusted vs Adjusted
result <- gg_adjusted_forest(
  data       = mtcars,
  outcome    = "am",
  exposure   = "hp",
  covariates = c("wt", "cyl"),
  model_type = "logistic",
  title      = "Effect of Horsepower on Transmission Type"
)
result$plot
result$table

# Cumulative adjustment
result_cum <- gg_adjusted_forest(
  data       = mtcars,
  outcome    = "am",
  exposure   = "hp",
  covariates = c("wt", "cyl", "disp"),
  cumulative = TRUE
)
result_cum$plot

# Table only
forest_table(
  data       = mtcars,
  outcome    = "am",
  exposure   = "hp",
  covariates = c("wt", "cyl"),
  model_type = "logistic"
)
```

## Supported model types

| `model_type` | Underlying function | Effect measure |
|---|---|---|
| `"logistic"` | `stats::glm(..., family = binomial())` | Odds ratio |
| `"linear"` | `stats::lm()` | Coefficient |
| `"poisson"` | `stats::glm(..., family = poisson())` | Risk ratio |
| `"coxph"` | `survival::coxph()` | Hazard ratio |

## References

- Westreich D, Greenland S (2013). The table 2 fallacy. *Am J Epidemiol*
  177(4): 292–298.
- Hernán MA, Robins JM (2020). *Causal Inference: What If*. Chapman & Hall/CRC.
- ICH E9(R1) (2019). Addendum on Estimands.

## License

MIT + file LICENSE
