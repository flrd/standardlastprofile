# Generate a standard load profile for gas

A standard load profile reflects the typical pattern of gas consumption.
It is used for forecasting and balancing purposes for various customer
types or customer groups for which no continuous measurement data is
available. In this respect, standard load profiles represent a
simplification.

In this article we explain how
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
implements the algorithm of the **synthetic procedure** (German:
*synthetisches Verfahren*), following the definitions by BDEW, VKU, and
GEODE in the *Leitfaden Abwicklung von Standardlastprofilen Gas*
(2025).[^1]

## Synthetic procedure

The synthetic procedure takes a bottom-up approach: the gas consumption
for a gas network is explained by the sum of the individual gas
consumers within that network.[^2]

For each customer type, i.e. profile, the gas consumption of day \\D\\
is the result of three factors:

1.  outside temperature
2.  preferences and habits
3.  the day of the week

Mathematically, this is expressed as:[^3]

\\ Q(D) = h(\vartheta_D) \times KW \times F\_{WT, D} \\ where:

- \\h(\ldots)\\ is a profile function evaluated at the daily temperature
  \\\vartheta_D\\.
- \\KW\\ is a customer-specific scaling factor in kWh/day (German:
  “Kundenwert”).
- \\F\_{WT}\\ is a weekday factor that adjusts for consumption
  differences across days of the week.

### Profile function \\h(\vartheta_D)\\

Gas consumption is strongly correlated with outdoor temperature; the
colder it gets, the more gas is consumed. The relationship between
outside temperature and gas consumption is captured by the profile
function \\h(\vartheta)\\.

This function was initially published in 2003 as an S-shaped sigmoid
function:[^4]

\\ h(\vartheta) = \frac{A}{1 + \left(\dfrac{B}{\vartheta -
\vartheta_0}\right)^C} + D \\

Since then, it has been revised as part of an ongoing debate. In a
research paper from 2015 it was found that a pure sigmoid approach
systematically underestimated consumption at very cold temperatures. The
authors proposed an improved formulation called **SigLinDe**
(**Sig**moid + **Lin**ear + **De**utschland).[^5] SigLinDe adds a linear
component to that sigmoid equation representing space-heating demand
(German: *Heizgas-Gerade*) and hot water demand (German:
*Warmwasser-Gerade*).

\\ h(\vartheta) = \underbrace{\frac{A}{1 + \left(\dfrac{B}{\vartheta -
\vartheta_0}\right)^C} + D}\_{\text{sigmoid part}} +
\underbrace{\max\\\left(m_H \vartheta + b_H,\\ m_W \vartheta +
b_W\right)}\_{\text{linear part}} \\

Higher h(ϑ) means more gas consumption on that day

Toggle between Sigmoid and SigLinDe functions

The SigLinDe approach was adopted by BDEW and has since been the binding
standard.[^6]
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
implements the SigLinDe approach. The parameters \\A\\, \\B\\, \\C\\,
\\D\\, \\\vartheta_0\\, \\m_H\\, \\b_H\\, \\m_W\\, \\b_W\\ are
profile-specific constants.[^7]

All **15 gas profile IDs** share this one SigLinDe function — they
differ only in their parameter values (\\A\\, \\B\\, …, \\b_W\\). The
complete set is tabulated in the [SigLinDe Parameters and Weekday
Factors](https://flrd.github.io/standardlastprofile/articles/slp-gas-parameters.md)
article and returned in R by
[`slp_gas_coefficients()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_coefficients.md):

``` r

slp_gas_coefficients("HEF")
#>   profile_id variant        A         B        C         D theta0         mH
#> 1        HEF      34 1.381966 -37.41242 6.172318 0.0396284     40 -0.0672159
#> 2        HEF      33 1.620954 -37.18331 5.672785 0.0716431     40 -0.0495700
#>          bH         mW        bW
#> 1 1.1167138 -0.0019982 0.1355070
#> 2 0.8401015 -0.0022090 0.1074468
```

The `HKO` profile (cooking and hot water only) is a special case: all
four linear coefficients (\\m_H\\, \\b_H\\, \\m_W\\, \\b_W\\) are zero,
so the linear term \\\max(m_H\vartheta + b_H,\\ m_W\vartheta + b_W)\\
vanishes and \\h(\vartheta)\\ collapses to the bare sigmoid — it is the
original pre-SigLinDe TU München profile, carried over unchanged.
Because the variant 33 / 34 split only affects the linear part, the two
variants are **identical for `HKO`**.

The result of \\h(\vartheta)\\ is a number \> 0 without a dimension:

``` r

# profile "GMF", Ausprägung: 34
slp_gas_siglinde(
  theta  =   8.0,
  A      =   1.0443538,
  B      = -35.0333754,
  C      =   6.2240634,
  D      =   0.0502917,
  theta0 =  40.0,
  mH     =  -0.053583,
  bH     =   0.9995901,
  mW     =  -0.0021758,
  bW     =   0.1633299
)
#> [1] 1
```

The result above is **exactly 1** — and that is no coincidence. The
SigLinDe coefficients of every profile are calibrated so that the
profile function equals 1 at the reference temperature of **8 °C**. At 8
°C the profile term drops out of \\Q(D) = KW \times h(\vartheta_D)
\times F\_{WT,D}\\, so the customer value \\KW\\ is simply the daily
consumption on an 8 °C day — which is exactly how it is defined.

`HKO` is the one exception, and precisely because of its missing linear
part. The SigLinDe profiles owe that exact-1 value at 8 °C to the linear
term, which is fitted (together with the sigmoid) to pin
\\h(8\\\text{°C}) = 1\\. `HKO` has no linear part, so its bare sigmoid
is not pinned to the reference and reaches about **1.06** at 8 °C
instead — visible in the BDEW profile sheet, where the `HKO` row lists
\\h(8\\\text{°C}) = 1.05612\\.

The temperature \\\vartheta\\ fed to this function is the daily
*allocation temperature* (defined next); the dimensionless
\\h(\vartheta)\\ is later scaled to kWh by the customer value \\KW\\
(covered below).

### Allocation temperature

The *allocation temperature* \\\vartheta_D\\ is the daily temperature
fed to the profile function \\h(\vartheta)\\. Two ways to compute it are
defined in the Leitfaden:[^8]

**Simple daily mean** — the arithmetic mean of the 24 hourly values over
the gas day:

\\\vartheta_D = \frac{1}{24} \sum\_{i=1}^{24} T_i\\

**Geometrically-weighted 4-day mean** — recommended by BDEW for grid
operators, giving more weight to the current day:

\\\vartheta_D = \frac{T_D + 0.5 \cdot T\_{D-1} + 0.25 \cdot T\_{D-2} +
0.125 \cdot T\_{D-3}}{1 + 0.5 + 0.25 + 0.125}\\

[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
accepts whichever values you pass in `temperatures` — the choice of
method is the caller’s responsibility. If you have raw daily means from
DWD and want the geometrically-weighted variant, apply it before calling
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md).
(If you already have gas forecast temperature (GPT) values from a
meteorological service provider, use those directly — GPT is not this
formula.)

``` r

# Geometrically-weighted 4-day mean (more weight on the current day):
weights <- c(1, 0.5, 0.25, 0.125)

allocation_temp <- \(temps) {
  as.numeric(
    stats::filter(temps, weights / sum(weights),
                  method = "convolution", sides = 1)  # past values only
  )
}

# Apply to your daily mean series before passing it to slp_gas().
# The first three days come back NA (no 3-day history yet):
# temps_weighted <- allocation_temp(temps)
```

### Customer value (Kundenwert)

The customer value accounts for a customer’s individual consumption
behaviour. It is a scaling factor in kWh/day — specifically, the daily
gas consumption at the reference temperature of 8 °C, the point at which
\\h(\vartheta) = 1\\ for every profile. We can rearrange the gas
consumption equation above and write \\KW\\ as:

\\ KW = \frac{E_a}{\displaystyle\sum\_{D} h(\vartheta_D) \times
F\_{WT,D}} \\

Where

- \\E_a\\ is the annual gas consumption
- \\\vartheta_D\\ is the daily allocation temperature for day \\D\\
- \\F\_{WT,D}\\ is the weekday factor for day \\D\\

Using the example of a single-family home (`HEF`) in Düsseldorf with an
annual consumption of 15,000 kWh — the same customer as in the README —
the table below shows how the denominator is built up, day by day, from
the Düsseldorf long-term daily mean temperatures (DWD station 1078,
2004–2024):

| Date   |   °C |   h(ϑ) |
|:-------|-----:|-------:|
| Jan 1  |  4.8 | 1.3962 |
| ⋮      |    ⋮ |      ⋮ |
| Jun 30 | 19.2 | 0.1727 |
| Jul 1  | 18.9 | 0.1765 |
| Jul 2  | 19.2 | 0.1727 |
| ⋮      |    ⋮ |      ⋮ |
| Dec 31 |  5.7 | 1.2833 |

The sum in the denominator across all 365 days gives \\\sum_D
h(\vartheta_D) \times F\_{WT,D}\\ = 272.32, so \\KW \approx\\ 15,000 /
272.32 = **55.1 kWh/day**.

With \\h(\vartheta_D)\\ and \\KW\\ in hand, the only remaining factor in
\\Q(D) = KW \times h(\vartheta_D) \times F\_{WT,D}\\ is the weekday
factor \\F\_{WT,D}\\.

### Weekday factors

Unlike the electricity profiles, which group Monday–Friday into a single
`workday` type, the gas procedure uses a separate scaling factor for
every weekday from Monday through Sunday.[^9]

Public holidays are treated as a Sunday.[^10] 24 December and 31
December are treated as Saturday unless they fall on a Sunday; this
convention mirrors the established rule from the BDEW electricity SLP
procedure and is applied here by analogy.

For the residential profiles `HEF`, `HMF`, and `HKO`, however, all
weekday factors are equal to 1, that is, gas consumption in households
is assumed not to differ significantly by day of the week. Commercial
profiles on the other hand show visible weekday patterns, the range of
the weekday factors is 0.3877 - 1.2707, illustrated by the chart below:

## Profile IDs

There are 15 gas profile IDs defined in the BDEW Leitfaden, split into
residential and commercial / industrial types.

### Residential profiles

Residential profiles share two important characteristics: all weekday
factors equal 1 (no day-of-week differentiation), and heating load is
the dominant driver of demand variability.

| Profile | Description | Notes |
|----|----|----|
| `HEF` | Single-family home (Einfamilienhaus) | Strongest seasonal swing; includes space heating + hot water |
| `HMF` | Multi-family home (Mehrfamilienhaus) | Lower per-unit demand than `HEF` due to shared building envelope |
| `HKO` | Cooking and hot water only (Kochen / Warmwasser) | No space heating; TUM profile — sigmoid only, linear part is zero |

`HKO` is appropriate for customers whose gas connection serves only a
cooker or instantaneous water heater. Its flat, temperature-insensitive
shape is visible in the SigLinDe curve plot above.

### Commercial and industrial profiles

Commercial profiles have profile-specific weekday factors that reflect
the operating hours and schedules of each sector. They are grouped here
by consumption pattern:

**Process-heat dominated** (relatively flat seasonal pattern, strong
weekday structure):

| Profile | Description |
|----|----|
| `GWA` | Laundries — large hot-water demand, insensitive to outdoor temperature |
| `GBA` | Bakeries — continuous baking process, pronounced weekday factors |
| `GPD` | Paper and printing — industrial process heat |

**Space-heating dominated** (strong winter peak, moderate weekday
variation):

| Profile | Description                                            |
|---------|--------------------------------------------------------|
| `GKO`   | Small commercial (Kleinstgewerbe)                      |
| `GHA`   | Trade and commerce (Handel)                            |
| `GBD`   | Services (Dienstleistung)                              |
| `GBH`   | Accommodation (Beherbergung)                           |
| `GGA`   | Gastronomy (Gastronomie)                               |
| `GMK`   | Metal and automotive (Metall / Kfz)                    |
| `GGB`   | Mixed commercial (gemischtes Gewerbe)                  |
| `GMF`   | Large multi-family / mixed use (Mehrfamilienhaus groß) |

**Aggregate / summary profile**:

| Profile | Description |
|----|----|
| `GHD` | Trade, commerce and services aggregate (GHD-Stützpunkt) — weighted mean across all G-types |

`GHD` is used when a customer cannot be assigned to a specific sector.
Its parameters are a weighted average of the individual commercial
profiles and its weekday factors are close to but not equal to 1.

## A working example: Düsseldorf

With the algorithm covered, let us see how to use
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
in practice.
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
takes: - a `profile_id` - a `dates` vector, and a matching
`temperatures` vector, and - a `kundenwert`.

`kundenwert` is the customer-specific scaling factor in kWh/day.

### Deriving the Kundenwert

To produce a meaningful result the temperature series should cover a
full year at least. You can use measured data from a trustworthy
institution like the German Meteorological Service, or DWD for short.
The [`rdwd`](https://cran.r-project.org/package=rdwd) package provides a
straightforward interface to the open-data portal of the DWD (Deutscher
Wetterdienst).[^11] No registration or API key is required.

#### rdwd package

The workflow has three steps:

1.  [`selectDWD()`](https://rdrr.io/pkg/rdwd/man/selectDWD.html) — find
    the download URL for a station and dataset.
2.  [`dataDWD()`](https://rdrr.io/pkg/rdwd/man/dataDWD.html) — download
    and unzip the file.
3.  [`readDWD()`](https://rdrr.io/pkg/rdwd/man/readDWD.html) — parse the
    file into a data frame.

For gas SLPs, we need the **daily climate summary** (`var = "kl"`,
`res = "daily"`). The column `TMK` contains the daily mean temperature
in °C. To find the exact station name to pass to
[`selectDWD()`](https://rdrr.io/pkg/rdwd/man/selectDWD.html), use
[`findID()`](https://rdrr.io/pkg/rdwd/man/findID.html) or open the
interactive station map:

``` r

rdwd::findID("Freiburg")             # returns matching station names and IDs
rdwd::selectDWD(mapDWD = TRUE)       # opens an interactive map in the browser
```

The Kundenwert is derived once, from the customer’s annual consumption
and a **reference temperature series for their location**, using
[`slp_gas_kundenwert()`](https://flrd.github.io/standardlastprofile/reference/slp_gas_kundenwert.md).
The resulting value is then passed to
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
for whatever period you want to generate — a single month, a quarter,
the whole year.

Keeping the derivation a separate step is deliberate. \\KW\\ is a
property of the customer and their local climate, so it should be
computed from a representative full year — ideally a multi-year mean.

Take the single-family home (`HEF`) from the README’s example: located
in **Düsseldorf**, with an annual gas consumption of **15,000 kWh**. For
the reference temperatures we use the **long-term daily mean over
2004–2024** — a multi-year (climatological) mean rather than a single
year, so that no individual-year anomaly distorts the scaling
factor[^12].

``` r

library(rdwd)

# Full daily climate record for Düsseldorf (DWD station 1078)
links <- selectDWD("Duesseldorf", res = "daily", var = "kl",
                   per = c("historical", "recent"))
raw   <- do.call(rbind, readDWD(dataDWD(links, read = FALSE, force = TRUE),
                                varnames = FALSE))

# Long-term mean daily temperature over 2004-2024, one value per calendar day
ref       <- raw[format(raw$MESS_DATUM, "%Y") %in% as.character(2004:2024), ]
ref$mmdd  <- format(ref$MESS_DATUM, "%m-%d")
clim      <- aggregate(TMK ~ mmdd, data = ref, FUN = mean)
clim      <- clim[clim$mmdd != "02-29", ]          # drop the leap day
dates_ref <- as.Date(paste0("2023-", clim$mmdd))   # any non-leap year
temps_ref <- clim$TMK

# kundenwert for a 15,000 kWh/a HEF customer
slp_gas_kundenwert("HEF", dates_ref, temps_ref, annual_consumption = 15000)
#>      HEF
#> 55.08344
```

This Düsseldorf customer has a Kundenwert of about **55.1 kWh/day**.
That fixed value is what the README example passes to
[`slp_gas()`](https://flrd.github.io/standardlastprofile/reference/slp_gas.md)
to generate the 2025/26 heating season — and it is what we use below to
ask how the same customer would fare in a different climate.

### What if the customer moves?

We keep the Düsseldorf customer’s Kundenwert of **55.1 kWh/day** fixed
and ask what they would consume in a colder climate — same customer,
same KW, different weather. Germany spans several distinct climate
zones; we compare three:

- **Chemnitz** — continental climate in the Erzgebirge foothills of
  Saxony; colder winters and the greatest temperature amplitude of the
  three.
- **Freiburg im Breisgau** — mild oceanic-continental climate in the
  sheltered Upper Rhine Plain; the warmest, sunniest large city in
  Germany.
- **Hamburg** — maritime climate on the North Sea coast; mild but
  cloudy, windy winters.

The grid below has one column per comparison city and one row per month
of the 2025/26 heating season (the same period as the README example).
Each point is a day, plotting the city’s daily gas consumption (y-axis)
against Düsseldorf (x-axis); the 45° line marks equal consumption.

That winter all three cities ran colder than Düsseldorf, so every point
cloud sits above the line — the question is by how much:

- **Chemnitz** is highest, about **35 % more gas** over the season (≈
  16,400 vs 12,200 kWh);
- **Hamburg** follows at about **25 % more**;
- **Freiburg** is closest to Düsseldorf at about **11 % more**.

The gap is widest on the cold January and February days at the top-right
of each panel, and narrows in the mild shoulder months of October and
April where the clouds approach the line.

![Faceted scatterplot grid: columns are Chemnitz, Freiburg, Hamburg;
rows are months October to April. Each point is a day; the x-axis is
daily gas consumption in Düsseldorf, the y-axis in the comparison city,
with a 45-degree reference line. All three cities' point clouds sit
above the line that winter, furthest for Chemnitz (about 35 percent
more), then Hamburg (about 25 percent), with Freiburg closest to the
line (about 11
percent).](slp-gas_files/figure-html/gas_cities_chart-1.png)

[^1]: BDEW/VKU/GEODE (2025). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*. Berlin. Available at
    <https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf>

[^2]: In addition to the synthetic procedure, there is also the
    analytical procedure. In brief, under this procedure, a network
    operator forecasts the proportion of the daily gas volume
    attributable to *all* SLP customers based on the expected
    temperature for that day and the residual gas amount derived from
    the total gas consumption, minus the gas volume attributable to
    customers with metered consumption. The analytical procedure is not
    in scope of this package.

[^3]: BDEW/VKU/GEODE (2025). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*. Berlin, Allgemeine Begriffsbestimmungen /
    Erläuterungen, p. VIII

[^4]: Hellwig, Mark (2003). *Entwicklung und Anwendung parametrisierter
    Standard-Lastprofile*. Dissertation, TU München.

[^5]: Hinterstocker, M., Eberl, B., von Roon, S. (2015).
    *Weiterentwicklung des Standardlastprofilverfahrens Gas*.
    Endbericht. Forschungsgesellschaft für Energiewirtschaft mbH (FfE),
    available at
    <https://www.bdew.de/media/documents/201507_Weiterentwicklung-SLP-Gas.pdf>

[^6]: BDEW/VKU/GEODE (2025). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*, as of 2025-10-28. Available at
    <https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf>

[^7]: The coefficients A, B, C, D, m_(H), b_(H), m_(W), b_(W) for each
    consumption profile are published in Annex 6 of the BDEW Leitfaden
    (pp. 140–163).

[^8]: BDEW/VKU/GEODE (2025). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*, as of 2025-10-28. Berlin, section 3.5.2,
    p. 22.

[^9]: BDEW/VKU/GEODE (2025). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*, as of 2025-10-28. Berlin, Annex 6,
    pp. 140–163 (per-profile data sheets).

[^10]: BDEW/VKU/GEODE (2025). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*, as of 2025-10-28. Berlin, Annex 3,
    pp. 129–130.

[^11]: DWD Open Data: <https://opendata.dwd.de/>

[^12]: BDEW Leitfaden, section 3.6.3
