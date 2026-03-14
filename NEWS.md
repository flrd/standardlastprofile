# standardlastprofile (development version)

## New profiles

* Added five new standard load profiles published by BDEW in 2025: `H25`
  (household), `G25` (commerce), `L25` (agriculture), `P25` (combination
  profile with photovoltaics), and `S25` (combination profile with storage and
  photovoltaics). All five are available via `slp_generate()` and `slp_info()`,
  and are included in the `slp` dataset. Unlike the 1999 profiles, which use
  seasonal periods (`winter`, `summer`, `transition`), the 2025 profiles carry
  month names in the `period` column (`january` … `december`).

## New features

* `slp_generate()` gains a `holidays` argument: a character or Date vector of
  ISO 8601 dates that are treated as public holidays (mapped to `"sunday"` in
  the algorithm). When supplied, the built-in holiday data are ignored entirely,
  giving callers full control over which dates count as holidays.

## Deprecations

* The `state_code` argument of `slp_generate()` is deprecated. Pass a vector
  of holiday dates to the new `holidays` argument instead (#3).

## Bug fixes

* Fixed incorrect weekday assignment when a date range contains a Dec 24 or
  Dec 31 that falls on a Sunday. The previous check used `all()` across the
  entire range, which caused every other Dec 24/31 in the range to be mapped to
  `"workday"` instead of `"saturday"` (#2).

# standardlastprofile 1.0.0

* Initial CRAN release
