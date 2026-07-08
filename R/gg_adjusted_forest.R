#' Forest plot of unadjusted and adjusted effects for a single exposure
#'
#' Creates a publication-quality forest plot showing only the unadjusted and
#' adjusted (or cumulatively adjusted) effect estimates for a specified exposure
#' variable, hiding confounder coefficients in accordance with causal inference
#' principles.
#'
#' @param data A data frame containing all variables.
#' @param outcome Character string. Name of the outcome variable (ignored for
#'   Cox models - use `time_var` and `event_var` instead).
#' @param exposure Character string. Name of the exposure variable of interest.
#' @param covariates Character vector of confounder/covariate names. In
#'   non-cumulative mode all covariates are added together; in cumulative mode
#'   they are added one at a time in the order supplied. Default `NULL` produces
#'   only the unadjusted estimate.
#' @param model_type Character. One of `"logistic"` (default), `"linear"`,
#'   `"poisson"`, or `"coxph"`.
#' @param cumulative Logical. If `TRUE`, fit models that progressively add one
#'   covariate at a time and show each step as a separate row. Default `FALSE`.
#' @param cumulative_labels Optional named character vector to rename the
#'   cumulative model labels. Names should match the auto-generated labels
#'   (e.g., `"+ age"`, `"+ age + sex"`); values are the replacement labels.
#' @param effect_label Character. X-axis label. Defaults to `"Odds Ratio
#'   (95 \% CI)"` for logistic, `"Risk Ratio (95 \% CI)"` for Poisson,
#'   `"Hazard Ratio (95 \% CI)"` for Cox, and `"Coefficient (95 \% CI)"` for
#'   linear.
#' @param title Character. Plot title. Default `NULL` (no title).
#' @param ref_line Numeric. Position of the vertical reference line. Defaults
#'   to `1` for ratio models and `0` for linear.
#' @param point_size Numeric. Size of the point estimate symbol. Default `4`.
#' @param point_shape Integer. ggplot2 shape code. Default `15` (filled square).
#' @param line_size Numeric. Thickness of the CI lines. Default `0.7`.
#' @param color Character. Colour for points and CI lines. Default `"black"`.
#' @param vline_color Character. Colour of the reference line. Default
#'   `"grey50"`.
#' @param vline_linetype Character. Linetype of the reference line. Default
#'   `"dashed"`.
#' @param x_limits Numeric vector of length 2. Manual x-axis limits. Default
#'   `NULL` (automatic).
#' @param x_breaks Numeric vector. Manual x-axis break positions. Default
#'   `NULL` (automatic).
#' @param log_scale Logical. Use log scale on the x-axis for ratio models.
#'   Default `TRUE`.
#' @param conf_level Numeric. Confidence level for intervals. Default `0.95`.
#' @param time_var Character. Name of the time variable (Cox model only).
#' @param event_var Character. Name of the event indicator variable (Cox model
#'   only; should be 0/1 or logical).
#' @param strata Character. Name of a stratification variable for Cox models.
#'   Default `NULL`.
#' @param cluster Character. Name of a clustering variable for cluster-robust
#'   standard errors. Requires the \pkg{sandwich} and \pkg{lmtest} packages.
#'   Default `NULL`.
#' @param weights Character. Name of a survey/frequency weight variable.
#'   Default `NULL`.
#' @param show_table Logical. Combine the forest plot with a formatted table
#'   panel (using \pkg{patchwork}). Default `TRUE`.
#' @param table_digits Integer. Number of decimal places in the table. Default
#'   `2`.
#'
#' @return An object of class `ggadjustedforest` (a list) with components:
#'   \describe{
#'     \item{`plot`}{The combined \pkg{ggplot2}/\pkg{patchwork} plot object.
#'       When `show_table = FALSE` this is just the forest plot.}
#'     \item{`table`}{A data frame with columns `model`, `estimate`,
#'       `conf.low`, `conf.high`, `p.value`, and `n`.}
#'     \item{`formatted_table`}{A data frame with a `formatted` column
#'       containing strings like `"1.23 (1.01-1.55)"`.}
#'   }
#'
#' @export
#'
#' @examples
#' # Logistic regression example
#' data(mtcars)
#' mtcars$am <- as.integer(mtcars$am)   # binary outcome
#' result <- gg_adjusted_forest(
#'   data        = mtcars,
#'   outcome     = "am",
#'   exposure    = "hp",
#'   covariates  = c("wt", "cyl"),
#'   model_type  = "logistic",
#'   title       = "Effect of Horsepower on Transmission Type"
#' )
#' result$table
#'
#' # Cumulative adjustment
#' result2 <- gg_adjusted_forest(
#'   data       = mtcars,
#'   outcome    = "am",
#'   exposure   = "hp",
#'   covariates = c("wt", "cyl"),
#'   cumulative = TRUE
#' )
#' result2$table
gg_adjusted_forest <- function(
    data,
    outcome,
    exposure,
    covariates          = NULL,
    model_type          = "logistic",
    cumulative          = FALSE,
    cumulative_labels   = NULL,
    effect_label        = NULL,
    title               = NULL,
    ref_line            = NULL,
    point_size          = 4,
    point_shape         = 15,
    line_size           = 0.7,
    color               = "black",
    colour              = NULL,
    vline_color         = "grey50",
    vline_linetype      = "dashed",
    x_limits            = NULL,
    x_breaks            = NULL,
    log_scale           = TRUE,
    conf_level          = 0.95,
    time_var            = NULL,
    event_var           = NULL,
    strata              = NULL,
    cluster             = NULL,
    weights             = NULL,
    show_table          = TRUE,
    table_digits        = 2
) {
  # Accept British spelling (ggplot2 convention)
  if (!is.null(colour)) color <- colour

  # --------------------------------------------------------------------------
  # Input validation
  # --------------------------------------------------------------------------
  validate_inputs(data, outcome, exposure, covariates, model_type,
                  time_var, event_var)

  if (!is.logical(cumulative) || length(cumulative) != 1L) {
    rlang::abort("`cumulative` must be a single logical value.", call = NULL)
  }
  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    rlang::abort("`conf_level` must be a number strictly between 0 and 1.",
                 call = NULL)
  }

  # --------------------------------------------------------------------------
  # Default axis label
  # --------------------------------------------------------------------------
  ci_pct <- paste0(round(conf_level * 100), "%")
  if (is.null(effect_label)) {
    effect_label <- switch(
      model_type,
      logistic = paste0("Odds Ratio (", ci_pct, " CI)"),
      poisson  = paste0("Risk Ratio (", ci_pct, " CI)"),
      coxph    = paste0("Hazard Ratio (", ci_pct, " CI)"),
      linear   = paste0("Coefficient (", ci_pct, " CI)")
    )
  }

  # Default reference line
  is_ratio <- model_type %in% c("logistic", "poisson", "coxph")
  if (is.null(ref_line)) {
    ref_line <- if (is_ratio) 1 else 0
  }

  # --------------------------------------------------------------------------
  # Build list of model specifications
  # --------------------------------------------------------------------------
  # Each element: list(label, covs_to_include)
  if (cumulative) {
    steps <- 0:length(covariates)
    specs <- lapply(steps, function(s) {
      list(
        label = build_label(s, covariates, cumulative_labels),
        covs  = if (s == 0L) NULL else covariates[seq_len(s)]
      )
    })
  } else {
    specs <- list(
      list(label = "Unadjusted", covs = NULL),
      list(label = "Adjusted",   covs = covariates)
    )
    # If no covariates supplied, only unadjusted
    if (is.null(covariates)) {
      specs <- list(list(label = "Unadjusted", covs = NULL))
    }
  }

  # --------------------------------------------------------------------------
  # Fit models and extract coefficients
  # --------------------------------------------------------------------------
  results_list <- lapply(specs, function(spec) {
    fit <- fit_model(
      data       = data,
      outcome    = outcome,
      exposure   = exposure,
      covariates = spec$covs,
      model_type = model_type,
      time_var   = time_var,
      event_var  = event_var,
      strata     = strata,
      weights    = weights,
      conf_level = conf_level
    )
    coef_df <- extract_coef(
      fit        = fit,
      exposure   = exposure,
      model_type = model_type,
      cluster    = cluster,
      data       = data,
      conf_level = conf_level
    )
    # For multi-level factors, collapse to one summary row? Keep all levels.
    coef_df$model <- spec$label
    coef_df
  })

  results_df <- dplyr::bind_rows(results_list)

  # Build ordered model factor (reversed for ggplot y-axis top-to-bottom)
  all_labels <- vapply(specs, `[[`, character(1), "label")
  # Expand labels for factor levels when exposure has multiple terms
  expanded_labels <- character(0)
  for (lbl in all_labels) {
    subset_rows <- results_df[results_df$model == lbl, ]
    if (nrow(subset_rows) > 1) {
      expanded_labels <- c(expanded_labels,
                           paste0(lbl, ": ", subset_rows$term))
    } else {
      expanded_labels <- c(expanded_labels, lbl)
    }
  }

  # Flatten: if multiple terms per model label, append term suffix
  results_df$row_label <- ifelse(
    ave(seq_len(nrow(results_df)),
        results_df$model, FUN = length) > 1,
    paste0(results_df$model, ": ", results_df$term),
    results_df$model
  )

  # Factor with correct order (reversed so top of plot = first model)
  results_df$row_label <- factor(results_df$row_label,
                                 levels = rev(unique(results_df$row_label)))

  # --------------------------------------------------------------------------
  # Table output
  # --------------------------------------------------------------------------
  tbl <- tibble::tibble(
    model     = results_df$row_label,
    estimate  = results_df$estimate,
    conf.low  = results_df$conf.low,
    conf.high = results_df$conf.high,
    p.value   = results_df$p.value,
    n         = results_df$n
  )

  fmt_num <- function(x) formatC(x, digits = table_digits, format = "f")
  sep_char <- "\u2013"  # en-dash
  formatted_tbl <- tibble::tibble(
    model     = as.character(tbl$model),
    estimate  = fmt_num(tbl$estimate),
    ci        = paste0(fmt_num(tbl$conf.low), sep_char, fmt_num(tbl$conf.high)),
    formatted = paste0(
      fmt_num(tbl$estimate),
      " (", fmt_num(tbl$conf.low), sep_char, fmt_num(tbl$conf.high), ")"
    ),
    p.value   = dplyr::if_else(
      tbl$p.value < 0.001,
      "<0.001",
      formatC(tbl$p.value, digits = 3, format = "f")
    ),
    n         = tbl$n
  )

  # --------------------------------------------------------------------------
  # Forest plot
  # --------------------------------------------------------------------------
  forest_plot <- build_forest_plot(
    results_df     = results_df,
    ref_line       = ref_line,
    effect_label   = effect_label,
    title          = title,
    point_size     = point_size,
    point_shape    = point_shape,
    line_size      = line_size,
    color          = color,
    vline_color    = vline_color,
    vline_linetype = vline_linetype,
    x_limits       = x_limits,
    x_breaks       = x_breaks,
    log_scale      = log_scale && is_ratio
  )

  # --------------------------------------------------------------------------
  # Combine with table if requested
  # --------------------------------------------------------------------------
  if (show_table) {
    tbl_plot <- build_table_plot(
      formatted_tbl = formatted_tbl,
      table_digits  = table_digits
    )
    combined_plot <- patchwork::wrap_plots(
      forest_plot, tbl_plot,
      ncol = 2,
      widths = c(2, 1.2)
    )
  } else {
    combined_plot <- forest_plot
  }

  # --------------------------------------------------------------------------
  # Return
  # --------------------------------------------------------------------------
  structure(
    list(
      plot            = combined_plot,
      table           = tbl,
      formatted_table = formatted_tbl
    ),
    class = "ggadjustedforest"
  )
}


# ------------------------------------------------------------------------------
# Internal: build forest ggplot
# ------------------------------------------------------------------------------
# Expansion constants shared by forest plot and table panel to keep y-alignment
.EXPAND_BOTTOM <- 0.6
.EXPAND_TOP    <- 1.4   # extra space used by the table header row

#' @noRd
build_forest_plot <- function(results_df, ref_line, effect_label, title,
                               point_size, point_shape, line_size, color,
                               vline_color, vline_linetype, x_limits, x_breaks,
                               log_scale) {

  p <- ggplot2::ggplot(
    results_df,
    ggplot2::aes(
      x    = .data[["estimate"]],
      y    = .data[["row_label"]],
      xmin = .data[["conf.low"]],
      xmax = .data[["conf.high"]]
    )
  ) +
    ggplot2::geom_vline(
      xintercept = ref_line,
      color      = vline_color,
      linetype   = vline_linetype,
      linewidth  = 0.6
    ) +
    ggplot2::geom_errorbar(
      width       = 0,
      linewidth   = line_size,
      color       = color,
      lineend     = "butt",
      orientation = "y"
    ) +
    ggplot2::geom_point(
      size  = point_size,
      shape = point_shape,
      color = color
    ) +
    ggplot2::labs(
      x     = effect_label,
      y     = NULL,
      title = title
    ) +
    ggplot2::theme_classic(base_size = 12) +
    ggplot2::theme(
      plot.title        = ggplot2::element_text(face = "bold", size = 13),
      axis.text.y       = ggplot2::element_text(size = 11),
      axis.text.x       = ggplot2::element_text(size = 11),
      axis.title.x      = ggplot2::element_text(size = 11),
      axis.line.y       = ggplot2::element_blank(),
      axis.ticks.y      = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(
        colour   = "grey90",
        linewidth = 0.3
      ),
      plot.margin       = ggplot2::margin(5, 10, 5, 5)
    )

  # Pin y expansion to known values so the table panel can match exactly
  p <- p + ggplot2::scale_y_discrete(
    expand = ggplot2::expansion(add = c(.EXPAND_BOTTOM, .EXPAND_TOP))
  )

  if (log_scale) {
    if (!is.null(x_breaks)) {
      p <- p + ggplot2::scale_x_log10(
        limits = x_limits,
        breaks = x_breaks,
        labels = scales::label_number(drop0trailing = TRUE)
      )
    } else {
      p <- p + ggplot2::scale_x_log10(
        limits = x_limits,
        labels = scales::label_number(drop0trailing = TRUE)
      )
    }
  } else {
    if (!is.null(x_breaks)) {
      p <- p + ggplot2::scale_x_continuous(
        limits = x_limits,
        breaks = x_breaks
      )
    } else {
      p <- p + ggplot2::scale_x_continuous(limits = x_limits)
    }
  }

  p
}


# ------------------------------------------------------------------------------
# Internal: build table ggplot panel
# ------------------------------------------------------------------------------
#' @noRd
build_table_plot <- function(formatted_tbl, table_digits) {

  n_rows <- nrow(formatted_tbl)

  # y positions must mirror the forest plot's factor-level integers exactly:
  # factor level 1 = bottom row, level n_rows = top row (Unadjusted)
  formatted_tbl$y_pos <- seq(n_rows, 1)

  # Match the forest plot's pinned expansion so patchwork aligns rows exactly
  y_min    <- 1 - .EXPAND_BOTTOM                  # same as forest plot lower bound
  y_max    <- n_rows + .EXPAND_TOP                 # same as forest plot upper bound
  header_y <- n_rows + .EXPAND_TOP * 0.65          # header sits in the extra top space

  tbl_df <- data.frame(
    x     = c(rep(0.02, n_rows), rep(0.72, n_rows)),
    y     = rep(formatted_tbl$y_pos, 2),
    label = c(formatted_tbl$formatted, formatted_tbl$p.value),
    hjust = c(rep(0, n_rows), rep(0, n_rows)),
    stringsAsFactors = FALSE
  )

  hdr <- data.frame(
    x        = c(0.02, 0.72),
    y        = header_y,
    label    = c("Estimate (95% CI)", "p-value"),
    hjust    = c(0, 0),
    stringsAsFactors = FALSE
  )

  ggplot2::ggplot() +
    ggplot2::geom_text(
      data = tbl_df,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   label = .data[["label"]], hjust = .data[["hjust"]]),
      size = 3.5
    ) +
    ggplot2::geom_text(
      data = hdr,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   label = .data[["label"]], hjust = .data[["hjust"]]),
      size     = 3.5,
      fontface = "bold"
    ) +
    ggplot2::scale_x_continuous(limits = c(0, 1)) +
    ggplot2::scale_y_continuous(limits = c(y_min, y_max)) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.margin = ggplot2::margin(5, 5, 5, 0)
    )
}


#' Print method for ggadjustedforest objects
#'
#' @param x An object of class `ggadjustedforest`.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns `x`.
#' @export
print.ggadjustedforest <- function(x, ...) {
  print(x$plot)
  cat("\nEffect estimates:\n")
  print(x$formatted_table[, c("model", "formatted", "p.value", "n")])
  invisible(x)
}


#' Plot method for ggadjustedforest objects
#'
#' @param x An object of class `ggadjustedforest`.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns the plot object.
#' @export
plot.ggadjustedforest <- function(x, ...) {
  print(x$plot)
  invisible(x$plot)
}
