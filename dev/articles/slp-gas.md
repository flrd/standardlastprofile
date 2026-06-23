# Gas Standard Load Profiles (Standardlastprofile Gas)

A standard load profile reflects the assumed pattern of gas consumption.
It is used for forecasting and balancing purposes for various customer
types or customer groups for which no continuous measurement data is
available. In this respect, standard load profiles represent a
simplification.

In this article we explain how
[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
implements the algorithm of the synthetic procedure (German:
“synthetisches Verfahren”), following the definitions by BDEW, VKU, and
GEODE in the *Leitfaden Abwicklung von Standardlastprofilen Gas*
(2026).[^1]

## Synthetic procedure

The synthetic procedure takes a bottom-up approach: the gas consumption
is explained by the sum of the individual gas consumers.[^2] The gas
consumption on day \\D\\ is the result of three factors:

1.  outside temperature
2.  preferences and habits
3.  the day of the week

Mathematically, this is expressed as:[^3]

\\ Q(D) = h(\vartheta_D) \times KW \times F\_{WT, D}
\tag{1}\label{eq:qdaily} \\ where:

- \\h(\ldots)\\ is a profile function evaluated at the daily temperature
  \\\vartheta_D\\.
- \\KW\\ is a customer-specific scaling factor in kWh/day (German:
  “Kundenwert”).
- \\F\_{WT}\\ is a weekday factor that adjusts for consumption
  differences across days of the week.

### Weekday factors \\F\_{WT}\\

Weekday factors are scaling factors applied for every day from Monday to
Sunday.[^4]

For the residential profiles `HEF`, `HMF`, and `HKO`, however, all
weekday factors are equal to 1, that is, gas consumption in households
is assumed *not* to differ significantly by day of the week. Commercial
profiles on the other hand show visible weekday patterns, the range of
the weekday factors is 0.3877 - 1.2707.

The weekday factor values are returned by
[`slp_gas_weekday_factors()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_weekday_factors.md)
and illustrated by the chart below:

Public holidays are treated as a Sunday.[^5] 24 December and 31 December
are treated as Saturday unless they fall on a Sunday; this convention
mirrors the established rule from the BDEW electricity SLP procedure and
is applied here by analogy.

### Profile function \\h(\vartheta_D)\\

Gas consumption is strongly correlated with outdoor temperature; the
colder it gets, the more gas is consumed — at least when gas is used for
space heating. The relationship between outside temperature and gas
consumption is captured by the profile function \\h(\vartheta)\\:

\\ h(\vartheta) = \underbrace{\frac{A}{1 + \left(\dfrac{B}{\vartheta -
\vartheta_0}\right)^C} + D}\_{\text{sigmoid part}} +
\underbrace{\max\\\left(m_H \vartheta + b_H,\\ m_W \vartheta +
b_W\right)}\_{\text{linear part}} \\

This function was initially published in 2003 as an S-shaped sigmoid
function:[^6]

\\ h(\vartheta) = \frac{A}{1 + \left(\dfrac{B}{\vartheta -
\vartheta_0}\right)^C} + D \\

Since then, it has been revised as part of an ongoing debate. In a
research paper from 2015 it was found that a pure sigmoid approach
systematically underestimated consumption at very cold temperatures. The
authors proposed an improved formulation called **SigLinDe**
(**Sig**moid + **Lin**ear + **De**utschland) and published SigLinDe
coeffeciants for 15 different customer groups, i.e. profile IDs.[^7]
SigLinDe adds a linear component to that sigmoid equation representing
space-heating demand (German: *Heizgas-Gerade*) and hot water demand
(German: *Warmwasser-Gerade*).

The SigLinDe approach was adopted by BDEW and has since been the binding
standard.[^8]

> [`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
> implements the SigLinDe approach.

### Profile IDs

There are 15 gas profile IDs defined, split into residential and
commercial / industrial types.

#### Residential profiles

Residential profiles share two important characteristics: all weekday
factors equal 1 (see above), and heating load is the dominant driver of
demand variability.

| Profile | Description | Notes |
|----|----|----|
| `HEF` | Single-family home (Einfamilienhaus) | Strongest seasonal swing; includes space heating + hot water |
| `HMF` | Multi-family home (Mehrfamilienhaus) | Lower per-unit demand than `HEF` due to shared building envelope |
| `HKO` | Cooking and hot water only (Kochen / Warmwasser) | No space heating; TUM profile — sigmoid only, linear part is zero |

`HKO` is appropriate for customers whose gas connection serves only a
cooker or instantaneous water heater. Its flat, temperature-insensitive
shape is visible in the SigLinDe curve plot above.

#### Commercial and industrial profiles

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

All 15 gas profile IDs share the same SigLinDe function — but they
differ in their parameter values. The parameters \\A\\, \\B\\, \\C\\,
\\D\\, \\\vartheta_0\\, \\m_H\\, \\b_H\\, \\m_W\\, \\b_W\\ are
profile-specific constants.[^9]

You find the complete set in the [SigLinDe Parameters and Weekday
Factors](https://flrd.github.io/standardlastprofile/dev/articles/slp-gas-parameters.md)
article, and those values are returned by
[`slp_gas_coefficients()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_coefficients.md).

Higher h(ϑ) means more gas consumption on that day

Toggle between Sigmoid and SigLinDe functions for profile HEF HMF HKO
GKO GHA GMK GBD GBH GWA GGA GBA GGB GPD GMF GHD

Single-family home

The result of \\h(\vartheta)\\ is a number \> 0 without a dimension:

``` r

# profile "HEF", Ausprägung: 34
slp_gas_siglinde(
  theta  =   8.0,
  A      =   1.381966,
  B      = -37.41242,
  C      =   6.172318,
  D      =   0.0396284,
  theta0 =  40.0,
  mH     =  -0.0672159,
  bH     =   1.116714,
  mW     =  -0.0019982,
  bW     =   0.135507
)
#> [1] 0.9999997
```

For `theta = 8` the result above is ~1 — which is no coincidence, and
brings us to the `kundenwert`.

### Kundenwert \\KW\\

`kundenwert` accounts for a customer’s individual consumption behaviour.
It answers the question: how much gas does a customer consume on a day
when the outside temperature is 8°C? It is a scaling factor in kWh/day —
8°C is the temperature at which \\h(\vartheta) = 1\\ for every profile,
with one exception: `HKO`, whose linear parameters (\\m_H\\, \\b_H\\,
\\m_W\\, \\b_W\\) are all 0. With no linear component, the `HKO` profile
function is a plain sigmoid rather than a SigLinDe (sigmoid-plus-linear)
function, and so is not normalised to 1 at 8°C.

`kundenwert` is derived from the customer’s annual consumption and the
year’s temperature and weekday profile. Starting with
\\\eqref{eq:qdaily}\\, the annual total consumption is the sum of all
daily values:

\\ Q_a = \sum\_{D} Q(D) = \sum\_{D} h(\vartheta_D) \times KW \times
F\_{WT,D} \\

Rearranging to solve for \\KW\\:

\\ KW = \frac{Q_a}{\displaystyle\sum\_{D} h(\vartheta_D) \times
F\_{WT,D}} \tag{2}\label{eq:kw} \\

Where

- \\Q_a\\ is the annual gas consumption (German: *Jahresverbrauch*)
- \\\vartheta_D\\ is the daily temperature for day \\D\\
- \\F\_{WT,D}\\ is the weekday factor for day \\D\\

Using the example of a single-family home (`HEF`) in Düsseldorf with an
annual consumption of 15,000 kWh — [the same customer as in the
README](https://flrd.github.io/standardlastprofile/#gas) — the table
below shows how the denominator is built up, day by day, from the
Düsseldorf long-term daily mean temperatures (2004–2024):

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
h(\vartheta_D) = 272.32\\. And since for all three residential profiles
the weekday factors are 1, \\\eqref{eq:kw}\\ simplifies to:

\\ KW = \frac{Q_a}{\displaystyle\sum\_{D} h(\vartheta_D)} \\

So \\KW \approx\\ 15,000 / 272.32 = **55.1** kWh/day.

## A working example: Düsseldorf

With the algorithm covered, let us see how to use
[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
with real-world temperature data.

[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
takes:

- a `profile_id`
- a `dates` vector, and a matching vector of `temperatures`, and
- a `kundenwert`.

### Deriving the Kundenwert

To derive `kundenwert` we need an annual consumption and temperature
data. We can feed this information into the function
[`slp_gas_kundenwert()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_kundenwert.md)
together with any of the 15 gas profile IDs. To produce a meaningful
result the temperature series should cover at least a full year. We show
you how to fetch measured data from a trustworthy institution like the
German Meteorological Service, or DWD for short.

The [`rdwd`](https://cran.r-project.org/package=rdwd) package provides a
straightforward interface to the open-data portal of the DWD (Deutscher
Wetterdienst).[^10] No registration or API key is required.

#### rdwd package

This section gives you a quick introduction to the `rdwd` package, read
more about its features at
[brry.github.io/rdwd](https://brry.github.io/rdwd/index.html).

Our workflow has three steps:

1.  [`selectDWD()`](https://rdrr.io/pkg/rdwd/man/selectDWD.html) — find
    the download URL for a station and dataset.
2.  [`dataDWD()`](https://rdrr.io/pkg/rdwd/man/dataDWD.html) — download
    and unzip the file.
3.  [`readDWD()`](https://rdrr.io/pkg/rdwd/man/readDWD.html) — parse the
    file into a data frame.

We need the daily climate summary (`var = "kl"`, `res = "daily"`). The
column `TMK` contains the daily mean temperature in °C. To find the
exact station name to pass to
[`selectDWD()`](https://rdrr.io/pkg/rdwd/man/selectDWD.html), use
[`findID()`](https://rdrr.io/pkg/rdwd/man/findID.html):

``` r

# returns matching station names and IDs
rdwd::findID("Duesseldorf", exactmatch = FALSE) 
```

For the reference temperatures we use the long-term daily mean over
2004–2024 rather than a single year, so that no individual-year anomaly
distorts the scaling factor[^11].

``` r

library(rdwd)

# Full daily climate record for Düsseldorf (DWD station 1078)
links <- selectDWD(
  "Duesseldorf",
  res = "daily",
  var = "kl",
  per = c("historical", "recent"),
  current = TRUE
)

raw <- do.call(
  rbind,
  readDWD(dataDWD(links, read = FALSE, force = TRUE), varnames = FALSE)
)

# drop historical/recent overlap
raw <- raw[!duplicated(raw$MESS_DATUM), ]   

# Long-term mean daily temperature over 2004-2024, one value per calendar day
ref       <- raw[format(raw$MESS_DATUM, "%Y") %in% as.character(2004:2024), ]
ref$mmdd  <- format(ref$MESS_DATUM, "%m-%d")
clim      <- aggregate(TMK ~ mmdd, data = ref, FUN = mean)
clim      <- clim[clim$mmdd != "02-29", ]          # drop the leap day
dates_ref <- as.Date(paste0("2023-", clim$mmdd))   # any non-leap year
temps_ref <- clim$TMK
```

Now that we have a reference temperature series, we can call
[`slp_gas_kundenwert()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas_kundenwert.md):

``` r

# kundenwert for a 15,000 kWh/a HEF customer
slp_gas_kundenwert("HEF", dates_ref, temps_ref, annual_consumption = 15000)
#>      HEF 
#> 55.08305
```

That value is what the README example passes to
[`slp_gas()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_gas.md)
to generate the 2025/26 heating season — and it is what we use below to
ask how the same customer would fare in a different climate.

### Same customer preferences, different climate

We keep that `kundenwert` of 55.1 kWh/day fixed and ask how the gas
consumption changes in another place — same customer, same KW, different
climate. Germany spans several distinct climate zones; we compare three:

- **Chemnitz** — continental climate in the Ore Mountains foothills of
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
- **Freiburg im Breisgau** is closest to Düsseldorf at about **11 %
  more**;
- **Hamburg** follows at about **25 % more**.

The gap is widest on the cold January and February days at the top-right
of each panel, and narrows in the mild shoulder months of October and
April where the clouds approach the line.

SLP Gas – single family home, three climates vs Düsseldorf

Each point is one heating-season day. Points above the 45° line used
more gas than in Düsseldorf.

Chemnitz

Freiburg im Breisgau

Hamburg

[^1]: BDEW/VKU/GEODE (2026). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*, Kooperationsvereinbarung Gas, Annex XV,
    as of 2026-03-27. Berlin. Archived copy:
    <https://web.archive.org/web/20260619125016/https://www.bdew.de/media/documents/260327_LF_SLP_Gas_KoV_XV_CO4f7Rb.pdf>
    (current edition via the [BDEW gas SLP
    page](https://www.bdew.de/energie/standardlastprofile-gas/)).

[^2]: In addition to the synthetic procedure, there is also the
    analytical procedure. In brief, under this procedure, a network
    operator forecasts the proportion of the daily gas volume
    attributable to *all* SLP customers based on the expected
    temperature for that day and the residual gas amount derived from
    the total gas consumption, minus the gas volume attributable to
    customers with metered consumption. The analytical procedure is not
    in scope of this package.

[^3]: BDEW/VKU/GEODE (2026). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*. Berlin, Allgemeine Begriffsbestimmungen /
    Erläuterungen, p. VIII

[^4]: BDEW/VKU/GEODE (2026). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*, as of 2026-03-27. Berlin, Annex 6,
    pp. 146–173 (per-profile data sheets).

[^5]: BDEW/VKU/GEODE (2026). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*, as of 2026-03-27. Berlin, Annex 3
    (Kalender für Feiertage), p. 135.

[^6]: Hellwig, Mark (2003). *Entwicklung und Anwendung parametrisierter
    Standard-Lastprofile*. Dissertation, TU München.

[^7]: Hinterstocker, M., Eberl, B., von Roon, S. (2015).
    *Weiterentwicklung des Standardlastprofilverfahrens Gas*.
    Endbericht. Forschungsgesellschaft für Energiewirtschaft mbH (FfE),
    available at
    <https://web.archive.org/web/20260620061251/https://www.bdew.de/media/documents/201507_Weiterentwicklung-SLP-Gas.pdf>

[^8]: BDEW/VKU/GEODE (2026). *Leitfaden Abwicklung von
    Standardlastprofilen Gas*, as of 2026-03-27. Available at
    <https://web.archive.org/web/20260619125016/https://www.bdew.de/media/documents/260327_LF_SLP_Gas_KoV_XV_CO4f7Rb.pdf>

[^9]: The coefficients A, B, C, D, m_(H), b_(H), m_(W), b_(W) for each
    consumption profile are published in Annex 6 of the BDEW Leitfaden
    (pp. 146–173).

[^10]: DWD Open Data: <https://opendata.dwd.de/>

[^11]: BDEW Leitfaden, section 3.6.3
