# Generate a Standard Load Profile for Gas

Generate daily gas consumption values using the BDEW/VKU/GEODE synthetic
standard load profile procedure (SigLinDe method).

## Usage

``` r
slp_gas(
  profile_id,
  dates,
  temperatures,
  kundenwert,
  variant = c("34", "33"),
  holidays = NULL
)
```

## Source

<https://www.bdew.de/energie/standardlastprofile-gas/>

BDEW/VKU/GEODE. *Leitfaden Abwicklung von Standardlastprofilen Gas*,
Kooperationsvereinbarung Gas, Annex XIV.2, as of 2025-10-28, Appendix 6.
<https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf>

## Arguments

- profile_id:

  gas load profile identifier, required. One of `"HEF"`, `"HMF"`,
  `"HKO"`, `"GKO"`, `"GHA"`, `"GMK"`, `"GBD"`, `"GBH"`, `"GWA"`,
  `"GGA"`, `"GBA"`, `"GGB"`, `"GPD"`, `"GMF"`, `"GHD"`. Multiple values
  are supported.

- dates:

  a Date vector or character vector in ISO 8601 format (`"YYYY-MM-DD"`).
  Each element is the **start date** of a gas day (German: *Gastag*,
  06:00–06:00). Must have the same length as `temperatures`.

- temperatures:

  a numeric vector of daily temperatures in degrees Celsius, one value
  per gas day. Must have the same length as `dates`. The temperature
  should be the allocation temperature (German: *Allokationstemperatur*)
  for that gas day. Two options are supported by the Leitfaden (see
  Details):

  - **Simple daily mean** (*Tagesmitteltemperatur*): arithmetic average
    of hourly values over the gas day.

  - **Geometrically-weighted 4-day mean**: recommended by BDEW for
    distribution network operators.

  In production contexts, distribution network operators increasingly
  use the **gas forecast temperature** (German: *Gasprognosetemperatur*,
  GPT) published by DWD or DTN instead of a raw daily mean. The GPT
  incorporates a multi-day weighted average and seasonal adjustment that
  reduces the systematic seasonal allocation bias of pure
  temperature-based profiles (VKU SLP evaluation reports 2023, 2025).
  This function accepts whichever temperature values are passed; the
  choice of method is the caller's responsibility.

- kundenwert:

  numeric scalar, required. Customer value (Kundenwert) in kWh/day — the
  daily gas consumption at the reference temperature of 8 °C. Derive it
  once from a full reference year with
  [`slp_gas_kundenwert()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_kundenwert.md),
  or supply a value you already know. See Details.

- variant:

  SigLinDe variant (German: *Ausprägung*) to use. Either `"34"`
  (default) or `"33"`. Variant 34 has a 57 % linear component and a
  steeper heating slope; variant 33 has a 45 % linear component. The
  BDEW Leitfaden recommends that distribution network operators test
  both variants against their own grid data and select the better fit.
  See Details.

  The `"HKO"` profile is a pure sigmoid with no linear part and is
  unaffected by this argument.

- holidays:

  controls public holiday treatment:

  - `NULL` (default): built-in nationwide German holidays are used.

  - `NA`: no dates are treated as public holidays.

  - a character or Date vector in ISO 8601 format (`"YYYY-MM-DD"`): only
    these dates are treated as public holidays; the built-in data are
    ignored entirely.

## Value

A data.frame with three variables:

- `profile_id`, character, gas load profile identifier

- `date`, Date, start date of the gas day (06:00 local time)

- `kwh`, numeric, estimated gas consumption in kWh for that gas day

## Details

### Background

In the (German) gas market, standard load profiles (Standardlastprofile,
SLP) are used to allocate gas volumes to low-pressure customers who are
not continuously metered. The synthetic procedure computes a daily gas
quantity as:

\$\$Q(D) = KW \times h(\vartheta_D) \times F\_{WT}\$\$

where:

- \\KW\\ is a customer-specific scaling factor in kWh/day (German:
  *Kundenwert*).

- \\h(\vartheta_D)\\ is the SigLinDe profile function value for the
  daily temperature \\\vartheta_D\\.

- \\F\_{WT}\\ is the weekday factor for the profile and day type.

### SigLinDe Profile Function

The SigLinDe function is defined in two variants (German:
*Ausprägungen*). The pure sigmoid term was introduced by TU München
(Geiger / Hellwig 2002); the linear envelope on top — together with the
33 / 34 variant split — was added by FfE in the 2015 research report
*Weiterentwicklung des Standard- lastprofilverfahrens Gas* (Appendix
7.1). The current operational coefficient set is published in the BDEW
Leitfaden, Appendix 6 (as of 2025-10-28):

\$\$h(\vartheta) = \frac{A}{1 + \left(\frac{B}{\vartheta -
\vartheta_0}\right)^C} + D + \max(m_H \vartheta + b_H,\\ m_W \vartheta +
b_W)\$\$

The first four terms form the sigmoid part; the last term is the linear
part (space-heating and hot water lines). Variant 34 (57 % linear
component, steeper heating slope) is the default. Variant 33 (45 %
linear component) is an alternative for distribution network areas where
it fits better. Distribution network operators are advised to test both
against their own grid data.

The `HKO` profile (Kochgasprofil) is a pure sigmoid retained from the
pre-SigLinDe era; it has no 33/34 variant and its linear part is always
zero.

### Allocation temperature

The allocation temperature can be computed in two ways:

**Simple daily mean** — arithmetic mean of hourly temperatures:
\$\$\vartheta_D = \frac{1}{24} \sum\_{h=1}^{24} T_h\$\$

**Geometrically-weighted 4-day mean** (recommended by BDEW for network
operators): \$\$\vartheta_D = \frac{T_D + 0.5 \times T\_{D-1} + 0.25
\times T\_{D-2} + 0.125 \times T\_{D-3}}{1.875}\$\$

This function accepts whichever temperature values the user provides in
`temperatures`; the choice of method is the user's responsibility.

### Kundenwert

The Kundenwert \\KW\\ scales the dimensionless profile to a customer's
actual consumption and is a **required** input. The recommended workflow
is two steps:

1.  Derive \\KW\\ once from a full reference year of temperatures with
    [`slp_gas_kundenwert()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_kundenwert.md):
    \$\$KW = \frac{E_a}{\sum_D h(\vartheta_D) \times F\_{WT,D}}\$\$
    where \\E_a\\ is the annual consumption.

2.  Pass that \\KW\\ to `slp_gas()` for any period you want to generate.

Keeping the two steps separate is deliberate: `kundenwert` is a property
of the customer and their climate zone, computed from a representative
(ideally multi-year) temperature mean. Deriving it from the same short
series you are generating over would collapse the seasonal denominator
and bias the result — for a single day the \\h\\ values cancel entirely.

### Profile IDs

There are 15 gas profile IDs defined in the BDEW Leitfaden:

**Residential**:

- `HEF`: single-family home (Einfamilienhaus)

- `HMF`: multi-family home (Mehrfamilienhaus)

- `HKO`: cooking and hot water only (Kochen / Warmwasser)

**Commercial / industrial**:

- `GKO`: small commercial (Kleinstgewerbe)

- `GHA`: trade and commerce (Handel)

- `GMK`: metal and automotive (Metall / Kfz)

- `GBD`: services (Dienstleistung)

- `GBH`: accommodation (Beherbergung)

- `GWA`: laundries (Wäscherei)

- `GGA`: gastronomy (Gastronomie)

- `GBA`: bakeries (Bäckerei)

- `GGB`: mixed commercial (gemischtes Gewerbe)

- `GPD`: paper and printing (Papier / Druck)

- `GMF`: large multi-family / mixed use (Mehrfamilienhaus groß)

- `GHD`: trade, commerce and services aggregate (GHD-Stützpunkt)

### Weekday Factors

Unlike the electricity profiles, gas weekday factors use seven
individual weekdays (Mo, Tu, We, Th, Fr, Sa, Su) rather than three day
types. Public holidays are treated as Sunday (`Su`); 24 December and 31
December are treated as Saturday (`Sa`) unless they fall on a Sunday.

For the residential profiles `HEF`, `HMF`, and `HKO` all weekday factors
are 1, meaning no day-of-week differentiation is applied.

The built-in holiday data cover the years 1990 to 2099. For dates
outside this range, `holidays = NULL` will yield no public holiday
adjustments; pass `holidays` explicitly if needed.

## See also

[`slp_gas_kundenwert()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_kundenwert.md)
to derive the `kundenwert`;
[`slp_gas_coefficients()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_coefficients.md)
and
[`slp_gas_siglinde()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_siglinde.md)
for the underlying coefficients and profile function.

## Examples

``` r
dates <- seq.Date(as.Date("2026-01-01"), as.Date("2026-01-07"), by = "day")
temps <- c(2.1, -1.3, 0.5, 3.8, 5.2, 4.0, 1.9)

# Supply the Kundenwert directly (kWh/day)
slp_gas("HEF", dates, temps, kundenwert = 55.1)
#>   profile_id       date       kwh
#> 1        HEF 2026-01-01  95.53071
#> 2        HEF 2026-01-02 117.87083
#> 3        HEF 2026-01-03 106.25679
#> 4        HEF 2026-01-04  83.85639
#> 5        HEF 2026-01-05  74.16239
#> 6        HEF 2026-01-06  82.47256
#> 7        HEF 2026-01-07  96.88841

# Multiple profiles
slp_gas(c("HEF", "HMF", "GKO"), dates, temps, kundenwert = 55.1)
#>    profile_id       date       kwh
#> 1         HEF 2026-01-01  95.53071
#> 2         HEF 2026-01-02 117.87083
#> 3         HEF 2026-01-03 106.25679
#> 4         HEF 2026-01-04  83.85639
#> 5         HEF 2026-01-05  74.16239
#> 6         HEF 2026-01-06  82.47256
#> 7         HEF 2026-01-07  96.88841
#> 8         HMF 2026-01-01  87.32526
#> 9         HMF 2026-01-02 104.02730
#> 10        HMF 2026-01-03  95.41578
#> 11        HMF 2026-01-04  78.32423
#> 12        HMF 2026-01-05  70.66946
#> 13        HMF 2026-01-06  77.24199
#> 14        HMF 2026-01-07  88.35808
#> 15        GKO 2026-01-01  99.09886
#> 16        GKO 2026-01-02 130.41347
#> 17        GKO 2026-01-03 104.62147
#> 18        GKO 2026-01-04  85.50262
#> 19        GKO 2026-01-05  81.36665
#> 20        GKO 2026-01-06  93.55573
#> 21        GKO 2026-01-07 111.48772
```
