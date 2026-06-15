# Get started

A **standard load profile** (German: *Standardlastprofil*, SLP) is a
representative pattern of energy consumption used by the German energy
industry to forecast demand for customer groups that are not
continuously metered. The profiles are published by the BDEW
(Bundesverband der Energie- und Wasserwirtschaft e.V.) and form the
basis of balancing and settlement in the German electricity and gas
markets.

This package provides functions to generate standard load profiles for
**electricity** and **gas**.

## Electricity

[`slp_electricity()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_electricity.md)
produces a 15-minute resolution load profile in watts, normalised to an
annual consumption of 1,000 kWh.

``` r
library(standardlastprofile)

G5 <- slp_electricity(
  profile_id = "G5",
  start_date = "2026-01-12",
  end_date   = "2026-01-18"
)

head(G5)
#>   profile_id          start_time            end_time watts
#> 1         G5 2026-01-12 00:00:00 2026-01-12 00:15:00  50.1
#> 2         G5 2026-01-12 00:15:00 2026-01-12 00:30:00  47.4
#> 3         G5 2026-01-12 00:30:00 2026-01-12 00:45:00  44.9
#> 4         G5 2026-01-12 00:45:00 2026-01-12 01:00:00  43.3
#> 5         G5 2026-01-12 01:00:00 2026-01-12 01:15:00  43.0
#> 6         G5 2026-01-12 01:15:00 2026-01-12 01:30:00  43.8
```

See
[`?slp_electricity`](https://flrd.github.io/standardlastprofile/dev/reference/slp_electricity.md)
for the full list of profile IDs, and the [electricity algorithm
article](https://flrd.github.io/standardlastprofile/dev/articles/slp-electricity.md)
for a detailed explanation of the algorithm.

## Gas

[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
produces daily gas consumption in kWh. It requires daily (mean)
temperatures and a `kundenwert` (customer value, kWh/day). The
Kundenwert is derived once from a full reference year with
[`slp_gas_kundenwert()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_kundenwert.md);
here we pass a known value:

``` r
dates <- seq.Date(as.Date("2026-01-12"), as.Date("2026-01-18"), by = "day")
temps <- c(-3.2, -1.8, 0.4, 2.1, 4.5, 3.8, 1.2)

slp_gas(
  profile_id   = "HEF",
  dates        = dates,
  temperatures = temps,
  kundenwert   = 3.055241
)
#>   profile_id       date      kwh
#> 1        HEF 2026-01-12 7.181257
#> 2        HEF 2026-01-13 6.709228
#> 3        HEF 2026-01-14 5.928369
#> 4        HEF 2026-01-15 5.297084
#> 5        HEF 2026-01-16 4.381003
#> 6        HEF 2026-01-17 4.649755
#> 7        HEF 2026-01-18 5.633867
```

See
[`?slp_gas`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
for the full list of gas profile IDs, and the [gas algorithm
article](https://flrd.github.io/standardlastprofile/dev/articles/slp-gas.md)
for a detailed explanation of the parameters and the algorithm.

## Further reading

- [Electricity SLP
  algorithm](https://flrd.github.io/standardlastprofile/dev/articles/slp-electricity.md)
  — in detail
- [Gas SLP
  algorithm](https://flrd.github.io/standardlastprofile/dev/articles/slp-gas.md)
  — SigLinDe method, Kundenwert, and climate zone comparison in detail
- [SigLinDe
  parameters](https://flrd.github.io/standardlastprofile/dev/articles/slp-gas-parameters.md)
  — reference tables of all SigLinDe coefficients and weekday factors
