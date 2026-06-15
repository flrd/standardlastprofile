# Compute Dimensionless Daily Heating Demand (SigLinDe)

Computes the dimensionless daily heating demand \\h(\vartheta)\\ for a
given outdoor temperature using the SigLinDe method.

## Usage

``` r
slp_gas_siglinde(theta, A, B, C, D, theta0, mH, bH, mW, bW)
```

## Arguments

- theta:

  Numeric vector of daily mean outdoor temperatures in °C (the daily
  temperature).

- A, B, C, D:

  Numeric scalars — sigmoid coefficients.

- theta0:

  Numeric scalar — pole temperature (40 °C for all published profiles).
  The function is undefined at \\\vartheta = \vartheta_0\\ and
  physically meaningless above it.

- mH, bH:

  Numeric scalars — slope and intercept of the heating linear component
  (*Heizgas-Gerade*).

- mW, bW:

  Numeric scalars — slope and intercept of the hot-water linear
  component (*Warmwasser-Gerade*).

## Value

A numeric vector the same length as `theta` giving the dimensionless
profile value \\h(\vartheta)\\ for each temperature.

## Details

The function value is the sum of a sigmoid part and a linear part:

\$\$h(\vartheta) = \frac{A}{1 + \left(\frac{B}{\vartheta -
\vartheta_0}\right)^C} + D + \max(m_H \vartheta + b_H,\\ m_W \vartheta +
b_W)\$\$

The sigmoid captures the non-linear relationship between outdoor
temperature and heating demand. The linear envelope of two lines
represents space-heating demand (*Heizgas-Gerade*, slope `mH`) and
hot-water demand (*Warmwasser-Gerade*, slope `mW`).

For residential profiles (e.g. `HEF`, `HMF`) both parts contribute. For
the `HKO` (TUM) profile the linear coefficients are all zero, so only
the sigmoid part remains.

This is the low-level building block used internally by
[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md).
It is exported so that users with custom or region-specific coefficients
(e.g. state-level parameters such as `BW_HEF03` for Baden-Württemberg)
can compute \\h(\vartheta)\\ directly and build their own profiles.

Published coefficients for all 15 standard profiles are listed in the
[SigLinDe
parameters](https://flrd.github.io/standardlastprofile/articles/slp-gas-parameters.html)
article.

## References

BDEW/VKU/GEODE (2025). *Abwicklung von Standardlastprofilen Gas*,
Kooperationsvereinbarung Gas, Annex XIV.2, as of 2025-10-28. The unified
SigLinDe profile function is shown on p. 42 (Abbildung 12; PDF page 54);
the per-profile coefficients are tabulated in Appendix 6, pp. 145–166.
<https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf>

## See also

[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md);
[SigLinDe
parameters](https://flrd.github.io/standardlastprofile/articles/slp-gas-parameters.html)
article

## Examples

``` r
# h value at 0 °C for HEF (single-family home), variant 34
slp_gas_siglinde(
  theta = 0,
  A = 1.3819663, B = -37.4124155, C = 6.1723179, D = 0.0396284,
  theta0 = 40,
  mH = -0.0672159, bH = 1.1167138,
  mW = -0.0019982, bW = 0.1355070
)
#> [1] 1.987948

# h values across a temperature range
temps <- seq(-15, 30, by = 5)
slp_gas_siglinde(
  theta = temps,
  A = 1.3819663, B = -37.4124155, C = 6.1723179, D = 0.0396284,
  theta0 = 40,
  mH = -0.0672159, bH = 1.1167138,
  mW = -0.0019982, bW = 0.1355070
)
#>  [1] 3.4293065 3.0127624 2.5394535 1.9879480 1.3710776 0.7657901 0.2540835
#>  [8] 0.1635316 0.1300671 0.1155908
```
