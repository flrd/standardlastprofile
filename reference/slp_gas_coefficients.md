# Retrieve SigLinDe Coefficients for Gas Standard Load Profiles

Returns the SigLinDe profile function coefficients for one or more gas
standard load profiles as a data frame. These are the values used
internally by
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
and
[`slp_gas_siglinde()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_siglinde.md).

## Usage

``` r
slp_gas_coefficients(profile_id = NULL, variant = NULL)
```

## Source

BDEW/VKU/GEODE (2026). *Leitfaden Abwicklung von Standardlastprofilen
Gas*, Kooperationsvereinbarung Gas, Annex XV, as of 2026-03-27, Appendix
6.
<https://web.archive.org/web/20260619125016/https://www.bdew.de/media/documents/260327_LF_SLP_Gas_KoV_XV_CO4f7Rb.pdf>

## Arguments

- profile_id:

  character vector of gas profile identifiers. One or more of `"HEF"`,
  `"HMF"`, `"HKO"`, `"GKO"`, `"GHA"`, `"GMK"`, `"GBD"`, `"GBH"`,
  `"GWA"`, `"GGA"`, `"GBA"`, `"GGB"`, `"GPD"`, `"GMF"`, `"GHD"`. Pass
  `NULL` (the default) to retrieve all 15 profiles.

- variant:

  character vector of SigLinDe variants to include. One or both of
  `"34"` (57 % linear component) and `"33"` (45 % linear component).
  Pass `NULL` (the default) to retrieve both variants. Duplicate values
  are silently ignored.

## Value

A data frame with one row per profile–variant combination and 11
variables:

- profile_id:

  character, gas profile identifier

- variant:

  character, SigLinDe variant (`"34"` or `"33"`)

- A, B, C, D:

  numeric, sigmoid coefficients

- theta0:

  numeric, pole temperature (40 °C for all published profiles)

- mH, bH:

  numeric, slope and intercept of the space-heating line
  (*Heizgas-Gerade*)

- mW, bW:

  numeric, slope and intercept of the hot-water line
  (*Warmwasser-Gerade*)

## Details

The `HKO` profile (Kochgasprofil) is a pure sigmoid with no linear
component; its `mH`, `bH`, `mW`, and `bW` are all zero for both
variants.

The returned coefficients can be passed directly to
[`slp_gas_siglinde()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_siglinde.md)
for custom calculations. When selecting a single profile and variant the
result is a one-row data frame, so use `[[ ]]` or `$` to extract
scalars:

    p <- slp_gas_coefficients("HEF", variant = "34")
    slp_gas_siglinde(0, p$A, p$B, p$C, p$D, p$theta0, p$mH, p$bH, p$mW, p$bW)

\[ \]: R:%20

## See also

[`slp_gas_siglinde()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_siglinde.md),
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md),
[`slp_gas_weekday_factors()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_weekday_factors.md);
all values are listed in tabular form in the [SigLinDe
parameters](https://flrd.github.io/standardlastprofile/articles/slp-gas-parameters.html)
article.

## Examples

``` r
# Single profile, both variants
slp_gas_coefficients("HEF")
#>   profile_id variant        A         B        C         D theta0         mH
#> 1        HEF      34 1.381966 -37.41242 6.172318 0.0396284     40 -0.0672159
#> 2        HEF      33 1.620954 -37.18331 5.672785 0.0716431     40 -0.0495700
#>          bH         mW        bW
#> 1 1.1167138 -0.0019982 0.1355070
#> 2 0.8401015 -0.0022090 0.1074468

# Single profile, single variant
slp_gas_coefficients("HEF", variant = "34")
#>   profile_id variant        A         B        C         D theta0         mH
#> 1        HEF      34 1.381966 -37.41242 6.172318 0.0396284     40 -0.0672159
#>         bH         mW       bW
#> 1 1.116714 -0.0019982 0.135507

# Both variants explicitly — same as NULL
slp_gas_coefficients(c("HEF", "GKO"), variant = c("34", "33"))
#>   profile_id variant        A         B        C         D theta0         mH
#> 1        HEF      34 1.381966 -37.41242 6.172318 0.0396284     40 -0.0672159
#> 2        GKO      34 1.425668 -36.65905 7.608323 0.0371116     40 -0.0809359
#> 3        HEF      33 1.620954 -37.18331 5.672785 0.0716431     40 -0.0495700
#> 4        GKO      33 1.355452 -35.14126 7.130339 0.0990619     40 -0.0526487
#>          bH         mW        bW
#> 1 1.1167138 -0.0019982 0.1355070
#> 2 1.2364527 -0.0007628 0.1002979
#> 3 0.8401015 -0.0022090 0.1074468
#> 4 0.8626086 -0.0008808 0.0964014
```
