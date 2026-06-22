# ------------------------------------------------------------------
# Virginia Arts Vibrancy Index — raw -> processed pipeline
# DSPG x SMU DataArts (prototype, synthetic data)
#
# Reads : data/raw/arts_vibrancy_va_synthetic.csv
# Writes: data/processed/va_arts_vibrancy_index.csv
#
# Run from the repo root:  Rscript R/01_build_index.R
# ------------------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

raw <- read_csv("data/raw/arts_vibrancy_va_synthetic.csv", show_col_types = FALSE)

# --- Declare the variable sets (which columns build the score) ------
# Six arts measures = index inputs, grouped into the three AVI dimensions.
arts_vars    <- c("arts_estab", "arts_emp",            # Arts Providers
                  "arts_payroll_k", "nonprofit_rev_k", # Arts Dollars
                  "fed_grant_k", "state_grant_k")      # Grant Activity
# ACS context = held out to VALIDATE the index, never used to build it.
context_vars <- c("median_income", "pct_college", "pct_poverty")
reverse_vars <- c("pct_poverty")  # higher poverty != more vibrant

# --- Handle the one suppressed value (made explicit, not silently dropped) ---
# Charlottesville's nonprofit revenue is suppressed; impute from payroll,
# the Dollars-dimension variable it tracks most closely.
fit  <- lm(nonprofit_rev_k ~ arts_payroll_k, data = raw)
proc <- raw %>%
  mutate(
    nonprofit_rev_imputed = is.na(nonprofit_rev_k),
    nonprofit_rev_k = ifelse(nonprofit_rev_imputed,
                             round(predict(fit, .)), nonprofit_rev_k)
  )

# --- Standardize each arts measure (z-score = base R scale(), n-1 SD) ---
z <- function(x) as.numeric(scale(x))
zt <- proc %>% transmute(across(all_of(arts_vars), z, .names = "z_{.col}"))

# --- Build the three dimension scores + the equal-weight composite ---
proc <- proc %>%
  mutate(
    providers_z = rowMeans(zt[, c("z_arts_estab", "z_arts_emp")]),
    dollars_z   = rowMeans(zt[, c("z_arts_payroll_k", "z_nonprofit_rev_k")]),
    grants_z    = rowMeans(zt[, c("z_fed_grant_k", "z_state_grant_k")]),
    avi_z       = rowMeans(zt),                                  # equal weights
    avi_score   = round(100 * (avi_z - min(avi_z)) /
                          (max(avi_z) - min(avi_z)), 1),         # rescale 0-100
    avi_rank        = dense_rank(desc(avi_z)),
    providers_rank  = dense_rank(desc(providers_z)),
    dollars_rank    = dense_rank(desc(dollars_z)),
    grants_rank     = dense_rank(desc(grants_z))
  ) %>%
  arrange(avi_rank)

out <- proc %>%
  select(fips, locality, providers_z, dollars_z, grants_z, avi_z, avi_score,
         avi_rank, providers_rank, dollars_rank, grants_rank, nonprofit_rev_imputed) %>%
  mutate(across(c(providers_z, dollars_z, grants_z, avi_z), \(x) round(x, 3)))

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write_csv(out, "data/processed/va_arts_vibrancy_index.csv")

cat("Wrote data/processed/va_arts_vibrancy_index.csv  (", nrow(out), " localities)\n", sep = "")
cat("\nTop 10 by Arts Vibrancy:\n")
print(out %>% select(avi_rank, locality, avi_score) %>% head(10), n = 10)
