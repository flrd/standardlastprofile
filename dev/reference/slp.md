# Standard Load Profile Data for Electricity from BDEW

Data about representative, standard load profiles for electricity from
the German Association of Energy and Water Industries (BDEW
Bundesverband der Energie- und Wasserwirtschaft e.V.) in a tidy format.

## Usage

``` r
slp
```

## Format

A data.frame with 26,784 observations and 5 variables:

- profile_id:

  character, identifier for load profile, see 'Details'

- period:

  character, one of `'summer'`, `'winter'`, `'transition'` for 1999
  profiles; one of `'january'` through `'december'` for 2025 profiles

- day:

  character, one of `'saturday'`, `'sunday'`, `'workday'`

- timestamp:

  character, format: %H:%M

- watts:

  numeric, electric power in watts, normalised to 1,000 kWh/a

## Source

<https://www.bdew.de/energie/standardlastprofile-strom/>

<https://www.bdew.de/media/documents/Profile.zip>

<https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>

## Details

There are 96 x 1/4h measurements of electrical power for each
combination of `profile_id`, `period` and `day`, which we refer to as
the "standard load profile".

In total there are 16 `profile_id` across two generations of profiles:

**1999 profiles** (based on analysis of 1,209 load profiles of
low-voltage electricity consumers in Germany):

- Households: `H0`

- Commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`

- Agriculture: `L0`, `L1`, `L2`

**2025 profiles** (updated profiles published by BDEW in 2025):

- Households: `H25`

- Commercial: `G25`

- Agriculture: `L25`

- Combination profile PV: `P25`

- Combination profile storage and PV: `S25`

The 2025 profiles use calendar months rather than seasons for the
`period` column (`'january'` through `'december'`).

Call
[`slp_info()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_info.md)
for more information and examples.

**Period definitions (1999 profiles)**:

- `summer`: May 15 to September 14

- `winter`: November 1 to March 20

- `transition`: March 21 to May 14, and September 15 to October 31

**Day definitions**:

- `workday`: Monday to Friday

- `saturday`: Saturdays; Dec 24th and Dec 31st are also treated as
  Saturdays unless they fall on a Sunday

- `sunday`: Sundays and all public holidays

**Units and normalisation**:

The source Excel file for the 1999 profiles stores values in watts (W),
normalised to an annual consumption of 1,000 kWh/a. The source Excel
file for the 2025 profiles stores values in kilowatt-hours (kWh) per
15-minute interval, normalised to 1,000,000 kWh/a. To keep the internal
representation consistent and backwards compatible, all 2025 values have
been converted to watts normalised to 1,000 kWh/a.

As a result, the `watts` column in both this dataset and the output of
[`slp_generate()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_generate.md)
always represents average electric power in watts, normalised to 1,000
kWh/a. To convert to energy consumed per 15-minute interval in kWh,
divide by 4 and by 1,000:

    watts_to_kwh <- \(x) x / 4 / 1000

## Examples

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
