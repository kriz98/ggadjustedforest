#' Extract a formatted effect-size table without generating a plot
#'
#' A convenience wrapper around `gg_adjusted_forest()` that returns only the
#' formatted table. Useful when you want numeric summaries without producing a
#' graphic.
#'
#' @inheritParams gg_adjusted_forest
#'
#' @return A data frame with columns:
#'   \describe{
#'     \item{`model`}{Row label (e.g., "Unadjusted", "Adjusted").}
#'     \item{`estimate`}{Point estimate (formatted character).}
#'     \item{`ci`}{Confidence interval as a character string (e.g.,
#'       `"0.95–1.42"`).}
#'     \item{`formatted`}{Combined estimate and CI (e.g.,
#'       `"1.15 (0.95–1.42)"`).}
#'     \item{`p.value`}{Formatted p-value character string.}
#'     \item{`n`}{Number of observations.}
#'   }
#'
#' @export
#'
#' @examples
#' data(mtcars)
#' mtcars$am <- as.integer(mtcars$am)
#' forest_table(
#'   data       = mtcars,
#'   outcome    = "am",
#'   exposure   = "hp",
#'   covariates = c("wt", "cyl"),
#'   model_type = "logistic"
#' )
forest_table <- function(
    data,
    outcome,
    exposure,
    covariates        = NULL,
    model_type        = "logistic",
    cumulative        = FALSE,
    cumulative_labels = NULL,
    conf_level        = 0.95,
    time_var          = NULL,
    event_var         = NULL,
    strata            = NULL,
    cluster           = NULL,
    weights           = NULL,
    table_digits      = 2
) {
  result <- gg_adjusted_forest(
    data              = data,
    outcome           = outcome,
    exposure          = exposure,
    covariates        = covariates,
    model_type        = model_type,
    cumulative        = cumulative,
    cumulative_labels = cumulative_labels,
    conf_level        = conf_level,
    time_var          = time_var,
    event_var         = event_var,
    strata            = strata,
    cluster           = cluster,
    weights           = weights,
    show_table        = FALSE,
    table_digits      = table_digits
  )
  result$formatted_table
}
