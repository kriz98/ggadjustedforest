#' Forest plot comparing effects across multiple outcomes
#'
#' Runs `gg_adjusted_forest()` for each outcome and combines the results into
#' a single faceted forest plot, with one facet panel per outcome.  Two usage
#' modes are supported:
#'
#' - **Simple mode** (supply `outcomes`, `exposure`, and optional `covariates`):
#'   all outcomes share the same exposure, covariates, and model type.
#' - **Advanced mode** (supply `outcome_list`): pass a named list of objects
#'   returned by `gg_adjusted_forest()`, giving full per-outcome control over
#'   covariates, model type, and cumulative adjustment.
#'
#' @param data A data frame. Required for simple mode; ignored in advanced mode.
#' @param outcomes Named character vector mapping display labels to column names,
#'   e.g. `c("30-day Mortality" = "mort_30d", "Failure to Rescue" = "ftr")`.
#'   Used only in simple mode.
#' @param exposure Character string. Name of the exposure variable. Used only
#'   in simple mode.
#' @param covariates Character vector of confounder names shared across all
#'   outcomes. Used only in simple mode. Default `NULL`.
#' @param model_type Character. One of `"logistic"` (default), `"linear"`,
#'   `"poisson"`, or `"coxph"`. A single value is applied to all outcomes.
#'   Used only in simple mode.
#' @param cumulative Logical. Passed to each `gg_adjusted_forest()` call in
#'   simple mode. Default `FALSE`.
#' @param cumulative_labels Optional named character vector. Passed to each
#'   `gg_adjusted_forest()` call in simple mode.
#' @param outcome_list Named list of `ggadjustedforest` objects (the return
#'   value of `gg_adjusted_forest()`).  Used only in advanced mode.  Names
#'   become the facet strip labels.
#' @param conf_level Numeric. Confidence level for intervals. Default `0.95`.
#'   Used only in simple mode.
#' @param time_var Character. Time variable name for Cox models. Simple mode.
#' @param event_var Character. Event indicator variable name for Cox models.
#'   Simple mode.
#' @param strata Character. Stratification variable for Cox models. Simple mode.
#' @param cluster Character. Clustering variable for robust SEs. Simple mode.
#' @param weights Character. Survey weight variable name. Simple mode.
#' @param effect_label Character. X-axis label. Auto-generated if `NULL`.
#' @param title Character. Overall plot title. Default `NULL`.
#' @param ref_line Numeric. Reference line position. Defaults to `1` for ratio
#'   models and `0` for linear.
#' @param point_size Numeric. Size of the point symbol. Default `4`.
#' @param point_shape Integer. ggplot2 shape code. Default `15` (filled square).
#' @param line_size Numeric. CI line thickness. Default `0.7`.
#' @param color Character. Colour for points and CI lines. Default `"black"`.
#' @param vline_color Character. Reference line colour. Default `"grey50"`.
#' @param vline_linetype Character. Reference line linetype. Default
#'   `"dashed"`.
#' @param x_limits Numeric vector of length 2. Manual x-axis limits. Default
#'   `NULL`.
#' @param x_breaks Numeric vector. Manual x-axis break positions. Default
#'   `NULL`.
#' @param log_scale Logical. Use log scale for ratio models. Default `TRUE`.
#' @param free_x Logical. Allow each facet to have its own x-axis scale.
#'   Default `FALSE` (shared scale for comparability).
#' @param strip_position Character. Where to place outcome strip labels:
#'   `"right"` (default) or `"left"`.
#' @param show_table Logical. Attach a formatted table panel. Default `TRUE`.
#' @param table_digits Integer. Decimal places in table. Default `2`.
#'
#' @return An object of class `ggadjustedforest_multi` (a list) with:
#'   \describe{
#'     \item{`plot`}{The combined \pkg{ggplot2}/\pkg{patchwork} plot.}
#'     \item{`tables`}{A named list of `formatted_table` data frames, one per
#'       outcome.}
#'     \item{`combined_table`}{A single data frame with all outcomes stacked,
#'       including an `outcome` column.}
#'     \item{`results`}{A named list of the underlying `ggadjustedforest`
#'       objects.}
#'   }
#'
#' @export
#'
#' @examples
#' data(mtcars)
#' mtcars$am  <- as.integer(mtcars$am)
#' mtcars$vs  <- as.integer(mtcars$vs)
#'
#' # Simple mode: two binary outcomes, same exposure and covariates
#' result <- gg_multi_outcome_forest(
#'   data       = mtcars,
#'   outcomes   = c("Transmission" = "am", "Engine Shape" = "vs"),
#'   exposure   = "hp",
#'   covariates = c("wt", "cyl"),
#'   model_type = "logistic",
#'   show_table = FALSE
#' )
#' result$combined_table
#'
#' # Advanced mode: different covariate sets per outcome
#' r1 <- gg_adjusted_forest(mtcars, "am", "hp", c("wt"),       show_table = FALSE)
#' r2 <- gg_adjusted_forest(mtcars, "vs", "hp", c("wt", "cyl"), show_table = FALSE)
#' result2 <- gg_multi_outcome_forest(
#'   outcome_list = list("Transmission" = r1, "Engine Shape" = r2),
#'   show_table   = FALSE
#' )
gg_multi_outcome_forest <- function(
    data              = NULL,
    outcomes          = NULL,
    exposure          = NULL,
    covariates        = NULL,
    model_type        = "logistic",
    cumulative        = FALSE,
    cumulative_labels = NULL,
    outcome_list      = NULL,
    conf_level        = 0.95,
    time_var          = NULL,
    event_var         = NULL,
    strata            = NULL,
    cluster           = NULL,
    weights           = NULL,
    effect_label      = NULL,
    title             = NULL,
    ref_line          = NULL,
    point_size        = 4,
    point_shape       = 15,
    line_size         = 0.7,
    color             = "black",
    vline_color       = "grey50",
    vline_linetype    = "dashed",
    x_limits          = NULL,
    x_breaks          = NULL,
    log_scale         = TRUE,
    free_x            = FALSE,
    strip_position    = "right",
    show_table        = TRUE,
    table_digits      = 2
) {

  # ---------------------------------------------------------------------------
  # Determine mode and collect per-outcome ggadjustedforest objects
  # ---------------------------------------------------------------------------
  advanced_mode <- !is.null(outcome_list)
  simple_mode   <- !is.null(outcomes) && !is.null(exposure)

  if (!advanced_mode && !simple_mode) {
    rlang::abort(
      paste0(
        "Supply either `outcomes` + `exposure` (simple mode) or ",
        "`outcome_list` (advanced mode)."
      ),
      call = NULL
    )
  }
  if (advanced_mode && simple_mode) {
    rlang::warn(
      "`outcome_list` takes precedence; `outcomes` / `exposure` are ignored.",
      call = NULL
    )
    simple_mode <- FALSE
  }

  if (simple_mode) {
    if (!is.character(outcomes) || is.null(names(outcomes))) {
      rlang::abort(
        paste0(
          "`outcomes` must be a named character vector, e.g. ",
          'c("Label" = "column_name").'
        ),
        call = NULL
      )
    }
    results <- lapply(outcomes, function(col) {
      gg_adjusted_forest(
        data              = data,
        outcome           = col,
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
        show_table        = FALSE
      )
    })
    names(results) <- names(outcomes)
  } else {
    if (!is.list(outcome_list) || is.null(names(outcome_list))) {
      rlang::abort("`outcome_list` must be a named list.", call = NULL)
    }
    bad <- vapply(outcome_list,
                  function(x) !inherits(x, "ggadjustedforest"),
                  logical(1))
    if (any(bad)) {
      rlang::abort(
        paste0(
          "All elements of `outcome_list` must be `ggadjustedforest` objects ",
          "(returned by `gg_adjusted_forest()`). Problem: ",
          paste(names(outcome_list)[bad], collapse = ", ")
        ),
        call = NULL
      )
    }
    results <- outcome_list
    # Infer model_type from the first result (best effort, for defaults)
    model_type <- attr(results[[1]], "model_type") %||% model_type
  }

  outcome_names <- names(results)

  # ---------------------------------------------------------------------------
  # Collect raw results_df from each outcome, tagged with outcome label
  # ---------------------------------------------------------------------------
  all_dfs <- lapply(seq_along(results), function(i) {
    tbl <- results[[i]]$table
    # We need the internal results_df with row_label as factor; reconstruct
    # from table (row_label was stored in $table$model as a factor)
    df <- data.frame(
      row_label = tbl$model,
      estimate  = tbl$estimate,
      conf.low  = tbl$conf.low,
      conf.high = tbl$conf.high,
      p.value   = tbl$p.value,
      n         = tbl$n,
      outcome   = outcome_names[[i]],
      stringsAsFactors = FALSE
    )
    df
  })

  combined_df <- dplyr::bind_rows(all_dfs)

  # Preserve per-outcome row order while making a single factor across all rows
  combined_df$outcome <- factor(combined_df$outcome, levels = outcome_names)

  # Factor levels from each single-outcome result are already reversed
  # (gg_adjusted_forest stores them as rev(unique(row_label)), so level 1 is
  # the most-adjusted row and the highest level is "Unadjusted").  Using them
  # directly here keeps "Unadjusted" at the top of each facet panel.
  ordered_labels <- unlist(lapply(results, function(r) {
    levels(r$table$model)
  }), use.names = FALSE)
  combined_df$row_label <- factor(combined_df$row_label,
                                  levels = unique(ordered_labels))

  # ---------------------------------------------------------------------------
  # Defaults shared across outcomes
  # ---------------------------------------------------------------------------
  is_ratio <- model_type %in% c("logistic", "poisson", "coxph")
  ci_pct   <- paste0(round(conf_level * 100), "%")

  if (is.null(effect_label)) {
    effect_label <- switch(
      model_type,
      logistic = paste0("Odds Ratio (", ci_pct, " CI)"),
      poisson  = paste0("Risk Ratio (", ci_pct, " CI)"),
      coxph    = paste0("Hazard Ratio (", ci_pct, " CI)"),
      linear   = paste0("Coefficient (", ci_pct, " CI)"),
      paste0("Effect Estimate (", ci_pct, " CI)")
    )
  }
  if (is.null(ref_line)) ref_line <- if (is_ratio) 1 else 0

  # ---------------------------------------------------------------------------
  # Build multi-outcome forest plot
  # ---------------------------------------------------------------------------
  x_scale_args <- list(limits = x_limits)
  if (!is.null(x_breaks)) x_scale_args$breaks <- x_breaks

  facet_scales <- if (free_x) "free" else "free_y"

  p <- ggplot2::ggplot(
    combined_df,
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
      width     = 0,
      linewidth = line_size,
      color     = color,
      lineend   = "butt",
      orientation = "y"
    ) +
    ggplot2::geom_point(
      size  = point_size,
      shape = point_shape,
      color = color
    ) +
    ggplot2::facet_grid(
      outcome ~ .,
      scales   = facet_scales,
      space    = "free_y",
      switch   = if (strip_position == "left") "y" else NULL
    ) +
    ggplot2::labs(
      x     = effect_label,
      y     = NULL,
      title = title
    ) +
    ggplot2::theme_classic(base_size = 12) +
    ggplot2::theme(
      plot.title         = ggplot2::element_text(face = "bold", size = 13),
      axis.text.y        = ggplot2::element_text(size = 11),
      axis.text.x        = ggplot2::element_text(size = 11),
      axis.title.x       = ggplot2::element_text(size = 11),
      axis.line.y        = ggplot2::element_blank(),
      axis.ticks.y       = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "grey90",
                                                  linewidth = 0.3),
      strip.background   = ggplot2::element_rect(fill = "grey95",
                                                  colour = "grey70"),
      strip.text.y       = ggplot2::element_text(face = "bold", size = 10,
                                                  angle = 0),
      panel.spacing      = ggplot2::unit(0.6, "lines"),
      plot.margin        = ggplot2::margin(5, 10, 5, 5)
    )

  if (strip_position == "left") {
    p <- p + ggplot2::theme(
      strip.placement = "outside"
    )
  }

  if (log_scale && is_ratio) {
    log_args <- x_scale_args
    log_args$labels <- scales::label_number(drop0trailing = TRUE)
    p <- p + do.call(ggplot2::scale_x_log10, log_args)
  } else {
    p <- p + do.call(ggplot2::scale_x_continuous, x_scale_args)
  }

  # ---------------------------------------------------------------------------
  # Combined table
  # ---------------------------------------------------------------------------
  fmt_num <- function(x) formatC(x, digits = table_digits, format = "f")
  sep_char <- "\u2013"

  combined_table <- data.frame(
    outcome   = combined_df$outcome,
    model     = as.character(combined_df$row_label),
    estimate  = fmt_num(combined_df$estimate),
    ci        = paste0(fmt_num(combined_df$conf.low), sep_char,
                       fmt_num(combined_df$conf.high)),
    formatted = paste0(
      fmt_num(combined_df$estimate),
      " (", fmt_num(combined_df$conf.low), sep_char,
      fmt_num(combined_df$conf.high), ")"
    ),
    p.value   = ifelse(
      combined_df$p.value < 0.001,
      "<0.001",
      formatC(combined_df$p.value, digits = 3, format = "f")
    ),
    n         = combined_df$n,
    stringsAsFactors = FALSE
  )

  tables <- lapply(results, function(r) r$formatted_table)

  # ---------------------------------------------------------------------------
  # Attach table panel if requested
  # ---------------------------------------------------------------------------
  if (show_table) {
    tbl_plot <- build_multi_table_plot(combined_table, outcome_names,
                                       table_digits)
    combined_plot <- patchwork::wrap_plots(
      p, tbl_plot,
      ncol   = 2,
      widths = c(2, 1.2)
    )
  } else {
    combined_plot <- p
  }

  # ---------------------------------------------------------------------------
  # Return
  # ---------------------------------------------------------------------------
  structure(
    list(
      plot           = combined_plot,
      tables         = tables,
      combined_table = combined_table,
      results        = results
    ),
    class = "ggadjustedforest_multi"
  )
}


# ------------------------------------------------------------------------------
# Internal: table panel for multi-outcome plot
# ------------------------------------------------------------------------------
#' @noRd
build_multi_table_plot <- function(combined_table, outcome_names, table_digits) {

  n_rows  <- nrow(combined_table)
  # Assign y positions top-to-bottom per outcome group, preserving order
  combined_table$y_pos <- seq(n_rows, 1)

  tbl_df <- data.frame(
    x     = c(rep(0.15, n_rows), rep(0.75, n_rows)),
    y     = rep(combined_table$y_pos, 2),
    label = c(combined_table$formatted, combined_table$p.value),
    stringsAsFactors = FALSE
  )

  # Group separators: horizontal lines between outcomes
  sep_positions <- numeric(0)
  prev <- NULL
  for (i in seq_len(n_rows)) {
    curr <- as.character(combined_table$outcome[i])
    if (!is.null(prev) && curr != prev) {
      sep_positions <- c(sep_positions, combined_table$y_pos[i] + 0.5)
    }
    prev <- curr
  }

  # Outcome group labels on the left
  group_label_df <- do.call(rbind, lapply(outcome_names, function(nm) {
    rows <- combined_table[as.character(combined_table$outcome) == nm, ]
    if (nrow(rows) == 0) return(NULL)
    data.frame(
      x     = 0.5,
      y     = mean(rows$y_pos),
      label = nm,
      stringsAsFactors = FALSE
    )
  }))

  y_max <- n_rows + 1.5
  y_min <- 0.5

  hdr <- data.frame(
    x        = c(0.15, 0.75),
    y        = n_rows + 1,
    label    = c("Estimate (95% CI)", "p-value"),
    stringsAsFactors = FALSE
  )

  plt <- ggplot2::ggplot() +
    ggplot2::geom_text(
      data = tbl_df,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   label = .data[["label"]]),
      size  = 3.5,
      hjust = 0.5
    ) +
    ggplot2::geom_text(
      data = hdr,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   label = .data[["label"]]),
      size     = 3.5,
      hjust    = 0.5,
      fontface = "bold"
    ) +
    ggplot2::scale_x_continuous(limits = c(0, 1)) +
    ggplot2::scale_y_continuous(limits = c(y_min - 0.5, y_max)) +
    ggplot2::theme_void() +
    ggplot2::theme(plot.margin = ggplot2::margin(5, 5, 5, 0))

  if (length(sep_positions) > 0) {
    plt <- plt +
      ggplot2::geom_hline(
        yintercept = sep_positions,
        color      = "grey80",
        linewidth  = 0.4,
        linetype   = "solid"
      )
  }

  plt
}


#' Print method for ggadjustedforest_multi objects
#'
#' @param x An object of class `ggadjustedforest_multi`.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns `x`.
#' @export
print.ggadjustedforest_multi <- function(x, ...) {
  print(x$plot)
  cat("\nCombined effect estimates:\n")
  print(x$combined_table[, c("outcome", "model", "formatted", "p.value", "n")])
  invisible(x)
}


#' Plot method for ggadjustedforest_multi objects
#'
#' @param x An object of class `ggadjustedforest_multi`.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns the plot object.
#' @export
plot.ggadjustedforest_multi <- function(x, ...) {
  print(x$plot)
  invisible(x$plot)
}


# Infix null-coalescing operator (unexported)
`%||%` <- function(a, b) if (!is.null(a)) a else b
