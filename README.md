
<!-- README.md is generated from README.Rmd. Please edit that file -->

# standardlastprofile

<!-- badges: start -->

[![](https://codecov.io/gh/flrd/standardlastprofile/branch/main/graph/badge.svg)](https://codecov.io/gh/flrd/standardlastprofile)
<!-- [![](http://cranlogs.r-pkg.org/badges/last-month/standardlastprofile)](https://cran.r-project.org/package=standardlastprofile) -->
[![R-CMD-check](https://github.com/flrd/standardlastprofile/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/flrd/standardlastprofile/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

This package provides data about representative, standard load profiles
for electricity from the German Association of Energy and Water
Industries (BDEW Bundesverband der Energie- und Wasserwirtschaft e.V.)
in a tidy format.

<img src="man/figures/README-small_multiples-1.png" alt="Small multiple line chart of 11 standard load profiles published by the German Association of Energy and Water Industries (BDEW Bundesverband der Energie- und Wasserwirtschaft e.V.). The lines compare the consumption for three different periods over a year, and also compare the consumption between different days of a week." width="90%" style="display: block; margin: auto;" />

## Installation

<!-- You can install the released version of standardlastprofile from CRAN with: -->
<!-- ```{r eval=FALSE} -->
<!-- install.packages("standardlastprofile") -->
<!-- ``` -->

To install the development version of standardlastprofile from
[GitHub](https://github.com/) call:

``` r
# install.packages("devtools")
devtools::install_github("flrd/standardlastprofile")
```

## About the data

The standardlastprofile package contains one dataset called `slp`. In
total there are 9,504 observations of 5 variables:

- `profile_id`: identifier of standard load profile
- `period`: one of “summer”, “winter”, “transition”
- `day`: one of “saturday”, “sunday”, “workday”
- `timestamp`: format “%H:%M”
- `watts`: electric power

``` r
str(slp)
#> 'data.frame':    9504 obs. of  5 variables:
#>  $ profile_id: chr  "H0" "H0" "H0" "H0" ...
#>  $ period    : chr  "winter" "winter" "winter" "winter" ...
#>  $ day       : chr  "saturday" "saturday" "saturday" "saturday" ...
#>  $ timestamp : chr  "00:00" "00:15" "00:30" "00:45" ...
#>  $ watts     : num  70.8 68.2 65.9 63.3 59.5 55 50.5 46.6 43.9 42.3 ...
```

A standard load profile can be used as a basis for energy utilities to
create an annual consumption forecast for their customers. It is a
simplification that does not necessarily correspond to the consumption
profile of an individual customer, but represents a valid approximation
for a larger group of similar customers.

For each combination of `profile_id`, `period` and `day` there are 96 x
1/4h-measurements in watts. If you have no idea what `H0` stands for,
you are not alone.

- `H0`: households (German: “Haushalte”)
- `G0` to `G6`: commerce (“Gewerbe”)
- `L0` to `L2`: agriculture (“Landwirtschaft”)

Call `slp_info()` for more information.

``` r
slp_info(language = "EN")$H0
#> $profile
#> [1] "H0"
#> 
#> $description
#> [1] "household"
#> 
#> $details
#> [1] "This profile includes all households with exclusively and predominantly private consumption. Households with predominantly private electrical consumption, i.e. also with minor commercial consumption are e.g. sales representatives, home workers, etc. with an office in the household. The Household profile is not applicable for special applications such as storage heaters or heat pumps."
```

### Generate a standard load profile

Use the function `slp_generate()` to generate a standard load profile
for a given period of time:

``` r
G5 <- slp_generate(
  profile_id = "G5",
  start_date = "2023-12-22",
  end_date = "2023-12-27",
  state_code = "DE-BE"       # Berlin
  )
head(G5)
#>   profile_id          start_time            end_time watts
#> 1         G5 2023-12-22 00:00:00 2023-12-22 00:15:00  50.1
#> 2         G5 2023-12-22 00:15:00 2023-12-22 00:30:00  47.4
#> 3         G5 2023-12-22 00:30:00 2023-12-22 00:45:00  44.9
#> 4         G5 2023-12-22 00:45:00 2023-12-22 01:00:00  43.3
#> 5         G5 2023-12-22 01:00:00 2023-12-22 01:15:00  43.0
#> 6         G5 2023-12-22 01:15:00 2023-12-22 01:30:00  43.8
```

<img src="man/figures/README-G5_plot_readme-1.png" alt="Line plot of the standard load profile 'G5' (i.e. Bakery with a bakehouse) based on data from the German Association of Energy and Water Industries (BDEW Bundesverband der Energie- und Wasserwirtschaft e.V.) from December 22nd to December 27th 2023; values are normalized to an annual consumption of 1,000kWh." width="90%" style="display: block; margin: auto;" />

Optionally you can also retrieve public holidays for a given German
state, see
[`vignette("algorithm-step-by-step", package = "standardlastprofile")`](https://flrd.github.io/standardlastprofile/articles/algorithm-step-by-step.html)
for a detailed explanation of the algorithm.

## Source

Data and information about the methodology can be found on website of
the BDEW: <https://www.bdew.de/energie/standardlastprofile-strom/>

## Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://github.com/flrd/standardlastprofile/blob/master/conduct.md).
By participating in this project you agree to abide by its terms.
