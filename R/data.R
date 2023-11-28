#' Standard Load Profile Data for Electricity from BDEW
#'
#'Data about representative, standard load profiles for electricity from
#'the German Association of Energy and Water Industries (BDEW Bundesverband
#'der Energie- und Wasserwirtschaft e.V.) in a tidy format.
#'
#' @format A data.frame with 9,504 observations and 5 variables:
#' \describe{
#'   \item{profile_id}{character, identifier for load profile, see 'Details'}
#'   \item{period}{character, one of 'summer', 'winter', 'transition'}
#'   \item{day}{character, one of 'saturday', 'sunday', 'workday'}
#'   \item{timestamp}{character, format: %H:%M}
#'   \item{watt}{numeric, electric power}
#' }
#'
#'@examples
#'head(slp)
#'
#'# There are 96 observations for each combination of profile_id, period and day
#'tmp <- subset(slp, profile_id == "L0" & period == "summer" & day == "workday")
#'dim(tmp)
#'# [1] 96  5
#'
#'@details
#'There are 96 values for each combination of profile_id, period and day. These
#'are 1/4-hour measurements and represent a standard load profile
#'(German: "Standardlastprofil"). The data was derived in 1999 on the
#'basis of 1,209 measured load profiles from low-voltage customers in Germany
#'
#'These 96 values per day correspond to the average quarter-hourly power
#'that is expected if the customer / customer group consumes 1000 kWh/a
#'("normalized annual consumption"). So if we sum up all the quarter-hourly
#'consumption values for one year, the result is (approximately) 1,000 kWh/a. See
#'vignette("algorithm-step-by-step") for more information.
#'
#'In total there are 11 representative, standard load profiles for 3 different
#'customer groups:
#'
#'- households: `H0`
#'- commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`
#'- agriculture: `L0`, `L1`, `L2`
#'
#'Call [slp_info()] to for more information and examples.
#'
#'Periods are defined as:
#'- `summer`: May 15 to September 14
#'- `winter`: November 1 to March 20
#'- `transition`: March 21 to May 14, and September 15 to October 31
#'
#'There are 3 different characteristic days:
#'- `workday`: Monday to Friday
#'- `saturday`: Saturdays; Dec 24th and Dec 31th are considered a Saturday too,
#'if they are not a Sunday
#'- `sunday`: Sundays and all public holidays in Germany
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/Profile.zip>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
#' @source <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>
#'
"slp"
