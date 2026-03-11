# Retrieve information on standard load profiles

Information and examples on standard load profiles from the German
Association of Energy and Water Industries (BDEW Bundesverband der
Energie- und Wasserwirtschaft e.V.)

## Usage

``` r
slp_info(profile_id, language = c("EN", "DE"))
```

## Source

<https://www.bdew.de/energie/standardlastprofile-strom/>

<https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>

<https://www.bdew.de/media/documents/Zuordnung_der_VDEW-Lastprofile_zum_Kundengruppenschluessel.pdf>

## Arguments

- profile_id:

  load profile identifier, required

- language:

  one of 'EN' (English), 'DE' (German)

## Value

A list

## Examples

``` r
slp_info("G5", language = "DE")
#> $G5
#> $G5$profile
#> [1] "G5"
#> 
#> $G5$description
#> [1] "Bäckerei mit Backstube"
#> 
#> $G5$details
#> [1] "Bäckereien mit Backstube haben den Schwerpunkt ihres Verbrauchs an den Werktagen traditionell ab ca. 3 Uhr früh und in der Nacht zum Samstag ab etwa Mitternacht. Der Tagverbrauch ist zum Gesamtbedarf relativ gering und wird hauptsächlich von der Verkaufstätigkeit bestimmt. Verkaufsorientierte Bäckereien, in denen zu Geschäftszeiten Backwaren zubereitet werden ('Backen im Laden'), verhalten sich wie andere Läden und sind im Profil G4 einzuordnen."
#> 
#> 

# multiple profile IDs are supported
slp_info(c("G0", "G5"))
#> $G0
#> $G0$profile
#> [1] "G0"
#> 
#> $G0$description
#> [1] "commerce in general"
#> 
#> $G0$details
#> [1] "If an assignment to one of the profiles G1 to G6 is not possible or desired, this profile represents the weighted average of the overall group."
#> 
#> 
#> $G5
#> $G5$profile
#> [1] "G5"
#> 
#> $G5$description
#> [1] "bakery with bakehouse"
#> 
#> $G5$details
#> [1] "Bakeries with a bakehouse traditionally have their main consumption on weekdays from around 3 a.m. and on Saturday nights from around midnight. Daytime consumption is relatively low compared to overall demand and is mainly determined by sales activities. Sales-oriented bakeries in which bakery products are prepared during business hours ('in-store baking') behave like other stores and are classified in profile G4."
#> 
#> 
```
