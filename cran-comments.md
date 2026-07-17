## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

- macOS (aarch64-apple-darwin), R 4.4.x (local)
- win-builder (R-devel)

## Resubmission

This is a resubmission of ggadjustedforest (v0.1.1). Changes since v0.1.0:

- All examples updated to use the `rotterdam` breast cancer dataset (survival
  package) instead of the built-in `mtcars` dataset.
- Added a runtime warning when `cumulative = TRUE` is used with `model_type =
  "logistic"` or `"coxph"`, informing users that odds ratios and hazard ratios
  are non-collapsible effect measures and that sequential changes in the
  coefficient should not be attributed solely to confounding.
- Vignette extended with a collapsibility table and literature references
  (Greenland 1987; Hernán 2010).
- `finalfit` removed from Suggests (no longer used); `tidyr` added to Suggests
  (used in vignette and README examples via `tidyr::drop_na()`).
- Minor documentation fixes (typos, `colour` alias documented).
