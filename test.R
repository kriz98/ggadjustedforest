# ggadjustedforest — demonstration using colon_s (finalfit package)
# ─────────────────────────────────────────────────────────────────────────────
# Dataset: colon_s — 929 patients with colon cancer from the North Central
#   Cancer Treatment Group (Moertel et al., NEJM 1990)
#
# Research question: Does having >4 positive lymph nodes (node4) increase the
#   risk of 5-year mortality, before and after adjusting for patient and tumour
#   characteristics?
#
# This mirrors the motivating use case: showing only the exposure of interest
# (node4) rather than reporting every confounder coefficient — in line with
# causal inference principles (Westreich & Greenland, AJE 2013).
#
# Tidy tools manifesto compliance (Wickham 2023):
#   1. Reuse existing data structures — tables returned as tibbles; plots as
#      ggplot2 objects composable with any ggplot2 extension.
#   2. Compose simple functions with the pipe — data is always the first
#      argument, enabling colon_s |> gg_adjusted_forest(...).
#   3. Embrace functional programming — pure functions, no global state,
#      results fully contained in the returned list object.
#   4. Design for humans — gg_ prefix for discoverability; colour/color both
#      accepted; informative error messages via rlang.
# ─────────────────────────────────────────────────────────────────────────────

library(ggadjustedforest)
library(finalfit)  # for colon_s dataset

# ── Data preparation ──────────────────────────────────────────────────────────
data(colon_s)

# Create binary outcome: 5-year mortality (0 = alive, 1 = died)
colon_s$died_5yr   <- as.integer(colon_s$mort_5yr == "Died")

# Second outcome: overall death status for multi-outcome demo
colon_s$died_all   <- colon_s$status   # already 0/1

cat("Outcome prevalence (5yr mortality):", round(mean(colon_s$died_5yr, na.rm = TRUE) * 100, 1), "%\n")
cat("Exposure prevalence (>4 nodes)    :", round(mean(colon_s$node4) * 100, 1), "%\n\n")

# Confounders to adjust for
confounders <- c("age", "sex.factor", "extent.factor", "differ.factor", "surg.factor")

# ── 1. Unadjusted vs fully adjusted (pipe-friendly API) ───────────────────────
# Manifesto principle 2: data is first argument — pipe works naturally
result <- colon_s |>
  gg_adjusted_forest(
    outcome    = "died_5yr",
    exposure   = "node4",
    covariates = confounders,
    model_type = "logistic",
    title      = "Effect of Lymph Node Involvement (>4 nodes) on 5-Year Mortality"
  )

result$plot            # ggplot2 object — composable with any ggplot2 extension
result$table           # tibble of numeric estimates
result$formatted_table # tibble with "OR (lower–upper)" strings

# ── 2. Cumulative adjustment ──────────────────────────────────────────────────
cumulative_result <- gg_adjusted_forest(
  data       = colon_s,
  outcome    = "died_5yr",
  exposure   = "node4",
  covariates = confounders,
  model_type = "logistic",
  cumulative = TRUE,
  cumulative_labels = c(
    "Unadjusted"                                                    = "Unadjusted",
    "+ age"                                                         = "+ Age",
    "+ age + sex.factor"                                            = "+ Sex",
    "+ age + sex.factor + extent.factor"                            = "+ Extent of spread",
    "+ age + sex.factor + extent.factor + differ.factor"            = "+ Tumour differentiation",
    "+ age + sex.factor + extent.factor + differ.factor + surg.factor" = "+ Time from surgery"
  ),
  title = "Cumulative Adjustment: Effect of Lymph Node Involvement on 5-Year Mortality"
)

cumulative_result$plot
# The estimate barely moves across adjustment steps, suggesting node4 is not
# heavily confounded by these patient/tumour characteristics.

# ── 3. Multiple outcomes — panel with cowplot::plot_grid() ────────────────────
# Each outcome is fitted independently, then panels are combined externally.
# This keeps each model fully specified and avoids false coupling of outcomes.
library(cowplot)

# Extract $plot — cowplot works with ggplot2 objects, not the ggadjustedforest wrapper
p_5yr <- gg_adjusted_forest(
  data       = colon_s,
  outcome    = "died_5yr",
  exposure   = "node4",
  covariates = confounders,
  model_type = "logistic",
  title      = "5-Year Mortality",
  show_table = FALSE
)$plot

p_all <- gg_adjusted_forest(
  data       = colon_s,
  outcome    = "died_all",
  exposure   = "node4",
  covariates = confounders,
  model_type = "logistic",
  title      = "Death (all follow-up)",
  show_table = FALSE
)$plot

# align = "v" + axis = "lr" keeps y-axis labels vertically aligned
cowplot::plot_grid(p_5yr, p_all, ncol = 1, align = "v", axis = "lr")

# ── 4. Cox proportional hazards (survival outcome) ────────────────────────────
# colon_s$time.years = time to death/censoring; status = died (0/1)
cox_result <- gg_adjusted_forest(
  data       = colon_s,
  outcome    = "status",     # ignored for coxph
  exposure   = "node4",
  covariates = confounders,
  model_type = "coxph",
  time_var   = "time.years",
  event_var  = "status",
  title      = "Hazard of Death by Lymph Node Involvement (Cox model)"
)

cox_result$plot

# ── 5. Downstream pipe use of tibble output ───────────────────────────────────
# Manifesto principle 1: tibble output integrates directly with dplyr
library(dplyr)

result$formatted_table |>
  filter(p.value == "<0.001" | as.numeric(p.value) < 0.05) |>
  select(model, formatted, p.value)

# ── 6. Save plots ─────────────────────────────────────────────────────────────
multi_panel <- cowplot::plot_grid(p_5yr, p_all, ncol = 1, align = "v", axis = "lr")

ggplot2::ggsave("plot_adjusted.png",   result$plot,           width = 9, height = 3.5, dpi = 300)
ggplot2::ggsave("plot_cumulative.png", cumulative_result$plot, width = 9, height = 6,   dpi = 300)
ggplot2::ggsave("plot_multi.png",      multi_panel,           width = 9, height = 6,   dpi = 300)
ggplot2::ggsave("plot_cox.png",        cox_result$plot,       width = 9, height = 3.5, dpi = 300)

cat("\nAll plots saved.\n")
