#' Load Profile Data for Electricity from BDEW
#'
#'A load profile shows the variation in the electrical load versus time. Data is
#'provided by the German Association of Energy andvWater Industries (BDEW
#'Bundesverband der Energie- und Wasserwirtschaft e.V.).
#'
#' @format A data.frame with 9,504 rows and 5 parameters:
#' \describe{
#'   \item{profile}{character, one of 11 load profiles, see 'Details'}
#'   \item{period}{character, one of 'summer', 'winter', 'transition'}
#'   \item{day}{character, one of 'saturday', 'sunday', 'workday'}
#'   \item{timestamp}{character, format: %H:%M}
#'   \item{watt}{numeric, electricity load}
#' }
#'
#'@examples
#'subset(load_profiles,
#'       profile == "L0" & period == "summer" & day == "workday") |>
#'  dim()
#'  # [1] 96  5
#'
#'@details
#'Data is differentiated by workday, Saturday and Sunday in the three annual
#'periods of winter, transitional period and summer. Hence for each profile
#'there are 96 values per weekday and period.
#'
#'These 96 values per day correspond to the average quarter-hourly power
#'that is expected if the customer / customer group consumes 1000 kWh/a
#'("normalized annual consumption"). Put differently, the sum over all
#'quarter-hourly power values for one calender year equals (roughly)
#'1000 kWh/a.
#'
#'Included are eleven representative load profiles covering three different
#'customer groups:
#'- households: `H0`
#'- commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`
#'- agriculture: `L0`, `L1`, `L2`
#'
#'Call [get_load_profile_info()] to get description for each profile.
#'
#'Periods as defined by the BDEW:
#'- `summer`: May 15 to September 14
#'- `winter`: November 1 to March 20
#'- `transition`: March 21 to May 14, and September 15 to October 31
#'
#'In addition, a distinction is made between three different type of days:
#'- `workday`: Monday to Friday
#'- `saturday`: Saturdays; Dec 24th and Dec 31th are considered a Saturday too,
#'if they are not a Sunday
#'- `sunday`: Sundays and all nationwide holidays in Germany
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/Profile.zip>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
#' @source <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>
#'
"load_profiles"
