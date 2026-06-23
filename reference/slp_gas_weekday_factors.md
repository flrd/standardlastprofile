# Retrieve Weekday Factors for Gas Standard Load Profiles

Returns the weekday scaling factors (\\F\_{WT}\\) for one or more gas
standard load profiles as a data frame. These are the values used
internally by
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md).

## Usage

``` r
slp_gas_weekday_factors(profile_id = NULL)
```

## Source

BDEW/VKU/GEODE (2026). *Leitfaden Abwicklung von Standardlastprofilen
Gas*, Kooperationsvereinbarung Gas, Annex XV, as of 2026-03-27, Appendix
6.
<https://web.archive.org/web/20260619125016/https://www.bdew.de/media/documents/260327_LF_SLP_Gas_KoV_XV_CO4f7Rb.pdf>

## Arguments

- profile_id:

  character vector of gas profile identifiers. Same values as
  [`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md).
  Pass `NULL` (the default) to retrieve all 15 profiles.

## Value

A data frame with one row per profile–day combination and 3 variables:

- profile_id:

  character, gas profile identifier

- day:

  character, abbreviated weekday: `"Mo"`, `"Tu"`, `"We"`, `"Th"`,
  `"Fr"`, `"Sa"`, `"Su"`

- f_wt:

  numeric, weekday scaling factor

## Details

For the residential profiles `HEF`, `HMF`, and `HKO` all weekday factors
are 1: gas consumption in households is assumed not to vary by day of
the week. Commercial profiles show sector-specific patterns — for
example, `GWA` (laundries) has high Monday–Wednesday factors (busy wash
days) and very low weekend factors.

Public holidays are treated as Sunday (`"Su"`); 24 and 31 December are
treated as Saturday (`"Sa"`) unless they fall on a Sunday. See
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
for details.

## See also

[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md),
[`slp_gas_coefficients()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_coefficients.md);
all values are listed in tabular form in the [SigLinDe
parameters](https://flrd.github.io/standardlastprofile/articles/slp-gas-parameters.html)
article.

## Examples

``` r
slp_gas_weekday_factors(c("HEF", "GWA"))
#>    profile_id day   f_wt
#> 1         HEF  Mo 1.0000
#> 2         HEF  Tu 1.0000
#> 3         HEF  We 1.0000
#> 4         HEF  Th 1.0000
#> 5         HEF  Fr 1.0000
#> 6         HEF  Sa 1.0000
#> 7         HEF  Su 1.0000
#> 8         GWA  Mo 1.2457
#> 9         GWA  Tu 1.2615
#> 10        GWA  We 1.2707
#> 11        GWA  Th 1.2430
#> 12        GWA  Fr 1.1276
#> 13        GWA  Sa 0.3877
#> 14        GWA  Su 0.4638
```
