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
# Install from CRAN
install.packages("ggadjustedforest")

# Or install the development version from GitHub
# install.packages("remotes")
remotes::install_github("kriz98/gg_adjusted_forest")
```

## Quick start

The examples below use the `rotterdam` breast cancer dataset from the **survival**
package (2,982 patients; Rotterdam tumour bank). The research question is whether
hormonal therapy (`hormon`) affects survival, before and after adjusting for age,
tumour size, grade, lymph node involvement, and oestrogen receptor level.

```r
library(ggadjustedforest)
library(dplyr)
data(cancer, package = "survival")

df <- rotterdam |>
  transmute(
    hormon = hormon,   # 1 = hormonal therapy, 0 = none
    age    = age,
    size   = size,     # tumour size (mm)
    grade  = grade,
    nodes  = nodes,    # positive lymph nodes
    er10   = er / 10,  # oestrogen receptor (fmol/10 l)
    death  = death,
    time   = dtime
  ) |>
  tidyr::drop_na()

covariates <- c("age", "size", "grade", "nodes", "er10")

# Cox proportional hazards — unadjusted vs adjusted
result <- gg_adjusted_forest(
  data       = df,
  outcome    = "death",
  exposure   = "hormon",
  covariates = covariates,
  model_type = "coxph",
  time_var   = "time",
  event_var  = "death",
  title      = "Effect of Hormonal Therapy on Survival (Rotterdam)"
)
result$plot
result$table           # tibble of numeric estimates
result$formatted_table # tibble with "HR (lower–upper)" strings

# Cumulative adjustment — watch the estimate evolve as confounders are added
result_cum <- gg_adjusted_forest(
  data       = df,
  outcome    = "death",
  exposure   = "hormon",
  covariates = covariates,
  model_type = "coxph",
  time_var   = "time",
  event_var  = "death",
  cumulative = TRUE,
  cumulative_labels = c(
    "Unadjusted"                       = "Unadjusted",
    "+ age"                            = "+ Age",
    "+ age + size"                     = "+ Tumour size",
    "+ age + size + grade"             = "+ Grade",
    "+ age + size + grade + nodes"     = "+ Lymph nodes",
    "+ age + size + grade + nodes + er10" = "+ Oestrogen receptor"
  ),
  title = "Cumulative Adjustment: Hormonal Therapy on Survival"
)
result_cum$plot

# Multiple outcomes — stack with patchwork (already a dependency)
library(patchwork)
p1 <- gg_adjusted_forest(df, "death", "hormon", covariates,
                          model_type = "coxph", time_var = "time",
                          event_var = "death", title = "Overall survival",
                          show_table = FALSE)$plot
p2 <- gg_adjusted_forest(df, "death", "nodes", covariates[covariates != "nodes"],
                          model_type = "coxph", time_var = "time",
                          event_var = "death", title = "Effect of lymph node burden",
                          show_table = FALSE)$plot
p1 / p2
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
