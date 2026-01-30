# Generate a Standard Load Profile

Generate a standard load profile, normalized to an annual consumption of
1,000 kWh.

## Usage

``` r
slp_generate(profile_id, start_date, end_date, state_code = NULL)
```

## Source

<https://www.bdew.de/energie/standardlastprofile-strom/>

<https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>

<https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>

## Arguments

- profile_id:

  load profile identifier, required

- start_date:

  start date in ISO 8601 format, required

- end_date:

  end date in ISO 8601 format, required

- state_code:

  identifier for one of 16 German states, optional

## Value

A data.frame with four variables:

- `profile_id`, character, load profile identifier

- `start_time`, POSIXct / POSIXlt, start time

- `end_time`, POSIXct / POSIXlt, end time

- `watts`, numeric, electric power

## Details

In regards to the electricity market in Germany, the term "Standard Load
Profile" refers to a representative pattern of electricity consumption
over a specific period. These profiles can be used to depict the
expected electricity consumption for various customer groups, such as
households or businesses.

For each distinct combination of `profile_id`, `period`, and `day`,
there are 96 x 1/4 hour measurements of electrical power. Values are
normalized so that they correspond to an annual consumption of 1,000
kWh. That is, summing up all the quarter-hourly consumption values for
one year yields an approximate total of 1,000 kWh/a; for more
information, refer to the 'Examples' section, or call
[`vignette("algorithm-step-by-step")`](https://flrd.github.io/standardlastprofile/dev/articles/algorithm-step-by-step.md).

In total there are 11 `profile_id` for three different customer groups:

- Households: `H0`

- Commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`

- Agriculture: `L0`, `L1`, `L2`

For more information and examples, call
[`slp_info()`](https://flrd.github.io/standardlastprofile/dev/reference/slp_info.md).

Period definitions:

- `summer`: May 15 to September 14

- `winter`: November 1 to March 20

- `transition`: March 21 to May 14, and September 15 to October 31

Day definitions:

- `workday`: Monday to Friday

- `saturday`: Saturdays; Dec 24th and Dec 31th are considered a
  Saturdays too if they are not a Sunday

- `sunday`: Sundays and all public holidays

**Note**: The package supports public holidays for Germany, retrieved
from the [nager.Date API](https://github.com/nager/Nager.Date). Use the
optional argument `state_code` to consider public holidays on a state
level too. Allowed values are listed below:

- `DE-BB`: Brandenburg

- `DE-BE`: Berlin

- `DE-BW`: Baden-Württemberg

- `DE-BY`: Bavaria

- `DE-HB`: Bremen

- `DE-HE`: Hesse

- `DE-HH`: Hamburg

- `DE-MV`: Mecklenburg-Vorpommern

- `DE-NI`: Lower-Saxony

- `DE-NW`: North Rhine-Westphalia

- `DE-RP`: Rhineland-Palatinate

- `DE-SH`: Schleswig-Holstein

- `DE-SL`: Saarland

- `DE-SN`: Saxony

- `DE-ST`: Saxony-Anhalt

- `DE-TH`: Thuringia

`start_date` must be greater or equal to "1990-01-01". This is because
public holidays in Germany would be ambitious before the reunification
in 1990 (think of the state of Berlin in 1989 and earlier).

`end_date` must be smaller or equal to "2073-12-31" because this is last
year supported by the [nager.Date
API](https://github.com/nager/Nager.Date).

## Examples

``` r
start <- "2024-01-01"
end <- "2024-12-31"

# multiple profile IDs are supported
L <- slp_generate(c("L0", "L1", "L2"), start, end)
head(L)
#>   profile_id          start_time            end_time watts
#> 1         L0 2024-01-01 00:00:00 2024-01-01 00:15:00  68.3
#> 2         L0 2024-01-01 00:15:00 2024-01-01 00:30:00  66.0
#> 3         L0 2024-01-01 00:30:00 2024-01-01 00:45:00  64.3
#> 4         L0 2024-01-01 00:45:00 2024-01-01 01:00:00  63.0
#> 5         L0 2024-01-01 01:00:00 2024-01-01 01:15:00  62.1
#> 6         L0 2024-01-01 01:15:00 2024-01-01 01:30:00  61.4

# you can specify one of the 16 ISO 3166-2:DE codes to take into
# account holidays determined at the level of the federal states
berlin <- slp_generate("H0", start, end, state_code = "DE-BE")

# for convenience, the codes can be specified without the prefix "DE-"
identical(berlin, slp_generate("H0", start, end, state_code = "BE"))
#> [1] TRUE

# state codes are not case-sensitive
identical(berlin, slp_generate("H0", start, end, state_code = "de-be"))
#> [1] TRUE

# consider only nationwide public holidays
H0_2024 <- slp_generate("H0", start, end)

# electric power values are normalized to consumption of ~1,000 kWh/a
sum(H0_2024$watts / 4 / 1000)
#> [1] 1002.084
```
