# ggadjustedforest 0.1.1

## Documentation

* Updated vignette and README examples to use the `rotterdam` breast cancer
  dataset (from **survival**) for the Cox model demonstration.
* Installation instructions updated to reflect CRAN availability.
* Long plot titles now wrap automatically to prevent clipping.

# ggadjustedforest 0.1.0

## Initial release

* `gg_adjusted_forest()`: main function producing forest plots and tables for
  unadjusted and adjusted exposure effects.
* `forest_table()`: standalone table extraction helper.
* Supports `"logistic"`, `"linear"`, `"poisson"`, and `"coxph"` model types.
* Cumulative adjustment mode (`cumulative = TRUE`).
* Optional cluster-robust standard errors via **sandwich** / **lmtest**.
* Optional survey weights.
* `patchwork`-based combined plot + table display.
* S3 `print` and `plot` methods for `ggadjustedforest` objects.
