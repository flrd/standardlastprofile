# Changelog

## standardlastprofile 2.0.0

This release (finally) adds **gas** SLPs alongside the existing
electricity profiles. We introduce an updated interface for electricity
SLPs too. All renames and deprecations below are backward compatible.

### New functions

- [`slp_electricity()`](https://flrd.github.io/standardlastprofile/reference/slp_electricity.md)
  is the new primary function for generating electricity standard load
  profiles. It replaces
  [`slp_generate()`](https://flrd.github.io/standardlastprofile/reference/slp_generate.md)
  with a cleaner interface: no `state_code` argument and no restriction
  on the date range (previously limited to 1990–2073 by the built-in
  holiday data).

- [`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
  implements the BDEW/VKU/GEODE synthetic procedure for gas standard
  load profiles (SigLinDe method). It supports all 15 gas profile IDs
  defined in the BDEW Leitfaden, as of 2025-10-28 (`HEF`, `HMF`, `HKO`,
  `GKO`, `GHA`, `GMK`, `GBD`, `GBH`, `GWA`, `GGA`, `GBA`, `GGB`, `GPD`,
  `GMF`, `GHD`). The function takes daily temperatures and a
  `kundenwert` (kWh/day), and returns daily gas consumption in kWh. The
  `kundenwert` is a required input, derived once from a full reference
  year with
  [`slp_gas_kundenwert()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_kundenwert.md).
  A `variant` argument selects between SigLinDe Ausprägung `"34"`
  (default, 57 % linear component) and `"33"` (45 % linear component).

- [`slp_gas_kundenwert()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_kundenwert.md)
  derives the `kundenwert` from a full reference year of daily
  temperatures and an annual consumption target. You might use this in a
  two-step workflow: compute KW once from a representative year, then
  pass the result as `kundenwert` to
  [`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
  for any shorter period. Daily mean temperatures can be obtained from
  the DWD open-data archive, e.g. via the `rdwd` package; see the
  gas-slp article on the package website for a complete fetch-to-profile
  walkthrough.

- [`slp_gas_siglinde()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_siglinde.md)
  exposes the low-level dimensionless daily heating demand function h(θ)
  used internally by
  [`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md).
  It is exported so that users with custom or region-specific
  coefficients (e.g. state-level parameters such as `BW_HEF03` for
  Baden-Württemberg) can compute h(θ) directly and build their own
  profiles.

- [`slp_gas_coefficients()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_coefficients.md)
  returns the SigLinDe profile function coefficients (A, B, C, D, θ₀,
  mH, bH, mW, bW) for one or more gas profiles as a data frame. Supports
  both variants (`"34"`, `"33"`).

- [`slp_gas_weekday_factors()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_weekday_factors.md)
  returns the weekday scaling factors (F_WT) for one or more gas
  profiles as a data frame with columns `profile_id`, `day`, and `f_wt`.

- Nationwide German public holidays are now computed via the Anonymous
  Gregorian Easter algorithm rather than looked up in a precomputed
  table. Coverage is open-ended from 1990 onward (the year German Unity
  Day was introduced); the previous 2073 / 2099 caps no longer apply.
  State-level holidays are no longer included; use the `holidays`
  argument to supply custom dates.

- [`slp_info()`](https://flrd.github.io/standardlastprofile/reference/slp_info.md)
  now accepts gas profile IDs too (`HEF`, `HMF`, `HKO`, etc.) in
  addition to electricity IDs, and respects the `language` argument for
  both. Electricity and gas IDs can be mixed freely in a single call.

### Deprecations

- The dataset `slp` has been renamed to `slp_electricity_profiles`. The
  package no longer ships under the old name, but accessing `slp` still
  returns the data and emits a `lifecycle` deprecation warning pointing
  to the new name. The shim will be removed in a future release.

### Superseded

- [`slp_generate()`](https://flrd.github.io/standardlastprofile/reference/slp_generate.md)
  is now superseded in favour of
  [`slp_electricity()`](https://flrd.github.io/standardlastprofile/reference/slp_electricity.md).
  It remains in the package and will not be removed for now, but new
  code should use
  [`slp_electricity()`](https://flrd.github.io/standardlastprofile/reference/slp_electricity.md)
  instead.

### Breaking changes

- Passing `state_code` to
  [`slp_generate()`](https://flrd.github.io/standardlastprofile/reference/slp_generate.md)
  now throws an error (previously a warning since version 1.1.0). Use
  the `holidays` argument of
  [`slp_electricity()`](https://flrd.github.io/standardlastprofile/reference/slp_electricity.md)
  to supply custom holiday dates.

## standardlastprofile 1.1.0

CRAN release: 2026-03-16

### New profiles

- Added five new standard load profiles published by BDEW in 2025: `H25`
  (household), `G25` (commercial), `L25` (agriculture), `P25`
  (combination profile with photovoltaics), and `S25` (combination
  profile with storage and photovoltaics). All five are available via
  [`slp_generate()`](https://flrd.github.io/standardlastprofile/reference/slp_generate.md)
  and
  [`slp_info()`](https://flrd.github.io/standardlastprofile/reference/slp_info.md),
  and are included in the `slp` dataset.

### New features

- [`slp_generate()`](https://flrd.github.io/standardlastprofile/reference/slp_generate.md)
  gains a `holidays` argument: a character or Date vector of ISO 8601
  dates that are treated as public holidays (mapped to `"sunday"` in the
  algorithm). When supplied, the built-in holiday data are ignored
  entirely, giving callers full control over which dates count as
  holidays.

### Deprecations

- The `state_code` argument of
  [`slp_generate()`](https://flrd.github.io/standardlastprofile/reference/slp_generate.md)
  is deprecated. Pass a vector of holiday dates to the new `holidays`
  argument instead
  ([\#3](https://github.com/flrd/standardlastprofile/issues/3)).

### Bug fixes

- Fixed incorrect weekday assignment when a date range contains a Dec 24
  or Dec 31 that falls on a Sunday. The previous check used
  [`all()`](https://rdrr.io/r/base/all.html) across the entire range,
  which caused every other Dec 24/31 in the range to be mapped to
  `"workday"` instead of `"saturday"`
  ([\#2](https://github.com/flrd/standardlastprofile/issues/2)).

## standardlastprofile 1.0.0

CRAN release: 2023-12-11

- Initial CRAN release
