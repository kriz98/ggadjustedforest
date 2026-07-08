# Demo script for ggadjustedforest
# ─────────────────────────────────────────────────────────────────────────────
# Uses synthetic data designed to illustrate the key motivating idea:
#   confounders can make the unadjusted effect look very different from the
#   true causal effect — and the package shows only THOSE two estimates,
#   not the confounder coefficients.
#
# Scenario: does being in the 'exposed' group (binary) increase the risk of
# the outcome, after accounting for age, comorbidity score, and hospital?
# ─────────────────────────────────────────────────────────────────────────────

library(ggadjustedforest)

# ── Synthetic dataset ─────────────────────────────────────────────────────────
set.seed(42)
n <- 500

age          <- round(rnorm(n, mean = 62, sd = 12))
comorbidity  <- rpois(n, lambda = 2)
hospital     <- sample(c("A", "B", "C"), n, replace = TRUE)

# Exposure is confounded by age and comorbidity (sicker/older more likely exposed)
log_odds_exp <- -1 + 0.03 * age + 0.2 * comorbidity
exposed      <- rbinom(n, 1, plogis(log_odds_exp))

# Outcome: true OR for exposure ≈ 1.8 after adjusting for confounders
log_odds_out <- -3 + 0.6 * exposed + 0.04 * age + 0.3 * comorbidity +
                ifelse(hospital == "B", 0.4, ifelse(hospital == "C", -0.3, 0))
outcome      <- rbinom(n, 1, plogis(log_odds_out))

dat <- data.frame(outcome, exposed, age, comorbidity, hospital)

cat("Outcome prevalence:", round(mean(outcome) * 100, 1), "%\n")
cat("Exposure prevalence:", round(mean(exposed) * 100, 1), "%\n\n")

# ── 1. Unadjusted vs fully adjusted ──────────────────────────────────────────
result <- gg_adjusted_forest(
  data       = dat,
  outcome    = "outcome",
  exposure   = "exposed",
  covariates = c("age", "comorbidity", "hospital"),
  model_type = "logistic",
  title      = "Effect of Exposure on Outcome"
)

result$plot
result$formatted_table

# ── 2. Cumulative adjustment (each confounder added one at a time) ────────────
cumulative_result <- gg_adjusted_forest(
  data       = dat,
  outcome    = "outcome",
  exposure   = "exposed",
  covariates = c("age", "comorbidity", "hospital"),
  model_type = "logistic",
  cumulative = TRUE,
  cumulative_labels = c(
    "Unadjusted"                        = "Unadjusted",
    "+ age"                             = "+ Age",
    "+ age + comorbidity"               = "+ Comorbidity",
    "+ age + comorbidity + hospital"    = "+ Hospital"
  ),
  title = "How Does the Estimate Change as We Add Confounders?"
)

cumulative_result$plot
# Note: the unadjusted OR is inflated because age/comorbidity are shared
# causes of both exposure and outcome (confounding). Adjustment reveals
# the estimate closest to the true causal effect.

# ── 3. Multiple outcomes side-by-side ─────────────────────────────────────────
# Simulate a second outcome (e.g. a different complication)
log_odds_out2 <- -2.5 + 0.4 * exposed + 0.02 * age + 0.1 * comorbidity
dat$outcome2  <- rbinom(n, 1, plogis(log_odds_out2))

multi_result <- gg_multi_outcome_forest(
  data       = dat,
  outcomes   = c(
    "Primary Outcome"   = "outcome",
    "Secondary Outcome" = "outcome2"
  ),
  exposure   = "exposed",
  covariates = c("age", "comorbidity", "hospital"),
  model_type = "logistic",
  title      = "Effect of Exposure on Multiple Outcomes"
)

multi_result$plot
multi_result$combined_table

# ── 4. Linear regression (continuous outcome) ─────────────────────────────────
dat$continuous_outcome <- 5 + 1.5 * exposed - 0.05 * age +
                          0.2 * comorbidity + rnorm(n, sd = 2)

linear_result <- gg_adjusted_forest(
  data       = dat,
  outcome    = "continuous_outcome",
  exposure   = "exposed",
  covariates = c("age", "comorbidity"),
  model_type = "linear",
  title      = "Effect of Exposure on Continuous Outcome"
)

linear_result$plot

# ── 5. Save plots ──────────────────────────────────────────────────────────────
ggplot2::ggsave("plot_adjusted.png",    result$plot,            width = 8, height = 3.5, dpi = 300)
ggplot2::ggsave("plot_cumulative.png",  cumulative_result$plot, width = 8, height = 5,   dpi = 300)
ggplot2::ggsave("plot_multi.png",       multi_result$plot,      width = 8, height = 5,   dpi = 300)
ggplot2::ggsave("plot_linear.png",      linear_result$plot,     width = 8, height = 3.5, dpi = 300)

cat("\nAll plots saved.\n")
