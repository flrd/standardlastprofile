# standardlastprofile (development version)

## New functions

* `slp_electricity()` is the new primary function for generating electricity
  standard load profiles. It replaces `slp_generate()` with a cleaner
  interface: no `state_code` argument and no restriction on the date range
  (previously limited to 1990–2073 by the built-in holiday data).

* Built-in nationwide German public holidays are now computed algorithmically
  (Anonymous Gregorian algorithm) rather than fetched from the nager.Date API,
  extending coverage from 2073 to 2099. State-level holidays are no longer
  included; use the `holidays` argument to supply custom dates.

* `slp_gas()` implements the BDEW/VKU/GEODE synthetic procedure for gas
  standard load profiles (SigLinDe method). It supports all 15 gas profile IDs
  defined in the BDEW Leitfaden 2018 (`HEF`, `HMF`, `HKO`, `GKO`, `GHA`,
  `GMK`, `GBD`, `GBH`, `GWA`, `GGA`, `GBA`, `GGB`, `GPD`, `GMF`, `GHD`).
  The function accepts daily temperatures (*Allokationstemperatur*) and an
  annual consumption or a fixed Kundenwert, and returns daily gas consumption
  in kWh. A `variant` argument selects between SigLinDe Ausprägung `"34"`
  (default, 57 % linear component) and `"33"` (45 % linear component).

* `slp_kundenwert()` derives the Kundenwert (KW, kWh/day) from a full
  reference year of daily temperatures and an annual consumption target. Use
  this in a two-step workflow: compute KW once from a representative year,
  then pass the result as `kundenwert` to `slp_gas()` for any shorter period.
  A `station` argument provides convenient access to built-in long-term mean
  temperatures (WMO climate normal 1991–2020) for ten representative DWD
  weather stations: Oberstdorf, Potsdam, Hamburg, Freiburg, Chemnitz,
  Duesseldorf, Erfurt, Frankfurt, Nuernberg, and Regensburg.

* `slp_info()` now accepts gas profile IDs (`HEF`, `HMF`, `HKO`, etc.)
  in addition to electricity IDs, and respects the `language` argument for
  both. Electricity and gas IDs can be mixed freely in a single call.

## Superseded

* `slp_generate()` is now superseded in favour of `slp_electricity()`. It
  remains in the package and will not be removed, but new code should use
  `slp_electricity()` instead.

## Breaking changes

* Passing `state_code` to `slp_generate()` now throws an error (previously a
  warning since version 1.1.0). Use the `holidays` argument of
  `slp_electricity()` to supply custom holiday dates.

# standardlastprofile 1.1.0

## New profiles

* Added five new standard load profiles published by BDEW in 2025: `H25`
  (household), `G25` (commercial), `L25` (agriculture), `P25` (combination
  profile with photovoltaics), and `S25` (combination profile with storage and
  photovoltaics). All five are available via `slp_generate()` and `slp_info()`,
  and are included in the `slp` dataset.

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
