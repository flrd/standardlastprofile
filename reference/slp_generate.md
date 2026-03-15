# Generate a Standard Load Profile for Electricity

Generate a standard load profile in watts, normalised to an annual
consumption of 1,000 kWh.

## Usage

``` r
slp_generate(
  profile_id,
  start_date,
  end_date,
  holidays = NULL,
  state_code = deprecated()
)
```

## Source

<https://www.bdew.de/energie/standardlastprofile-strom/>

<https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>

<https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>

## Arguments

- profile_id:

  load profile identifier, required

- start_date:

  start date in ISO 8601 format, greater than or equal to
  `"1990-01-01"`, required

- end_date:

  end date in ISO 8601 format, no later than `"2073-12-31"`, required

- holidays:

  an optional character or Date vector of dates in ISO 8601 format
  (`"YYYY-MM-DD"`) that are treated as public holidays (and therefore
  mapped to `"sunday"` in the algorithm). When supplied, the built-in
  holiday data are ignored entirely and only the dates in `holidays` are
  used.

- state_code:

  **\[deprecated\]** Use `holidays` instead.

## Value

A data.frame with four variables:

- `profile_id`, character, load profile identifier

- `start_time`, POSIXct / POSIXlt, start time

- `end_time`, POSIXct / POSIXlt, end time

- `watts`, numeric, average electric power in watts per 15-minute
  interval, normalised to an annual consumption of 1,000 kWh

## Details

In the German electricity market, a standard load profile is a
representative pattern of electricity consumption used to forecast
demand for customer groups that are not continuously metered. For each
distinct combination of `profile_id`, `period`, and `day` there are 96
quarter-hourly measurements of electrical power, normalised to an annual
consumption of 1,000 kWh. This function supports data from 1990 to 2073.

See
[`vignette("standardlastprofile")`](https://flrd.github.io/standardlastprofile/articles/standardlastprofile.md)
for more details about the algorithm.

### Profile IDs

There are 16 profile IDs across two generations:

**1999 profiles**:

- `H0`: Households

- `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`: Commercial

- `L0`, `L1`, `L2`: Agriculture

**2025 profiles**

In 2025, BDEW published an updated set of standard load profiles
reflecting changes in electricity consumption patterns since the
original 1999 study. Five new profiles are included:

- `H25`: households — updated version of `H0`

- `G25`: commerce (general) — updated version of `G0`

- `L25`: agriculture — updated version of `L0`

- `P25`: combination profile for households with a photovoltaic (PV)
  system

- `S25`: combination profile for households with a PV system and battery
  storage

For descriptions of each profile, call
[`slp_info()`](https://flrd.github.io/standardlastprofile/reference/slp_info.md).

### Periods and day types

**1999 profiles** use three seasonal periods:

- `summer`: May 15 to September 14

- `winter`: November 1 to March 20

- `transition`: March 21 to May 14, and September 15 to October 31

**2025 profiles** use calendar months (`january` … `december`) instead
of seasons.

Within each period, days are classified as:

- `workday`: Monday to Friday

- `saturday`: Saturdays; Dec 24th and Dec 31st are also treated as
  Saturdays unless they fall on a Sunday

- `sunday`: Sundays and all public holidays

### Public holidays

By default, the following nine public holidays observed nationwide
across all German states are treated as Sundays:

- New Year's Day (1 January)

- Good Friday

- Easter Monday

- Labour Day (1 May)

- Ascension Day

- Whit Monday

- German Unity Day (3 October)

- Christmas Day (25 December)

- Boxing Day (26 December)

State-level holidays are **not** included by default. These vary by
state and can change — for example, Berlin observed a one-time holiday
on 8 May 2025 (end of World War II anniversary). Use the `holidays`
argument to supply your own dates instead; the built-in data are then
ignored entirely.

### Units and conversion

The 1999 source file stores values in watts (W), normalised to 1,000
kWh/a. The 2025 source file stores values in kWh per 15-minute interval,
normalised to 1,000,000 kWh/a. To keep all profiles consistent, the 2025
values are converted to watts normalised to 1,000 kWh/a.

To convert to energy consumed per interval in kWh:

    kwh <- out$watts / 4 / 1000

## Examples

``` r
start <- "2026-01-01"
end <- "2026-12-31"

# multiple profile IDs are supported
L <- slp_generate(c("L0", "L1", "L2"), start, end)
head(L)
#>   profile_id          start_time            end_time watts
#> 1         L0 2026-01-01 00:00:00 2026-01-01 00:15:00  68.3
#> 2         L0 2026-01-01 00:15:00 2026-01-01 00:30:00  66.0
#> 3         L0 2026-01-01 00:30:00 2026-01-01 00:45:00  64.3
#> 4         L0 2026-01-01 00:45:00 2026-01-01 01:00:00  63.0
#> 5         L0 2026-01-01 01:00:00 2026-01-01 01:15:00  62.1
#> 6         L0 2026-01-01 01:15:00 2026-01-01 01:30:00  61.4

# supply custom holiday dates (e.g. only treat New Year's Day as a holiday)
H0_custom <- slp_generate("H0", start, end, holidays = "2026-01-01")

# Fetch state-level holidays from the nager.Date API and pass them in.
# Each entry in the API response contains two relevant fields:
#   $global  — logical; TRUE = nationwide holiday, FALSE = state-specific
#   $counties — list of ISO 3166-2 state codes (e.g. "DE-BE" for Berlin)
#               when global is FALSE; NULL otherwise
#
# Berlin (DE-BE) observes International Women's Day (March 8) in addition
# to all nationwide holidays. The example below fetches 2027 holidays,
# keeps entries where global is TRUE or "DE-BE" appears in counties, and
# passes the resulting dates to slp_generate().
if (FALSE) { # \dontrun{
resp <- httr2::request("https://date.nager.at/api/v3") |>
  httr2::req_url_path_append("PublicHolidays", "2027", "DE") |>
  httr2::req_perform() |>
  httr2::resp_body_json()

is_berlin <- \(x) isTRUE(x$global) || "DE-BE" %in% unlist(x$counties)
holidays_berlin_2027 <- as.Date(
  vapply(Filter(is_berlin, resp), \(x) x$date, character(1))
)

H0_berlin_2027 <- slp_generate(
  "H0", "2027-01-01", "2027-12-31",
  holidays = holidays_berlin_2027
)
} # }

# consider only nationwide public holidays (default)
H0_2026 <- slp_generate("H0", start, end)

# when the deprecated state_code and holidays are both supplied, both sets
# of dates are treated as Sundays: user-provided dates from holidays and
# state-specific built-in holidays from state_code are merged
suppressWarnings(
  slp_generate("G0", "2026-04-01", "2026-04-01",
    state_code = "SL", holidays = "2026-04-01") |>
    head()
)
#>   profile_id          start_time            end_time watts
#> 1         G0 2026-04-01 00:00:00 2026-04-01 00:15:00  68.3
#> 2         G0 2026-04-01 00:15:00 2026-04-01 00:30:00  66.5
#> 3         G0 2026-04-01 00:30:00 2026-04-01 00:45:00  64.6
#> 4         G0 2026-04-01 00:45:00 2026-04-01 01:00:00  62.6
#> 5         G0 2026-04-01 01:00:00 2026-04-01 01:15:00  60.3
#> 6         G0 2026-04-01 01:15:00 2026-04-01 01:30:00  57.9

# electric power values are normalised to consumption of ~1,000 kWh/a
sum(H0_2026$watts / 4 / 1000)
#> [1] 998.1163

# convert watts to kWh per interval using a wrapper
slp_generate_kwh <- \(...) {
  out <- slp_generate(...)
  out$kwh <- out$watts / 4 / 1000
  out
}
H0_kwh <- slp_generate_kwh("H0", start, end)
head(H0_kwh)
#>   profile_id          start_time            end_time     watts        kwh
#> 1         H0 2026-01-01 00:00:00 2026-01-01 00:15:00 108.67764 0.02716941
#> 2         H0 2026-01-01 00:15:00 2026-01-01 00:30:00 100.72864 0.02518216
#> 3         H0 2026-01-01 00:30:00 2026-01-01 00:45:00  93.15226 0.02328806
#> 4         H0 2026-01-01 00:45:00 2026-01-01 01:00:00  85.82428 0.02145607
#> 5         H0 2026-01-01 01:00:00 2026-01-01 01:15:00  78.74471 0.01968618
#> 6         H0 2026-01-01 01:15:00 2026-01-01 01:30:00  72.28615 0.01807154
```
