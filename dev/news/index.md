# Changelog

## standardlastprofile (development version)

### New profiles

- Added five new standard load profiles published by BDEW in 2025: `H25`
  (household), `G25` (commerce), `L25` (agriculture), `P25` (combination
  profile with photovoltaics), and `S25` (combination profile with
  storage and photovoltaics). All five are available via
  [`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
  and
  [`slp_info()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_info.md),
  and are included in the `slp` dataset. Unlike the 1999 profiles, which
  use seasonal periods (`winter`, `summer`, `transition`), the 2025
  profiles carry month names in the `period` column (`january` …
  `december`).

### New features

- [`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
  gains a `holidays` argument: a character or Date vector of ISO 8601
  dates that are treated as public holidays (mapped to `"sunday"` in the
  algorithm). When supplied, the built-in holiday data are ignored
  entirely, giving callers full control over which dates count as
  holidays.

- [`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
  gains a `unit` argument (`"W"` or `"KWH"`, default `"W"`). `"KWH"`
  converts the `watts` column from average power (W) to energy consumed
  per 15-minute interval (kWh). Matching is case-insensitive, so `"kWh"`
  is accepted silently.

### Deprecations

- The `state_code` argument of
  [`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
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

- The christmastide rule (`get_weekday()`) now runs after the
  public-holiday lookup. The condition checks the already-resolved
  `weekday` vector (`weekday != "sunday"`) rather than the raw calendar
  weekday, so a Dec 24 or Dec 31 that is also a public holiday is never
  redundantly set to `"saturday"` before being overridden.

## standardlastprofile 1.0.0

CRAN release: 2023-12-11

- Initial CRAN release 🎉
