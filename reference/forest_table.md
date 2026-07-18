# Extract a formatted effect-size table without generating a plot

A convenience wrapper around
[`gg_adjusted_forest()`](https://kriz98.github.io/ggadjustedforest/reference/gg_adjusted_forest.md)
that returns only the formatted table. Useful when you want numeric
summaries without producing a graphic.

## Usage

``` r
forest_table(
  data,
  outcome,
  exposure,
  covariates = NULL,
  model_type = "logistic",
  cumulative = FALSE,
  cumulative_labels = NULL,
  conf_level = 0.95,
  time_var = NULL,
  event_var = NULL,
  strata = NULL,
  cluster = NULL,
  weights = NULL,
  table_digits = 2
)
```

## Arguments

- data:

  A data frame containing all variables.

- outcome:

  Character string. Name of the outcome variable (ignored for Cox
  models - use `time_var` and `event_var` instead).

- exposure:

  Character string. Name of the exposure variable of interest.

- covariates:

  Character vector of confounder/covariate names. In non-cumulative mode
  all covariates are added together; in cumulative mode they are added
  one at a time in the order supplied. Default `NULL` produces only the
  unadjusted estimate.

- model_type:

  Character. One of `"logistic"` (default), `"linear"`, `"poisson"`, or
  `"coxph"`.

- cumulative:

  Logical. If `TRUE`, fit models that progressively add one covariate at
  a time and show each step as a separate row. Default `FALSE`.

  **Important:** Odds ratios (`"logistic"`) and hazard ratios
  (`"coxph"`) are **non-collapsible** effect measures. This means the
  exposure coefficient will change as covariates are added even in the
  complete absence of confounding, because adding covariates reduces
  residual variance on the latent scale. Consequently, a shifting OR or
  HR across sequential models cannot be cleanly attributed to
  confounding. For causal inference, the unadjusted vs. fully-adjusted
  comparison (the default) is preferred. Cumulative display is most
  interpretable for collapsible measures: risk differences (`"linear"`)
  and risk ratios (`"poisson"`).

- cumulative_labels:

  Optional named character vector to rename the cumulative model labels.
  Names should match the auto-generated labels (e.g., `"+ age"`,
  `"+ age + sex"`); values are the replacement labels.

- conf_level:

  Numeric. Confidence level for intervals. Default `0.95`.

- time_var:

  Character. Name of the time variable (Cox model only).

- event_var:

  Character. Name of the event indicator variable (Cox model only;
  should be 0/1 or logical).

- strata:

  Character. Name of a stratification variable for Cox models. Default
  `NULL`.

- cluster:

  Character. Name of a clustering variable for cluster-robust standard
  errors. Requires the sandwich and lmtest packages. Default `NULL`.

- weights:

  Character. Name of a survey/frequency weight variable. Default `NULL`.

- table_digits:

  Integer. Number of decimal places in the table. Default `2`.

## Value

A data frame with columns:

- `model`:

  Row label (e.g., "Unadjusted", "Adjusted").

- `estimate`:

  Point estimate (formatted character).

- `ci`:

  Confidence interval as a character string (e.g., `"0.95–1.42"`).

- `formatted`:

  Combined estimate and CI (e.g., `"1.15 (0.95–1.42)"`).

- `p.value`:

  Formatted p-value character string.

- `n`:

  Number of observations.

## Examples

``` r
data(mtcars)
mtcars$am <- as.integer(mtcars$am)
forest_table(
  data       = mtcars,
  outcome    = "am",
  exposure   = "hp",
  covariates = c("wt", "cyl"),
  model_type = "logistic"
)
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
#> # A tibble: 2 × 6
#>   model      estimate ci        formatted        p.value     n
#>   <chr>      <chr>    <chr>     <chr>            <chr>   <int>
#> 1 Unadjusted 0.99     0.98–1.00 0.99 (0.98–1.00) 0.181      32
#> 2 Adjusted   1.03     1.00–1.09 1.03 (1.00–1.09) 0.084      32
```
