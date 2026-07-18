# Changelog

## ggadjustedforest 0.1.1

### Changes

- `cumulative = TRUE` with `model_type = "logistic"` or `"coxph"` now
  emits a warning explaining that odds ratios and hazard ratios are
  non-collapsible effect measures. A shifting OR/HR across sequential
  models cannot be cleanly attributed to confounding; cumulative display
  is most interpretable for collapsible measures (risk differences, risk
  ratios). The feature is retained for descriptive and predictive
  modelling contexts.

### Documentation

- Updated vignette and README examples to use the `rotterdam` breast
  cancer dataset (from **survival**) for the Cox model demonstration.
- Installation instructions updated to reflect CRAN availability.
- Long plot titles now wrap automatically to prevent clipping.

## ggadjustedforest 0.1.0

CRAN release: 2026-07-17

### Initial release

- [`gg_adjusted_forest()`](https://kriz98.github.io/ggadjustedforest/reference/gg_adjusted_forest.md):
  main function producing forest plots and tables for unadjusted and
  adjusted exposure effects.
- [`forest_table()`](https://kriz98.github.io/ggadjustedforest/reference/forest_table.md):
  standalone table extraction helper.
- Supports `"logistic"`, `"linear"`, `"poisson"`, and `"coxph"` model
  types.
- Cumulative adjustment mode (`cumulative = TRUE`).
- Optional cluster-robust standard errors via **sandwich** / **lmtest**.
- Optional survey weights.
- `patchwork`-based combined plot + table display.
- S3 `print` and `plot` methods for `ggadjustedforest` objects.
