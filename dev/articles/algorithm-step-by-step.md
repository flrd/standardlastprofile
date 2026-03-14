# Generate a standard load profile

Standard load profiles are crucial for electricity providers, grid
operators, and the energy industry as a whole. They support planning and
optimising electricity generation and distribution. Additionally, they
serve as the foundation for billing and balancing electricity quantities
in the energy market. For smaller consumers, the financial expense of
continuous consumption measurement is often unreasonable. Energy supply
companies can therefore use a standard load profile as the basis for
creating a consumption forecast.

The aim of this vignette is to show how the algorithm of the
[`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
function works.[¹](#fn1) The data in the `slp` dataset forms the basis
for all subsequent steps.

``` r
head(slp)
#>   profile_id period      day timestamp watts
#> 1         H0 winter saturday     00:00  70.8
#> 2         H0 winter saturday     00:15  68.2
#> 3         H0 winter saturday     00:30  65.9
#> 4         H0 winter saturday     00:45  63.3
#> 5         H0 winter saturday     01:00  59.5
#> 6         H0 winter saturday     01:15  55.0
```

There are 96 x 1/4 hour measurements of electrical power for each unique
combination of `profile_id`, `period` and `day`, which we refer to as
the “standard load profile”. The value for “00:00” indicates the average
power consumed between 00:00 and 00:15. The `slp` dataset contains
26,784 observations and covers two generations of profiles published by
the German Association of Energy and Water Industries (BDEW
Bundesverband der Energie- und Wasserwirtschaft e.V.):

- **1999 profiles** (`H0`, `G0`–`G6`, `L0`–`L2`): based on an analysis
  of 1,209 load profiles of low-voltage electricity consumers. Each
  profile uses three seasonal `period` values: `summer`, `winter`, and
  `transition`.[²](#fn2)
- **2025 profiles** (`H25`, `G25`, `L25`, `P25`, `S25`): an updated set
  reflecting changes in electricity consumption patterns. Instead of
  seasons, `period` carries a lowercase month name (`january` …
  `december`).

![Small multiple line chart of 11 standard load profiles published by
the German Association of Energy and Water Industries (BDEW
Bundesverband der Energie- und Wasserwirtschaft e.V.). The lines compare
the consumption for three different periods over a year, and also
compare the consumption between different days of a
week.](algorithm-step-by-step_files/figure-html/small_multiples_vignette-1.png)

Those measurements are normalised to an annual consumption of 1,000 kWh.
So, if we convert all the quarter-hourly power measurements to energy
and sum them for a year, the result is (approximately) 1,000 kWh/year.

``` r
library(standardlastprofile)
H0_2026 <- slp_generate(
  profile_id = "H0",
  start_date = "2026-01-01",
  end_date = "2026-12-31"
  )
```

``` r
sum(H0_2026$watts)
#> [1] 3992465
```

‘Hold on - didn’t you just say 1,000?!’, you might be thinking. Yes, you
are correct; we must [convert power units into energy
units](https://en.wikipedia.org/wiki/Watt#Distinction_between_watts_and_watt-hours).
The values returned are 1/4-hour measurements in watts. To convert the
values to watt-hours, we must, therefore, divide them by 4. Since one
watt-hour is equal to 1/1000 kilowatt-hour, we also divide by 1,000:

``` r
sum(H0_2026$watts / 4 / 1000)
#> [1] 998.1163
```

## Units and normalisation

The two generations of profiles come from different source files and use
different units:

- The **1999 profiles** (`H0`, `G0`–`G6`, `L0`–`L2`) were published as
  an Excel file in which every value is already expressed as **average
  electric power in watts (W)**, normalised so that the annual sum of
  all 15-minute intervals equals 1,000 kWh.[³](#fn3)

- The **2025 profiles** (`H25`, `G25`, `L25`, `P25`, `S25`) were
  published as a separate Excel file in which every value is expressed
  as **energy consumed in the 15-minute interval in kilowatt-hours
  (kWh)**, but normalised to an annual consumption of **1,000,000
  kWh**.[⁴](#fn4)

To give users a single, consistent interface we convert all values to
watts normalised to 1,000 kWh/a. This conversion is applied once, at
data-build time, in `data-raw/DATASET.R`. As a result,
[`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
always returns watts regardless of which profile is requested. We can
verify that the normalisation holds for a 2025 profile just as it does
for a 1999 profile:

``` r
P25_2026 <- slp_generate("P25", "2026-01-01", "2026-12-31")
sum(P25_2026$watts / 4 / 1000)
#> [1] 1000.08
```

### Converting the output to kWh

The values returned by
[`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
represent **average electric power** during each 15-minute interval. To
obtain the **energy consumed** during that interval in kWh you can wrap
[`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
once:

``` r
slp_generate_kwh <- \(...) {
  out <- slp_generate(...)
  out$kwh <- out$watts / 4 / 1000
  out
}

H0_kwh <- slp_generate_kwh("H0", "2026-01-01", "2026-12-31")
sum(H0_kwh$kwh)
#> [1] 998.1163
```

## Algorithm step by step

When you call
[`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md),
you generate (surprise!) a standard load profile. These are the steps
that are then performed:

1.  Generate a date sequence from `start_date` to `end_date`.
2.  Map each day to combination of `day` and `period` (1999 profiles:
    seasonal period; 2025 profiles: calendar month).
3.  Use result from 2nd step to extract values from `slp`.[⁵](#fn5)

&nbsp;

4.  Apply polynomial function to values of profile identifiers `H0`,
    `H25`, `P25`, and `S25`.
5.  Return data.

### Generate a date sequence

In the initial step, a date sequence is created from `start_date` to
`end_date` based on the user input. Here’s a simple example:

``` r
start <- as.Date("2023-12-22")
end <- as.Date("2023-12-27")

(date_seq <- seq.Date(start, end, by = "day"))
#> [1] "2023-12-22" "2023-12-23" "2023-12-24" "2023-12-25" "2023-12-26"
#> [6] "2023-12-27"
```

### Map each day to a period and a weekday

The measured load profiles analysed in the study showed that electricity
consumption across all groups fluctuates both over the period of a year
and over the days within a week. For the **1999 profiles**, the `period`
definition is:

- `summer`: May 15 to September 14
- `winter`: November 1 to March 20
- `transition`: March 21 to May 14, and September 15 to October 31

For the **2025 profiles**, each calendar month is treated as its own
period (`january` … `december`) rather than grouping months into
seasons.

The 1999 study also found no significant difference in consumption on
weekdays from Monday to Friday for any group. For this reason, the days
Monday to Friday are grouped together as `workday`. December 24th and
31st are considered Saturdays too if they are not Sundays. Public
holidays are regarded as Sundays.

*Note*: The function
[`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
supports by default nationwide public holidays for Germany. Those were
retrieved from the [nager.Date
API](https://github.com/nager/Nager.Date):

- New Year’s (Jan 1)
- Good Friday
- Easter Monday
- Labour Day (May 1)
- Ascension Day
- Whit Monday
- German Unity Day (Oct 3)
- Christmas Day (Dec 25)
- Boxing Day (Dec 26)

> State-level holidays are **not** included by default, as these vary by
> state and can change over time. Use the optional `holidays` argument
> to pass your own vector of dates and take full control over which
> dates are treated as public holidays; the built-in data are then
> ignored entirely. See the
> [README](https://flrd.github.io/standardlastprofile/index.html#public-holidays)
> for an example of how to fetch state-level holidays from the
> [nager.Date API](https://date.nager.at) and pass them to
> [`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md).

The result of this second step is a mapping from each date to a
so-called characteristic profile day, i.e. a combination of weekday and
period:

``` r
wkday_period <- standardlastprofile:::get_wkday_period(date_seq)
data.frame(input = date_seq, output = wkday_period)
#>        input          output
#> 1 2023-12-22  workday_winter
#> 2 2023-12-23 saturday_winter
#> 3 2023-12-24   sunday_winter
#> 4 2023-12-25   sunday_winter
#> 5 2023-12-26   sunday_winter
#> 6 2023-12-27  workday_winter
```

### Assign consumption values to each day

The third step is to assign the measurements we know from the `slp`
dataset to each characteristic profile day. This is the job of the
[`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
function:

``` r
G5 <- slp_generate(
  profile_id = "G5",
  start_date = "2023-12-22",
  end_date = "2023-12-27"
  )
```

This function returns a data frame with 4 columns:

``` r
head(G5)
#>   profile_id          start_time            end_time watts
#> 1         G5 2023-12-22 00:00:00 2023-12-22 00:15:00  50.1
#> 2         G5 2023-12-22 00:15:00 2023-12-22 00:30:00  47.4
#> 3         G5 2023-12-22 00:30:00 2023-12-22 00:45:00  44.9
#> 4         G5 2023-12-22 00:45:00 2023-12-22 01:00:00  43.3
#> 5         G5 2023-12-22 01:00:00 2023-12-22 01:15:00  43.0
#> 6         G5 2023-12-22 01:15:00 2023-12-22 01:30:00  43.8
```

The data analysis revealed that load fluctuations for both commercial
and agricultural customers remain moderate throughout the year.
Specifically, for customers and customer groups labelled as `G0` to `G6`
and `L0` to `L2`, the standard load profile can be accurately derived
from the nine characteristic profile day combinations (3 day types × 3
seasonal periods) available in the dataset `slp`.

Below is the code snippet from the
[README](https://github.com/flrd/standardlastprofile#generate-a-load-profile),
which can be used to reproduce the plot for the G5 profile, showcasing
the algorithm’s outcome:

``` r
library(ggplot2)
ggplot(G5, aes(start_time, watts)) +
  geom_line(color = "#0CC792") +
  scale_x_datetime(
    date_breaks = "1 day",
    date_labels = "%b %d") +
  scale_y_continuous(NULL, labels = \(x) paste(x, "W")) +
  labs(
    title = "'G5': bakery with bakehouse",
    subtitle = "1/4h measurements, based on consumption of 1,000 kWh/a",
    caption = "data: www.bdew.de",
    x = NULL) +
  theme_minimal() +
  theme(
    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid = element_line(
      linetype = "12",
      lineend = "round",
      colour = "#FAF6F4"
      )
  ) +
  NULL
```

![Line plot of the BDEW standard load profile 'G5' (Bakery with a
bakehouse) from December 22nd to December 27th 2023; values are
normalized to an annual consumption of 1,000
kWh.](algorithm-step-by-step_files/figure-html/G5_plot_vignette-1.png)

As you can see, the values in 2023 for December 24 (a Sunday) and
December 25 and 26 (both public holidays) are identical.

### Special case: H0, H25, P25, S25

In contrast to most commercial and agricultural businesses, which have a
relatively even and constant electricity consumption throughout the
year, household electricity consumption decreases from winter to summer
and vice versa (at least in Germany). Because of the distinctive annual
load profile characteristics of household customers, we contend that
these customers cannot be adequately described through a static
representation using characteristic days alone. Consequently, the values
in the `slp` dataset for `H0`, `H25`, `P25`, and `S25` serve as base
values to be scaled by a dynamization factor.

This is taken into account when you call
[`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md).
The study suggested the application of a 4th order polynomial function
to the values of these profiles.

$$w_{d} = w_{s} \times \left( - 3.92e{- 10} \times d^{4} + 3.20e{- 7} \times d^{3} - 7.02e{- 5} \times d^{2} + 2.10e{- 3} \times d + 1.24 \right)$$
Where:

- $w_{d}$ is the resulting ‘dynamic’ value
- $w_{s}$ is the ‘static’ value
- $d$ is the day of the year as integer, starting at 1 on January 1st

The following plot shows how the electrical power develops over the year
for profile `H0`; for a clearer picture, the values are aggregated at
daily level:

![Line plot of standard load profile 'H0' (households) aggregated by day
from January 1st to December 31st, 2026. The plot shows that households
have a continuously decreasing load from winter to summer and vice
versa.](algorithm-step-by-step_files/figure-html/H0_2026_plot-1.png)

This dynamization step produces a representative, dynamic load profile.
Finally, the following chart compares the dynamic values with their
static counterparts.[⁶](#fn6)

![A plot of standard load profile 'H0' (households) that shows a
comparision between the static values, and their dynamic
counterparts.](algorithm-step-by-step_files/figure-html/H0_dynamic-1.png)

------------------------------------------------------------------------

1.  More information on the algorithm can be found
    [here](https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf)

2.  More information on the data and methodology can be found
    [here](https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf).

3.  See the source Excel file distributed with the step-by-step guide:
    <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>

4.  See the BDEW 2025 publication:
    <https://www.bdew.de/energie/standardlastprofile-strom/>

5.  That is actually a lie. There is an internal data object from which
    the data is extracted for efficiency.

6.  Refer to page 9 in [Anwendung der Repräsentativen VDEW-Lastprofile
    step-by-step](https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf).
