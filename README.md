
<!-- README.md is generated from README.Rmd. Please edit that file -->

# standardlastprofile

<!-- badges: start -->

[![](https://codecov.io/gh/flrd/standardlastprofile/branch/main/graph/badge.svg)](https://codecov.io/gh/flrd/standardlastprofile)
<!-- [![](http://cranlogs.r-pkg.org/badges/last-month/standardlastprofile)](https://cran.r-project.org/package=standardlastprofile) -->
<!-- badges: end -->

This package provides data about load profile for electricity from the
German Association of Energy and Water Industries (BDEW Bundesverband
der Energie- und Wasserwirtschaft e.V.) in a tidy format.

<img src="man/figures/README-readme_example-1.png" width="90%" style="display: block; margin: auto;" />

In practice, standardized load profiles are used by an energy suppliers
to create an annual consumption forecast for customers (or customer
groups) who do not have a modern meter. That is, customers whose
electricity consumption is not continuously measured. A load profile is
a simplification that does not necessarily correspond to the consumption
profile of an individual customer, but is a valid approximation for a
larger group of similar customers.

## Installation

You can install the development version of standardlastprofile from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("flrd/standardlastprofile")
```

## About the data

The standardlastprofile package contains one dataset called
`load_profiles` used for the plot above.

``` r
library(standardlastprofile)
data(package = "standardlastprofile")
```

The dataset contains 9,504 observations of 5 variables. Given a day, a
period and a profile the data in `load_profiles` represents a ‘typical
day’, e.g. a Sunday in winter versus a workday in summer. There are 11
load profiles for 3 customer groups:

``` r
head(load_profiles)
#>   profile period      day timestamp watt
#> 1      H0 winter saturday     00:00 70.8
#> 2      H0 winter saturday     00:15 68.2
#> 3      H0 winter saturday     00:30 65.9
#> 4      H0 winter saturday     00:45 63.3
#> 5      H0 winter saturday     01:00 59.5
#> 6      H0 winter saturday     01:15 55.0
```

If you have no idea what `H0` etc. stands for, you are not alone.

- `H0`: households (German: “Haushalte”)
- `G0` to `G6`: commerce (“Gewerbe”)
- `L0` to `L2`: agriculture (“Landwirtschaft”)

Call `get_load_profile_info()` for more information and examples.

### Generate a load profile

Use the function `get_load_profile()` to generate a load profile.

``` r
get_load_profile(profile = "G5",
                 start_date = "2023-12-22",
                 end_date = "2023-12-27")
```

The algorithm sets a public holiday to be a Sunday, December 24 and 31
to be a Saturday – if they are not a Sunday. **Note**: As of now the
package supports only public holidays for Germany, which were retrieved
from the [nager.Date API](https://github.com/nager/Nager.Date).

<img src="man/figures/README-G5_example-1.png" width="90%" style="display: block; margin: auto;" />

## Source

Data is published on website of BDEW:
<https://www.bdew.de/energie/standardlastprofile-strom/>

## Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://github.com/flrd/standardlastprofile/blob/master/conduct.md).
By participating in this project you agree to abide by its terms.
