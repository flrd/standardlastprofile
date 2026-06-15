# Compute the Kundenwert for a Gas Standard Load Profile

Compute the customer value (Kundenwert, KW) that scales a gas standard
load profile to a specific annual consumption. The result can be passed
directly to
[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
via its `kundenwert` argument, enabling a two-step workflow: derive KW
from a representative full-year reference temperature series, then
generate profiles for any shorter period using that fixed KW.

## Usage

``` r
slp_gas_kundenwert(
  profile_id,
  dates = NULL,
  temperatures = NULL,
  annual_consumption = 1000,
  variant = c("34", "33"),
  holidays = NULL
)
```

## Arguments

- profile_id:

  gas load profile identifier, required. Same values as
  [`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md).
  Multiple values are supported; the result is a named numeric vector
  with one element per profile.

- dates:

  a Date vector or character vector in ISO 8601 format (`"YYYY-MM-DD"`),
  representing a **full reference year** of daily dates. For a
  meaningful Kundenwert the series should ideally cover 365 (or 366)
  days. Must have the same length as `temperatures`.

- temperatures:

  a numeric vector of daily temperatures in degrees Celsius. Must have
  the same length as `dates`.

- annual_consumption:

  numeric scalar, annual gas consumption in kWh. Defaults to `1000`.

- variant:

  SigLinDe variant, either `"34"` (default) or `"33"`. Must match the
  `variant` passed to
  [`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
  when applying the resulting Kundenwert.

- holidays:

  controls public holiday treatment. Same semantics as in
  [`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md).
  The reference year used here should apply the same holiday calendar as
  the generation step.

## Value

A named numeric vector of length `length(profile_id)`. Each element is
the Kundenwert in kWh/day for the corresponding profile. Names match the
input `profile_id` values.

## Details

The Kundenwert is derived from the annual consumption and the year's
temperature profile:

\$\$KW = \frac{Q_a}{\sum_D h(\vartheta_D) \cdot F\_{WT,D}}\$\$

where \\Q_a\\ is `annual_consumption` (the annual consumption total;
German: *Jahresverbrauchsprognose*, JVP) and the sum \\\sum_D
h(\vartheta_D) \cdot F\_{WT,D}\\ runs over all days in the temperature
and weekday factor series. For the result to be meaningful the
denominator must reflect a full seasonal cycle (ideally a calendar
year).

### Reference temperature series

For a robust Kundenwert the temperature series should represent a **full
reference year**, ideally a multi-year climatological mean rather than a
single year, so that no individual-year anomaly distorts the scaling
factor; with fewer than 365 days a message is shown.

Daily mean temperatures can be downloaded from the DWD (Deutscher
Wetterdienst) open-data archive, e.g. via the
[rdwd](https://brry.github.io/rdwd/) package. The [gas
SLP](https://flrd.github.io/standardlastprofile/articles/slp-gas.html)
article on the package website walks through fetching DWD data, deriving
the Kundenwert, and generating profiles.

### Recommended workflow

[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
requires a `kundenwert`. If you do not already know it, compute it first
with `slp_gas_kundenwert()` from a full reference year and the
customer's annual consumption, then pass the result into
[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
to generate the profile for whatever period you need:

    # Step 1 — derive KW from a full-year reference temperature series
    kw <- slp_gas_kundenwert("HEF", dates_year, temps_year, annual_consumption = 15000)

    # Step 2 — generate a profile for any shorter period
    slp_gas("HEF", dates_jan_mar, temps_jan_mar, kundenwert = kw)

## See also

[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)

## Examples

``` r
# Derive KW from a full-year reference temperature series
dates_ref <- seq.Date(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
doy       <- as.integer(format(dates_ref, "%j"))

# fake temperature data for demonstration here only
temps_ref <- 10 - 11 * cos(2 * pi * (doy - 15) / 365)
slp_gas_kundenwert("HEF", dates = dates_ref, temperatures = temps_ref,
                   annual_consumption = 15000)
#>      HEF 
#> 43.13977 

# Multiple profiles at once
slp_gas_kundenwert(c("HEF", "GKO", "GWA"), dates_ref, temps_ref,
                   annual_consumption = 15000)
#>      HEF      GKO      GWA 
#> 43.13977 41.23944 41.45100 
```
