
<!-- README.md is generated from README.Rmd. Please edit that file -->

# standardlastprofile

<!-- badges: start -->
<!-- badges: end -->

A load profile describes the consumption profile of an electricity
consumer over a certain period of time. `standardlastprofile` provides
data from the German Association of Energy and Water Industries (BDEW
Bundesverband der Energie- und Wasserwirtschaft e.V.) in a tidy format.

Each of the 11 load profiles represents a simplification for an
electricity supplier to be able to create an annual consumption forecast
for its customers (or customer groups). In practice, the standard load
profiles are used for customers (or customer groups) who do not have
modern metering equipment. That is, customers whose electricity
consumption is not measured continuously.

<img src="man/figures/README-readme_xample-1.png" width="90%" style="display: block; margin: auto;" />

## Installation

You can install the development version of standardlastprofile from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("flrd/standardlastprofile")
```

## About the data

The standardlastprofile package contains one dataset called
`load_profiles` used in the plot above.

``` r
library(standardlastprofile)
data(package = "standardlastprofile")
```

It contains 9.504 observations of 5 variables, you can see the first
records below, see `?load_profiles` for more information.

``` r
head(load_profiles)
#>   profile period  weekday timestamp watt
#> 1      H0 winter saturday     00:00 70.8
#> 2      H0 winter saturday     00:15 68.2
#> 3      H0 winter saturday     00:30 65.9
#> 4      H0 winter saturday     00:45 63.3
#> 5      H0 winter saturday     01:00 59.5
#> 6      H0 winter saturday     01:15 55.0
```

Included are 11 load profiles for 3 customer groups:

- households: ‘H0’
- commerce: ‘G0’, ‘G1’, ‘G2’, ‘G3’, ‘G4’, ‘G5’, ‘G6’
- agriculture: ‘L0’, ‘L1’, ‘L2’

Call `get_load_profile_info()` to see a description for each profile.
