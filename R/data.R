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
#'@details
#'There are 96 x 1/4h measurements of electrical power for each combination
#'of `profile_id`, `period` and `day`, which we refer to as the "standard load
#'profile". The data was determined in 1999 on the basis of 1,209 measured load
#'profiles of low-voltage customers in Germany.
#'
#'For each profile identifier the measurements were normalized so that they
#'correspond to an annual consumption of 1,000 kWh. So if we sum up all the
#'quarter-hourly consumption values for one year, the result is (approximately)
#'1,000 kWh/a.
#'
#'**Note** The values given for profile H0 are only characteristic calculation
#'values. Only through multiplication with the 4th order polynomial function do
#'they become a representative and dynamized load profile for the group of
#'household customers. This fact is taken care of in the function `slp_generate()`,
#'see `vignette("algorithm-step-by-step")` for more information.
#'
#'There are 11 standard load profiles for 3 different customer groups:
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

