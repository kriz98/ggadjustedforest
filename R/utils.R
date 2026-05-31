# Internal helper: fit a regression model
# @noRd
fit_model <- function(data, outcome, exposure, covariates = NULL,
                      model_type = "logistic",
                      time_var = NULL, event_var = NULL,
                      strata = NULL, weights = NULL,
                      conf_level = 0.95) {

  # Build right-hand side
  rhs_vars <- c(exposure, covariates)
  if (!is.null(strata) && model_type == "coxph") {
    strata_term <- paste0("survival::strata(", strata, ")")
    rhs_vars <- c(rhs_vars, strata_term)
  }
  rhs <- paste(rhs_vars, collapse = " + ")

  # Build formula
  if (model_type == "coxph") {
    if (is.null(time_var) || is.null(event_var)) {
      rlang::abort(
        "For Cox models, `time_var` and `event_var` must be specified.",
        call = NULL
      )
    }
    lhs <- paste0("survival::Surv(", time_var, ", ", event_var, ")")
  } else {
    lhs <- outcome
  }
  f <- stats::as.formula(paste(lhs, "~", rhs))

  # Weights
  w <- if (!is.null(weights)) data[[weights]] else NULL

  # Fit
  fit <- switch(
    model_type,
    logistic = stats::glm(f, data = data, family = stats::binomial(),
                          weights = w),
    linear   = stats::lm(f, data = data, weights = w),
    poisson  = stats::glm(f, data = data, family = stats::poisson(),
                          weights = w),
    coxph    = survival::coxph(f, data = data, weights = w),
    rlang::abort(
      paste0(
        "`model_type` must be one of 'logistic', 'linear', 'poisson', 'coxph'. ",
        "Got: '", model_type, "'."
      ),
      call = NULL
    )
  )
  fit
}


# Internal helper: extract the exposure coefficient(s) from a fitted model
# @noRd
extract_coef <- function(fit, exposure, model_type, cluster = NULL,
                         data = NULL, conf_level = 0.95) {

  exponentiate <- model_type %in% c("logistic", "poisson", "coxph")

  # Robust SEs via sandwich / lmtest when cluster is given
  if (!is.null(cluster)) {
    if (!requireNamespace("sandwich", quietly = TRUE) ||
        !requireNamespace("lmtest", quietly = TRUE)) {
      rlang::inform(
        paste0(
          "Packages 'sandwich' and 'lmtest' are required for cluster-robust ",
          "standard errors but are not installed. Falling back to model-based SEs."
        )
      )
      cluster <- NULL
    }
  }

  if (!is.null(cluster) && !is.null(data)) {
    vcov_cl <- sandwich::vcovCL(fit, cluster = data[[cluster]])
    ct <- lmtest::coeftest(fit, vcov. = vcov_cl)
    alpha <- 1 - conf_level
    z_crit <- stats::qnorm(1 - alpha / 2)
    coefs <- as.data.frame(ct[, , drop = FALSE])
    coefs$term <- rownames(coefs)
    names(coefs)[1:4] <- c("estimate", "std.error", "statistic", "p.value")
    coefs$conf.low  <- coefs$estimate - z_crit * coefs$std.error
    coefs$conf.high <- coefs$estimate + z_crit * coefs$std.error
    if (exponentiate) {
      coefs$estimate  <- exp(coefs$estimate)
      coefs$conf.low  <- exp(coefs$conf.low)
      coefs$conf.high <- exp(coefs$conf.high)
    }
    tidy_df <- coefs[, c("term", "estimate", "conf.low", "conf.high",
                         "p.value")]
  } else {
    tidy_df <- broom::tidy(fit, conf.int = TRUE, exponentiate = exponentiate,
                           conf.level = conf_level)
  }

  # Sample size
  n_obs <- tryCatch(stats::nobs(fit), error = function(e) NA_integer_)

  # Filter to exposure term(s): exact match or starts with exposure (for factors)
  rows <- tidy_df[grepl(paste0("^", exposure), tidy_df$term), , drop = FALSE]

  if (nrow(rows) == 0) {
    rlang::abort(
      paste0(
        "Could not find exposure '", exposure,
        "' in model terms. Available terms: ",
        paste(tidy_df$term, collapse = ", ")
      ),
      call = NULL
    )
  }

  rows$n <- n_obs
  rows
}


# Internal helper: build the model label for cumulative mode
# @noRd
build_label <- function(step, covariates, cumulative_labels = NULL) {
  if (step == 0L) {
    lbl <- "Unadjusted"
  } else {
    lbl <- paste0("+ ", paste(covariates[seq_len(step)], collapse = " + "))
  }
  if (!is.null(cumulative_labels) && lbl %in% names(cumulative_labels)) {
    lbl <- cumulative_labels[[lbl]]
  }
  lbl
}


# Validate inputs to gg_adjusted_forest / forest_table
# @noRd
validate_inputs <- function(data, outcome, exposure, covariates, model_type,
                             time_var, event_var) {
  if (!is.data.frame(data)) {
    rlang::abort("`data` must be a data frame.", call = NULL)
  }
  if (!is.character(outcome) || length(outcome) != 1L) {
    rlang::abort("`outcome` must be a single character string.", call = NULL)
  }
  if (!is.character(exposure) || length(exposure) != 1L) {
    rlang::abort("`exposure` must be a single character string.", call = NULL)
  }
  if (model_type != "coxph" && !outcome %in% names(data)) {
    rlang::abort(
      paste0("`outcome` '", outcome, "' not found in `data`."),
      call = NULL
    )
  }
  if (!exposure %in% names(data)) {
    rlang::abort(
      paste0("`exposure` '", exposure, "' not found in `data`."),
      call = NULL
    )
  }
  if (!is.null(covariates)) {
    missing_covs <- setdiff(covariates, names(data))
    if (length(missing_covs) > 0) {
      rlang::abort(
        paste0(
          "The following covariates are not in `data`: ",
          paste(missing_covs, collapse = ", ")
        ),
        call = NULL
      )
    }
  }
  valid_types <- c("logistic", "linear", "poisson", "coxph")
  if (!model_type %in% valid_types) {
    rlang::abort(
      paste0(
        "`model_type` must be one of: ",
        paste(valid_types, collapse = ", "), "."
      ),
      call = NULL
    )
  }
  if (model_type == "coxph") {
    if (is.null(time_var) || is.null(event_var)) {
      rlang::abort(
        "For `model_type = 'coxph'`, `time_var` and `event_var` must be supplied.",
        call = NULL
      )
    }
    if (!time_var %in% names(data)) {
      rlang::abort(
        paste0("`time_var` '", time_var, "' not found in `data`."),
        call = NULL
      )
    }
    if (!event_var %in% names(data)) {
      rlang::abort(
        paste0("`event_var` '", event_var, "' not found in `data`."),
        call = NULL
      )
    }
  }
  invisible(NULL)
}
