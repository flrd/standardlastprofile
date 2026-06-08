# Generate a Standard Load Profile for Electricity

**\[superseded\]**

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

## Arguments

- profile_id:

  load profile identifier, required

- start_date:

  start date in ISO 8601 format, required

- end_date:

  end date in ISO 8601 format, required

- holidays:

  controls public holiday treatment:

  - `NULL` (default): built-in nationwide German holidays are used.

  - `NA`: no dates are treated as public holidays.

  - a character or Date vector in ISO 8601 format (`"YYYY-MM-DD"`): only
    these dates are treated as public holidays; the built-in data are
    ignored entirely.

- state_code:

  **\[defunct\]** Removed in version 2.0.0. Use `holidays` instead.

## Value

See
[`slp_electricity()`](https://flrd.github.io/standardlastprofile/reference/slp_electricity.md).

## Details

Please use
[`slp_electricity()`](https://flrd.github.io/standardlastprofile/reference/slp_electricity.md)
instead.

## Examples

``` r
# Superseded — use slp_electricity() instead:
if (FALSE) { # \dontrun{
slp_generate("H0", "2026-01-01", "2026-12-31")
} # }
```
