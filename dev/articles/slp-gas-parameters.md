# SigLinDe Parameters and Weekday Factors for Gas SLP

This article provides reference tables for all parameters used by
[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
to compute daily gas consumption under the BDEW/VKU/GEODE standard load
profile procedure. To retrieve these values programmatically, use
[`slp_gas_coefficients()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_coefficients.md)
for the SigLinDe coefficients and
[`slp_gas_weekday_factors()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_weekday_factors.md)
for the weekday factors.

## Source

All values are taken from the **BDEW/VKU/GEODE Leitfaden — Abwicklung
von Standardlastprofilen Gas**, pages 146–167.[^1]

## Profile overview

The BDEW Leitfaden defines 15 gas standard load profiles. Three are
residential (prefix ‘H’ for “Haushalt”) and twelve are commercial or
industrial (prefix ‘G’ for “Gewerbe”).

| Profile | Description                            | German                 |
|:--------|:---------------------------------------|:-----------------------|
| HEF     | Single-family home                     | Einfamilienhaus        |
| HMF     | Multi-family home                      | Mehrfamilienhaus       |
| HKO     | Cooking and hot water only             | Kochen / Warmwasser    |
| GKO     | Small commercial                       | Kleinstgewerbe         |
| GHA     | Trade and commerce                     | Handel                 |
| GMK     | Metal and automotive                   | Metall / Kfz           |
| GBD     | Services                               | Dienstleistung         |
| GBH     | Accommodation                          | Beherbergung           |
| GWA     | Laundries                              | Wäscherei              |
| GGA     | Gastronomy                             | Gastronomie            |
| GBA     | Bakeries                               | Bäckerei               |
| GGB     | Mixed commercial                       | Gemischtes Gewerbe     |
| GPD     | Paper and printing                     | Papier / Druck         |
| GMF     | Large multi-family / mixed use         | Mehrfamilienhaus gross |
| GHD     | Trade, commerce and services aggregate | GHD-Stützpunkt         |

Table 1: BDEW gas standard load profile identifiers and descriptions.
{.table}

## SigLinDe coefficients

Daily gas consumption is computed using the **SigLinDe** method
(Sigmoid + Linear + Deutschland). The dimensionless daily heating demand
\\h(\vartheta)\\ for a daily temperature \\\vartheta\\ (in °C) is:

\\h(\vartheta) = \frac{A}{1 + \left(\frac{B}{\vartheta -
\vartheta_0}\right)^C} + D + \max\left(m_H \cdot \vartheta + b_H,\\ m_W
\cdot \vartheta + b_W\right)\\

Each profile has its own set of nine coefficients. The linear component
\\\max(m_H \vartheta + b_H,\\ m_W \vartheta + b_W)\\ represents the
envelope of a space-heating line (*Heizgas-Gerade*) and a hot-water line
(*Warmwasser-Gerade*). The parameters differ between **variant 34** (57
% linear component, default) and **variant 33** (45 % linear component).

Use
[`slp_gas_coefficients()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_coefficients.md)
to retrieve these values in R:

``` r

slp_gas_coefficients()                        # all 15 profiles, both variants (30 rows)
slp_gas_coefficients(variant = "34")         # all profiles, variant 34 only
slp_gas_coefficients("HEF")                  # one profile, both variants
slp_gas_coefficients("HEF", variant = "33")  # one profile, one variant
```

### Variant 34 (Ausprägung 34)

| Profile | A | B | C | D | theta_0 | m_H | b_H | m_W | b_W |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| HEF | 1.3819663 | -37.41242 | 6.172318 | 0.0396284 | 40 | -0.0672159 | 1.1167138 | -0.0019982 | 0.1355070 |
| HMF | 1.0443538 | -35.03338 | 6.224063 | 0.0502917 | 40 | -0.0535830 | 0.9995901 | -0.0021758 | 0.1633299 |
| HKO | 0.4040932 | -24.43930 | 6.571817 | 0.7107710 | 40 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0000000 |
| GKO | 1.4256684 | -36.65905 | 7.608323 | 0.0371116 | 40 | -0.0809359 | 1.2364527 | -0.0007628 | 0.1002979 |
| GHA | 1.8398455 | -37.82820 | 8.159337 | 0.0259710 | 40 | -0.1069262 | 1.4552240 | -0.0004920 | 0.0691851 |
| GMK | 1.3284913 | -35.87151 | 7.518683 | 0.0175540 | 40 | -0.0758983 | 1.1942555 | -0.0008980 | 0.0603337 |
| GBD | 1.5175792 | -37.50000 | 6.800000 | 0.0295801 | 40 | -0.0788559 | 1.2161250 | -0.0013134 | 0.0968721 |
| GBH | 0.9872585 | -35.25321 | 6.058700 | 0.0793512 | 40 | -0.0495013 | 0.9637999 | -0.0022304 | 0.2288398 |
| GWA | 0.3925339 | -35.30000 | 4.866275 | 0.3045099 | 40 | -0.0167993 | 0.6710889 | -0.0020301 | 0.5614623 |
| GGA | 1.1848320 | -36.00000 | 7.736852 | 0.0793107 | 40 | -0.0687383 | 1.1308570 | -0.0006587 | 0.1910301 |
| GBA | 0.3537640 | -33.35000 | 5.721230 | 0.3033305 | 40 | -0.0177463 | 0.6825699 | -0.0013912 | 0.5434624 |
| GGB | 1.6266812 | -37.88254 | 6.983607 | 0.0297136 | 40 | -0.0854333 | 1.2709629 | -0.0011319 | 0.0928124 |
| GPD | 1.8834609 | -37.00000 | 10.240502 | 0.0275470 | 40 | -0.1253100 | 1.6275999 | -0.0001105 | 0.0635119 |
| GMF | 1.0443538 | -35.03338 | 6.224063 | 0.0502917 | 40 | -0.0535830 | 0.9995901 | -0.0021758 | 0.1633299 |
| GHD | 1.2569600 | -36.60785 | 7.321187 | 0.0776960 | 40 | -0.0696826 | 1.1379702 | -0.0008522 | 0.1921068 |

Table 2: SigLinDe coefficients — variant 34 (Ausprägung 34, 57 % linear
component). Source: BDEW Leitfaden, Appendix 6, pp. 146–167. {.table}

### Variant 33 (Ausprägung 33)

| Profile | A | B | C | D | theta_0 | m_H | b_H | m_W | b_W |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| HEF | 1.6209544 | -37.18331 | 5.672785 | 0.0716431 | 40 | -0.0495700 | 0.8401015 | -0.0022090 | 0.1074468 |
| HMF | 1.2328655 | -34.72136 | 5.816430 | 0.0873352 | 40 | -0.0409284 | 0.7672920 | -0.0022320 | 0.1199207 |
| HKO | 0.4040932 | -24.43930 | 6.571817 | 0.7107710 | 40 | 0.0000000 | 0.0000000 | 0.0000000 | 0.0000000 |
| GKO | 1.3554515 | -35.14126 | 7.130339 | 0.0990619 | 40 | -0.0526487 | 0.8626086 | -0.0008808 | 0.0964014 |
| GHA | 1.9724775 | -36.96501 | 7.225695 | 0.0345782 | 40 | -0.0742174 | 1.0448869 | -0.0008295 | 0.0461795 |
| GMK | 1.4202419 | -34.88061 | 6.595190 | 0.0385317 | 40 | -0.0521084 | 0.8647919 | -0.0014369 | 0.0637602 |
| GBD | 1.4633682 | -36.17941 | 5.926516 | 0.0808835 | 40 | -0.0475800 | 0.8230754 | -0.0019273 | 0.1077046 |
| GBH | 0.9874283 | -35.25321 | 6.154441 | 0.2265716 | 40 | -0.0339020 | 0.6938234 | -0.0012849 | 0.2029732 |
| GWA | 0.3337838 | -36.02379 | 4.866275 | 0.4912280 | 40 | -0.0092263 | 0.4595757 | -0.0009676 | 0.3964291 |
| GGA | 1.1582082 | -36.28786 | 6.588513 | 0.2235680 | 40 | -0.0410335 | 0.7526451 | -0.0009088 | 0.1916641 |
| GBA | 0.2770087 | -33.00000 | 5.721230 | 0.4865118 | 40 | -0.0094849 | 0.4630237 | -0.0007134 | 0.3867447 |
| GGB | 1.8213778 | -37.50000 | 6.346215 | 0.0678118 | 40 | -0.0607666 | 0.9308159 | -0.0013967 | 0.0850399 |
| GPD | 1.7110739 | -35.80000 | 8.400000 | 0.0702546 | 40 | -0.0745381 | 1.0463005 | -0.0003672 | 0.0621882 |
| GMF | 1.2328655 | -34.72136 | 5.816430 | 0.0873352 | 40 | -0.0409284 | 0.7672920 | -0.0022320 | 0.1199207 |
| GHD | 1.3010623 | -35.68161 | 6.685798 | 0.1409267 | 40 | -0.0473428 | 0.8141691 | -0.0010601 | 0.1325092 |

Table 3: SigLinDe coefficients — variant 33 (Ausprägung 33, 45 % linear
component). Source: BDEW Leitfaden, Appendix 6, pp. 146–167. {.table}

Use
[`slp_gas_coefficients()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_coefficients.md)
to retrieve these coefficients for one or more profiles:

``` r

slp_gas_coefficients()                        # all 15 profiles, variant 34
slp_gas_coefficients("HEF", variant = "33")  # single profile, variant 33
```

### Notes

- `HKO` (cooking and hot water only) has \\m_H = b_H = m_W = b_W = 0\\:
  the linear part is zero and only the sigmoid remains.
- `HMF` and `GMF` share identical coefficients in both variants — `GMF`
  (large multi-family / mixed use) uses the residential multi-family
  curve.
- \\\vartheta_0 = 40\\°C\\ for all profiles (the pole temperature of the
  sigmoid).

## Weekday factors (\\F\_{WT}\\)

The weekday factor \\F\_{WT}\\ scales daily consumption for day-of-week
effects. Residential profiles (`HEF`, `HMF`, `HKO`) have all factors
equal to 1 — no weekday differentiation.

| Profile |     Mo |     Tu |     We |     Th |     Fr |     Sa |     Su |
|:--------|-------:|-------:|-------:|-------:|-------:|-------:|-------:|
| HEF     | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| HMF     | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| HKO     | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| GKO     | 1.0354 | 1.0523 | 1.0449 | 1.0494 | 0.9885 | 0.8860 | 0.9435 |
| GHA     | 1.0358 | 1.0232 | 1.0252 | 1.0295 | 1.0253 | 0.9675 | 0.8935 |
| GMK     | 1.0699 | 1.0365 | 0.9933 | 0.9948 | 1.0659 | 0.9362 | 0.9034 |
| GBD     | 1.1052 | 1.0857 | 1.0378 | 1.0622 | 1.0266 | 0.7629 | 0.9196 |
| GBH     | 0.9767 | 1.0389 | 1.0028 | 1.0162 | 1.0024 | 1.0043 | 0.9587 |
| GWA     | 1.2457 | 1.2615 | 1.2707 | 1.2430 | 1.1276 | 0.3877 | 0.4638 |
| GGA     | 0.9322 | 0.9894 | 1.0033 | 1.0109 | 1.0180 | 1.0356 | 1.0106 |
| GBA     | 1.0848 | 1.1211 | 1.0769 | 1.1353 | 1.1402 | 0.4852 | 0.9565 |
| GGB     | 0.9897 | 0.9627 | 1.0507 | 1.0552 | 1.0297 | 0.9767 | 0.9353 |
| GPD     | 1.0214 | 1.0866 | 1.0720 | 1.0557 | 1.0117 | 0.9001 | 0.8525 |
| GMF     | 1.0354 | 1.0523 | 1.0449 | 1.0494 | 0.9885 | 0.8860 | 0.9435 |
| GHD     | 1.0300 | 1.0300 | 1.0200 | 1.0300 | 1.0100 | 0.9300 | 0.9500 |

Table 4: Weekday factors (F_WT) for all 15 BDEW gas standard load
profiles. Mo = Monday, …, Su = Sunday. Source: BDEW Leitfaden, Appendix
6, pp. 146–167. {.table}

Use
[`slp_gas_weekday_factors()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_weekday_factors.md)
to retrieve these values:

``` r

slp_gas_weekday_factors()        # all 15 profiles, tidy (long) format
slp_gas_weekday_factors("GWA")  # single profile
```

### Notes

- Weekday factors are the same for both variant 33 and variant 34.

[^1]: The document is available at
    <https://web.archive.org/web/20260619125016/https://www.bdew.de/media/documents/260327_LF_SLP_Gas_KoV_XV_CO4f7Rb.pdf>
