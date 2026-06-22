# Data dictionary — `arts_vibrancy_va_synthetic.csv`

133 Virginia localities (counties + independent cities). **All arts/economic figures are synthetic
and illustrative.** County boundaries and `population` are real.

| column | role | meaning | direction |
|---|---|---|---|
| `fips` | key | 5-digit county FIPS (state 51) | — |
| `locality` | key | County / independent-city name | — |
| `lsad` | meta | "County" or "city" | — |
| `population` | meta | Resident population (real, JHU/Census lookup) | — |
| `arts_estab` | **index · Providers** | Arts establishments | more = higher |
| `arts_emp` | **index · Providers** | Arts employment | more = higher |
| `arts_payroll_k` | **index · Dollars** | Arts payroll, $k | more = higher |
| `nonprofit_rev_k` | **index · Dollars** | Nonprofit arts revenue, $k *(1 suppressed value)* | more = higher |
| `fed_grant_k` | **index · Grants** | Federal arts grants, $k | more = higher |
| `state_grant_k` | **index · Grants** | State arts grants, $k | more = higher |
| `median_income` | context · validate | ACS median household income | — (not in index) |
| `pct_college` | context · validate | ACS % age 25+ with bachelor's+ | — (not in index) |
| `pct_poverty` | context · reverse | ACS % in poverty | more = LOWER vibrancy |

**Index inputs** are the six arts measures only, grouped into the three AVI dimensions
(Providers = establishments + employment · Dollars = payroll + nonprofit revenue · Grants = federal + state).
The three ACS variables are **context for validation**, not index inputs; `pct_poverty` would need its
sign flipped if it were ever included.

**Suppressed value.** `nonprofit_rev_k` is blank for Charlottesville (mimicking real Census/IRS
suppression). The pipeline imputes it from `arts_payroll_k` and flags it via `nonprofit_rev_imputed`.

## Processed output — `va_arts_vibrancy_index.csv`

| column | meaning |
|---|---|
| `providers_z`, `dollars_z`, `grants_z` | standardized (z) score for each dimension |
| `avi_z` | equal-weight mean of the six standardized measures |
| `avi_score` | `avi_z` rescaled to 0–100 |
| `avi_rank` | overall rank (1 = most vibrant) |
| `providers_rank`, `dollars_rank`, `grants_rank` | rank within each dimension |
| `nonprofit_rev_imputed` | TRUE where the suppressed value was imputed |
