test_that("simple mode returns correct structure", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)
  mtcars$vs <- as.integer(mtcars$vs)

  suppressWarnings(
    res <- gg_multi_outcome_forest(
      data       = mtcars,
      outcomes   = c("Transmission" = "am", "Engine" = "vs"),
      exposure   = "hp",
      covariates = c("wt", "cyl"),
      model_type = "logistic",
      show_table = FALSE
    )
  )

  expect_s3_class(res, "ggadjustedforest_multi")
  expect_named(res, c("plot", "tables", "combined_table", "results"))
  expect_s3_class(res$plot, "gg")
  expect_equal(length(res$results), 2L)
  expect_named(res$results, c("Transmission", "Engine"))
})

test_that("combined_table has correct columns and rows", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)
  mtcars$vs <- as.integer(mtcars$vs)

  suppressWarnings(
    res <- gg_multi_outcome_forest(
      data       = mtcars,
      outcomes   = c("A" = "am", "B" = "vs"),
      exposure   = "hp",
      covariates = "wt",
      show_table = FALSE
    )
  )

  ct <- res$combined_table
  expect_true(all(c("outcome", "model", "formatted", "p.value", "n") %in% names(ct)))
  # 2 outcomes x 2 rows (Unadjusted + Adjusted) = 4
  expect_equal(nrow(ct), 4L)
  expect_equal(levels(ct$outcome), c("A", "B"))
})

test_that("advanced mode accepts list of ggadjustedforest objects", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)
  mtcars$vs <- as.integer(mtcars$vs)

  suppressWarnings({
    r1 <- gg_adjusted_forest(mtcars, "am", "hp", "wt",       show_table = FALSE)
    r2 <- gg_adjusted_forest(mtcars, "vs", "hp", c("wt","cyl"), show_table = FALSE)
  })

  res <- gg_multi_outcome_forest(
    outcome_list = list("Transmission" = r1, "Engine" = r2),
    show_table   = FALSE
  )

  expect_s3_class(res, "ggadjustedforest_multi")
  expect_equal(nrow(res$combined_table), 4L)
})

test_that("advanced mode errors on non-ggadjustedforest list elements", {
  expect_error(
    gg_multi_outcome_forest(outcome_list = list("A" = list(x = 1))),
    "ggadjustedforest"
  )
})

test_that("show_table = TRUE attaches table panel via patchwork", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)
  mtcars$vs <- as.integer(mtcars$vs)

  suppressWarnings(
    res <- gg_multi_outcome_forest(
      data       = mtcars,
      outcomes   = c("A" = "am", "B" = "vs"),
      exposure   = "hp",
      covariates = "wt",
      show_table = TRUE
    )
  )

  expect_true(inherits(res$plot, "patchwork") || inherits(res$plot, "gg"))
})

test_that("error when neither outcomes nor outcome_list supplied", {
  expect_error(
    gg_multi_outcome_forest(data = mtcars),
    "simple mode"
  )
})

test_that("print method works without error", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)
  mtcars$vs <- as.integer(mtcars$vs)

  suppressWarnings(
    res <- gg_multi_outcome_forest(
      data       = mtcars,
      outcomes   = c("A" = "am", "B" = "vs"),
      exposure   = "hp",
      show_table = FALSE
    )
  )
  expect_invisible(suppressWarnings(print(res)))
})
