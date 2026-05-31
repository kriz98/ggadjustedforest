test_that("forest_table returns a data frame with expected columns", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)

  tbl <- forest_table(
    data       = mtcars,
    outcome    = "am",
    exposure   = "hp",
    covariates = c("wt", "cyl"),
    model_type = "logistic"
  )

  expect_true(is.data.frame(tbl))
  expect_true(all(c("model", "estimate", "ci", "formatted",
                    "p.value", "n") %in% names(tbl)))
  expect_equal(nrow(tbl), 2L)
})


test_that("forest_table formatted column has expected pattern", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)

  tbl <- forest_table(
    data       = mtcars,
    outcome    = "am",
    exposure   = "hp",
    model_type = "logistic"
  )

  # Pattern: number (number-number)
  expect_true(all(grepl("^[0-9.]+\\s*\\([0-9.]", tbl$formatted)))
})


test_that("forest_table respects table_digits", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)

  tbl3 <- forest_table(
    data         = mtcars,
    outcome      = "am",
    exposure     = "hp",
    model_type   = "logistic",
    table_digits = 3
  )

  # With digits=3, formatted strings should have 3 decimal places
  # Extract the first number from 'estimate' column
  first_est <- tbl3$estimate[1]
  n_decimals <- nchar(strsplit(first_est, "\\.")[[1]][2])
  expect_equal(n_decimals, 3L)
})


test_that("forest_table cumulative mode has correct number of rows", {
  data(mtcars)
  mtcars$am <- as.integer(mtcars$am)
  covs <- c("wt", "cyl")

  tbl <- forest_table(
    data       = mtcars,
    outcome    = "am",
    exposure   = "hp",
    covariates = covs,
    cumulative = TRUE
  )

  expect_equal(nrow(tbl), length(covs) + 1L)
})
