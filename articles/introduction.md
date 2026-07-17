# Introduction to ggadjustedforest

## Installation

``` r

# Install from CRAN
install.packages("ggadjustedforest")

# Or install the development version from GitHub
# install.packages("remotes")
remotes::install_github("kriz98/gg_adjusted_forest")
```

## Motivation

When building multivariable models for causal inference, there is an
**exposure** of interest for which a causal estimand applies to. The
coefficients for adjusted covariates (confounders) can however be
misinterpreted when presented together with the estimand of interest.
Reporting them can even mislead readers, because confounder coefficients
are not identified under the causal model, and are susceptible to
absorbing collider bias, mediation pathways, and other artefacts
depending on causal structures (Hernán & Robins, *Causal Inference: What
If*, 2020; Westreich & Greenland, *Am J Epidemiol*, 2013).

STROBE guidelines (Vandenbroucke et al., 2007) and recent work on the
**estimand framework** (ICH E9(R1), 2019) both emphasise that reporting
should clearly distinguish the target quantity from nuisance parameters.

`ggadjustedforest` operationalises this principle and fits the models
you specify but **only exposes the coefficient of interest** in both the
plot and the table, hiding confounder estimates by design. We also
provide a cumulative adjustment option, to show the effect of adjustment
and model building during exploratory phases of studies.

------------------------------------------------------------------------

## Data

All examples use `colon_s` from the `finalfit` package — 929 patients
with colon cancer from the North Central Cancer Treatment Group (NCCTG)
trial (Moertel et al., *NEJM* 1990). The research question throughout is
whether having \>4 positive lymph nodes (`node4`) increases the risk of
5-year mortality, before and after adjusting for patient and tumour
characteristics.

``` r

library(ggadjustedforest)
#> ggadjustedforest 0.1.1 -- Forest plots for exposure effects, hiding confounders by design.
#> See `?gg_adjusted_forest` to get started.
library(finalfit)

data(colon_s)
colon_s$died_5yr <- as.integer(colon_s$mort_5yr == "Died")

confounders <- c("age", "sex.factor", "extent.factor", "differ.factor", "surg.factor")
```

------------------------------------------------------------------------

## Basic usage — logistic regression

The pipe-friendly API puts `data` first so the function composes
naturally with `|>`:

``` r

result <- colon_s |>
  gg_adjusted_forest(
    outcome    = "died_5yr",
    exposure   = "node4",
    covariates = confounders,
    model_type = "logistic",
    title      = "Effect of Lymph Node Involvement (>4 nodes) on 5-Year Mortality"
  )
result$table
#> # A tibble: 2 × 6
#>   model      estimate conf.low conf.high  p.value     n
#>   <fct>         <dbl>    <dbl>     <dbl>    <dbl> <int>
#> 1 Unadjusted     3.99     2.94      5.46 1.81e-18   915
#> 2 Adjusted       3.98     2.87      5.55 1.91e-16   876
```

The returned object has three components:

| Component          | Contents                                           |
|--------------------|----------------------------------------------------|
| `$plot`            | Combined forest plot + table (ggplot2 / patchwork) |
| `$table`           | Tibble of numeric estimates                        |
| `$formatted_table` | Tibble with formatted “OR (lower–upper)” strings   |

To render the plot:

``` r

result$plot
```

![](introduction_files/figure-html/plot-logistic-1.png)

------------------------------------------------------------------------

## Cumulative adjustment

When you want to visualise how the effect estimate changes as
confounders are added sequentially — a common presentation in
epidemiological reporting — use `cumulative = TRUE`. Use
`cumulative_labels` to provide human-readable row names:

``` r

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
```

![](introduction_files/figure-html/cumulative-1.png)

The numeric table is available for downstream use:

``` r

result_cum$formatted_table[, c("model", "formatted", "p.value")]
#> # A tibble: 6 × 3
#>   model                    formatted        p.value
#>   <chr>                    <chr>            <chr>  
#> 1 Unadjusted               3.99 (2.94–5.46) <0.001 
#> 2 + Age                    4.07 (2.99–5.58) <0.001 
#> 3 + Sex                    4.07 (2.99–5.59) <0.001 
#> 4 + Extent of spread       4.00 (2.92–5.52) <0.001 
#> 5 + Tumour differentiation 3.89 (2.82–5.40) <0.001 
#> 6 + Time from surgery      3.98 (2.87–5.55) <0.001
```

------------------------------------------------------------------------

## Cox proportional hazards regression

For time-to-event outcomes supply `model_type = "coxph"` along with
`time_var` and `event_var`. This example uses the `rotterdam` breast
cancer dataset from the **survival** package (2,982 primary breast
cancer patients; Rotterdam tumour bank). The exposure of interest is
hormonal therapy (`hormon`), adjusted for age, tumour size, grade,
number of positive lymph nodes, and oestrogen receptor level.

``` r

library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
data(cancer, package = "survival")

df <- rotterdam |>
  transmute(
    hormon = hormon,       # 1 = hormonal therapy, 0 = none
    age    = age,
    size   = size,         # tumour size (mm)
    grade  = grade,        # tumour grade
    nodes  = nodes,        # positive lymph nodes
    er10   = er / 10,      # oestrogen receptor (fmol/10 l)
    death  = death,
    time   = dtime
  ) |>
  tidyr::drop_na()

result_cox <- gg_adjusted_forest(
  data       = df,
  outcome    = "death",
  exposure   = "hormon",
  covariates = c("age", "size", "grade", "nodes", "er10"),
  model_type = "coxph",
  time_var   = "time",
  event_var  = "death",
  title      = "Effect of Hormonal Therapy on Survival (Rotterdam)"
)
result_cox$plot
```

![](introduction_files/figure-html/cox-1.png)

------------------------------------------------------------------------

## Comparing multiple outcomes side-by-side

`ggadjustedforest` intentionally does not provide a built-in
multi-outcome wrapper. Each outcome deserves its own carefully specified
model, and bundling them into a single function call obscures that.
Instead, fit each outcome separately and stack the plots with
`patchwork`, which is already a dependency of `ggadjustedforest`:

``` r

library(patchwork)

colon_s$died_all <- colon_s$status

p_5yr <- gg_adjusted_forest(
  data = colon_s, outcome = "died_5yr", exposure = "node4",
  covariates = confounders, model_type = "logistic",
  title = "5-Year Mortality", show_table = FALSE
)$plot

p_all <- gg_adjusted_forest(
  data = colon_s, outcome = "died_all", exposure = "node4",
  covariates = confounders, model_type = "logistic",
  title = "Death (all follow-up)", show_table = FALSE
)$plot

p_5yr / p_all
```

![](introduction_files/figure-html/multi-patchwork-1.png)

This approach gives full control over each panel — different covariate
sets, model types, or axis scales per outcome. The `/` operator stacks
plots vertically; use `|` for side-by-side.

------------------------------------------------------------------------

## Customising appearance

All the major aesthetic parameters are exposed:

``` r

gg_adjusted_forest(
  data           = colon_s,
  outcome        = "died_5yr",
  exposure       = "node4",
  covariates     = confounders,
  model_type     = "logistic",
  color          = "#2166ac",
  point_size     = 5,
  point_shape    = 18,
  vline_color    = "firebrick",
  vline_linetype = "dotted",
  title          = "Custom aesthetics"
)$plot
```

![](introduction_files/figure-html/custom-1.png)

------------------------------------------------------------------------

## Extracting the table only

Use
[`forest_table()`](https://kriz98.github.io/gg_adjusted_forest/reference/forest_table.md)
when you only need the numbers:

``` r

forest_table(
  data       = colon_s,
  outcome    = "died_5yr",
  exposure   = "node4",
  covariates = confounders,
  model_type = "logistic"
)
#> # A tibble: 2 × 6
#>   model      estimate ci        formatted        p.value     n
#>   <chr>      <chr>    <chr>     <chr>            <chr>   <int>
#> 1 Unadjusted 3.99     2.94–5.46 3.99 (2.94–5.46) <0.001    915
#> 2 Adjusted   3.98     2.87–5.55 3.98 (2.87–5.55) <0.001    876
```

------------------------------------------------------------------------

## References

- Hernán MA, Robins JM (2020). *Causal Inference: What If*. Chapman &
  Hall/CRC.
- Moertel CG et al. (1990). Levamisole and fluorouracil for adjuvant
  therapy of resected colon carcinoma. *N Engl J Med* 322(6): 352–358.
- Vandenbroucke JP et al. (2007). Strengthening the Reporting of
  Observational Studies in Epidemiology (STROBE). *PLoS Med* 4(10):
  e297.
- Westreich D, Greenland S (2013). The table 2 fallacy: presenting and
  interpreting confounder and modifier coefficients. *Am J Epidemiol*
  177(4): 292–298.
- ICH E9(R1) (2019). Statistical Principles for Clinical Trials:
  Addendum on Estimands and Sensitivity Analysis in Clinical Trials. ICH
  Harmonised Guideline.
