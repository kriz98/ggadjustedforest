test_that("gg_adjusted_forest returns correct structure (logistic)", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)

  result <- gg_adjusted_forest(
    data       = mtcars,
    outcome    = "am",
    exposure   = "hp",
    covariates = c("wt", "cyl"),
    model_type = "logistic",
    show_table = FALSE
  )

  expect_s3_class(result, "ggadjustedforest")
  expect_named(result, c("plot", "table", "formatted_table"))
  expect_s3_class(result$plot, "gg")
  expect_true(is.data.frame(result$table))
  expect_true(is.data.frame(result$formatted_table))

  # Should have 2 rows: Unadjusted + Adjusted
  expect_equal(nrow(result$table), 2L)
  expect_true(all(c("model", "estimate", "conf.low", "conf.high",
                    "p.value", "n") %in% names(result$table)))
})


test_that("gg_adjusted_forest cumulative mode produces correct number of rows", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)
  covs <- c("wt", "cyl", "disp")

  result <- gg_adjusted_forest(
    data       = mtcars,
    outcome    = "am",
    exposure   = "hp",
    covariates = covs,
    model_type = "logistic",
    cumulative = TRUE,
    show_table = FALSE
  )

  # length(covs) + 1 unadjusted = 4 rows
  expect_equal(nrow(result$table), length(covs) + 1L)
})


test_that("gg_adjusted_forest works for linear model", {
  data(mtcars)
  result <- gg_adjusted_forest(
    data       = mtcars,
    outcome    = "mpg",
    exposure   = "hp",
    covariates = "wt",
    model_type = "linear",
    show_table = FALSE
  )
  expect_s3_class(result, "ggadjustedforest")
  expect_equal(nrow(result$table), 2L)
})


test_that("gg_adjusted_forest works for Poisson model", {
  data(mtcars)
  mtcars$cyl <- as.integer(mtcars$cyl)
  result <- gg_adjusted_forest(
    data       = mtcars,
    outcome    = "cyl",
    exposure   = "hp",
    covariates = "wt",
    model_type = "poisson",
    show_table = FALSE
  )
  expect_s3_class(result, "ggadjustedforest")
  expect_equal(nrow(result$table), 2L)
})


test_that("gg_adjusted_forest works for Cox model", {
  # Use the built-in lung dataset from the survival package
  lung <- survival::lung
  lung$status01 <- as.integer(lung$status == 2)
  lung <- stats::na.omit(lung[, c("time", "status01", "age", "sex", "ph.ecog")])

  result <- gg_adjusted_forest(
    data       = lung,
    outcome    = "status01",   # ignored for coxph
    exposure   = "age",
    covariates = c("sex", "ph.ecog"),
    model_type = "coxph",
    time_var   = "time",
    event_var  = "status01",
    show_table = FALSE
  )

  expect_s3_class(result, "ggadjustedforest")
  expect_equal(nrow(result$table), 2L)
})


test_that("gg_adjusted_forest no covariates returns only unadjusted", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)

  result <- gg_adjusted_forest(
    data       = mtcars,
    outcome    = "am",
    exposure   = "hp",
    model_type = "logistic",
    show_table = FALSE
  )

  expect_equal(nrow(result$table), 1L)
  expect_equal(as.character(result$table$model[1]), "Unadjusted")
})


test_that("gg_adjusted_forest validates bad inputs", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)

  expect_error(
    gg_adjusted_forest("not_a_df", "am", "hp"),
    "`data` must be a data frame"
  )

  expect_error(
    gg_adjusted_forest(mtcars, "nonexistent_col", "hp"),
    "not found in `data`"
  )

  expect_error(
    gg_adjusted_forest(mtcars, "am", "nonexistent_col"),
    "not found in `data`"
  )

  expect_error(
    gg_adjusted_forest(mtcars, "am", "hp", model_type = "invalid"),
    "`model_type` must be one of"
  )

  expect_error(
    gg_adjusted_forest(mtcars, "am", "hp", model_type = "coxph"),
    "time_var.*event_var"
  )
})


test_that("show_table = TRUE returns a patchwork object", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)

  result <- gg_adjusted_forest(
    data       = mtcars,
    outcome    = "am",
    exposure   = "hp",
    covariates = "wt",
    model_type = "logistic",
    show_table = TRUE
  )

  expect_s3_class(result$plot, "patchwork")
})


test_that("cumulative_labels override works", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)

  custom_labels <- c(
    "Unadjusted" = "Model 1: Crude",
    "+ wt"        = "Model 2: + Weight"
  )

  result <- gg_adjusted_forest(
    data              = mtcars,
    outcome           = "am",
    exposure          = "hp",
    covariates        = c("wt", "cyl"),
    model_type        = "logistic",
    cumulative        = TRUE,
    cumulative_labels = custom_labels,
    show_table        = FALSE
  )

  labels <- as.character(result$table$model)
  expect_true("Model 1: Crude" %in% labels)
  expect_true("Model 2: + Weight" %in% labels)
})


test_that("print and plot methods work without error", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)

  result <- gg_adjusted_forest(
    data       = mtcars,
    outcome    = "am",
    exposure   = "hp",
    covariates = "wt",
    show_table = FALSE
  )

  expect_output(print(result))

  # plot method should return invisibly
  plt <- withVisible(plot(result))
  expect_false(plt$visible)
})
