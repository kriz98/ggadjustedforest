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
# Install from GitHub (CRAN submission pending)
# install.packages("remotes")
remotes::install_github("kriz98/gg_adjusted_forest")
```

## Quick start

The examples below use `colon_s` from the `finalfit` package — 929 colon
cancer patients from the NCCTG trial. The research question is whether having
>4 positive lymph nodes (`node4`) increases 5-year mortality (`mort_5yr`),
before and after adjusting for patient and tumour characteristics.

```r
library(ggadjustedforest)
library(finalfit)  # for colon_s

data(colon_s)
colon_s$died_5yr <- as.integer(colon_s$mort_5yr == "Died")

confounders <- c("age", "sex.factor", "extent.factor", "differ.factor", "surg.factor")

# Unadjusted vs fully adjusted — pipe-friendly
result <- colon_s |>
  gg_adjusted_forest(
    outcome    = "died_5yr",
    exposure   = "node4",
    covariates = confounders,
    model_type = "logistic",
    title      = "Effect of Lymph Node Involvement on 5-Year Mortality"
  )
result$plot
result$table          # tibble of numeric estimates
result$formatted_table  # tibble with "OR (lower–upper)" strings

# Cumulative adjustment — watch the estimate evolve as confounders are added
result_cum <- gg_adjusted_forest(
  data       = colon_s,
  outcome    = "died_5yr",
  exposure   = "node4",
  covariates = confounders,
  model_type = "logistic",
  cumulative = TRUE,
  cumulative_labels = c(
    "Unadjusted"                                                         = "Unadjusted",
    "+ age"                                                              = "+ Age",
    "+ age + sex.factor"                                                 = "+ Sex",
    "+ age + sex.factor + extent.factor"                                 = "+ Extent of spread",
    "+ age + sex.factor + extent.factor + differ.factor"                 = "+ Tumour differentiation",
    "+ age + sex.factor + extent.factor + differ.factor + surg.factor"   = "+ Time from surgery"
  ),
  title = "Cumulative Adjustment: Lymph Node Involvement on 5-Year Mortality"
)
result_cum$plot

# Multiple outcomes — stack with patchwork (already a dependency)
library(patchwork)
p1 <- gg_adjusted_forest(colon_s, "died_5yr", "node4", confounders,
                          model_type = "logistic", title = "5-Year Mortality",
                          show_table = FALSE)$plot
p2 <- gg_adjusted_forest(colon_s, "status",   "node4", confounders,
                          model_type = "logistic", title = "Death (all follow-up)",
                          show_table = FALSE)$plot
p1 / p2

# Cox proportional hazards
cox_result <- gg_adjusted_forest(
  data       = colon_s,
  outcome    = "status",
  exposure   = "node4",
  covariates = confounders,
  model_type = "coxph",
  time_var   = "time.years",
  event_var  = "status",
  title      = "Hazard of Death by Lymph Node Involvement"
)
cox_result$plot
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
