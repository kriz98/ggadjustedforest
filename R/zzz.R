## Suppress R CMD check NOTEs for .data and stats::ave
## The .data pronoun is used in aes() calls within ggplot2 pipelines.
#' @importFrom rlang .data
#' @importFrom stats ave nobs as.formula glm lm qnorm
NULL

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "ggadjustedforest ", utils::packageVersion("ggadjustedforest"),
    " -- Forest plots for exposure effects, hiding confounders by design.\n",
    "See `?gg_adjusted_forest` to get started."
  )
}
