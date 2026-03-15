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
  and are included in the `slp` dataset.

### New features

- [`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
  gains a `holidays` argument: a character or Date vector of ISO 8601
  dates that are treated as public holidays (mapped to `"sunday"` in the
  algorithm). When supplied, the built-in holiday data are ignored
  entirely, giving callers full control over which dates count as
  holidays.

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

## standardlastprofile 1.0.0

CRAN release: 2023-12-11

- Initial CRAN release
