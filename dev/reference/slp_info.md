# Retrieve information on standard load profiles

Returns descriptions for electricity and gas standard load profiles
defined by BDEW. Accepts both electricity profile IDs (`H0`, `G0`–`G6`,
`L0`–`L2`, `H25`, `G25`, `L25`, `P25`, `S25`) and gas profile IDs
(`HEF`, `HMF`, `HKO`, `GKO`, `GHA`, `GMK`, `GBD`, `GBH`, `GWA`, `GGA`,
`GBA`, `GGB`, `GPD`, `GMF`, `GHD`).

## Usage

``` r
slp_info(profile_id, language = c("EN", "DE"))
```

## Source

<https://www.bdew.de/energie/standardlastprofile-strom/>

<https://www.bdew.de/energie/standardlastprofile-gas/>

## Arguments

- profile_id:

  character vector of profile identifiers. Electricity and gas IDs can
  be mixed freely.

- language:

  one of `"EN"` (default) or `"DE"`.

## Value

A named list with one element per `profile_id`. Each element is a list
with character components `profile` (the identifier), `description` (a
short label), and — for electricity profiles only — `details` (a longer
explanation).

## Examples

``` r
# Electricity profile
slp_info("H0")
#> $H0
#> $H0$profile
#> [1] "H0"
#> 
#> $H0$description
#> [1] "household"
#> 
#> $H0$details
#> [1] "This profile includes all households with exclusively and predominantly private consumption. Households with predominantly private electrical consumption, i.e. also with minor commercial consumption are e.g. sales representatives, home workers, etc. with an office in the household. The Household profile is not applicable for special applications such as storage heaters or heat pumps."
#> 
#> 

# Gas profile
slp_info("HEF")
#> $HEF
#> $HEF$profile
#> [1] "HEF"
#> 
#> $HEF$description
#> [1] "Single-family home"
#> 
#> 

# Mixed
slp_info(c("H0", "HEF", "GKO"))
#> $H0
#> $H0$profile
#> [1] "H0"
#> 
#> $H0$description
#> [1] "household"
#> 
#> $H0$details
#> [1] "This profile includes all households with exclusively and predominantly private consumption. Households with predominantly private electrical consumption, i.e. also with minor commercial consumption are e.g. sales representatives, home workers, etc. with an office in the household. The Household profile is not applicable for special applications such as storage heaters or heat pumps."
#> 
#> 
#> $HEF
#> $HEF$profile
#> [1] "HEF"
#> 
#> $HEF$description
#> [1] "Single-family home"
#> 
#> 
#> $GKO
#> $GKO$profile
#> [1] "GKO"
#> 
#> $GKO$description
#> [1] "Small commercial"
#> 
#> 

# German descriptions
slp_info("HEF", language = "DE")
#> $HEF
#> $HEF$profile
#> [1] "HEF"
#> 
#> $HEF$description
#> [1] "Einfamilienhaus"
#> 
#> 
```
