# Forest plot of unadjusted and adjusted effects for a single exposure

Creates a publication-quality forest plot showing only the unadjusted
and adjusted (or cumulatively adjusted) effect estimates for a specified
exposure variable, hiding confounder coefficients in accordance with
causal inference principles.

## Usage

``` r
gg_adjusted_forest(
  data,
  outcome,
  exposure,
  covariates = NULL,
  model_type = "logistic",
  cumulative = FALSE,
  cumulative_labels = NULL,
  effect_label = NULL,
  title = NULL,
  ref_line = NULL,
  point_size = 4,
  point_shape = 15,
  line_size = 0.7,
  color = "black",
  colour = NULL,
  vline_color = "grey50",
  vline_linetype = "dashed",
  x_limits = NULL,
  x_breaks = NULL,
  log_scale = TRUE,
  conf_level = 0.95,
  time_var = NULL,
  event_var = NULL,
  strata = NULL,
  cluster = NULL,
  weights = NULL,
  show_table = TRUE,
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

- effect_label:

  Character. X-axis label. Defaults to `"Odds Ratio (95 \% CI)"` for
  logistic, `"Risk Ratio (95 \% CI)"` for Poisson,
  `"Hazard Ratio (95 \% CI)"` for Cox, and `"Coefficient (95 \% CI)"`
  for linear.

- title:

  Character. Plot title. Default `NULL` (no title).

- ref_line:

  Numeric. Position of the vertical reference line. Defaults to `1` for
  ratio models and `0` for linear.

- point_size:

  Numeric. Size of the point estimate symbol. Default `4`.

- point_shape:

  Integer. ggplot2 shape code. Default `15` (filled square).

- line_size:

  Numeric. Thickness of the CI lines. Default `0.7`.

- color:

  Character. Colour for points and CI lines. Default `"black"`.

- colour:

  Alias for `color` (British English spelling).

- vline_color:

  Character. Colour of the reference line. Default `"grey50"`.

- vline_linetype:

  Character. Linetype of the reference line. Default `"dashed"`.

- x_limits:

  Numeric vector of length 2. Manual x-axis limits. Default `NULL`
  (automatic).

- x_breaks:

  Numeric vector. Manual x-axis break positions. Default `NULL`
  (automatic).

- log_scale:

  Logical. Use log scale on the x-axis for ratio models. Default `TRUE`.

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

- show_table:

  Logical. Combine the forest plot with a formatted table panel (using
  patchwork). Default `TRUE`.

- table_digits:

  Integer. Number of decimal places in the table. Default `2`.

## Value

An object of class `ggadjustedforest` (a list) with components:

- `plot`:

  The combined ggplot2/patchwork plot object. When `show_table = FALSE`
  this is just the forest plot.

- `table`:

  A data frame with columns `model`, `estimate`, `conf.low`,
  `conf.high`, `p.value`, and `n`.

- `formatted_table`:

  A data frame with a `formatted` column containing strings like
  `"1.23 (1.01-1.55)"`.

## Examples

``` r
# Logistic regression example
data(mtcars)
mtcars$am <- as.integer(mtcars$am)   # binary outcome
result <- gg_adjusted_forest(
  data        = mtcars,
  outcome     = "am",
  exposure    = "hp",
  covariates  = c("wt", "cyl"),
  model_type  = "logistic",
  title       = "Effect of Horsepower on Transmission Type"
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
result$table
#> # A tibble: 2 × 6
#>   model      estimate conf.low conf.high p.value     n
#>   <fct>         <dbl>    <dbl>     <dbl>   <dbl> <int>
#> 1 Unadjusted    0.992    0.979      1.00  0.181     32
#> 2 Adjusted      1.03     1.00       1.09  0.0840    32

# Cumulative adjustment
result2 <- gg_adjusted_forest(
  data       = mtcars,
  outcome    = "am",
  exposure   = "hp",
  covariates = c("wt", "cyl"),
  cumulative = TRUE
)
#> Warning: Cumulative adjustment with `model_type = "logistic"` uses a non-collapsible effect measure (odds ratio).
#> The exposure coefficient will change across sequential models even without confounding, because adding covariates reduces residual variance on the latent scale. Changes in the OR/HR cannot be cleanly attributed to confounding. For causal inference, prefer the default unadjusted vs. fully-adjusted display. Cumulative mode is most interpretable for collapsible measures: risk differences (model_type = "linear") or risk ratios (model_type = "poisson").
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
result2$table
#> # A tibble: 3 × 6
#>   model      estimate conf.low conf.high p.value     n
#>   <fct>         <dbl>    <dbl>     <dbl>   <dbl> <int>
#> 1 Unadjusted    0.992    0.979      1.00  0.181     32
#> 2 + wt          1.04     1.01       1.09  0.0409    32
#> 3 + wt + cyl    1.03     1.00       1.09  0.0840    32
```
