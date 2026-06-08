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

BDEW/VKU/GEODE (2025). *Leitfaden Abwicklung von Standardlastprofilen
Gas*, Kooperationsvereinbarung Gas, Annex XIV.2, as of 2025-10-28,
Appendix 6.
<https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf>

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
# All 15 profiles, both variants (30 rows)
slp_gas_coefficients()
#>    profile_id variant         A         B         C         D theta0         mH
#> 1         HEF      34 1.3819663 -37.41242  6.172318 0.0396284     40 -0.0672159
#> 2         HMF      34 1.0443538 -35.03338  6.224063 0.0502917     40 -0.0535830
#> 3         HKO      34 0.4040932 -24.43930  6.571817 0.7107710     40  0.0000000
#> 4         GKO      34 1.4256684 -36.65905  7.608323 0.0371116     40 -0.0809359
#> 5         GHA      34 1.8398455 -37.82820  8.159337 0.0259710     40 -0.1069262
#> 6         GMK      34 1.3284913 -35.87151  7.518683 0.0175540     40 -0.0758983
#> 7         GBD      34 1.5175792 -37.50000  6.800000 0.0295801     40 -0.0788559
#> 8         GBH      34 0.9872585 -35.25321  6.058700 0.0793512     40 -0.0495013
#> 9         GWA      34 0.3925339 -35.30000  4.866275 0.3045099     40 -0.0167993
#> 10        GGA      34 1.1848320 -36.00000  7.736852 0.0793107     40 -0.0687383
#> 11        GBA      34 0.3537640 -33.35000  5.721230 0.3033305     40 -0.0177463
#> 12        GGB      34 1.6266812 -37.88254  6.983607 0.0297136     40 -0.0854333
#> 13        GPD      34 1.8834609 -37.00000 10.240502 0.0275470     40 -0.1253100
#> 14        GMF      34 1.0443538 -35.03338  6.224063 0.0502917     40 -0.0535830
#> 15        GHD      34 1.2569600 -36.60785  7.321187 0.0776960     40 -0.0696826
#> 16        HEF      33 1.6209544 -37.18331  5.672785 0.0716431     40 -0.0495700
#> 17        HMF      33 1.2328655 -34.72136  5.816430 0.0873352     40 -0.0409284
#> 18        HKO      33 0.4040932 -24.43930  6.571817 0.7107710     40  0.0000000
#> 19        GKO      33 1.3554515 -35.14126  7.130339 0.0990619     40 -0.0526487
#> 20        GHA      33 1.9724775 -36.96501  7.225695 0.0345782     40 -0.0742174
#> 21        GMK      33 1.4202419 -34.88061  6.595190 0.0385317     40 -0.0521084
#> 22        GBD      33 1.4633682 -36.17941  5.926516 0.0808835     40 -0.0475800
#> 23        GBH      33 0.9874283 -35.25321  6.154441 0.2265716     40 -0.0339020
#> 24        GWA      33 0.3337838 -36.02379  4.866275 0.4912280     40 -0.0092263
#> 25        GGA      33 1.1582082 -36.28786  6.588513 0.2235680     40 -0.0410335
#> 26        GBA      33 0.2770087 -33.00000  5.721230 0.4865118     40 -0.0094849
#> 27        GGB      33 1.8213778 -37.50000  6.346215 0.0678118     40 -0.0607666
#> 28        GPD      33 1.7110739 -35.80000  8.400000 0.0702546     40 -0.0745381
#> 29        GMF      33 1.2328655 -34.72136  5.816430 0.0873352     40 -0.0409284
#> 30        GHD      33 1.3010623 -35.68161  6.685798 0.1409267     40 -0.0473428
#>           bH         mW        bW
#> 1  1.1167138 -0.0019982 0.1355070
#> 2  0.9995901 -0.0021758 0.1633299
#> 3  0.0000000  0.0000000 0.0000000
#> 4  1.2364527 -0.0007628 0.1002979
#> 5  1.4552240 -0.0004920 0.0691851
#> 6  1.1942555 -0.0008980 0.0603337
#> 7  1.2161250 -0.0013134 0.0968721
#> 8  0.9637999 -0.0022304 0.2288398
#> 9  0.6710889 -0.0020301 0.5614623
#> 10 1.1308570 -0.0006587 0.1910301
#> 11 0.6825699 -0.0013912 0.5434624
#> 12 1.2709629 -0.0011319 0.0928124
#> 13 1.6275999 -0.0001105 0.0635119
#> 14 0.9995901 -0.0021758 0.1633299
#> 15 1.1379702 -0.0008522 0.1921068
#> 16 0.8401015 -0.0022090 0.1074468
#> 17 0.7672920 -0.0022320 0.1199207
#> 18 0.0000000  0.0000000 0.0000000
#> 19 0.8626086 -0.0008808 0.0964014
#> 20 1.0448869 -0.0008295 0.0461795
#> 21 0.8647919 -0.0014369 0.0637602
#> 22 0.8230754 -0.0019273 0.1077046
#> 23 0.6938234 -0.0012849 0.2029732
#> 24 0.4595757 -0.0009676 0.3964291
#> 25 0.7526451 -0.0009088 0.1916641
#> 26 0.4630237 -0.0007134 0.3867447
#> 27 0.9308159 -0.0013967 0.0850399
#> 28 1.0463005 -0.0003672 0.0621882
#> 29 0.7672920 -0.0022320 0.1199207
#> 30 0.8141691 -0.0010601 0.1325092

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
