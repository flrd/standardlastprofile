# Generate a Standard Load Profile

Generate a standard load profile, normalized to an annual consumption of
1,000 kWh.

## Usage

``` r
slp_generate(
  profile_id,
  start_date,
  end_date,
  holidays = NULL,
  unit = "W",
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

  start date in ISO 8601 format, required

- end_date:

  end date in ISO 8601 format, required

- holidays:

  an optional character or Date vector of dates in ISO 8601 format
  (`"YYYY-MM-DD"`) that are treated as public holidays (and therefore
  mapped to `"sunday"` in the algorithm). When supplied, the built-in
  holiday data are ignored entirely and only the dates in `holidays` are
  used.

- unit:

  one of `"W"` (default) or `"KWH"`. Controls the unit of the returned
  `watts` column. `"W"` returns average electric power in watts for each
  15-minute interval. `"KWH"` converts to energy consumed during each
  interval in kilowatt-hours (`watts * 0.25 / 1000`). Matching is
  case-insensitive, so `"kWh"` is accepted.

- state_code:

  **\[deprecated\]** Use `holidays` instead.

## Value

A data.frame with four variables:

- `profile_id`, character, load profile identifier

- `start_time`, POSIXct / POSIXlt, start time

- `end_time`, POSIXct / POSIXlt, end time

- `watts`, numeric, electric power

## Details

In regards to the electricity market in Germany, the term "Standard Load
Profile" refers to a representative pattern of electricity consumption
over a specific period. These profiles can be used to depict the
expected electricity consumption for various customer groups, such as
households or businesses.

For each distinct combination of `profile_id`, `period`, and `day`,
there are 96 x 1/4 hour measurements of electrical power. Values are
normalized so that they correspond to an annual consumption of 1,000
kWh. That is, summing up all the quarter-hourly consumption values for
one year yields an approximate total of 1,000 kWh/a; for more
information, refer to the 'Examples' section, or call
[`vignette("algorithm-step-by-step")`](https://flrd.github.io/standardlastprofile/dev/articles/algorithm-step-by-step.md).

In total there are 11 `profile_id` for three different customer groups:

- Households: `H0`

- Commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`

- Agriculture: `L0`, `L1`, `L2`

For more information and examples, call
[`slp_info()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_info.md).

Period definitions:

- `summer`: May 15 to September 14

- `winter`: November 1 to March 20

- `transition`: March 21 to May 14, and September 15 to October 31

Day definitions:

- `workday`: Monday to Friday

- `saturday`: Saturdays; Dec 24th and Dec 31st are considered Saturdays
  too if they are not a Sunday

- `sunday`: Sundays and all public holidays

**Note**: By default, the package uses built-in nationwide public
holiday data for Germany (1990–2073). Use `holidays` to supply your own
set of holiday dates instead.

`start_date` must be greater or equal to "1990-01-01" and `end_date`
must be smaller or equal to "2073-12-31".

## Examples

``` r
start <- "2024-01-01"
end <- "2024-12-31"

# multiple profile IDs are supported
L <- slp_generate(c("L0", "L1", "L2"), start, end)
head(L)
#>   profile_id          start_time            end_time watts
#> 1         L0 2024-01-01 00:00:00 2024-01-01 00:15:00  68.3
#> 2         L0 2024-01-01 00:15:00 2024-01-01 00:30:00  66.0
#> 3         L0 2024-01-01 00:30:00 2024-01-01 00:45:00  64.3
#> 4         L0 2024-01-01 00:45:00 2024-01-01 01:00:00  63.0
#> 5         L0 2024-01-01 01:00:00 2024-01-01 01:15:00  62.1
#> 6         L0 2024-01-01 01:15:00 2024-01-01 01:30:00  61.4

# supply custom holiday dates (e.g. only treat New Year's Day as a holiday)
H0_custom <- slp_generate("H0", start, end, holidays = "2024-01-01")

# consider only nationwide public holidays (default)
H0_2024 <- slp_generate("H0", start, end)

# electric power values are normalized to consumption of ~1,000 kWh/a
sum(H0_2024$watts / 4 / 1000)
#> [1] 1002.084
```
