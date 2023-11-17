#' Load Profile Data for Electricity from BDEW
#'
#'A load profile shows the variation in the electrical load versus time. Data is
#'provided by the German Association of Energy andvWater Industries (BDEW
#'Bundesverband der Energie- und Wasserwirtschaft e.V.).
#'
#'The load profiles are available in the form of quarter-hourly values in Watt
#'that are standardised to an annual consumption of 1,000 kWh. They are
#'differentiated by workday, Saturday and Sunday in the three annual periods of
#'winter, transitional period and summer. Hence for each profile there are 96
#'values per weekday and period. See 'Details' for more information.
#'
#' @format A data frame with 9,504 rows and 5 columns:
#' \describe{
#'   \item{profile}{character, one of 11 load profiles, see 'Details'}
#'   \item{period}{factor, one of 'summer', 'winter', 'transition'}
#'   \item{day}{factor, one of 'saturday', 'sunday', and 'workday'}
#'   \item{timestamp}{character, format %H:%M}
#'   \item{watt}{numeric, electricity load}
#' }
#'
#'@details
#'Included are eleven representative load profiles covering three different
#'customer groups:
#'- households: `H0`
#'- commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`
#'- agriculture: `L0`, `L1`, `L2`
#'
#'Call [get_load_profile_info()] to get description for each profile.
#'
#'Periods as defined by the BDEW:
#'- summer: May 15 to September 14
#'- winter: November 1 to March 20
#'- transition: March 21 to May 14, and September 15 to October 31
#'
#'In addition, a distinction is made between three different type of days:
#'- `workday`: Monday to Friday
#'- `saturday`: Saturdays; Dec 24th and Dec 31th are considered a Saturday too,
#'if they are not a Sunday
#'- `sunday`'`: Sundays and all nationwide holidays in Germany
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
"load_profiles"
